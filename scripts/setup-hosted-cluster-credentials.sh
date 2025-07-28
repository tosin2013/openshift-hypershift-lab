#!/bin/bash

# setup-hosted-cluster-credentials.sh
# Script to set up credentials for hosted cluster instances

set -euo pipefail

# Default values
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] CLUSTER_NAME

Set up credentials for a hosted cluster instance.

OPTIONS:
    --namespace NAMESPACE           Cluster namespace (default: clusters)
    --pull-secret-path PATH         Path to pull secret file (default: ~/pull-secret.json)
    --ssh-key-path PATH             Path to SSH private key (default: ~/.ssh/id_rsa)
    --aws-credentials-path PATH     Path to AWS credentials file (for AWS clusters)
    --platform PLATFORM            Platform type (kubevirt, aws) (default: kubevirt)
    --create-ssh-key                Create new SSH key if not found
    --interactive                   Interactive mode for credential setup
    --use-existing-credentials NAME Use existing credentials from another namespace
    --credentials-namespace NS      Namespace where existing credentials are located (default: virt-creds)
    --use-external-secrets          Use External Secrets Operator for credential management
    --setup-external-secrets        Set up External Secrets Operator configuration
    --dry-run                       Show what would be created without creating
    -h, --help                      Show this help message

EXAMPLES:
    # Set up credentials for KubeVirt cluster
    $0 dev-cluster-01

    # Set up credentials with custom paths
    $0 --pull-secret-path /path/to/pull-secret.json --ssh-key-path ~/.ssh/openshift-key dev-cluster-01

    # Set up AWS cluster credentials
    $0 --platform aws --aws-credentials-path ~/.aws/credentials prod-cluster-01

    # Use existing RHACM credentials from virt-creds namespace
    $0 --use-existing-credentials virt-creds --credentials-namespace virt-creds dev-cluster-01

    # Use External Secrets Operator for credential management
    $0 --use-external-secrets dev-cluster-01

    # Set up External Secrets Operator configuration
    $0 --setup-external-secrets

    # Interactive setup
    $0 --interactive --create-ssh-key dev-cluster-01

EOF
}

# Function to check if oc is available
check_oc() {
    if ! command -v oc &> /dev/null; then
        print_error "oc (OpenShift CLI) is required but not installed"
        exit 1
    fi
}

# Function to check if cluster is logged in
check_login() {
    if ! oc whoami &> /dev/null; then
        print_error "Not logged in to OpenShift cluster. Please run 'oc login' first."
        exit 1
    fi
}

# Function to validate pull secret
validate_pull_secret() {
    local pull_secret_path="$1"
    
    if [[ ! -f "$pull_secret_path" ]]; then
        print_error "Pull secret not found at: $pull_secret_path"
        return 1
    fi
    
    if ! jq empty "$pull_secret_path" 2>/dev/null; then
        print_error "Pull secret is not valid JSON: $pull_secret_path"
        return 1
    fi
    
    # Check if it contains required fields
    if ! jq -e '.auths' "$pull_secret_path" >/dev/null 2>&1; then
        print_error "Pull secret does not contain 'auths' field"
        return 1
    fi
    
    print_success "Pull secret validation passed"
    return 0
}

# Function to setup pull secret
setup_pull_secret() {
    local cluster_name="$1"
    local namespace="$2"
    local pull_secret_path="$3"
    local dry_run="$4"
    
    print_info "Setting up pull secret for cluster: $cluster_name"
    
    # Validate pull secret
    if ! validate_pull_secret "$pull_secret_path"; then
        return 1
    fi
    
    local secret_name="pullsecret-cluster"
    
    if [[ "$dry_run" == "true" ]]; then
        print_info "DRY RUN: Would create pull secret '$secret_name' in namespace '$namespace'"
        return 0
    fi
    
    # Check if secret already exists
    if oc get secret "$secret_name" -n "$namespace" &>/dev/null; then
        print_warning "Pull secret '$secret_name' already exists in namespace '$namespace'"
        read -p "Do you want to update it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping pull secret update"
            return 0
        fi
        
        # Delete existing secret
        oc delete secret "$secret_name" -n "$namespace"
    fi
    
    # Create pull secret
    oc create secret generic "$secret_name" \
        --from-file=.dockerconfigjson="$pull_secret_path" \
        --type=kubernetes.io/dockerconfigjson \
        -n "$namespace"
    
    print_success "Pull secret '$secret_name' created successfully"
}

# Function to setup SSH key
setup_ssh_key() {
    local cluster_name="$1"
    local namespace="$2"
    local ssh_key_path="$3"
    local create_key="$4"
    local dry_run="$5"
    
    print_info "Setting up SSH key for cluster: $cluster_name"
    
    # Check if SSH key exists
    if [[ ! -f "$ssh_key_path" ]]; then
        if [[ "$create_key" == "true" ]]; then
            print_info "Creating new SSH key: $ssh_key_path"
            
            if [[ "$dry_run" == "true" ]]; then
                print_info "DRY RUN: Would create SSH key at $ssh_key_path"
            else
                # Create directory if it doesn't exist
                mkdir -p "$(dirname "$ssh_key_path")"
                
                # Generate SSH key
                ssh-keygen -t rsa -b 4096 -f "$ssh_key_path" -N "" -C "openshift-hosted-cluster-$cluster_name"
                chmod 600 "$ssh_key_path"
                chmod 644 "${ssh_key_path}.pub"
                
                print_success "SSH key created: $ssh_key_path"
            fi
        else
            print_error "SSH key not found at: $ssh_key_path"
            print_info "Use --create-ssh-key to create a new key"
            return 1
        fi
    fi
    
    # Validate SSH key
    if [[ "$dry_run" != "true" ]] && [[ -f "$ssh_key_path" ]]; then
        if ! ssh-keygen -l -f "$ssh_key_path" &>/dev/null; then
            print_error "Invalid SSH key: $ssh_key_path"
            return 1
        fi
    fi
    
    local secret_name="sshkey-cluster"
    local pub_key_path="${ssh_key_path}.pub"
    
    if [[ "$dry_run" == "true" ]]; then
        print_info "DRY RUN: Would create SSH key secret '$secret_name' in namespace '$namespace'"
        return 0
    fi
    
    # Check if public key exists
    if [[ ! -f "$pub_key_path" ]]; then
        print_error "SSH public key not found: $pub_key_path"
        return 1
    fi
    
    # Check if secret already exists
    if oc get secret "$secret_name" -n "$namespace" &>/dev/null; then
        print_warning "SSH key secret '$secret_name' already exists in namespace '$namespace'"
        read -p "Do you want to update it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping SSH key secret update"
            return 0
        fi
        
        # Delete existing secret
        oc delete secret "$secret_name" -n "$namespace"
    fi
    
    # Create SSH key secret
    oc create secret generic "$secret_name" \
        --from-file=id_rsa.pub="$pub_key_path" \
        -n "$namespace"
    
    print_success "SSH key secret '$secret_name' created successfully"
}

# Function to copy existing credentials from another namespace
copy_existing_credentials() {
    local cluster_name="$1"
    local target_namespace="$2"
    local source_secret_name="$3"
    local source_namespace="$4"
    local dry_run="$5"

    print_info "Copying existing credentials from $source_namespace/$source_secret_name"

    if [[ "$dry_run" == "true" ]]; then
        print_info "DRY RUN: Would copy credentials from $source_namespace/$source_secret_name to $target_namespace"
        return 0
    fi

    # Check if source secret exists
    if ! oc get secret "$source_secret_name" -n "$source_namespace" &>/dev/null; then
        print_error "Source credentials secret '$source_secret_name' not found in namespace '$source_namespace'"
        return 1
    fi

    # Get the source secret data
    local pull_secret_data ssh_key_data
    pull_secret_data=$(oc get secret "$source_secret_name" -n "$source_namespace" -o jsonpath='{.data.pullSecret}' 2>/dev/null || echo "")
    ssh_key_data=$(oc get secret "$source_secret_name" -n "$source_namespace" -o jsonpath='{.data.ssh-publickey}' 2>/dev/null || echo "")

    if [[ -z "$pull_secret_data" ]]; then
        print_error "pullSecret not found in source secret"
        return 1
    fi

    if [[ -z "$ssh_key_data" ]]; then
        print_error "ssh-publickey not found in source secret"
        return 1
    fi

    # Create pull secret for the cluster
    local pull_secret_name="pullsecret-cluster-${cluster_name}"
    if oc get secret "$pull_secret_name" -n "$target_namespace" &>/dev/null; then
        print_warning "Pull secret '$pull_secret_name' already exists, updating..."
        oc delete secret "$pull_secret_name" -n "$target_namespace"
    fi

    echo "$pull_secret_data" | base64 -d | oc create secret docker-registry "$pull_secret_name" \
        --from-file=.dockerconfigjson=/dev/stdin \
        -n "$target_namespace"

    # Create SSH key secret for the cluster
    local ssh_secret_name="sshkey-cluster-${cluster_name}"
    if oc get secret "$ssh_secret_name" -n "$target_namespace" &>/dev/null; then
        print_warning "SSH key secret '$ssh_secret_name' already exists, updating..."
        oc delete secret "$ssh_secret_name" -n "$target_namespace"
    fi

    oc create secret generic "$ssh_secret_name" \
        --from-literal=id_rsa.pub="$(echo "$ssh_key_data" | base64 -d)" \
        -n "$target_namespace"

    print_success "Successfully copied credentials from $source_namespace/$source_secret_name"
    print_info "Created secrets: $pull_secret_name, $ssh_secret_name"
}

# Function to verify virt-creds secret exists and has required data
verify_virt_creds() {
    local dry_run="$1"

    if [[ "$dry_run" == "true" ]]; then
        print_info "DRY RUN: Would verify virt-creds secret"
        return 0
    fi

    # Check if virt-creds namespace exists
    if ! oc get namespace virt-creds &>/dev/null; then
        print_error "virt-creds namespace not found"
        print_info "Please ensure the virt-creds namespace and secret are set up"
        return 1
    fi

    # Check if virt-creds secret exists
    if ! oc get secret virt-creds -n virt-creds &>/dev/null; then
        print_error "virt-creds secret not found in virt-creds namespace"
        print_info "Please ensure the virt-creds secret is set up with pullSecret and ssh-publickey"
        return 1
    fi

    # Check if required keys exist
    local pull_secret_exists ssh_key_exists
    pull_secret_exists=$(oc get secret virt-creds -n virt-creds -o jsonpath='{.data.pullSecret}' 2>/dev/null || echo "")
    ssh_key_exists=$(oc get secret virt-creds -n virt-creds -o jsonpath='{.data.ssh-publickey}' 2>/dev/null || echo "")

    if [[ -z "$pull_secret_exists" ]]; then
        print_error "pullSecret not found in virt-creds secret"
        return 1
    fi

    if [[ -z "$ssh_key_exists" ]]; then
        print_error "ssh-publickey not found in virt-creds secret"
        return 1
    fi

    print_success "virt-creds secret verified successfully"
    return 0
}

# Function to setup External Secrets Operator configuration
setup_external_secrets_operator() {
    local dry_run="$1"

    print_info "Setting up External Secrets Operator configuration..."

    if [[ "$dry_run" == "true" ]]; then
        print_info "DRY RUN: Would set up External Secrets Operator configuration"
        return 0
    fi

    # Check if External Secrets Operator is installed
    if ! oc get crd externalsecrets.external-secrets.io &>/dev/null; then
        print_error "External Secrets Operator is not installed"
        print_info "Installing External Secrets Operator via GitOps..."
        print_info "Applying: gitops/cluster-config/apps/openshift-hypershift-lab/external-secrets-operator.yaml"

        if oc apply -f "$PROJECT_ROOT/gitops/cluster-config/apps/openshift-hypershift-lab/external-secrets-operator.yaml"; then
            print_info "External Secrets Operator installation initiated"
            print_info "Waiting for operator to be ready..."

            # Wait for the CRD to be available (up to 5 minutes)
            local timeout=300
            local elapsed=0
            while ! oc get crd externalsecrets.external-secrets.io &>/dev/null && [ $elapsed -lt $timeout ]; do
                sleep 10
                elapsed=$((elapsed + 10))
                print_info "Waiting for External Secrets Operator... ($elapsed/${timeout}s)"
            done

            if ! oc get crd externalsecrets.external-secrets.io &>/dev/null; then
                print_error "External Secrets Operator installation timed out"
                return 1
            fi

            print_success "External Secrets Operator is now available"
        else
            print_error "Failed to install External Secrets Operator"
            return 1
        fi
    fi

    # Apply the External Secrets configuration
    local eso_config_dir="$PROJECT_ROOT/gitops/cluster-config/external-secrets-operator-instance/overlays/default"
    if [[ -d "$eso_config_dir" ]]; then
        print_info "Applying External Secrets Operator configuration..."
        oc apply -k "$eso_config_dir"
        print_success "External Secrets Operator configuration applied"
    else
        print_error "External Secrets configuration not found: $eso_config_dir"
        return 1
    fi
}

# Function to create ExternalSecret resources for a cluster
create_external_secrets() {
    local cluster_name="$1"
    local namespace="$2"
    local dry_run="$3"

    print_info "Creating ExternalSecret resources for cluster: $cluster_name"

    if [[ "$dry_run" == "true" ]]; then
        print_info "DRY RUN: Would create ExternalSecret resources for $cluster_name"
        return 0
    fi

    # Create temporary directory for ExternalSecret manifests
    local temp_dir=$(mktemp -d)
    local template_file="$PROJECT_ROOT/gitops/cluster-config/external-secrets-operator-instance/base/externalsecret-template.yaml"

    if [[ ! -f "$template_file" ]]; then
        print_error "ExternalSecret template not found: $template_file"
        rm -rf "$temp_dir"
        return 1
    fi

    # Generate ExternalSecret manifests
    sed "s/CLUSTER_NAME_PLACEHOLDER/$cluster_name/g" "$template_file" > "$temp_dir/externalsecrets.yaml"

    # Apply the ExternalSecret resources
    oc apply -f "$temp_dir/externalsecrets.yaml"

    # Clean up
    rm -rf "$temp_dir"

    print_success "ExternalSecret resources created for cluster: $cluster_name"
    print_info "Secrets will be automatically synced from virt-creds namespace"
}

# Function to setup infrastructure credentials
setup_infra_credentials() {
    local cluster_name="$1"
    local namespace="$2"
    local dry_run="$3"
    
    print_info "Setting up infrastructure credentials for cluster: $cluster_name"
    
    local secret_name="${cluster_name}-infra-credentials"
    
    if [[ "$dry_run" == "true" ]]; then
        print_info "DRY RUN: Would create infrastructure credentials secret '$secret_name' in namespace '$namespace'"
        return 0
    fi
    
    # Check if secret already exists
    if oc get secret "$secret_name" -n "$namespace" &>/dev/null; then
        print_warning "Infrastructure credentials secret '$secret_name' already exists"
        read -p "Do you want to update it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping infrastructure credentials update"
            return 0
        fi
        
        # Delete existing secret
        oc delete secret "$secret_name" -n "$namespace"
    fi
    
    # Get current kubeconfig
    local current_kubeconfig="${KUBECONFIG:-$HOME/.kube/config}"
    
    if [[ ! -f "$current_kubeconfig" ]]; then
        print_error "Kubeconfig not found: $current_kubeconfig"
        return 1
    fi
    
    # Create infrastructure credentials secret
    oc create secret generic "$secret_name" \
        --from-file=kubeconfig="$current_kubeconfig" \
        -n "$namespace"
    
    print_success "Infrastructure credentials secret '$secret_name' created successfully"
}

# Function to setup AWS credentials
setup_aws_credentials() {
    local cluster_name="$1"
    local namespace="$2"
    local aws_credentials_path="$3"
    local dry_run="$4"
    
    print_info "Setting up AWS credentials for cluster: $cluster_name"
    
    if [[ ! -f "$aws_credentials_path" ]]; then
        print_error "AWS credentials file not found: $aws_credentials_path"
        return 1
    fi
    
    local secret_name="${cluster_name}-aws-credentials"
    
    if [[ "$dry_run" == "true" ]]; then
        print_info "DRY RUN: Would create AWS credentials secret '$secret_name' in namespace '$namespace'"
        return 0
    fi
    
    # Check if secret already exists
    if oc get secret "$secret_name" -n "$namespace" &>/dev/null; then
        print_warning "AWS credentials secret '$secret_name' already exists"
        read -p "Do you want to update it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping AWS credentials update"
            return 0
        fi
        
        # Delete existing secret
        oc delete secret "$secret_name" -n "$namespace"
    fi
    
    # Create AWS credentials secret
    oc create secret generic "$secret_name" \
        --from-file=credentials="$aws_credentials_path" \
        -n "$namespace"
    
    print_success "AWS credentials secret '$secret_name' created successfully"
}

# Function to interactive pull secret setup
interactive_pull_secret_setup() {
    local pull_secret_path="$1"
    
    if [[ -f "$pull_secret_path" ]] && validate_pull_secret "$pull_secret_path"; then
        return 0
    fi
    
    print_error "Pull secret not found or invalid at: $pull_secret_path"
    echo ""
    print_info "To obtain your pull secret:"
    echo "  1. Visit: https://console.redhat.com/openshift/install/pull-secret"
    echo "  2. Log in with your Red Hat account"
    echo "  3. Click 'Download pull secret'"
    echo "  4. Save the file as: $pull_secret_path"
    echo ""
    
    # Try to open browser
    if command -v xdg-open &> /dev/null; then
        read -p "Open browser to download pull secret? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            xdg-open "https://console.redhat.com/openshift/install/pull-secret" &
        fi
    fi
    
    read -p "Press Enter after you've saved the pull secret to $pull_secret_path..."
    
    if ! validate_pull_secret "$pull_secret_path"; then
        print_error "Pull secret setup failed"
        return 1
    fi
    
    return 0
}

# Function to run credential setup
run_credential_setup() {
    local cluster_name="$1"
    local namespace="$2"
    local pull_secret_path="$3"
    local ssh_key_path="$4"
    local aws_credentials_path="$5"
    local platform="$6"
    local create_ssh_key="$7"
    local interactive="$8"
    local use_existing_credentials="$9"
    local credentials_namespace="${10}"
    local use_external_secrets="${11}"
    local setup_external_secrets="${12}"
    local dry_run="${13}"
    
    print_info "Setting up credentials for hosted cluster: $cluster_name"
    print_info "Platform: $platform"
    print_info "Namespace: $namespace"

    # Handle External Secrets setup if specified
    if [[ "$setup_external_secrets" == "true" ]]; then
        print_info "Setting up External Secrets Operator configuration..."
        if ! setup_external_secrets_operator "$dry_run"; then
            return 1
        fi
        print_success "External Secrets Operator setup completed"
        return 0
    fi

    # Handle External Secrets for cluster credentials
    if [[ "$use_external_secrets" == "true" ]]; then
        print_info "Using External Secrets Operator for credential management..."

        # Verify virt-creds secret exists
        if ! verify_virt_creds "$dry_run"; then
            print_error "virt-creds verification failed"
            return 1
        fi

        # Create namespace if it doesn't exist
        if [[ "$dry_run" != "true" ]]; then
            if ! oc get namespace "$namespace" &>/dev/null; then
                print_info "Creating namespace: $namespace"
                oc create namespace "$namespace"
            fi
        fi

        # Create ExternalSecret resources
        if ! create_external_secrets "$cluster_name" "$namespace" "$dry_run"; then
            return 1
        fi

        # Setup infrastructure credentials (still needed)
        if ! setup_infra_credentials "$cluster_name" "$namespace" "$dry_run"; then
            return 1
        fi

        print_success "Credential setup completed using External Secrets Operator"
        return 0
    fi

    # Handle existing credentials if specified
    if [[ -n "$use_existing_credentials" ]]; then
        print_info "Using existing credentials: $use_existing_credentials from namespace: $credentials_namespace"

        # Create namespace if it doesn't exist
        if [[ "$dry_run" != "true" ]]; then
            if ! oc get namespace "$namespace" &>/dev/null; then
                print_info "Creating namespace: $namespace"
                oc create namespace "$namespace"
            fi
        fi

        # Copy existing credentials
        if ! copy_existing_credentials "$cluster_name" "$namespace" "$use_existing_credentials" "$credentials_namespace" "$dry_run"; then
            return 1
        fi

        # Setup infrastructure credentials (still needed)
        if ! setup_infra_credentials "$cluster_name" "$namespace" "$dry_run"; then
            return 1
        fi

        print_success "Credential setup completed using existing credentials: $use_existing_credentials"
        return 0
    fi
    
    # Create namespace if it doesn't exist
    if [[ "$dry_run" != "true" ]]; then
        if ! oc get namespace "$namespace" &>/dev/null; then
            print_info "Creating namespace: $namespace"
            oc create namespace "$namespace"
        fi
    fi
    
    # Interactive pull secret setup
    if [[ "$interactive" == "true" ]]; then
        if ! interactive_pull_secret_setup "$pull_secret_path"; then
            return 1
        fi
    fi
    
    # Setup pull secret
    if ! setup_pull_secret "$cluster_name" "$namespace" "$pull_secret_path" "$dry_run"; then
        return 1
    fi
    
    # Setup SSH key
    if ! setup_ssh_key "$cluster_name" "$namespace" "$ssh_key_path" "$create_ssh_key" "$dry_run"; then
        return 1
    fi
    
    # Setup infrastructure credentials
    if ! setup_infra_credentials "$cluster_name" "$namespace" "$dry_run"; then
        return 1
    fi
    
    # Setup AWS credentials if needed
    if [[ "$platform" == "aws" ]] && [[ -n "$aws_credentials_path" ]]; then
        if ! setup_aws_credentials "$cluster_name" "$namespace" "$aws_credentials_path" "$dry_run"; then
            return 1
        fi
    fi
    
    print_success "Credential setup completed for cluster: $cluster_name"
    
    # Show next steps
    echo ""
    print_info "Next steps:"
    print_info "  1. Create the hosted cluster instance:"
    print_info "     ./scripts/create-hosted-cluster-instance.sh --name $cluster_name --domain <your-domain>"
    print_info "  2. Deploy using GitOps:"
    print_info "     oc apply -f gitops/cluster-config/apps/openshift-hypershift-lab/hosted-clusters-applicationset.yaml"
    print_info "  3. Validate deployment:"
    print_info "     ./scripts/validate-deployment.sh $cluster_name"
}

# Parse command line arguments
CLUSTER_NAME=""
NAMESPACE="clusters"
PULL_SECRET_PATH="$HOME/pull-secret.json"
SSH_KEY_PATH="$HOME/.ssh/id_rsa"
AWS_CREDENTIALS_PATH=""
PLATFORM="kubevirt"
CREATE_SSH_KEY="false"
INTERACTIVE="false"
USE_EXISTING_CREDENTIALS=""
CREDENTIALS_NAMESPACE="virt-creds"
USE_EXTERNAL_SECRETS="false"
SETUP_EXTERNAL_SECRETS="false"
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --pull-secret-path)
            PULL_SECRET_PATH="$2"
            shift 2
            ;;
        --ssh-key-path)
            SSH_KEY_PATH="$2"
            shift 2
            ;;
        --aws-credentials-path)
            AWS_CREDENTIALS_PATH="$2"
            shift 2
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --create-ssh-key)
            CREATE_SSH_KEY="true"
            shift
            ;;
        --interactive)
            INTERACTIVE="true"
            shift
            ;;
        --use-existing-credentials)
            USE_EXISTING_CREDENTIALS="$2"
            shift 2
            ;;
        --credentials-namespace)
            CREDENTIALS_NAMESPACE="$2"
            shift 2
            ;;
        --use-external-secrets)
            USE_EXTERNAL_SECRETS="true"
            shift
            ;;
        --setup-external-secrets)
            SETUP_EXTERNAL_SECRETS="true"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            if [[ -z "$CLUSTER_NAME" ]]; then
                CLUSTER_NAME="$1"
            else
                print_error "Multiple cluster names provided: $CLUSTER_NAME and $1"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Handle setup-external-secrets mode (doesn't require cluster name)
if [[ "$SETUP_EXTERNAL_SECRETS" == "true" ]]; then
    setup_external_secrets_operator "$DRY_RUN"
    exit $?
fi

# Validate required parameters
if [[ -z "$CLUSTER_NAME" ]]; then
    print_error "Cluster name is required"
    usage
    exit 1
fi

# Validate platform
if [[ "$PLATFORM" != "kubevirt" ]] && [[ "$PLATFORM" != "aws" ]]; then
    print_error "Invalid platform: $PLATFORM (must be kubevirt or aws)"
    exit 1
fi

# Check prerequisites
check_oc
if [[ "$DRY_RUN" != "true" ]]; then
    check_login
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    print_error "jq is required but not installed. Please install jq first."
    exit 1
fi

# Run credential setup
run_credential_setup "$CLUSTER_NAME" "$NAMESPACE" "$PULL_SECRET_PATH" "$SSH_KEY_PATH" "$AWS_CREDENTIALS_PATH" "$PLATFORM" "$CREATE_SSH_KEY" "$INTERACTIVE" "$USE_EXISTING_CREDENTIALS" "$CREDENTIALS_NAMESPACE" "$USE_EXTERNAL_SECRETS" "$SETUP_EXTERNAL_SECRETS" "$DRY_RUN"
