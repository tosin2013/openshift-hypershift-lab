#!/bin/bash

# OpenShift 3-Node Cluster Deployment Script for AWS with Bare Metal Capabilities
# This script deploys a 3-node OpenShift cluster where masters act as workers
# Supports both standard and bare metal configurations
# Author: Original script creator
# Enhanced for bare metal workloads and OpenShift Virtualization

set -euo pipefail

# Configuration variables
BARE_METAL_ENABLED=false
INSTANCE_TYPE="m6i.4xlarge"
LOG_FILE="openshift-deployment-$(date +%Y%m%d-%H%M%S).log"

# Configurable deployment parameters with defaults
OPENSHIFT_VERSION="${OPENSHIFT_VERSION:-4.18.20}"
BASE_DOMAIN="${BASE_DOMAIN:-}"  # No default - user must provide
CLUSTER_NAME="${CLUSTER_NAME:-baremetal-lab}"
AWS_REGION="${AWS_REGION:-us-east-2}"
PULL_SECRET_PATH="${PULL_SECRET_PATH:-$HOME/pull-secret.json}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARN: $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

OpenShift 3-Node Cluster Deployment Script for AWS with Bare Metal Capabilities

OPTIONS:
    -i, --instance-type TYPE    AWS instance type for worker nodes (default: m6i.4xlarge)
    -v, --version VERSION       OpenShift version to deploy (default: 4.18.20)
    -d, --domain DOMAIN         Base domain for the cluster (REQUIRED - must have Route53 hosted zone)
    -n, --name NAME             Cluster name (default: baremetal-lab)
    -r, --region REGION         AWS region (default: us-east-2)
    -p, --pull-secret PATH      Path to pull secret file (default: ~/pull-secret.json)
    -h, --help                  Show this help message
    --bare-metal                Configure for bare metal deployment capabilities (uses larger instances)

Environment Variables:
    OPENSHIFT_VERSION           OpenShift version to deploy
    BASE_DOMAIN                 Base domain for the cluster
    CLUSTER_NAME                Cluster name
    AWS_REGION                  AWS region
    PULL_SECRET_PATH            Path to pull secret file

Examples:
    $0 --domain example.com --instance-type m6i.4xlarge
    $0 --domain my-domain.com --bare-metal --version 4.18.20
    $0 --name my-cluster --domain example.com --region us-west-2
    $0 --domain my-domain.com --instance-type c5n.metal --bare-metal

IMPORTANT: You must have a Route53 hosted zone for your domain before deployment!

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--instance-type)
            INSTANCE_TYPE="$2"
            shift 2
            ;;
        -v|--version)
            OPENSHIFT_VERSION="$2"
            shift 2
            ;;
        -d|--domain)
            BASE_DOMAIN="$2"
            shift 2
            ;;
        -n|--name)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -p|--pull-secret)
            PULL_SECRET_PATH="$2"
            shift 2
            ;;
        --bare-metal)
            BARE_METAL_ENABLED=true
            INSTANCE_TYPE="c5n.metal"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate configuration parameters
validate_configuration() {
    log "Validating configuration parameters..."

    # Validate OpenShift version format
    if [[ ! "$OPENSHIFT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        error "Invalid OpenShift version format: $OPENSHIFT_VERSION (expected: x.y.z)"
        exit 1
    fi

    # Validate cluster name (DNS-compatible)
    if [[ ! "$CLUSTER_NAME" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || [ ${#CLUSTER_NAME} -gt 63 ]; then
        error "Invalid cluster name: $CLUSTER_NAME (must be DNS-compatible, lowercase, max 63 chars)"
        exit 1
    fi

    # Validate base domain is provided and format
    if [ -z "$BASE_DOMAIN" ]; then
        error "Base domain is required but not provided"
        error "Please specify a domain using --domain or BASE_DOMAIN environment variable"
        error "Example: $0 --domain example.com"
        error "Note: You must have a Route53 hosted zone for this domain"
        exit 1
    fi

    if [[ ! "$BASE_DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$ ]]; then
        error "Invalid base domain format: $BASE_DOMAIN"
        exit 1
    fi

    # Validate AWS region format
    if [[ ! "$AWS_REGION" =~ ^[a-z]{2}-[a-z]+-[0-9]+$ ]]; then
        error "Invalid AWS region format: $AWS_REGION (expected: us-east-1, eu-west-1, etc.)"
        exit 1
    fi

    # Validate instance type format
    if [[ ! "$INSTANCE_TYPE" =~ ^[a-z][0-9]+[a-z]*\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge|metal)$ ]]; then
        error "Invalid instance type format: $INSTANCE_TYPE"
        exit 1
    fi

    # Validate pull secret path
    if [ ! -f "$PULL_SECRET_PATH" ]; then
        error "Pull secret file not found: $PULL_SECRET_PATH"
        error "Please download your pull secret from https://console.redhat.com/openshift/install/pull-secret"
        exit 1
    fi

    # Validate pull secret content
    if ! jq empty "$PULL_SECRET_PATH" 2>/dev/null; then
        error "Pull secret file is not valid JSON: $PULL_SECRET_PATH"
        exit 1
    fi

    log "Configuration validation completed"
}

# Interactive pull secret setup assistance
setup_pull_secret_interactive() {
    log "Setting up pull secret..."

    if [ -f "$PULL_SECRET_PATH" ]; then
        info "Pull secret found at: $PULL_SECRET_PATH"

        # Validate existing pull secret
        if jq empty "$PULL_SECRET_PATH" 2>/dev/null; then
            log "Pull secret validation passed"
            return 0
        else
            warn "Existing pull secret is invalid JSON, will guide you through setup"
        fi
    fi

    error "Pull secret not found or invalid at: $PULL_SECRET_PATH"
    echo ""
    info "To obtain your pull secret:"
    echo "  1. Visit: https://console.redhat.com/openshift/install/pull-secret"
    echo "  2. Log in with your Red Hat account"
    echo "  3. Click 'Download pull secret'"
    echo "  4. Save the file as: $PULL_SECRET_PATH"
    echo ""

    # Offer to open the URL if possible
    if command_exists xdg-open; then
        read -p "Would you like to open the pull secret download page in your browser? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            xdg-open "https://console.redhat.com/openshift/install/pull-secret" &
            info "Opening pull secret download page..."
        fi
    elif command_exists open; then
        read -p "Would you like to open the pull secret download page in your browser? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open "https://console.redhat.com/openshift/install/pull-secret" &
            info "Opening pull secret download page..."
        fi
    fi

    echo ""
    read -p "Press Enter after you have downloaded and saved the pull secret to $PULL_SECRET_PATH..."

    # Validate the newly downloaded pull secret
    if [ -f "$PULL_SECRET_PATH" ] && jq empty "$PULL_SECRET_PATH" 2>/dev/null; then
        log "Pull secret setup completed successfully"
        return 0
    else
        error "Pull secret is still not found or invalid. Please ensure you've saved it correctly."
        exit 1
    fi
}

# Enhanced pull secret validation with helpful error messages
validate_pull_secret() {
    log "Validating pull secret..."

    if [ ! -f "$PULL_SECRET_PATH" ]; then
        error "Pull secret file not found: $PULL_SECRET_PATH"
        setup_pull_secret_interactive
        return $?
    fi

    # Check if file is readable
    if [ ! -r "$PULL_SECRET_PATH" ]; then
        error "Pull secret file is not readable: $PULL_SECRET_PATH"
        error "Please check file permissions"
        exit 1
    fi

    # Check if file is empty
    if [ ! -s "$PULL_SECRET_PATH" ]; then
        error "Pull secret file is empty: $PULL_SECRET_PATH"
        setup_pull_secret_interactive
        return $?
    fi

    # Validate JSON format
    if ! jq empty "$PULL_SECRET_PATH" 2>/dev/null; then
        error "Pull secret file is not valid JSON: $PULL_SECRET_PATH"
        warn "The file may be corrupted or incomplete"
        setup_pull_secret_interactive
        return $?
    fi

    # Validate pull secret structure
    local auths_count=$(jq '.auths | length' "$PULL_SECRET_PATH" 2>/dev/null || echo "0")
    if [ "$auths_count" -eq 0 ]; then
        error "Pull secret does not contain any authentication entries"
        error "Please ensure you downloaded the correct pull secret from Red Hat"
        setup_pull_secret_interactive
        return $?
    fi

    info "Pull secret validation passed ($auths_count authentication entries found)"
    log "Pull secret validation completed"
}

# Check system prerequisites
check_system_prerequisites() {
    log "Checking system prerequisites..."

    # Check required commands (excluding those we can auto-install)
    local required_commands=("aws" "jq" "ssh-keygen")
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            error "$cmd is not installed. Please install it first."
            exit 1
        fi
    done

    # Check if yq exists, if not we'll install it during prerequisites
    if ! command_exists yq; then
        warn "yq not found. Will be downloaded during installation."
    fi

    # Check if openshift-install exists, if not download it
    if ! command_exists openshift-install; then
        warn "openshift-install not found. Will be downloaded during installation."
    fi

    log "System prerequisites check completed"
}

# Validate AWS environment
validate_aws_environment() {
    log "Validating AWS environment..."

    # Check AWS credentials
    if ! aws sts get-caller-identity &>/dev/null; then
        error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi

    # Get AWS account info
    local aws_account=$(aws sts get-caller-identity --query Account --output text)
    local aws_region=$(aws configure get region || echo "$AWS_REGION")

    info "AWS Account: $aws_account"
    info "AWS Region: $aws_region"

    # Check if required AWS services are available
    if ! aws ec2 describe-regions --region-names "$aws_region" &>/dev/null; then
        error "Cannot access EC2 in region $aws_region"
        exit 1
    fi

    log "AWS environment validation completed"
}

# Comprehensive AWS permissions and quota validation
validate_aws_permissions_and_quotas() {
    log "Validating AWS permissions and service quotas..."

    local aws_region=$(aws configure get region || echo "$AWS_REGION")
    local required_permissions_passed=true
    local quota_warnings=()

    # Test required IAM permissions
    info "Checking IAM permissions..."

    # Check EC2 permissions
    if ! aws ec2 describe-instances --max-items 1 &>/dev/null; then
        error "Missing EC2 describe permissions"
        required_permissions_passed=false
    fi

    if ! aws ec2 describe-vpcs --max-items 1 &>/dev/null; then
        error "Missing VPC describe permissions"
        required_permissions_passed=false
    fi

    # Check IAM permissions for OpenShift installer
    if ! aws iam list-roles --max-items 1 &>/dev/null; then
        error "Missing IAM list permissions"
        required_permissions_passed=false
    fi

    # Check Route53 permissions
    if ! aws route53 list-hosted-zones --max-items 1 &>/dev/null; then
        error "Missing Route53 permissions"
        required_permissions_passed=false
    fi

    # Check service quotas for the deployment
    info "Checking service quotas..."

    # Check EC2 instance limits
    local instance_type_to_check="m6i.xlarge"
    if $BARE_METAL_ENABLED; then
        instance_type_to_check="c5n.metal"
    fi

    # Get current running instances of the type
    local current_instances=$(aws ec2 describe-instances \
        --filters "Name=instance-type,Values=$instance_type_to_check" "Name=instance-state-name,Values=running,pending" \
        --query 'Reservations[*].Instances[*].InstanceId' --output text | wc -w)

    info "Current $instance_type_to_check instances: $current_instances"

    # Check VPC limits
    local current_vpcs=$(aws ec2 describe-vpcs --query 'Vpcs[*].VpcId' --output text | wc -w)
    info "Current VPCs: $current_vpcs"

    if [ "$current_vpcs" -gt 4 ]; then
        quota_warnings+=("High VPC usage ($current_vpcs/5 default limit)")
    fi

    # Check Elastic IP limits
    local current_eips=$(aws ec2 describe-addresses --query 'Addresses[*].AllocationId' --output text | wc -w)
    info "Current Elastic IPs: $current_eips"

    if [ "$current_eips" -gt 3 ]; then
        quota_warnings+=("High Elastic IP usage ($current_eips/5 default limit)")
    fi

    # Report quota warnings
    if [ ${#quota_warnings[@]} -gt 0 ]; then
        warn "Service quota warnings detected:"
        for warning in "${quota_warnings[@]}"; do
            warn "  - $warning"
        done
        warn "Consider requesting quota increases if deployment fails"
    fi

    if [ "$required_permissions_passed" = false ]; then
        error "Required AWS permissions are missing. Please ensure your AWS credentials have sufficient permissions."
        error "Required permissions include: EC2, VPC, IAM, Route53, ELB, S3"
        exit 1
    fi

    log "AWS permissions and quotas validation completed"
}

# Validate Route53 hosted zone for the domain
validate_route53_domain() {
    log "Validating Route53 hosted zone for domain: $BASE_DOMAIN"

    if [ -z "$BASE_DOMAIN" ]; then
        error "Base domain is required but not provided"
        error "Please specify a domain using --domain or BASE_DOMAIN environment variable"
        error "Example: $0 --domain example.com"
        exit 1
    fi

    # Check if Route53 hosted zone exists for the domain
    local hosted_zones=$(aws route53 list-hosted-zones --query "HostedZones[?Name=='${BASE_DOMAIN}.'].[Name,Id]" --output text 2>/dev/null)

    if [ -z "$hosted_zones" ]; then
        error "No Route53 hosted zone found for domain: $BASE_DOMAIN"
        echo ""
        warn "To fix this issue, you have several options:"
        echo ""
        echo "1. CREATE A ROUTE53 HOSTED ZONE (Recommended):"
        echo "   aws route53 create-hosted-zone --name $BASE_DOMAIN --caller-reference $(date +%s)"
        echo ""
        echo "2. USE AN EXISTING DOMAIN:"
        echo "   List your existing hosted zones:"
        echo "   aws route53 list-hosted-zones --query 'HostedZones[*].[Name,Id]' --output table"
        echo ""
        echo "3. USE A SUBDOMAIN OF AN EXISTING ZONE:"
        echo "   If you own 'example.com', you can use 'dev.example.com' or 'lab.example.com'"
        echo ""
        echo "4. FOR TESTING ONLY - Use a public domain service like:"
        echo "   - nip.io (e.g., cluster.1.2.3.4.nip.io)"
        echo "   - xip.io (e.g., cluster.1.2.3.4.xip.io)"
        echo ""
        exit 1
    fi

    local zone_name=$(echo "$hosted_zones" | awk '{print $1}' | sed 's/\.$//')
    local zone_id=$(echo "$hosted_zones" | awk '{print $2}')

    info "Found Route53 hosted zone: $zone_name (ID: $zone_id)"
    log "Route53 domain validation completed"
}

# Install prerequisites
install_prerequisites() {
    log "Installing OpenShift prerequisites..."
    
    # Create directory for binaries
    mkdir -p ~/bin
    
    # Download and install openshift-install if not present
    if ! command_exists openshift-install; then
        info "Downloading openshift-install version $OPENSHIFT_VERSION..."
        local url="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OPENSHIFT_VERSION}/openshift-install-linux.tar.gz"
        
        curl -L "$url" -o /tmp/openshift-install.tar.gz
        tar -xzf /tmp/openshift-install.tar.gz -C ~/bin/
        chmod +x ~/bin/openshift-install
        
        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
            export PATH="$HOME/bin:$PATH"
            echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
        fi
        
        rm /tmp/openshift-install.tar.gz
        log "openshift-install installed successfully"
    fi
    
    # Download and install oc if not present
    if ! command_exists oc; then
        info "Downloading oc client version $OPENSHIFT_VERSION..."
        local url="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OPENSHIFT_VERSION}/openshift-client-linux.tar.gz"
        
        curl -L "$url" -o /tmp/oc.tar.gz
        tar -xzf /tmp/oc.tar.gz -C ~/bin/
        chmod +x ~/bin/oc ~/bin/kubectl
        
        rm /tmp/oc.tar.gz
        log "oc client installed successfully"
    fi

    # Download and install yq if not present
    if ! command_exists yq; then
        info "Downloading yq YAML processor..."
        local yq_version="v4.44.3"
        local yq_url="https://github.com/mikefarah/yq/releases/download/${yq_version}/yq_linux_amd64"

        curl -L "$yq_url" -o ~/bin/yq
        chmod +x ~/bin/yq

        # Verify installation
        if ~/bin/yq --version &>/dev/null; then
            log "yq installed successfully"
        else
            error "Failed to install yq"
            exit 1
        fi
    fi
}



# Setup SSH keys
setup_ssh_keys() {
    log "Setting up SSH keys..."
    
    local ssh_key_path="$HOME/.ssh/openshift-key"
    
    if [ ! -f "$ssh_key_path" ]; then
        info "Generating new SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f "$ssh_key_path" -N "" -C "openshift-cluster-key"
        log "SSH key pair generated: $ssh_key_path"
    else
        info "Using existing SSH key: $ssh_key_path"
    fi
    
    # Set proper permissions
    chmod 600 "$ssh_key_path"
    chmod 644 "${ssh_key_path}.pub"
}

# Configure AWS CLI
configure_aws_cli() {
    log "Configuring AWS CLI..."
    
    # Ensure AWS region is set
    local aws_region=$(aws configure get region)
    if [ -z "$aws_region" ]; then
        warn "AWS region not set, using configured region: $AWS_REGION"
        aws configure set region "$AWS_REGION"
        aws_region="$AWS_REGION"
    fi
    
    # Verify AWS configuration
    local aws_account=$(aws sts get-caller-identity --query Account --output text)
    local aws_user=$(aws sts get-caller-identity --query Arn --output text)
    
    info "AWS Account: $aws_account"
    info "AWS User: $aws_user"
    info "AWS Region: $(aws configure get region)"
    
    log "AWS CLI configuration completed"
}

# Create install config
create_install_config() {
    log "Creating OpenShift install configuration..."
    
    # Create cluster directory
    mkdir -p cluster
    
    # Get AWS region and account info
    local aws_region=$(aws configure get region)
    local ssh_key_content=$(cat ~/.ssh/openshift-key.pub)
    
    # Validate and get pull secret
    validate_pull_secret
    local pull_secret=$(cat "$PULL_SECRET_PATH" | jq -c .)
    
    # Create install-config.yaml
    local config_file="cluster/install-config.yaml"
    
    cat > "$config_file" << EOF
apiVersion: v1
baseDomain: $BASE_DOMAIN
metadata:
  name: $CLUSTER_NAME
compute:
- name: worker
  replicas: 0
controlPlane:
  name: master
  replicas: 3
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16
platform:
  aws:
    region: $aws_region
    userTags:
      Environment: lab
      Purpose: baremetal-testing
      ClusterName: $CLUSTER_NAME
pullSecret: '$pull_secret'
sshKey: '$ssh_key_content'
EOF
    
    log "Install configuration created: $config_file"
}

# Configure 3-node cluster
configure_3_node_cluster() {
    log "Configuring 3-node cluster settings..."
    
    local config_file="cluster/install-config.yaml"
    
    # Configure control plane (3 masters)
    if $BARE_METAL_ENABLED; then
        info "Configuring control plane with 3 master nodes using c5n.metal instances..."
        yq -i eval '.controlPlane.replicas = 3' "$config_file"
        yq -i eval '.controlPlane.platform.aws.type = "c5n.metal"' "$config_file"
        yq -i eval '.controlPlane.platform.aws.rootVolume.size = 500' "$config_file"
        yq -i eval '.controlPlane.platform.aws.rootVolume.type = "gp3"' "$config_file"
        yq -i eval '.controlPlane.platform.aws.rootVolume.iops = 8000' "$config_file"
    else
        info "Configuring control plane with 3 master nodes using standard instances..."
        yq -i eval '.controlPlane.replicas = 3' "$config_file"
        yq -i eval '.controlPlane.platform.aws.type = "m6i.xlarge"' "$config_file"
        yq -i eval '.controlPlane.platform.aws.rootVolume.size = 200' "$config_file"
        yq -i eval '.controlPlane.platform.aws.rootVolume.type = "gp3"' "$config_file"
    fi

    # Configure for 3-node cluster (masters only, no separate workers)
    info "Configuring 3-node cluster with masters acting as workers (no separate worker nodes)..."
    # Worker replicas already set to 0 in initial config

    # Enable capabilities for virtualization and bare metal
    yq -i eval '.capabilities.baselineCapabilitySet = "vCurrent"' "$config_file"
    yq -i eval '.capabilities.additionalEnabledCapabilities = ["marketplace", "openshift-samples"]' "$config_file"

    # Configure networking for bare metal if enabled
    if $BARE_METAL_ENABLED; then
        yq -i eval '.networking.networkType = "OVNKubernetes"' "$config_file"
        yq -i eval '.networking.clusterNetwork[0].cidr = "10.128.0.0/14"' "$config_file"
        yq -i eval '.networking.clusterNetwork[0].hostPrefix = 23' "$config_file"
        yq -i eval '.networking.serviceNetwork[0] = "172.30.0.0/16"' "$config_file"
    fi

    log "3-node cluster configuration completed"
}


         
# Deploy the OpenShift cluster
deploy_cluster() {
    log "Starting OpenShift cluster deployment..."

    # Backup the install config for reference
    cp cluster/install-config.yaml cluster/install-config.yaml.backup

    info "Cluster deployment will take approximately 30-45 minutes..."
    info "Deployment logs: $LOG_FILE"

    # Start the deployment
    if openshift-install create cluster --dir cluster --log-level debug 2>&1 | tee -a "$LOG_FILE"; then
        log "OpenShift cluster deployed successfully!"

        # Wait a moment for cluster to stabilize
        info "Waiting for cluster to stabilize..."
        sleep 30

        display_cluster_info
        return 0
    else
        error "Cluster deployment failed. Check logs: $LOG_FILE"
        return 1
    fi
}

# Comprehensive post-deployment verification
verify_cluster_health() {
    log "Performing post-deployment cluster health verification..."

    if [ ! -f "cluster/auth/kubeconfig" ]; then
        error "Kubeconfig not found - cluster deployment failed"
        return 1
    fi

    # Set KUBECONFIG for verification
    export KUBECONFIG="$PWD/cluster/auth/kubeconfig"

    local verification_passed=true

    # Check cluster API accessibility
    info "Checking cluster API accessibility..."
    if ! oc cluster-info &>/dev/null; then
        error "Cluster API is not accessible"
        verification_passed=false
    else
        log "✓ Cluster API is accessible"
    fi

    # Check node status
    info "Checking node status..."
    local node_count=$(oc get nodes --no-headers 2>/dev/null | wc -l)
    local ready_nodes=$(oc get nodes --no-headers 2>/dev/null | grep -c " Ready ")

    if [ "$node_count" -ne 3 ]; then
        error "Expected 3 nodes, found $node_count"
        verification_passed=false
    elif [ "$ready_nodes" -ne 3 ]; then
        error "Expected 3 ready nodes, found $ready_nodes ready"
        verification_passed=false
    else
        log "✓ All 3 nodes are Ready"
    fi

    # Check cluster operators
    info "Checking cluster operators..."
    local total_operators=$(oc get clusteroperators --no-headers 2>/dev/null | wc -l)
    local available_operators=$(oc get clusteroperators --no-headers 2>/dev/null | grep -c "True.*False.*False")

    if [ "$total_operators" -eq 0 ]; then
        error "No cluster operators found"
        verification_passed=false
    elif [ "$available_operators" -lt $((total_operators * 80 / 100)) ]; then
        warn "Only $available_operators/$total_operators cluster operators are available"
        warn "Some operators may still be initializing"
    else
        log "✓ $available_operators/$total_operators cluster operators are available"
    fi

    # Check cluster version
    info "Checking cluster version..."
    local cluster_version=$(oc get clusterversion version -o jsonpath='{.status.desired.version}' 2>/dev/null)
    if [ -n "$cluster_version" ]; then
        log "✓ Cluster version: $cluster_version"
    else
        warn "Could not retrieve cluster version"
    fi

    # Check console accessibility
    info "Checking console accessibility..."
    local console_url=$(oc get route console -n openshift-console -o jsonpath='{.spec.host}' 2>/dev/null)
    if [ -n "$console_url" ]; then
        log "✓ Console URL: https://$console_url"
    else
        warn "Could not retrieve console URL"
    fi

    # Check storage classes
    info "Checking storage classes..."
    local storage_classes=$(oc get storageclass --no-headers 2>/dev/null | wc -l)
    if [ "$storage_classes" -gt 0 ]; then
        log "✓ $storage_classes storage class(es) available"
    else
        warn "No storage classes found"
    fi

    # Bare metal specific checks
    if $BARE_METAL_ENABLED; then
        info "Performing bare metal specific checks..."

        # Check node resources
        local node_resources=$(oc describe nodes 2>/dev/null | grep -E "cpu:|memory:" | head -2)
        if [ -n "$node_resources" ]; then
            log "✓ Node resources verified for bare metal workloads"
        fi

        # Check for virtualization capabilities
        if oc get nodes -o jsonpath='{.items[*].status.allocatable.devices\.kubevirt\.io/kvm}' 2>/dev/null | grep -q "[0-9]"; then
            log "✓ KVM virtualization capabilities detected"
        else
            warn "KVM virtualization capabilities not detected (may require additional configuration)"
        fi
    fi

    if [ "$verification_passed" = true ]; then
        log "✓ Cluster health verification completed successfully"
        return 0
    else
        error "Cluster health verification failed"
        return 1
    fi
}

# Display cluster access information
display_cluster_info() {
    log "=== OpenShift Cluster Information ==="

    if [ -f "cluster/auth/kubeconfig" ]; then
        # Set KUBECONFIG for immediate access
        export KUBECONFIG="$PWD/cluster/auth/kubeconfig"

        echo ""
        info "Cluster Details:"
        local api_url=$(oc whoami --show-server 2>/dev/null || cat cluster/auth/kubeconfig | grep server | awk '{print $2}')
        local console_url=$(echo "$api_url" | sed 's/api/console-openshift-console.apps/')

        echo "  Console URL: $console_url"
        echo "  API URL: $api_url"

        if [ -f "cluster/auth/kubeadmin-password" ]; then
            echo "  Username: kubeadmin"
            echo "  Password: $(cat cluster/auth/kubeadmin-password)"
        fi

        echo ""
        info "To access your cluster:"
        echo "  export KUBECONFIG=$PWD/cluster/auth/kubeconfig"
        echo "  oc get nodes"

        echo ""
        info "3-Node Cluster Configuration:"
        echo "  - 3 Master nodes (schedulable for workloads)"
        echo "  - 0 Dedicated worker nodes"
        echo "  - Masters act as both control plane and workers"

        if $BARE_METAL_ENABLED; then
            echo ""
            info "Bare metal capabilities enabled - cluster ready for:"
            echo "  - OpenShift Virtualization on master nodes"
            echo "  - High-performance workloads"
            echo "  - Metal3 bare metal provisioning"
        fi

        echo ""
        info "Cluster Health Status:"
        if verify_cluster_health; then
            echo "  ✓ All health checks passed"
        else
            echo "  ⚠ Some health checks failed - see logs above"
        fi
    else
        warn "Kubeconfig not found - cluster deployment may have failed"
    fi
}

# Cleanup function for failed deployments
cleanup_failed_deployment() {
    warn "Cleaning up failed deployment..."

    if [ -d "cluster" ]; then
        read -p "Do you want to destroy the partially created cluster? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            openshift-install destroy cluster --dir cluster --log-level debug
            log "Cluster destruction completed"
        fi
    fi
}

# Main execution function
main() {
    log "Starting OpenShift 3-Node Cluster Deployment"
    log "============================================="

    if $BARE_METAL_ENABLED; then
        info "Deploying 3-node bare metal cluster (masters only, no separate workers)"
        info "All Nodes: c5n.metal (64 vCPU, 256GB RAM per node)"
        info "Masters will be schedulable for workloads"
    else
        info "Deploying 3-node standard cluster (masters only, no separate workers)"
        info "All Nodes: m6i.xlarge (4 vCPU, 16GB RAM per node)"
        info "Masters will be schedulable for workloads"
    fi

    # Execute deployment steps
    validate_configuration
    check_system_prerequisites
    validate_aws_environment
    validate_aws_permissions_and_quotas
    validate_route53_domain
    install_prerequisites
    setup_ssh_keys
    configure_aws_cli
    create_install_config
    configure_3_node_cluster
    deploy_cluster

    log "Deployment completed successfully!"

    if $BARE_METAL_ENABLED; then
        echo ""
        info "Next steps for bare metal capabilities:"
        echo "  1. Install OpenShift Virtualization operator"
        echo "  2. Configure Metal3 for bare metal provisioning"
        echo "  3. Set up additional storage for VM workloads"
    fi

    echo ""
    info "Optional post-deployment steps:"
    echo "  - Configure Let's Encrypt certificates (non-root):"
    echo "    ./configure-keys-on-openshift-nonroot.sh <AWS_KEY> <AWS_SECRET> podman <EMAIL>"
    echo "  - Install operators (ArgoCD, ACM, ODF, OpenShift Virtualization)"
    echo "  - Set up monitoring and logging"
    echo "  - Configure additional storage classes"
}

# Trap for cleanup on script exit
trap cleanup_failed_deployment ERR

# Execute main function
main "$@"
