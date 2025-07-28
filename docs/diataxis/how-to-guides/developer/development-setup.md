# OpenShift HyperShift Lab Development Setup

This guide helps developers set up a local development environment for contributing to the OpenShift HyperShift Lab project, including testing the deployment scripts, modifying GitOps configurations, and developing new hosted cluster features.

## Prerequisites

- Linux-based development environment (RHEL, CentOS, Ubuntu, or Amazon Linux)
- Git installed and configured
- Internet access for downloading dependencies
- At least 8GB RAM and 20GB free disk space
- AWS account with appropriate permissions for testing deployments

## System Requirements

### Operating System Support
- **Primary**: RHEL 8+, CentOS 8+, Amazon Linux 2 (matches deployment targets)
- **Supported**: Ubuntu 20.04+, Fedora 35+
- **Architecture**: x86_64

### Hardware Requirements
- **CPU**: 4+ cores recommended (8+ for testing full deployments)
- **Memory**: 8GB minimum, 16GB recommended (32GB for local cluster testing)
- **Storage**: 20GB free space minimum (50GB+ for container images and logs)
- **Network**: Stable internet connection for AWS API calls and container pulls

## Step 1: Clone the OpenShift HyperShift Lab Repository

### Get the Source Code

```bash
# Clone the OpenShift HyperShift Lab repository
git clone https://github.com/tosin2013/openshift-hypershift-lab.git
cd openshift-hypershift-lab

# Verify the repository structure
ls -la
```

### Understanding the Repository Structure

```
openshift-hypershift-lab/
├── docs/                           # Project documentation
├── gitops/                         # GitOps configurations for ArgoCD
│   ├── apps/                       # ArgoCD Application definitions
│   └── cluster-config/             # Cluster configuration overlays
├── scripts/                        # Hosted cluster management scripts
├── openshift-3node-baremetal-cluster.sh  # Main foundation cluster deployment
├── configure-aws-cli.sh            # AWS CLI automated setup
├── setup-hosted-control-planes.sh  # HyperShift infrastructure setup
├── cluster-template*.yaml          # Hosted cluster templates
└── external-secrets-operatorconfig.yaml  # External Secrets configuration
```

### Key Development Areas

- **Deployment Scripts**: Main cluster deployment and setup automation
- **GitOps Configuration**: ArgoCD applications and cluster configurations
- **Hosted Cluster Scripts**: Tools for creating and managing hosted clusters
- **Templates**: Base configurations for new hosted cluster instances

## Step 2: Install Required Tools

### Core Development Tools

```bash
# Update system packages
sudo yum update -y  # For RHEL/CentOS/Amazon Linux
# OR
sudo apt update && sudo apt upgrade -y  # For Ubuntu

# Install essential development tools
sudo yum groupinstall -y "Development Tools"  # RHEL/CentOS
# OR
sudo apt install -y build-essential  # Ubuntu

# Install Git (if not already installed)
sudo yum install -y git  # RHEL/CentOS
# OR
sudo apt install -y git  # Ubuntu
```

### Required Command Line Tools

The project requires several CLI tools. Install them manually or let the scripts auto-install:

```bash
# Install jq (JSON processor) - REQUIRED
sudo yum install -y jq  # RHEL/CentOS
# OR
sudo apt install -y jq  # Ubuntu

# Install curl (usually pre-installed)
sudo yum install -y curl  # RHEL/CentOS
# OR
sudo apt install -y curl  # Ubuntu

# yq will be auto-installed by scripts if missing
# aws CLI will be auto-installed by configure-aws-cli.sh if missing
```

### OpenShift CLI (oc)

The deployment script will install `oc` automatically, but you can install it manually:

```bash
# Download and install oc CLI
curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz
tar -xzf openshift-client-linux.tar.gz
sudo mv oc kubectl /usr/local/bin/
rm openshift-client-linux.tar.gz

# Verify installation
oc version --client
```

## Step 3: Configure Development Environment

### Set Up Git Configuration

```bash
# Configure Git (if not already done)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set up Git aliases for productivity
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
```

### Create Development Branch

```bash
# Create and switch to a development branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/issue-description
```

### Set Up Environment Variables

Create a development environment file:

```bash
# Create .env file for development (DO NOT COMMIT)
cat > .env << 'EOF'
# Development environment variables
export OPENSHIFT_VERSION="4.18.20"
export AWS_REGION="us-east-2"
export CLUSTER_NAME="dev-cluster"
export BASE_DOMAIN="your-dev-domain.com"
export PULL_SECRET_PATH="$HOME/pull-secret.json"
EOF

# Add .env to .gitignore if not already there
echo ".env" >> .gitignore
```

## Step 4: AWS Development Setup

### Install AWS CLI

Use the provided script for automated installation:

```bash
# Make the script executable
chmod +x configure-aws-cli.sh

# Install AWS CLI with your development credentials
./configure-aws-cli.sh --install YOUR_DEV_ACCESS_KEY YOUR_DEV_SECRET_KEY YOUR_REGION
```

### Manual AWS CLI Installation

If you prefer manual installation:

```bash
# Download and install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Configure AWS credentials
aws configure
```

### Development AWS Account Setup

For development, you'll need:

1. **AWS Account**: Separate development AWS account (recommended)
2. **IAM User**: With appropriate permissions for OpenShift deployment
3. **Route53 Hosted Zone**: For your development domain
4. **Service Quotas**: Sufficient for EC2 instances and networking

## Step 5: Red Hat Account Setup

### Get Pull Secret

1. **Visit**: [Red Hat Console](https://console.redhat.com/openshift/install/pull-secret)
2. **Log in** with your Red Hat account
3. **Download** the pull secret file
4. **Save** as `~/pull-secret.json`

```bash
# Verify pull secret format
jq . ~/pull-secret.json
```

## Step 6: Development Workflow Setup

### Script Permissions

Make all scripts executable:

```bash
# Make main scripts executable
chmod +x openshift-3node-baremetal-cluster.sh
chmod +x configure-aws-cli.sh
chmod +x setup-hosted-control-planes.sh

# Make utility scripts executable
chmod +x scripts/*.sh
```

### Testing Environment

Set up a testing environment:

```bash
# Create a test configuration
export CLUSTER_NAME="test-cluster"
export BASE_DOMAIN="test.your-domain.com"
export INSTANCE_TYPE="m6i.large"  # Smaller for testing

# Test script syntax
bash -n openshift-3node-baremetal-cluster.sh
echo "Script syntax check passed"
```

## Step 7: IDE and Editor Setup

### VS Code Setup (Recommended)

```bash
# Install VS Code extensions for shell scripting
code --install-extension ms-vscode.vscode-json
code --install-extension timonwong.shellcheck
code --install-extension foxundermoon.shell-format
code --install-extension redhat.vscode-yaml
```

### Vim Setup (Alternative)

```bash
# Install vim with syntax highlighting
sudo yum install -y vim-enhanced  # RHEL/CentOS
# OR
sudo apt install -y vim  # Ubuntu

# Add basic vim configuration
cat >> ~/.vimrc << 'EOF'
syntax on
set number
set tabstop=2
set shiftwidth=2
set expandtab
EOF
```

## Step 8: Validation and Testing

### Validate Development Setup

```bash
# Check all required tools
echo "Checking development environment..."

# Check Git
git --version || echo "❌ Git not installed"

# Check jq
jq --version || echo "❌ jq not installed"

# Check curl
curl --version || echo "❌ curl not installed"

# Check AWS CLI
aws --version || echo "⚠️ AWS CLI not installed (will be auto-installed)"

# Check oc CLI
oc version --client || echo "⚠️ oc CLI not installed (will be auto-installed)"

echo "✅ Development environment check complete"
```

### Test Script Execution

```bash
# Test script help output
./openshift-3node-baremetal-cluster.sh --help

# Test AWS configuration script
./configure-aws-cli.sh --help

# Validate script syntax
for script in *.sh scripts/*.sh; do
    if bash -n "$script"; then
        echo "✅ $script syntax OK"
    else
        echo "❌ $script has syntax errors"
    fi
done
```

## Troubleshooting

### Common Issues

**Permission denied errors**:
```bash
# Fix script permissions
chmod +x *.sh scripts/*.sh
```

**Missing dependencies**:
```bash
# Install missing packages
sudo yum install -y jq curl git  # RHEL/CentOS
# OR
sudo apt install -y jq curl git  # Ubuntu
```

**AWS CLI issues**:
```bash
# Use the provided installation script
./configure-aws-cli.sh --install ACCESS_KEY SECRET_KEY REGION
```

### Getting Help

- Check the [troubleshooting guide](debugging-issues.md)
- Review [script reference](../../reference/script-reference.md)
- See [contributing guidelines](contributing-code.md)

## Next Steps

Now that your development environment is set up:

1. **Read the [contributing guidelines](contributing-code.md)**
2. **Learn about [building from source](building-from-source.md)**
3. **Understand [running tests](running-tests.md)**
4. **Review the [architecture](../../explanations/architecture-overview.md)**

## Summary

Your development environment now includes:
- ✅ Source code repository cloned
- ✅ Required development tools installed
- ✅ Git configuration completed
- ✅ AWS CLI configured for development
- ✅ Red Hat pull secret obtained
- ✅ Scripts made executable and validated
- ✅ Development workflow established

You're ready to start contributing to the OpenShift HyperShift Lab project!
