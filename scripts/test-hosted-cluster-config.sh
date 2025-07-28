#!/bin/bash

# test-hosted-cluster-config.sh
# Script to test hosted cluster configurations locally before GitOps deployment

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

Test hosted cluster configuration locally before GitOps deployment.

This script helps test cluster configurations in different scenarios:
1. Local Kustomize build validation
2. Local deployment testing (creates actual resources)
3. GitOps readiness validation
4. Cleanup after testing

OPTIONS:
    --namespace NAMESPACE           Cluster namespace (default: clusters)
    --build-only                    Only test Kustomize build (no deployment)
    --deploy-local                  Deploy resources locally for testing
    --cleanup                       Clean up locally deployed test resources
    --validate-gitops               Validate GitOps readiness (requires Git commit)
    --dry-run                       Show what would be done without doing it
    --verbose                       Enable verbose output
    -h, --help                      Show this help message

TESTING WORKFLOW:
    1. Build Test:     $0 --build-only my-cluster
    2. Local Deploy:   $0 --deploy-local my-cluster
    3. Validate:       $0 my-cluster
    4. Cleanup:        $0 --cleanup my-cluster
    5. Commit to Git:  git add . && git commit -m "Add my-cluster"
    6. GitOps Test:    $0 --validate-gitops my-cluster

EXAMPLES:
    # Test Kustomize build only
    $0 --build-only dev-cluster-01

    # Deploy locally for testing
    $0 --deploy-local dev-cluster-01

    # Full local validation
    $0 dev-cluster-01

    # Clean up test resources
    $0 --cleanup dev-cluster-01

    # Validate GitOps readiness (after Git commit)
    $0 --validate-gitops dev-cluster-01

EOF
}

# Function to check if oc is available
check_oc() {
    if ! command -v oc &> /dev/null; then
        print_error "oc (OpenShift CLI) is required but not installed"
        exit 1
    fi
}

# Function to check if kustomize is available
check_kustomize() {
    if ! command -v kustomize &> /dev/null; then
        print_error "kustomize is required but not installed"
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

# Function to test Kustomize build
test_kustomize_build() {
    local cluster_name="$1"
    local verbose="$2"
    
    local instance_dir="$PROJECT_ROOT/gitops/cluster-config/virt-lab-env/overlays/instances/$cluster_name"
    
    print_info "Testing Kustomize build for cluster: $cluster_name"
    
    if [[ ! -d "$instance_dir" ]]; then
        print_error "Instance directory not found: $instance_dir"
        return 1
    fi
    
    if [[ ! -f "$instance_dir/kustomization.yaml" ]]; then
        print_error "kustomization.yaml not found in: $instance_dir"
        return 1
    fi
    
    # Test kustomize build
    print_info "Running kustomize build..."
    
    if [[ "$verbose" == "true" ]]; then
        if kustomize build "$instance_dir"; then
            print_success "Kustomize build successful"
        else
            print_error "Kustomize build failed"
            return 1
        fi
    else
        if kustomize build "$instance_dir" > /dev/null; then
            print_success "Kustomize build successful"
        else
            print_error "Kustomize build failed"
            print_info "Run with --verbose to see detailed output"
            return 1
        fi
    fi
    
    # Validate resource types
    print_info "Validating generated resources..."
    
    local resources=$(kustomize build "$instance_dir" | grep -E "^kind:" | sort | uniq)
    
    if echo "$resources" | grep -q "HostedCluster"; then
        print_success "✓ HostedCluster resource found"
    else
        print_error "✗ HostedCluster resource not found"
        return 1
    fi
    
    if echo "$resources" | grep -q "NodePool"; then
        print_success "✓ NodePool resource found"
    else
        print_error "✗ NodePool resource not found"
        return 1
    fi
    
    # Check for required secrets
    local config_map_data=$(kustomize build "$instance_dir" | grep -A 50 "kind: ConfigMap" | grep -A 30 "name: cluster-config")
    
    if echo "$config_map_data" | grep -q "CLUSTER_NAME"; then
        print_success "✓ Cluster configuration found"
    else
        print_warning "⚠ Cluster configuration may be incomplete"
    fi
    
    return 0
}

# Function to deploy locally for testing
deploy_local() {
    local cluster_name="$1"
    local namespace="$2"
    local dry_run="$3"
    local verbose="$4"
    
    local instance_dir="$PROJECT_ROOT/gitops/cluster-config/virt-lab-env/overlays/instances/$cluster_name"
    
    print_info "Deploying cluster locally for testing: $cluster_name"
    print_warning "This will create actual resources in your cluster!"
    
    if [[ "$dry_run" != "true" ]]; then
        read -p "Continue with local deployment? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Local deployment cancelled"
            return 0
        fi
    fi
    
    # Create namespace if it doesn't exist
    if [[ "$dry_run" == "true" ]]; then
        print_info "DRY RUN: Would create namespace '$namespace' if it doesn't exist"
        print_info "DRY RUN: Would apply resources from: $instance_dir"
    else
        if ! oc get namespace "$namespace" &>/dev/null; then
            print_info "Creating namespace: $namespace"
            oc create namespace "$namespace"
        fi
        
        # Apply the configuration
        print_info "Applying configuration..."
        if [[ "$verbose" == "true" ]]; then
            oc apply -k "$instance_dir"
        else
            oc apply -k "$instance_dir" > /dev/null
        fi
        
        print_success "Local deployment completed"
        print_info "Resources created in namespace: $namespace"
        
        # Show created resources
        print_info "Created resources:"
        oc get hostedcluster,nodepool -n "$namespace" | grep "$cluster_name" || true
    fi
}

# Function to cleanup local deployment
cleanup_local() {
    local cluster_name="$1"
    local namespace="$2"
    local dry_run="$3"
    
    print_info "Cleaning up local deployment for cluster: $cluster_name"
    
    if [[ "$dry_run" == "true" ]]; then
        print_info "DRY RUN: Would delete HostedCluster and NodePool resources for $cluster_name"
        return 0
    fi
    
    # Delete HostedCluster
    if oc get hostedcluster "$cluster_name" -n "$namespace" &>/dev/null; then
        print_info "Deleting HostedCluster: $cluster_name"
        oc delete hostedcluster "$cluster_name" -n "$namespace"
    fi
    
    # Delete NodePools
    local nodepools=$(oc get nodepool -n "$namespace" -o name | grep "$cluster_name" || true)
    if [[ -n "$nodepools" ]]; then
        print_info "Deleting NodePools for cluster: $cluster_name"
        echo "$nodepools" | xargs -r oc delete -n "$namespace"
    fi
    
    print_success "Local cleanup completed"
}

# Function to validate GitOps readiness
validate_gitops_readiness() {
    local cluster_name="$1"
    local verbose="$2"
    
    print_info "Validating GitOps readiness for cluster: $cluster_name"
    
    # Check if instance is committed to Git
    local instance_path="gitops/cluster-config/virt-lab-env/overlays/instances/$cluster_name"
    
    if ! git ls-files --error-unmatch "$instance_path" &>/dev/null; then
        print_error "Instance not found in Git repository: $instance_path"
        print_info "Please commit your changes first:"
        print_info "  git add $instance_path"
        print_info "  git commit -m 'Add $cluster_name hosted cluster'"
        print_info "  git push origin main"
        return 1
    fi
    
    print_success "✓ Instance found in Git repository"
    
    # Check if there are uncommitted changes
    if ! git diff --quiet HEAD -- "$instance_path"; then
        print_warning "⚠ Uncommitted changes detected in: $instance_path"
        print_info "ArgoCD will use the committed version, not local changes"
        
        if [[ "$verbose" == "true" ]]; then
            print_info "Uncommitted changes:"
            git diff HEAD -- "$instance_path"
        fi
    else
        print_success "✓ No uncommitted changes"
    fi
    
    # Check ApplicationSet configuration
    local appset_file="$PROJECT_ROOT/gitops/cluster-config/virt-lab-env/applicationsets/hosted-clusters-appset.yaml"
    
    if [[ ! -f "$appset_file" ]]; then
        print_error "ApplicationSet not found: $appset_file"
        return 1
    fi
    
    print_success "✓ ApplicationSet configuration found"
    
    # Check if ApplicationSet is deployed
    if oc get applicationset hosted-clusters -n openshift-gitops &>/dev/null; then
        print_success "✓ ApplicationSet deployed in cluster"
        
        # Check if Application was created for this instance
        local app_name="hosted-cluster-$cluster_name"
        if oc get application "$app_name" -n openshift-gitops &>/dev/null; then
            print_success "✓ ArgoCD Application exists: $app_name"
            
            # Check Application status
            local sync_status=$(oc get application "$app_name" -n openshift-gitops -o jsonpath='{.status.sync.status}')
            local health_status=$(oc get application "$app_name" -n openshift-gitops -o jsonpath='{.status.health.status}')
            
            print_info "Application Status:"
            print_info "  Sync: $sync_status"
            print_info "  Health: $health_status"
            
        else
            print_warning "⚠ ArgoCD Application not yet created: $app_name"
            print_info "ApplicationSet may need time to discover the new instance"
        fi
    else
        print_error "✗ ApplicationSet not deployed"
        print_info "Deploy it with:"
        print_info "  oc apply -f gitops/cluster-config/apps/openshift-hypershift-lab/hosted-clusters-applicationset.yaml"
        return 1
    fi
    
    return 0
}

# Function to run comprehensive test
run_test() {
    local cluster_name="$1"
    local namespace="$2"
    local build_only="$3"
    local deploy_local="$4"
    local cleanup="$5"
    local validate_gitops="$6"
    local dry_run="$7"
    local verbose="$8"
    
    print_info "Testing hosted cluster configuration: $cluster_name"
    
    # Always test Kustomize build first
    if ! test_kustomize_build "$cluster_name" "$verbose"; then
        print_error "Kustomize build test failed"
        return 1
    fi
    
    if [[ "$build_only" == "true" ]]; then
        print_success "Build-only test completed successfully"
        return 0
    fi
    
    if [[ "$cleanup" == "true" ]]; then
        cleanup_local "$cluster_name" "$namespace" "$dry_run"
        return 0
    fi
    
    if [[ "$deploy_local" == "true" ]]; then
        deploy_local "$cluster_name" "$namespace" "$dry_run" "$verbose"
        return 0
    fi
    
    if [[ "$validate_gitops" == "true" ]]; then
        validate_gitops_readiness "$cluster_name" "$verbose"
        return 0
    fi
    
    # Default: comprehensive local test
    print_info "Running comprehensive local test..."
    
    # Test credentials exist
    print_info "Checking required credentials..."
    
    local pull_secret="pullsecret-cluster"
    local ssh_secret="sshkey-cluster"
    local infra_secret="${cluster_name}-infra-credentials"
    
    if oc get secret "$pull_secret" -n "$namespace" &>/dev/null; then
        print_success "✓ Pull secret found: $pull_secret"
    else
        print_error "✗ Pull secret not found: $pull_secret"
        print_info "Run: ./scripts/setup-hosted-cluster-credentials.sh $cluster_name"
        return 1
    fi
    
    if oc get secret "$ssh_secret" -n "$namespace" &>/dev/null; then
        print_success "✓ SSH key secret found: $ssh_secret"
    else
        print_error "✗ SSH key secret not found: $ssh_secret"
        print_info "Run: ./scripts/setup-hosted-cluster-credentials.sh $cluster_name"
        return 1
    fi
    
    if oc get secret "$infra_secret" -n "$namespace" &>/dev/null; then
        print_success "✓ Infrastructure credentials found: $infra_secret"
    else
        print_error "✗ Infrastructure credentials not found: $infra_secret"
        print_info "Run: ./scripts/setup-hosted-cluster-credentials.sh $cluster_name"
        return 1
    fi
    
    print_success "All tests passed! Configuration is ready for GitOps deployment."
    print_info ""
    print_info "Next steps:"
    print_info "  1. Commit to Git:"
    print_info "     git add gitops/cluster-config/virt-lab-env/overlays/instances/$cluster_name"
    print_info "     git commit -m 'Add $cluster_name hosted cluster'"
    print_info "     git push origin main"
    print_info ""
    print_info "  2. Deploy ApplicationSet (if not already deployed):"
    print_info "     oc apply -f gitops/cluster-config/apps/openshift-hypershift-lab/hosted-clusters-applicationset.yaml"
    print_info ""
    print_info "  3. Validate GitOps readiness:"
    print_info "     $0 --validate-gitops $cluster_name"
    
    return 0
}

# Parse command line arguments
CLUSTER_NAME=""
NAMESPACE="clusters"
BUILD_ONLY="false"
DEPLOY_LOCAL="false"
CLEANUP="false"
VALIDATE_GITOPS="false"
DRY_RUN="false"
VERBOSE="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --build-only)
            BUILD_ONLY="true"
            shift
            ;;
        --deploy-local)
            DEPLOY_LOCAL="true"
            shift
            ;;
        --cleanup)
            CLEANUP="true"
            shift
            ;;
        --validate-gitops)
            VALIDATE_GITOPS="true"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --verbose)
            VERBOSE="true"
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

# Validate required parameters
if [[ -z "$CLUSTER_NAME" ]]; then
    print_error "Cluster name is required"
    usage
    exit 1
fi

# Check prerequisites
check_oc
check_kustomize

if [[ "$DRY_RUN" != "true" ]] && [[ "$BUILD_ONLY" != "true" ]]; then
    check_login
fi

# Run test
run_test "$CLUSTER_NAME" "$NAMESPACE" "$BUILD_ONLY" "$DEPLOY_LOCAL" "$CLEANUP" "$VALIDATE_GITOPS" "$DRY_RUN" "$VERBOSE"
