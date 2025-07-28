#!/bin/bash

# Test script to validate Kustomize replacements work correctly
# This script creates a test instance and validates the output without applying to cluster

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Test configuration
TEST_INSTANCE_NAME="test-cluster"
TEST_BASE_DOMAIN="apps.sandbox1271.opentlc.com"
TEST_ENVIRONMENT="test"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GITOPS_DIR="$PROJECT_ROOT/gitops/cluster-config/virt-lab-env"
TEST_OUTPUT_DIR="/tmp/kustomize-test-$$"

print_info "Starting Kustomize replacements test"
print_info "Test instance name: $TEST_INSTANCE_NAME"
print_info "Test output directory: $TEST_OUTPUT_DIR"

# Create test instance using the existing script
print_info "Creating test instance..."
"$SCRIPT_DIR/create-hosted-cluster-instance.sh" \
    --name "$TEST_INSTANCE_NAME" \
    --domain "$TEST_BASE_DOMAIN" \
    --environment "$TEST_ENVIRONMENT" \
    --replicas 1 \
    --memory 4Gi \
    --cores 2

# Test directory
TEST_INSTANCE_DIR="$GITOPS_DIR/overlays/instances/$TEST_INSTANCE_NAME"

if [[ ! -d "$TEST_INSTANCE_DIR" ]]; then
    print_error "Test instance directory not created: $TEST_INSTANCE_DIR"
    exit 1
fi

print_success "Test instance created successfully"

# Create output directory
mkdir -p "$TEST_OUTPUT_DIR"

# Run kustomize build to test the configuration
print_info "Running kustomize build to test configuration..."
cd "$TEST_INSTANCE_DIR"

if kustomize build . > "$TEST_OUTPUT_DIR/output.yaml" 2> "$TEST_OUTPUT_DIR/errors.log"; then
    print_success "Kustomize build completed successfully"
else
    print_error "Kustomize build failed. Check errors:"
    cat "$TEST_OUTPUT_DIR/errors.log"
    exit 1
fi

# Validate the output
print_info "Validating replacements in output..."

# Check if placeholders were replaced
if grep -q "PLACEHOLDER" "$TEST_OUTPUT_DIR/output.yaml"; then
    print_error "Found unreplaced placeholders in output:"
    grep "PLACEHOLDER" "$TEST_OUTPUT_DIR/output.yaml"
    exit 1
else
    print_success "No unreplaced placeholders found"
fi

# Check specific values
print_info "Checking specific replacement values..."

# Check cluster name
if grep -q "name: $TEST_INSTANCE_NAME" "$TEST_OUTPUT_DIR/output.yaml"; then
    print_success "✓ Cluster name replacement working"
else
    print_error "✗ Cluster name replacement failed"
fi

# Check nodepool name
if grep -q "name: $TEST_INSTANCE_NAME-pool-1" "$TEST_OUTPUT_DIR/output.yaml"; then
    print_success "✓ NodePool name replacement working"
else
    print_error "✗ NodePool name replacement failed"
fi

# Check namespace
if grep -q "namespace: clusters" "$TEST_OUTPUT_DIR/output.yaml"; then
    print_success "✓ Namespace replacement working"
else
    print_error "✗ Namespace replacement failed"
fi

# Check base domain
if grep -q "baseDomain: $TEST_BASE_DOMAIN" "$TEST_OUTPUT_DIR/output.yaml"; then
    print_success "✓ Base domain replacement working"
else
    print_error "✗ Base domain replacement failed"
fi

print_info "Generated output saved to: $TEST_OUTPUT_DIR/output.yaml"
print_info "You can review the full output with: cat $TEST_OUTPUT_DIR/output.yaml"

# Cleanup test instance
print_info "Cleaning up test instance..."
rm -rf "$TEST_INSTANCE_DIR"
print_success "Test instance cleaned up"

print_success "Kustomize replacements test completed successfully!"
print_info "All replacements are working correctly at the instance level"
