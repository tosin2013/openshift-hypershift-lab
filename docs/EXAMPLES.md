# Examples and Use Cases

This guide provides practical examples and common use cases for deploying OpenShift 3-node clusters with various configurations and requirements.

## 📋 Table of Contents

- [Quick Start Examples](#quick-start-examples)
- [Environment-Specific Deployments](#environment-specific-deployments)
- [Advanced Configurations](#advanced-configurations)
- [Use Case Scenarios](#use-case-scenarios)
- [Best Practices](#best-practices)

## 🚀 Quick Start Examples

### 1. Development Cluster with Your Domain

**Use Case**: Quick development environment with your own domain

```bash
# Development deployment - domain is REQUIRED
./openshift-3node-baremetal-cluster.sh --domain dev.example.com

# Configuration used:
# - Cluster Name: baremetal-lab
# - Domain: dev.example.com (YOUR domain with Route53 hosted zone)
# - Region: us-east-2
# - Instance Type: m6i.xlarge
# - OpenShift Version: 4.18.20
```

**Prerequisites**: You must have a Route53 hosted zone for `example.com` or `dev.example.com`

**Expected Resources**:
- 3 × m6i.xlarge instances (4 vCPU, 16GB RAM each)
- 200GB GP3 storage per node
- Total cost: ~$1.50/hour

### 2. Bare Metal High-Performance Cluster

**Use Case**: High-performance computing and virtualization workloads

```bash
# Enable bare metal capabilities
./openshift-3node-baremetal-cluster.sh --bare-metal

# Configuration used:
# - Instance Type: c5n.metal (64 vCPU, 256GB RAM)
# - Storage: 500GB GP3 with 8000 IOPS
# - KVM virtualization enabled
```

**Expected Resources**:
- 3 × c5n.metal instances (64 vCPU, 256GB RAM each)
- 500GB GP3 storage with high IOPS per node
- Total cost: ~$15/hour

### 3. Custom Named Cluster

**Use Case**: Specific naming requirements for organization

```bash
# Custom cluster name and domain
./openshift-3node-baremetal-cluster.sh \
  --name production-ocp \
  --domain prod.example.com
```

## 🏢 Environment-Specific Deployments

### Development Environment

**Requirements**: Cost-effective, quick deployment, easy cleanup

#### Option 1: Automated AWS Setup
```bash
# Quick development setup with automated AWS configuration
./configure-aws-cli.sh --install $DEV_AWS_KEY $DEV_AWS_SECRET us-east-1

# Development cluster configuration
export CLUSTER_NAME="dev-cluster"
export BASE_DOMAIN="dev.example.com"
export INSTANCE_TYPE="m6i.large"

./openshift-3node-baremetal-cluster.sh

# Post-deployment: Install development tools
oc new-project development
oc adm policy add-scc-to-user anyuid -z default
```

#### Option 2: Manual Configuration
```bash
# Manual AWS setup for development
aws configure set aws_access_key_id $DEV_AWS_KEY
aws configure set aws_secret_access_key $DEV_AWS_SECRET
aws configure set region us-east-1

# Development cluster configuration
export CLUSTER_NAME="dev-cluster"
export BASE_DOMAIN="dev.example.com"
export AWS_REGION="us-east-1"
export INSTANCE_TYPE="m6i.large"

./openshift-3node-baremetal-cluster.sh
```

**Characteristics**:
- Lower-cost instances (m6i.large)
- Relaxed security policies
- Quick provisioning and teardown

### Staging Environment

**Requirements**: Production-like configuration, testing capabilities

```bash
# Staging cluster with production-like settings
./openshift-3node-baremetal-cluster.sh \
  --name staging-cluster \
  --domain staging.example.com \
  --region us-west-2 \
  --instance-type m6i.xlarge \
  --version 4.18.20

# Post-deployment: Configure monitoring
oc apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    enableUserWorkload: true
    prometheusK8s:
      retention: 7d
EOF
```

### Production Environment

**Requirements**: High availability, security, monitoring, backup

```bash
# Production cluster with enhanced configuration
export CLUSTER_NAME="prod-cluster"
export BASE_DOMAIN="prod.example.com"
export AWS_REGION="us-west-2"
export OPENSHIFT_VERSION="4.18.20"

./openshift-3node-baremetal-cluster.sh --bare-metal

# Post-deployment production setup
# 1. Configure Let's Encrypt certificates
# 2. Set up monitoring and alerting
# 3. Configure backup strategies
# 4. Implement security policies
```

## 🔧 Advanced Configurations

### Multi-Region Deployment Strategy

**Use Case**: Disaster recovery and geographic distribution

```bash
# Primary region deployment
./openshift-3node-baremetal-cluster.sh \
  --name primary-cluster \
  --domain primary.example.com \
  --region us-east-1

# Secondary region deployment
./openshift-3node-baremetal-cluster.sh \
  --name secondary-cluster \
  --domain secondary.example.com \
  --region us-west-2
```

### Custom Pull Secret Location

**Use Case**: Shared environments, CI/CD pipelines

```bash
# Using custom pull secret location
export PULL_SECRET_PATH="/shared/secrets/openshift-pull-secret.json"

./openshift-3node-baremetal-cluster.sh \
  --name ci-cluster \
  --domain ci.example.com
```

### Version-Specific Deployment

**Use Case**: Testing specific OpenShift versions

```bash
# Deploy specific OpenShift version
./openshift-3node-baremetal-cluster.sh \
  --version 4.17.15 \
  --name test-4-17 \
  --domain test.example.com

# Deploy latest version
./openshift-3node-baremetal-cluster.sh \
  --version 4.18.20 \
  --name test-latest \
  --domain latest.example.com
```

## 🎯 Use Case Scenarios

### 1. OpenShift Virtualization Lab

**Objective**: Set up environment for VM workloads and container-native virtualization

```bash
# Deploy bare metal cluster for virtualization
./openshift-3node-baremetal-cluster.sh \
  --bare-metal \
  --name virt-lab \
  --domain virt.example.com

# Post-deployment: Install OpenShift Virtualization
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-cnv
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: kubevirt-hyperconverged-group
  namespace: openshift-cnv
spec:
  targetNamespaces:
  - openshift-cnv
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: hco-operatorhub
  namespace: openshift-cnv
spec:
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  name: kubevirt-hyperconverged
  channel: "stable"
EOF
```

### 2. AI/ML Development Platform

**Objective**: Machine learning workloads with GPU support preparation

```bash
# Deploy cluster ready for AI/ML workloads
./openshift-3node-baremetal-cluster.sh \
  --bare-metal \
  --name ml-platform \
  --domain ml.example.com \
  --region us-west-2

# Post-deployment: Install OpenShift AI
# Note: GPU instances would require different instance types
# This prepares the foundation for GPU node addition
```

### 3. Edge Computing Simulation

**Objective**: Simulate edge computing scenarios

```bash
# Deploy lightweight cluster for edge simulation
./openshift-3node-baremetal-cluster.sh \
  --name edge-sim \
  --domain edge.example.com \
  --instance-type m6i.large \
  --region us-east-1

# Post-deployment: Configure for edge workloads
oc label nodes --all node-role.kubernetes.io/edge=true
```

### 4. CI/CD Pipeline Environment

**Objective**: Continuous integration and deployment testing

#### Automated CI/CD Setup
```bash
# Automated setup for CI/CD pipelines
./configure-aws-cli.sh --install $CI_AWS_KEY $CI_AWS_SECRET us-east-1

# Deploy cluster for CI/CD testing
export CLUSTER_NAME="cicd-test-$(date +%Y%m%d)"
export BASE_DOMAIN="cicd.example.com"

./openshift-3node-baremetal-cluster.sh

# Post-deployment: Install CI/CD tools
oc new-project cicd
oc new-app jenkins-persistent
oc new-app sonarqube
```

#### CI/CD with Credential Rotation
```bash
# Script for rotating AWS credentials in CI/CD
#!/bin/bash
# rotate-aws-credentials.sh

# Remove old credentials
./configure-aws-cli.sh --delete

# Install with new credentials
./configure-aws-cli.sh --install $NEW_AWS_KEY $NEW_AWS_SECRET $AWS_REGION

# Verify access
aws sts get-caller-identity
```

### 5. Security Testing Lab

**Objective**: Security testing and compliance validation

```bash
# Deploy cluster for security testing
./openshift-3node-baremetal-cluster.sh \
  --name security-lab \
  --domain security.example.com \
  --bare-metal

# Post-deployment: Install security tools
oc adm new-project security-scanning
oc new-app --name clair quay.io/coreos/clair:latest
```

## 📝 Best Practices

### 1. Naming Conventions

```bash
# Environment-based naming
--name dev-cluster-$(date +%Y%m%d)
--name staging-cluster-v2
--name prod-cluster-primary

# Purpose-based naming
--name ml-training-cluster
--name virt-lab-cluster
--name security-test-cluster
```

### 2. Resource Management

```bash
# Development: Cost-optimized
--instance-type m6i.large

# Staging: Balanced
--instance-type m6i.xlarge

# Production: Performance-optimized
--bare-metal  # Uses c5n.metal
```

### 3. Environment Variables for Automation

```bash
# Create environment-specific configuration files
cat > dev.env <<EOF
export CLUSTER_NAME="dev-cluster"
export BASE_DOMAIN="dev.example.com"
export AWS_REGION="us-east-1"
export INSTANCE_TYPE="m6i.large"
EOF

# Source and deploy
source dev.env
./openshift-3node-baremetal-cluster.sh
```

### 4. Deployment Automation

#### Full Automation Script
```bash
#!/bin/bash
# automated-deployment.sh

# Set environment
ENV=${1:-dev}
source ${ENV}.env

# Validate environment
if [[ -z "$CLUSTER_NAME" ]]; then
    echo "Error: Environment not properly configured"
    exit 1
fi

# Configure AWS CLI automatically
./configure-aws-cli.sh --install $AWS_ACCESS_KEY $AWS_SECRET_KEY $AWS_REGION

# Deploy cluster
./openshift-3node-baremetal-cluster.sh

# Post-deployment configuration
if [[ "$ENV" == "prod" ]]; then
    # Production-specific setup
    echo "Configuring production settings..."
    # Add production configurations
fi
```

#### Environment-Specific AWS Configuration
```bash
# dev.env
export AWS_ACCESS_KEY="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_REGION="us-east-1"
export CLUSTER_NAME="dev-cluster"

# prod.env
export AWS_ACCESS_KEY="AKIAI44QH8DHBEXAMPLE"
export AWS_SECRET_KEY="je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY"
export AWS_REGION="us-west-2"
export CLUSTER_NAME="prod-cluster"
```

### 5. Cost Optimization

```bash
# Development clusters - use smaller instances
export INSTANCE_TYPE="m6i.large"

# Scheduled deployments - use spot instances (manual configuration)
# Note: Spot instances require additional AWS configuration

# Auto-cleanup for temporary clusters
echo "0 2 * * * /path/to/cleanup-old-clusters.sh" | crontab -
```

### 6. Monitoring and Logging

```bash
# Enable comprehensive logging
export LOG_LEVEL="debug"

# Post-deployment monitoring setup
oc apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    enableUserWorkload: true
    prometheusK8s:
      retention: 30d
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 100Gi
EOF
```

## 🔄 Cleanup Examples

### Temporary Cluster Cleanup

```bash
# Destroy cluster after testing
openshift-install destroy cluster --dir cluster --log-level debug

# Clean up local files
rm -rf cluster/
rm openshift-deployment-*.log
```

### Automated Cleanup Script

```bash
#!/bin/bash
# cleanup-cluster.sh

CLUSTER_DIR=${1:-cluster}

if [[ -d "$CLUSTER_DIR" ]]; then
    echo "Destroying cluster in $CLUSTER_DIR..."
    openshift-install destroy cluster --dir "$CLUSTER_DIR" --log-level debug
    
    echo "Cleaning up local files..."
    rm -rf "$CLUSTER_DIR"
    rm -f openshift-deployment-*.log
    
    echo "Cleanup completed"
else
    echo "No cluster directory found"
fi
```

## 📚 Related Documentation

- [Configuration Guide](CONFIGURATION.md) - Detailed parameter options
- [Deployment Guide](DEPLOYMENT.md) - Step-by-step instructions
- [Validation Guide](VALIDATION.md) - Understanding health checks
