#!/bin/bash

# create-hosted-cluster-instance.sh
# Script to create a new hosted cluster instance from template

set -euo pipefail

# Default values
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="$PROJECT_ROOT/gitops/cluster-config/virt-lab-env/overlays/template"
INSTANCES_DIR="$PROJECT_ROOT/gitops/cluster-config/virt-lab-env/overlays/instances"

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

# Function to ensure yq is available
ensure_yq() {
    if ! command -v yq &> /dev/null; then
        print_info "Installing yq..."
        if command -v curl &> /dev/null; then
            curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /tmp/yq
            chmod +x /tmp/yq
            sudo mv /tmp/yq /usr/local/bin/yq
        else
            print_error "curl not found. Please install yq manually."
            exit 1
        fi
    fi
}

# Function to update YAML using yq
update_yaml_config() {
    local file="$1"
    local instance_name="$2"
    local environment="$3"
    local base_domain="$4"
    local replicas="$5"
    local memory="$6"
    local cores="$7"
    local storage_size="$8"
    local storage_class="$9"
    local clusterset="${10}"
    local release_image="${11}"

    print_info "Updating YAML configuration using yq"

    # Update cluster identification
    yq eval ".configMapGenerator[0].literals[] |= select(. | test(\"CLUSTER_NAME=\")) = \"CLUSTER_NAME=$instance_name\"" -i "$file"
    yq eval ".configMapGenerator[0].literals[] |= select(. | test(\"ENVIRONMENT=\")) = \"ENVIRONMENT=$environment\"" -i "$file"
    yq eval ".configMapGenerator[0].literals[] |= select(. | test(\"BASE_DOMAIN=\")) = \"BASE_DOMAIN=$base_domain\"" -i "$file"

    # Update nodepool configuration
    yq eval ".configMapGenerator[0].literals[] |= select(. | test(\"NODEPOOL_REPLICAS=\")) = \"NODEPOOL_REPLICAS=$replicas\"" -i "$file"
    yq eval ".configMapGenerator[0].literals[] |= select(. | test(\"NODEPOOL_MEMORY=\")) = \"NODEPOOL_MEMORY=$memory\"" -i "$file"
    yq eval ".configMapGenerator[0].literals[] |= select(. | test(\"NODEPOOL_CORES=\")) = \"NODEPOOL_CORES=$cores\"" -i "$file"
    yq eval ".configMapGenerator[0].literals[] |= select(. | test(\"VOLUME_SIZE=\")) = \"VOLUME_SIZE=$storage_size\"" -i "$file"
    yq eval ".configMapGenerator[0].literals[] |= select(. | test(\"STORAGE_CLASS=\")) = \"STORAGE_CLASS=$storage_class\"" -i "$file"
    yq eval ".configMapGenerator[0].literals[] |= select(. | test(\"CLUSTERSET=\")) = \"CLUSTERSET=$clusterset\"" -i "$file"
    yq eval ".configMapGenerator[0].literals[] |= select(. | test(\"NODEPOOL_FULL_NAME=\")) = \"NODEPOOL_FULL_NAME=$instance_name-pool-1\"" -i "$file"

    # Update release image if provided
    if [[ -n "$release_image" ]]; then
        yq eval ".configMapGenerator[0].literals[] |= select(. | test(\"RELEASE_IMAGE=\")) = \"RELEASE_IMAGE=$release_image\"" -i "$file"
    fi

    # Update labels (handle both label sections)
    yq eval "(.labels[] | select(has(\"pairs\")) | .pairs.cluster) = \"$instance_name\"" -i "$file"
    yq eval "(.labels[] | select(has(\"pairs\")) | .pairs.environment) = \"$environment\"" -i "$file"

    # Update patches section to replace example-instance with actual cluster name
    print_info "Updating patches section with cluster name: $instance_name"

    # Use sed to replace cluster names in the patches (simpler than complex yq)
    sed -i "s/example-instance/$instance_name/g" "$file"
    sed -i "s/pullsecret-cluster-$instance_name/pullsecret-cluster-$instance_name/g" "$file"
    sed -i "s/sshkey-cluster-$instance_name/sshkey-cluster-$instance_name/g" "$file"
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Create a new hosted cluster instance from template.

OPTIONS:
    -n, --name INSTANCE_NAME        Name of the hosted cluster instance (required)
    -e, --environment ENVIRONMENT   Environment (dev, staging, prod) (default: dev)
    -d, --domain BASE_DOMAIN         Base domain for hosted clusters (auto-detected from management cluster if not provided)
    -r, --replicas REPLICAS          Number of worker node replicas (default: 3)
    -m, --memory MEMORY              Memory per worker node (default: 8Gi)
    -c, --cores CORES                CPU cores per worker node (default: 4)
    -s, --storage-size SIZE          Root volume size (default: 32Gi)
    --storage-class CLASS            Storage class (default: gp3-csi)
    --release-image IMAGE            OpenShift release image (optional)
    --clusterset CLUSTERSET          Cluster set name (default: default)
    --setup-credentials              Set up credentials after creating instance
    --pull-secret-path PATH          Path to pull secret file (default: ~/pull-secret.json)
    --ssh-key-path PATH              Path to SSH private key (default: ~/.ssh/id_rsa)
    --create-ssh-key                 Create new SSH key if not found
    --interactive-credentials        Interactive credential setup
    --use-shared-credentials NAME    Use existing shared credentials (RHACM pattern)
    --credentials-namespace NS       Namespace for shared credentials (default: virt-creds)
    --infra-namespace NS             Namespace for infrastructure credentials (default: CLUSTER_NAME-creds)
    --dry-run                        Show what would be created without creating
    -h, --help                       Show this help message

EXAMPLES:
    # Create a development cluster (domain auto-detected from management cluster)
    $0 -n dev-cluster-01 -e dev

    # Create a production cluster with custom resources (domain auto-detected)
    $0 -n prod-cluster-01 -e prod -r 5 -m 16Gi -c 8

    # Create cluster with custom domain (for different management clusters)
    $0 -n dev-cluster-01 -e dev -d apps.my-mgmt-cluster.example.com

    # Create cluster for different management cluster environments
    $0 -n test-cluster -e dev -d apps.test-mgmt.lab.example.com

    # Create cluster and set up credentials interactively
    $0 -n dev-cluster-01 -e dev --setup-credentials --interactive-credentials

    # Create cluster using RHACM shared credentials
    $0 -n dev-cluster-01 -e dev --use-shared-credentials virt-creds

    # Dry run to see what would be created
    $0 -n test-cluster -e dev --dry-run

PREREQUISITES:
    Before creating a hosted cluster, you need to set up credentials:

    1. Pull Secret: Download from https://console.redhat.com/openshift/install/pull-secret
    2. SSH Key: For node access (can be auto-generated with --create-ssh-key)
    3. Management Cluster Access: Must be logged in with 'oc login'

    Use --setup-credentials to automatically configure these after instance creation.

EOF
}

# Function to validate cluster name
validate_cluster_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
        print_error "Invalid cluster name: $name"
        print_error "Cluster name must be DNS-compatible (lowercase letters, numbers, and hyphens only)"
        return 1
    fi
    if [[ ${#name} -gt 63 ]]; then
        print_error "Cluster name too long: $name (max 63 characters)"
        return 1
    fi
}

# Function to validate domain
validate_domain() {
    local domain="$1"
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$ ]]; then
        print_error "Invalid domain format: $domain"
        return 1
    fi
}

# Function to check if instance already exists
check_instance_exists() {
    local instance_name="$1"
    local instance_dir="$INSTANCES_DIR/$instance_name"
    
    if [[ -d "$instance_dir" ]]; then
        print_error "Instance '$instance_name' already exists at: $instance_dir"
        return 1
    fi
}

# Function to create instance directory and files
create_instance() {
    local instance_name="$1"
    local environment="$2"
    local base_domain="$3"
    local replicas="$4"
    local memory="$5"
    local cores="$6"
    local storage_size="$7"
    local storage_class="$8"
    local release_image="$9"
    local clusterset="${10}"
    local dry_run="${11}"
    
    local instance_dir="$INSTANCES_DIR/$instance_name"
    
    if [[ "$dry_run" == "true" ]]; then
        print_info "DRY RUN: Would create instance at: $instance_dir"
        print_info "DRY RUN: Configuration:"
        print_info "  - Name: $instance_name"
        print_info "  - Environment: $environment"
        print_info "  - Base Domain: $base_domain"
        print_info "  - Replicas: $replicas"
        print_info "  - Memory: $memory"
        print_info "  - Cores: $cores"
        print_info "  - Storage Size: $storage_size"
        print_info "  - Storage Class: $storage_class"
        print_info "  - Release Image: $release_image"
        print_info "  - Cluster Set: $clusterset"
        return 0
    fi
    
    # Create instance directory
    print_info "Creating instance directory: $instance_dir"
    mkdir -p "$instance_dir"
    
    # Ensure yq is available
    ensure_yq

    # Copy base kustomization template
    print_info "Creating kustomization.yaml from base template"
    cp "$PROJECT_ROOT/gitops/cluster-config/virt-lab-env/overlays/example-instance/kustomization.yaml" "$instance_dir/kustomization.yaml"

    # Fix the base path for instances directory structure
    yq eval ".resources[0] = \"../../../base\"" -i "$instance_dir/kustomization.yaml"

    # Get the management cluster domain for hosted clusters
    # The console route is: console-openshift-console.apps.tosins-dev-cluster.sandbox1271.opentlc.com
    # We want: apps.tosins-dev-cluster.sandbox1271.opentlc.com
    local mgmt_cluster_domain
    mgmt_cluster_domain=$(oc get route console -n openshift-console -o jsonpath='{.spec.host}' | sed 's/console-openshift-console.//')
    local hosted_base_domain="$mgmt_cluster_domain"

    print_info "Using hosted cluster base domain: $hosted_base_domain"

    # Update configuration using yq
    update_yaml_config "$instance_dir/kustomization.yaml" "$instance_name" "$environment" "$hosted_base_domain" \
        "$replicas" "$memory" "$cores" "$storage_size" "$storage_class" "$clusterset" "$release_image"

    # The kustomization.yaml already contains the replacements from example-instance
    print_info "Using existing replacements from example-instance template"

    # Create patch files using yq (if templates exist)
    if [[ -f "$PROJECT_ROOT/gitops/cluster-config/virt-lab-env/overlays/example-instance/hosted-cluster-patch.yaml" ]]; then
        print_info "Creating hosted-cluster-patch.yaml"
        cp "$PROJECT_ROOT/gitops/cluster-config/virt-lab-env/overlays/example-instance/hosted-cluster-patch.yaml" "$instance_dir/hosted-cluster-patch.yaml"
        # Update patch values using yq if needed
        yq eval ".spec.dns.baseDomain = \"$base_domain\"" -i "$instance_dir/hosted-cluster-patch.yaml" 2>/dev/null || true
    fi

    if [[ -f "$PROJECT_ROOT/gitops/cluster-config/virt-lab-env/overlays/example-instance/nodepool-patch.yaml" ]]; then
        print_info "Creating nodepool-patch.yaml"
        cp "$PROJECT_ROOT/gitops/cluster-config/virt-lab-env/overlays/example-instance/nodepool-patch.yaml" "$instance_dir/nodepool-patch.yaml"
        # Update patch values using yq if needed
        yq eval ".spec.replicas = $replicas" -i "$instance_dir/nodepool-patch.yaml" 2>/dev/null || true
    fi
    
    print_success "Successfully created hosted cluster instance: $instance_name"
    print_info "Instance location: $instance_dir"

    # Set up credentials if requested
    if [[ "${12}" == "true" ]]; then  # setup_credentials parameter
        print_info "Setting up credentials for cluster: $instance_name"

        local credential_args=()
        credential_args+=("$instance_name")

        if [[ -n "${13}" ]]; then  # pull_secret_path parameter
            credential_args+=("--pull-secret-path" "${13}")
        fi

        if [[ -n "${14}" ]]; then  # ssh_key_path parameter
            credential_args+=("--ssh-key-path" "${14}")
        fi

        if [[ "${15}" == "true" ]]; then  # create_ssh_key parameter
            credential_args+=("--create-ssh-key")
        fi

        if [[ "${16}" == "true" ]]; then  # interactive_credentials parameter
            credential_args+=("--interactive")
        fi

        if [[ "$dry_run" == "true" ]]; then
            credential_args+=("--dry-run")
        fi

        # Run credential setup script
        if "$SCRIPT_DIR/setup-hosted-cluster-credentials.sh" "${credential_args[@]}"; then
            print_success "Credentials set up successfully"
        else
            print_warning "Credential setup failed. You can run it manually later:"
            print_info "  ./scripts/setup-hosted-cluster-credentials.sh $instance_name"
        fi
    fi

    print_info "Next steps:"
    if [[ "${12}" != "true" ]]; then  # setup_credentials parameter
        print_info "  1. Set up credentials:"
        print_info "     ./scripts/setup-hosted-cluster-credentials.sh $instance_name"
        print_info "  2. Test configuration locally:"
        print_info "     ./scripts/test-hosted-cluster-config.sh $instance_name"
        print_info "  3. Commit changes to Git (REQUIRED for GitOps):"
        print_info "     git add gitops/cluster-config/virt-lab-env/overlays/instances/$instance_name"
        print_info "     git commit -m 'Add $instance_name hosted cluster'"
        print_info "     git push origin main"
        print_info "  4. Deploy ApplicationSet (if not already deployed):"
        print_info "     oc apply -f gitops/cluster-config/apps/openshift-hypershift-lab/hosted-clusters-applicationset.yaml"
        print_info "  5. Validate GitOps deployment:"
        print_info "     ./scripts/test-hosted-cluster-config.sh --validate-gitops $instance_name"
    else
        print_info "  1. Test configuration locally:"
        print_info "     ./scripts/test-hosted-cluster-config.sh $instance_name"
        print_info "  2. Commit changes to Git (REQUIRED for GitOps):"
        print_info "     git add gitops/cluster-config/virt-lab-env/overlays/instances/$instance_name"
        print_info "     git commit -m 'Add $instance_name hosted cluster'"
        print_info "     git push origin main"
        print_info "  3. Deploy ApplicationSet (if not already deployed):"
        print_info "     oc apply -f gitops/cluster-config/apps/openshift-hypershift-lab/hosted-clusters-applicationset.yaml"
        print_info "  4. Validate GitOps deployment:"
        print_info "     ./scripts/test-hosted-cluster-config.sh --validate-gitops $instance_name"
    fi

    print_warning "IMPORTANT: ArgoCD ApplicationSet uses Git discovery - instances must be committed to Git!"
    print_info ""
    print_info "Testing workflow:"
    print_info "  • Local test:  ./scripts/test-hosted-cluster-config.sh --build-only $instance_name"
    print_info "  • Full test:   ./scripts/test-hosted-cluster-config.sh $instance_name"
    print_info "  • After Git:   ./scripts/test-hosted-cluster-config.sh --validate-gitops $instance_name"
}

# Parse command line arguments
INSTANCE_NAME=""
ENVIRONMENT="dev"
BASE_DOMAIN=""
REPLICAS="3"
MEMORY="8Gi"
CORES="4"
STORAGE_SIZE="32Gi"
STORAGE_CLASS="gp3-csi"
RELEASE_IMAGE=""
CLUSTERSET="default"
SETUP_CREDENTIALS="false"
PULL_SECRET_PATH=""
SSH_KEY_PATH=""
CREATE_SSH_KEY="false"
INTERACTIVE_CREDENTIALS="false"
USE_SHARED_CREDENTIALS=""
CREDENTIALS_NAMESPACE="virt-creds"
INFRA_NAMESPACE=""
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            INSTANCE_NAME="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -d|--domain)
            BASE_DOMAIN="$2"
            shift 2
            ;;
        -r|--replicas)
            REPLICAS="$2"
            shift 2
            ;;
        -m|--memory)
            MEMORY="$2"
            shift 2
            ;;
        -c|--cores)
            CORES="$2"
            shift 2
            ;;
        -s|--storage-size)
            STORAGE_SIZE="$2"
            shift 2
            ;;
        --storage-class)
            STORAGE_CLASS="$2"
            shift 2
            ;;
        --release-image)
            RELEASE_IMAGE="$2"
            shift 2
            ;;
        --clusterset)
            CLUSTERSET="$2"
            shift 2
            ;;
        --setup-credentials)
            SETUP_CREDENTIALS="true"
            shift
            ;;
        --pull-secret-path)
            PULL_SECRET_PATH="$2"
            shift 2
            ;;
        --ssh-key-path)
            SSH_KEY_PATH="$2"
            shift 2
            ;;
        --create-ssh-key)
            CREATE_SSH_KEY="true"
            shift
            ;;
        --interactive-credentials)
            INTERACTIVE_CREDENTIALS="true"
            shift
            ;;
        --use-shared-credentials)
            USE_SHARED_CREDENTIALS="$2"
            shift 2
            ;;
        --credentials-namespace)
            CREDENTIALS_NAMESPACE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$INSTANCE_NAME" ]]; then
    print_error "Instance name is required"
    usage
    exit 1
fi

if [[ -z "$BASE_DOMAIN" ]]; then
    print_info "Auto-detecting hosted cluster domain from management cluster..."
    # Get the apps domain from the management cluster console route
    # This works for any management cluster: console-openshift-console.apps.{mgmt-cluster}.{base-domain}
    # Results in: apps.{mgmt-cluster}.{base-domain} (correct for hosted clusters)
    BASE_DOMAIN=$(oc get route console -n openshift-console -o jsonpath='{.spec.host}' | sed 's/console-openshift-console.//')
    print_info "Auto-detected hosted cluster base domain: $BASE_DOMAIN"
    print_info "Hosted cluster console will be: console-openshift-console.apps.$INSTANCE_NAME.$BASE_DOMAIN"
else
    print_info "Using provided base domain: $BASE_DOMAIN"
    print_info "Hosted cluster console will be: console-openshift-console.apps.$INSTANCE_NAME.$BASE_DOMAIN"
fi

# Validate inputs
validate_cluster_name "$INSTANCE_NAME"
validate_domain "$BASE_DOMAIN"

# Check if instance already exists (skip for dry run)
if [[ "$DRY_RUN" != "true" ]]; then
    check_instance_exists "$INSTANCE_NAME"
fi

# Create the instance
create_instance "$INSTANCE_NAME" "$ENVIRONMENT" "$BASE_DOMAIN" "$REPLICAS" "$MEMORY" "$CORES" "$STORAGE_SIZE" "$STORAGE_CLASS" "$RELEASE_IMAGE" "$CLUSTERSET" "$DRY_RUN" "$SETUP_CREDENTIALS" "$PULL_SECRET_PATH" "$SSH_KEY_PATH" "$CREATE_SSH_KEY" "$INTERACTIVE_CREDENTIALS"
