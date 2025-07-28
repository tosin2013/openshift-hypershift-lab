#!/bin/bash

# manage-cluster-config.sh
# Script to manage hosted cluster configurations

set -euo pipefail

# Default values
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_ROOT/gitops/cluster-config/virt-lab-env/config"
REGISTRY_FILE="$CONFIG_DIR/cluster-registry.yaml"

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
Usage: $0 COMMAND [OPTIONS]

Manage hosted cluster configurations.

COMMANDS:
    list                            List all registered clusters
    show CLUSTER_NAME               Show details for a specific cluster
    register CLUSTER_NAME           Register a new cluster configuration
    update CLUSTER_NAME             Update an existing cluster configuration
    delete CLUSTER_NAME             Delete a cluster configuration
    validate CLUSTER_NAME           Validate a cluster configuration
    validate-all                    Validate all cluster configurations
    export CLUSTER_NAME             Export cluster configuration to JSON
    import FILE                     Import cluster configuration from JSON file

OPTIONS:
    --environment ENV               Environment (dev, staging, prod, lab, test)
    --platform PLATFORM            Platform (kubevirt, aws, azure, gcp)
    --base-domain DOMAIN            Base domain for the cluster
    --replicas COUNT                Number of worker node replicas
    --memory SIZE                   Memory per worker node (e.g., 8Gi)
    --cores COUNT                   CPU cores per worker node
    --storage SIZE                  Root volume size (e.g., 32Gi)
    --storage-class CLASS           Storage class name
    --format FORMAT                 Output format (json, yaml, table)
    -h, --help                      Show this help message

EXAMPLES:
    # List all clusters
    $0 list

    # Show cluster details
    $0 show dev-cluster-01

    # Register a new cluster
    $0 register prod-cluster-01 --environment prod --base-domain prod.example.com

    # Validate all configurations
    $0 validate-all

    # Export cluster configuration
    $0 export dev-cluster-01 --format json

EOF
}

# Function to check if yq is available
check_yq() {
    if ! command -v yq &> /dev/null; then
        print_error "yq is required but not installed. Please install yq first."
        exit 1
    fi
}

# Function to check if jq is available
check_jq() {
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed. Please install jq first."
        exit 1
    fi
}

# Function to list all registered clusters
list_clusters() {
    local format="${1:-table}"
    
    check_yq
    
    if [[ ! -f "$REGISTRY_FILE" ]]; then
        print_warning "No cluster registry found at: $REGISTRY_FILE"
        return 0
    fi
    
    print_info "Registered hosted clusters:"
    
    case "$format" in
        json)
            yq eval '.data | to_entries | map(select(.key | test("\\.json$")) | .key |= sub("\\.json$"; "")) | from_entries' "$REGISTRY_FILE"
            ;;
        yaml)
            yq eval '.data | to_entries | map(select(.key | test("\\.json$")) | .key |= sub("\\.json$"; "")) | from_entries' "$REGISTRY_FILE"
            ;;
        table|*)
            echo "NAME                 ENVIRONMENT    PLATFORM     BASE_DOMAIN                              STATUS"
            echo "-------------------- -------------- ------------ ---------------------------------------- --------"
            
            for key in $(yq eval '.data | keys | .[] | select(test("\\.json$"))' "$REGISTRY_FILE"); do
                cluster_name=$(echo "$key" | sed 's/\.json$//')
                config=$(yq eval ".data.\"$key\"" "$REGISTRY_FILE" | yq eval '.' -)
                
                name=$(echo "$config" | yq eval '.name // "N/A"' -)
                environment=$(echo "$config" | yq eval '.environment // "N/A"' -)
                platform=$(echo "$config" | yq eval '.platform // "N/A"' -)
                baseDomain=$(echo "$config" | yq eval '.baseDomain // "N/A"' -)
                status=$(echo "$config" | yq eval '.status // "N/A"' -)
                
                printf "%-20s %-14s %-12s %-40s %-8s\n" "$name" "$environment" "$platform" "$baseDomain" "$status"
            done
            ;;
    esac
}

# Function to show cluster details
show_cluster() {
    local cluster_name="$1"
    local format="${2:-yaml}"
    
    check_yq
    
    if [[ ! -f "$REGISTRY_FILE" ]]; then
        print_error "No cluster registry found at: $REGISTRY_FILE"
        return 1
    fi
    
    local key="${cluster_name}.json"
    
    if ! yq eval ".data | has(\"$key\")" "$REGISTRY_FILE" | grep -q "true"; then
        print_error "Cluster '$cluster_name' not found in registry"
        return 1
    fi
    
    print_info "Configuration for cluster: $cluster_name"
    
    case "$format" in
        json)
            yq eval ".data.\"$key\"" "$REGISTRY_FILE" | yq eval '.' -
            ;;
        yaml|*)
            yq eval ".data.\"$key\"" "$REGISTRY_FILE" | yq eval '. | to_yaml' -
            ;;
    esac
}

# Function to validate cluster configuration
validate_cluster() {
    local cluster_name="$1"
    
    check_jq
    check_yq
    
    if [[ ! -f "$REGISTRY_FILE" ]]; then
        print_error "No cluster registry found at: $REGISTRY_FILE"
        return 1
    fi
    
    local key="${cluster_name}.json"
    local schema_key="schema.json"
    
    if ! yq eval ".data | has(\"$key\")" "$REGISTRY_FILE" | grep -q "true"; then
        print_error "Cluster '$cluster_name' not found in registry"
        return 1
    fi
    
    if ! yq eval ".data | has(\"$schema_key\")" "$REGISTRY_FILE" | grep -q "true"; then
        print_error "Schema not found in registry"
        return 1
    fi
    
    print_info "Validating configuration for cluster: $cluster_name"
    
    # Extract configuration and schema
    local config_json=$(yq eval ".data.\"$key\"" "$REGISTRY_FILE")
    local schema_json=$(yq eval ".data.\"$schema_key\"" "$REGISTRY_FILE")
    
    # Validate using jq (basic validation)
    if echo "$config_json" | jq empty 2>/dev/null; then
        print_success "Configuration is valid JSON"
    else
        print_error "Configuration is not valid JSON"
        return 1
    fi
    
    # Additional validation checks
    local name=$(echo "$config_json" | jq -r '.name // empty')
    local environment=$(echo "$config_json" | jq -r '.environment // empty')
    local platform=$(echo "$config_json" | jq -r '.platform // empty')
    local baseDomain=$(echo "$config_json" | jq -r '.baseDomain // empty')
    
    if [[ -z "$name" ]]; then
        print_error "Missing required field: name"
        return 1
    fi
    
    if [[ -z "$environment" ]]; then
        print_error "Missing required field: environment"
        return 1
    fi
    
    if [[ -z "$platform" ]]; then
        print_error "Missing required field: platform"
        return 1
    fi
    
    if [[ -z "$baseDomain" ]]; then
        print_error "Missing required field: baseDomain"
        return 1
    fi
    
    # Validate cluster name format
    if [[ ! "$name" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
        print_error "Invalid cluster name format: $name"
        return 1
    fi
    
    # Validate domain format
    if [[ ! "$baseDomain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$ ]]; then
        print_error "Invalid domain format: $baseDomain"
        return 1
    fi
    
    print_success "Configuration validation passed for cluster: $cluster_name"
}

# Function to validate all cluster configurations
validate_all_clusters() {
    check_yq
    
    if [[ ! -f "$REGISTRY_FILE" ]]; then
        print_error "No cluster registry found at: $REGISTRY_FILE"
        return 1
    fi
    
    print_info "Validating all cluster configurations..."
    
    local failed_count=0
    local total_count=0
    
    for key in $(yq eval '.data | keys | .[] | select(test("\\.json$"))' "$REGISTRY_FILE"); do
        cluster_name=$(echo "$key" | sed 's/\.json$//')
        total_count=$((total_count + 1))
        
        if ! validate_cluster "$cluster_name"; then
            failed_count=$((failed_count + 1))
        fi
    done
    
    if [[ $failed_count -eq 0 ]]; then
        print_success "All $total_count cluster configurations are valid"
    else
        print_error "$failed_count out of $total_count cluster configurations failed validation"
        return 1
    fi
}

# Parse command line arguments
COMMAND=""
CLUSTER_NAME=""
ENVIRONMENT=""
PLATFORM=""
BASE_DOMAIN=""
REPLICAS=""
MEMORY=""
CORES=""
STORAGE=""
STORAGE_CLASS=""
FORMAT="table"

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
    list)
        while [[ $# -gt 0 ]]; do
            case $1 in
                --format)
                    FORMAT="$2"
                    shift 2
                    ;;
                -h|--help)
                    usage
                    exit 0
                    ;;
                *)
                    print_error "Unknown option for list command: $1"
                    usage
                    exit 1
                    ;;
            esac
        done
        list_clusters "$FORMAT"
        ;;
    show)
        if [[ $# -eq 0 ]]; then
            print_error "Cluster name is required for show command"
            usage
            exit 1
        fi
        CLUSTER_NAME="$1"
        shift
        
        while [[ $# -gt 0 ]]; do
            case $1 in
                --format)
                    FORMAT="$2"
                    shift 2
                    ;;
                -h|--help)
                    usage
                    exit 0
                    ;;
                *)
                    print_error "Unknown option for show command: $1"
                    usage
                    exit 1
                    ;;
            esac
        done
        show_cluster "$CLUSTER_NAME" "$FORMAT"
        ;;
    validate)
        if [[ $# -eq 0 ]]; then
            print_error "Cluster name is required for validate command"
            usage
            exit 1
        fi
        CLUSTER_NAME="$1"
        validate_cluster "$CLUSTER_NAME"
        ;;
    validate-all)
        validate_all_clusters
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac
