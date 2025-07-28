#!/bin/bash

# validate-deployment.sh
# Script to validate hosted cluster deployments

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

Validate hosted cluster deployment.

OPTIONS:
    --namespace NAMESPACE           Cluster namespace (default: clusters)
    --timeout SECONDS               Timeout for checks (default: 300)
    --skip-health-check             Skip cluster health checks
    --skip-node-check               Skip node readiness checks
    --skip-operator-check           Skip operator status checks
    --local-test                    Test local configuration with 'oc apply -k' (before Git commit)
    --verbose                       Enable verbose output
    -h, --help                      Show this help message

EXAMPLES:
    # Validate a cluster deployment
    $0 dev-cluster-01

    # Validate with custom namespace and timeout
    $0 --namespace my-clusters --timeout 600 prod-cluster-01

    # Quick validation (skip detailed checks)
    $0 --skip-health-check --skip-node-check prod-cluster-01

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

# Function to validate HostedCluster resource
validate_hosted_cluster() {
    local cluster_name="$1"
    local namespace="$2"
    local timeout="$3"
    local verbose="$4"
    
    print_info "Validating HostedCluster resource: $cluster_name"
    
    # Check if HostedCluster exists
    if ! oc get hostedcluster "$cluster_name" -n "$namespace" &> /dev/null; then
        print_error "HostedCluster '$cluster_name' not found in namespace '$namespace'"
        return 1
    fi
    
    # Get HostedCluster status
    local status=$(oc get hostedcluster "$cluster_name" -n "$namespace" -o jsonpath='{.status.conditions[?(@.type=="Available")].status}')
    local reason=$(oc get hostedcluster "$cluster_name" -n "$namespace" -o jsonpath='{.status.conditions[?(@.type=="Available")].reason}')
    local message=$(oc get hostedcluster "$cluster_name" -n "$namespace" -o jsonpath='{.status.conditions[?(@.type=="Available")].message}')
    
    if [[ "$verbose" == "true" ]]; then
        print_info "HostedCluster status: $status"
        print_info "Reason: $reason"
        print_info "Message: $message"
    fi
    
    if [[ "$status" == "True" ]]; then
        print_success "HostedCluster '$cluster_name' is available"
    else
        print_warning "HostedCluster '$cluster_name' is not yet available"
        print_info "Status: $status, Reason: $reason"
        
        # Wait for cluster to become available
        print_info "Waiting for HostedCluster to become available (timeout: ${timeout}s)..."
        
        local count=0
        while [[ $count -lt $timeout ]]; do
            status=$(oc get hostedcluster "$cluster_name" -n "$namespace" -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || echo "Unknown")
            
            if [[ "$status" == "True" ]]; then
                print_success "HostedCluster '$cluster_name' is now available"
                break
            fi
            
            sleep 10
            count=$((count + 10))
            
            if [[ $((count % 60)) -eq 0 ]]; then
                print_info "Still waiting... (${count}s elapsed)"
            fi
        done
        
        if [[ "$status" != "True" ]]; then
            print_error "HostedCluster '$cluster_name' did not become available within ${timeout}s"
            return 1
        fi
    fi
    
    return 0
}

# Function to validate NodePool resource
validate_nodepool() {
    local cluster_name="$1"
    local namespace="$2"
    local timeout="$3"
    local verbose="$4"
    
    print_info "Validating NodePool resources for cluster: $cluster_name"
    
    # Get all NodePools for the cluster
    local nodepools=$(oc get nodepool -n "$namespace" -l "hypershift.openshift.io/cluster=$cluster_name" -o jsonpath='{.items[*].metadata.name}')
    
    if [[ -z "$nodepools" ]]; then
        print_error "No NodePools found for cluster '$cluster_name'"
        return 1
    fi
    
    for nodepool in $nodepools; do
        print_info "Checking NodePool: $nodepool"
        
        # Get NodePool status
        local replicas=$(oc get nodepool "$nodepool" -n "$namespace" -o jsonpath='{.spec.replicas}')
        local ready_replicas=$(oc get nodepool "$nodepool" -n "$namespace" -o jsonpath='{.status.readyReplicas}')
        
        if [[ "$verbose" == "true" ]]; then
            print_info "NodePool '$nodepool': $ready_replicas/$replicas replicas ready"
        fi
        
        if [[ "$ready_replicas" == "$replicas" ]]; then
            print_success "NodePool '$nodepool' has all replicas ready ($ready_replicas/$replicas)"
        else
            print_warning "NodePool '$nodepool' has $ready_replicas/$replicas replicas ready"
            
            # Wait for NodePool to become ready
            print_info "Waiting for NodePool '$nodepool' to become ready (timeout: ${timeout}s)..."
            
            local count=0
            while [[ $count -lt $timeout ]]; do
                ready_replicas=$(oc get nodepool "$nodepool" -n "$namespace" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
                
                if [[ "$ready_replicas" == "$replicas" ]]; then
                    print_success "NodePool '$nodepool' is now ready ($ready_replicas/$replicas)"
                    break
                fi
                
                sleep 15
                count=$((count + 15))
                
                if [[ $((count % 60)) -eq 0 ]]; then
                    print_info "Still waiting for NodePool '$nodepool'... (${count}s elapsed)"
                fi
            done
            
            if [[ "$ready_replicas" != "$replicas" ]]; then
                print_error "NodePool '$nodepool' did not become ready within ${timeout}s"
                return 1
            fi
        fi
    done
    
    return 0
}

# Function to validate cluster health
validate_cluster_health() {
    local cluster_name="$1"
    local namespace="$2"
    local verbose="$4"
    
    print_info "Validating cluster health for: $cluster_name"
    
    # Get kubeconfig secret
    local kubeconfig_secret="${cluster_name}-admin-kubeconfig"
    
    if ! oc get secret "$kubeconfig_secret" -n "$namespace" &> /dev/null; then
        print_error "Kubeconfig secret '$kubeconfig_secret' not found"
        return 1
    fi
    
    # Extract kubeconfig
    local temp_kubeconfig=$(mktemp)
    oc get secret "$kubeconfig_secret" -n "$namespace" -o jsonpath='{.data.kubeconfig}' | base64 -d > "$temp_kubeconfig"
    
    # Check cluster operators
    print_info "Checking cluster operators..."
    local degraded_operators=$(oc --kubeconfig="$temp_kubeconfig" get co --no-headers | awk '$3=="True" || $4=="True" {print $1}' || true)
    
    if [[ -n "$degraded_operators" ]]; then
        print_warning "Some cluster operators are degraded:"
        echo "$degraded_operators"
    else
        print_success "All cluster operators are healthy"
    fi
    
    # Check nodes
    print_info "Checking node status..."
    local not_ready_nodes=$(oc --kubeconfig="$temp_kubeconfig" get nodes --no-headers | awk '$2!="Ready" {print $1}' || true)
    
    if [[ -n "$not_ready_nodes" ]]; then
        print_warning "Some nodes are not ready:"
        echo "$not_ready_nodes"
    else
        print_success "All nodes are ready"
    fi
    
    # Cleanup
    rm -f "$temp_kubeconfig"
    
    return 0
}

# Function to run comprehensive validation
run_validation() {
    local cluster_name="$1"
    local namespace="$2"
    local timeout="$3"
    local skip_health="$4"
    local skip_node="$5"
    local skip_operator="$6"
    local verbose="$7"
    
    print_info "Starting validation for hosted cluster: $cluster_name"
    print_info "Namespace: $namespace"
    print_info "Timeout: ${timeout}s"
    
    local validation_failed=false
    
    # Validate HostedCluster
    if ! validate_hosted_cluster "$cluster_name" "$namespace" "$timeout" "$verbose"; then
        validation_failed=true
    fi
    
    # Validate NodePool
    if [[ "$skip_node" != "true" ]]; then
        if ! validate_nodepool "$cluster_name" "$namespace" "$timeout" "$verbose"; then
            validation_failed=true
        fi
    fi
    
    # Validate cluster health
    if [[ "$skip_health" != "true" ]]; then
        if ! validate_cluster_health "$cluster_name" "$namespace" "$timeout" "$verbose"; then
            validation_failed=true
        fi
    fi
    
    if [[ "$validation_failed" == "true" ]]; then
        print_error "Validation failed for cluster: $cluster_name"
        return 1
    else
        print_success "Validation completed successfully for cluster: $cluster_name"
        return 0
    fi
}

# Parse command line arguments
CLUSTER_NAME=""
NAMESPACE="clusters"
TIMEOUT="300"
SKIP_HEALTH="false"
SKIP_NODE="false"
SKIP_OPERATOR="false"
VERBOSE="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --skip-health-check)
            SKIP_HEALTH="true"
            shift
            ;;
        --skip-node-check)
            SKIP_NODE="true"
            shift
            ;;
        --skip-operator-check)
            SKIP_OPERATOR="true"
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
check_login

# Run validation
run_validation "$CLUSTER_NAME" "$NAMESPACE" "$TIMEOUT" "$SKIP_HEALTH" "$SKIP_NODE" "$SKIP_OPERATOR" "$VERBOSE"
