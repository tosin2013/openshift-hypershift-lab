# How to Set Up Credentials for Hosted Clusters

This guide explains how to set up the required credentials for hosted cluster deployments. Hosted clusters require several types of credentials to function properly.

## Overview of Required Credentials

### 1. **Pull Secret** (Required)
- **Purpose**: Authenticate with Red Hat registries to pull OpenShift images
- **Source**: Red Hat Customer Portal
- **Format**: JSON file containing registry authentication tokens

### 2. **SSH Key** (Required)
- **Purpose**: Access cluster nodes for debugging and maintenance
- **Source**: Generated locally or existing key pair
- **Format**: RSA private/public key pair

### 3. **Infrastructure Credentials** (Required)
- **Purpose**: Access to the management cluster for hosted control plane
- **Source**: Current kubeconfig of the management cluster
- **Format**: Kubernetes kubeconfig file

### 4. **AWS Credentials** (AWS clusters only)
- **Purpose**: Provision and manage AWS resources for hosted clusters
- **Source**: AWS IAM credentials
- **Format**: AWS credentials file or environment variables

## Quick Setup (Automated)

### Option 1: Interactive Setup (Recommended for First Time)

```bash
# Set up credentials interactively with automatic SSH key creation
./scripts/setup-hosted-cluster-credentials.sh \
  --interactive \
  --create-ssh-key \
  my-cluster-01
```

This will:
- Guide you through pull secret download
- Create SSH keys automatically
- Set up all required secrets in OpenShift

### Option 2: Automated Setup with Existing Files

```bash
# Set up credentials with existing files
./scripts/setup-hosted-cluster-credentials.sh \
  --pull-secret-path ~/pull-secret.json \
  --ssh-key-path ~/.ssh/openshift-key \
  my-cluster-01
```

### Option 3: Integrated with Instance Creation

```bash
# Create instance and set up credentials in one command
./scripts/create-hosted-cluster-instance.sh \
  --name my-cluster-01 \
  --environment dev \
  --domain dev.example.com \
  --setup-credentials \
  --interactive-credentials
```

## Manual Setup (Step by Step)

### Step 1: Download Pull Secret

1. **Visit Red Hat Console**:
   ```bash
   # Open browser to pull secret page
   xdg-open "https://console.redhat.com/openshift/install/pull-secret"
   ```

2. **Log in** with your Red Hat account

3. **Download pull secret** and save as `~/pull-secret.json`

4. **Validate the pull secret**:
   ```bash
   # Check if it's valid JSON
   jq . ~/pull-secret.json
   
   # Verify it contains auths
   jq '.auths' ~/pull-secret.json
   ```

### Step 2: Set Up SSH Key

#### Option A: Create New SSH Key
```bash
# Generate new SSH key for OpenShift clusters
ssh-keygen -t rsa -b 4096 -f ~/.ssh/openshift-key -N "" -C "openshift-hosted-clusters"

# Set proper permissions
chmod 600 ~/.ssh/openshift-key
chmod 644 ~/.ssh/openshift-key.pub
```

#### Option B: Use Existing SSH Key
```bash
# Use your existing SSH key
ls -la ~/.ssh/id_rsa*

# Ensure proper permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### Step 3: Verify Management Cluster Access

```bash
# Ensure you're logged in to the management cluster
oc whoami

# Verify your kubeconfig
echo $KUBECONFIG
ls -la ~/.kube/config
```

### Step 4: Create Secrets in OpenShift

#### Create Pull Secret
```bash
# Create pull secret in clusters namespace
oc create namespace clusters --dry-run=client -o yaml | oc apply -f -

oc create secret generic pullsecret-cluster \
  --from-file=.dockerconfigjson=~/pull-secret.json \
  --type=kubernetes.io/dockerconfigjson \
  -n clusters
```

#### Create SSH Key Secret
```bash
# Create SSH key secret
oc create secret generic sshkey-cluster \
  --from-file=id_rsa.pub=~/.ssh/openshift-key.pub \
  -n clusters
```

#### Create Infrastructure Credentials
```bash
# Create infrastructure credentials secret for each cluster
CLUSTER_NAME="my-cluster-01"

oc create secret generic "${CLUSTER_NAME}-infra-credentials" \
  --from-file=kubeconfig=~/.kube/config \
  -n clusters
```

## AWS-Specific Setup

For AWS-based hosted clusters, additional credentials are required:

### Step 1: Prepare AWS Credentials

#### Option A: AWS Credentials File
```bash
# Ensure AWS credentials are configured
cat ~/.aws/credentials

# Should contain:
# [default]
# aws_access_key_id = YOUR_ACCESS_KEY
# aws_secret_access_key = YOUR_SECRET_KEY
```

#### Option B: Environment Variables
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### Step 2: Create AWS Credentials Secret

```bash
# Create AWS credentials secret
CLUSTER_NAME="my-aws-cluster"

oc create secret generic "${CLUSTER_NAME}-aws-credentials" \
  --from-file=credentials=~/.aws/credentials \
  -n clusters
```

### Step 3: Use AWS Template

```bash
# Create AWS cluster instance using AWS template
./scripts/create-hosted-cluster-instance.sh \
  --name my-aws-cluster \
  --environment prod \
  --domain aws.example.com \
  --template aws \
  --setup-credentials \
  --aws-credentials-path ~/.aws/credentials
```

## Verification

### Check Created Secrets

```bash
# List all secrets in clusters namespace
oc get secrets -n clusters

# Verify pull secret
oc get secret pullsecret-cluster -n clusters -o yaml

# Verify SSH key secret
oc get secret sshkey-cluster -n clusters -o yaml

# Verify infrastructure credentials
oc get secret my-cluster-01-infra-credentials -n clusters -o yaml
```

### Test Credential Access

```bash
# Test pull secret format
oc get secret pullsecret-cluster -n clusters -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq .

# Test SSH key
oc get secret sshkey-cluster -n clusters -o jsonpath='{.data.id_rsa\.pub}' | base64 -d

# Test infrastructure credentials
oc get secret my-cluster-01-infra-credentials -n clusters -o jsonpath='{.data.kubeconfig}' | base64 -d | head -5
```

## Troubleshooting

### Common Issues

#### Pull Secret Invalid
```bash
# Error: Pull secret is not valid JSON
# Solution: Re-download from Red Hat Console
curl -s https://console.redhat.com/openshift/install/pull-secret
```

#### SSH Key Permissions
```bash
# Error: SSH key has wrong permissions
# Solution: Fix permissions
chmod 600 ~/.ssh/openshift-key
chmod 644 ~/.ssh/openshift-key.pub
```

#### Infrastructure Credentials
```bash
# Error: Cannot access management cluster
# Solution: Re-login to management cluster
oc login --token=<your-token> --server=<your-server>
```

#### AWS Credentials
```bash
# Error: AWS credentials not found
# Solution: Configure AWS CLI
aws configure
# or
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
```

### Validation Commands

```bash
# Validate all credentials for a cluster
./scripts/setup-hosted-cluster-credentials.sh --dry-run my-cluster-01

# Check credential setup status
oc get secrets -n clusters | grep -E "(pullsecret|sshkey|infra-credentials)"

# Validate cluster deployment
./scripts/validate-deployment.sh my-cluster-01
```

## Security Best Practices

### 1. **Credential Rotation**
- Rotate pull secrets when they expire
- Regularly update SSH keys
- Refresh AWS credentials periodically

### 2. **Access Control**
- Use RBAC to limit access to credential secrets
- Store credentials in secure locations
- Use separate credentials for different environments

### 3. **Monitoring**
- Monitor credential expiration dates
- Set up alerts for credential failures
- Audit credential access logs

## Next Steps

After setting up credentials:

1. **Create Hosted Cluster Instance**:
   ```bash
   ./scripts/create-hosted-cluster-instance.sh --name my-cluster --domain example.com
   ```

2. **Deploy with GitOps**:
   ```bash
   oc apply -f gitops/cluster-config/apps/openshift-hypershift-lab/hosted-clusters-applicationset.yaml
   ```

3. **Validate Deployment**:
   ```bash
   ./scripts/validate-deployment.sh my-cluster
   ```

4. **Access Your Cluster**:
   ```bash
   oc get secret my-cluster-admin-kubeconfig -n clusters -o jsonpath='{.data.kubeconfig}' | base64 -d > my-cluster-kubeconfig
   export KUBECONFIG=my-cluster-kubeconfig
   oc get nodes
   ```

---

**Related Documentation:**
- [Getting Started Tutorial](../tutorials/getting-started.md)
- [Configuration Reference](../reference/configuration.md)
- [Troubleshooting Guide](troubleshoot.md)
