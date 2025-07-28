# Deployment Guide

This comprehensive guide walks you through deploying an OpenShift 3-node cluster using the enhanced deployment script.

## 📋 Table of Contents

- [Pre-Deployment Checklist](#pre-deployment-checklist)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Post-Deployment Tasks](#post-deployment-tasks)
- [Verification Steps](#verification-steps)
- [Troubleshooting](#troubleshooting)

## ✅ Pre-Deployment Checklist

### 1. System Requirements
- [ ] Linux system (RHEL/CentOS/Amazon Linux/Ubuntu)
- [ ] Minimum 4GB RAM available
- [ ] Minimum 10GB free disk space
- [ ] Internet connectivity for downloads

### 2. AWS Prerequisites
- [ ] AWS account with appropriate permissions
- [ ] AWS CLI installed and configured
- [ ] Sufficient service quotas (see [AWS Requirements](#aws-requirements))
- [ ] Valid AWS region selected

### 3. Red Hat Prerequisites
- [ ] Red Hat account created
- [ ] Pull secret downloaded from [Red Hat Console](https://console.redhat.com/openshift/install/pull-secret)
- [ ] Pull secret saved to `~/pull-secret.json` (or custom path)

### 4. Domain and Network Prerequisites
- [ ] **Route53 Hosted Zone**: REQUIRED - Must have a hosted zone for your domain
- [ ] Domain ownership verified and accessible
- [ ] DNS resolution working for your domain
- [ ] Outbound internet access for cluster nodes

### 5. Security Prerequisites
- [ ] **SSL/TLS Requirements**: MANDATORY - Cluster must use secure SSL/TLS encryption
- [ ] Certificate authority access (Let's Encrypt or AWS Certificate Manager)
- [ ] HTTPS-only access enforcement for all endpoints
- [ ] Valid, trusted certificates for production deployments
- [ ] TLS 1.2 or higher support verification

#### Setting Up Your Domain (REQUIRED)

**Option 1: Create a new Route53 hosted zone**
```bash
# Create hosted zone for your domain
aws route53 create-hosted-zone --name example.com --caller-reference $(date +%s)
```

**Option 2: Use existing hosted zone**
```bash
# List your existing hosted zones
aws route53 list-hosted-zones --query 'HostedZones[*].[Name,Id]' --output table
```

**Option 3: Use subdomain of existing zone**
If you own `example.com`, you can use `dev.example.com` or `lab.example.com`

**Option 4: Testing with public DNS services (NOT for production)**
- `cluster.1.2.3.4.nip.io` (replace 1.2.3.4 with any IP)
- `cluster.1.2.3.4.xip.io` (replace 1.2.3.4 with any IP)

## 🚀 Step-by-Step Deployment

### Step 1: Download and Prepare Script

```bash
# Download the script (if not already available)
# Make it executable
chmod +x openshift-3node-baremetal-cluster.sh

# Verify script syntax
bash -n openshift-3node-baremetal-cluster.sh
```

### Step 2: Configure AWS CLI

#### Understanding 3-Node Cluster Architecture

**Why 3-Node Configuration**:
- **Cost Effective**: No dedicated worker nodes reduces infrastructure costs
- **Resource Efficient**: Master nodes are schedulable for workloads
- **Simplified Management**: Fewer nodes to manage and maintain
- **Development/Testing**: Ideal for non-production environments

**Configuration Details**:
- **Control Plane**: 3 master nodes with `replicas: 3`
- **Compute**: Worker section with `replicas: 0` (no dedicated workers)
- **Scheduling**: Masters are automatically made schedulable for workloads
- **High Availability**: 3 masters provide HA for the control plane

#### Understanding AWS Configuration Options

**When to use `configure-aws-cli.sh` (Automated)**:
- **New to AWS CLI**: First-time setup or unfamiliar with AWS CLI
- **CI/CD Pipelines**: Automated deployments requiring scripted setup
- **Team Environments**: Consistent setup across multiple developers
- **Credential Rotation**: Need to frequently change AWS credentials
- **Clean Installations**: Starting fresh or troubleshooting AWS CLI issues

**When to use Manual Configuration**:
- **Existing AWS Setup**: Already have AWS CLI configured and working
- **Multiple Profiles**: Need to manage multiple AWS accounts/profiles
- **Advanced Configuration**: Require custom AWS CLI settings
- **Security Policies**: Organization requires manual credential management

**When to use Environment Variables**:
- **Temporary Access**: Short-term or testing scenarios
- **Container Deployments**: Docker/Kubernetes environments
- **CI/CD Integration**: When credentials are injected by CI/CD systems

#### Option A: Automated Configuration (Recommended for New Users)
```bash
# Use the automated AWS CLI configuration script
chmod +x configure-aws-cli.sh

# Install and configure AWS CLI in one step
./configure-aws-cli.sh --install YOUR_ACCESS_KEY YOUR_SECRET_KEY YOUR_REGION

# The script will:
# 1. Install curl and unzip (via package manager)
# 2. Install yq YAML processor (latest version)
# 3. Install AWS CLI v2 if not present
# 4. Configure credentials in ~/.aws/credentials
# 5. Verify access with get-caller-identity
# 6. Clean up installation files
```

#### Option B: Manual Configuration
```bash
# Configure AWS credentials manually
aws configure

# Verify AWS access
aws sts get-caller-identity
```

#### Option C: Environment Variables
```bash
# Set AWS credentials via environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="your-region"

# Verify access
aws sts get-caller-identity
```

### Step 3: Prepare Pull Secret

```bash
# Option 1: Use default location
# Download pull secret to ~/pull-secret.json

# Option 2: Use custom location
export PULL_SECRET_PATH="/path/to/your/pull-secret.json"

# Verify pull secret format
jq . ~/pull-secret.json
```

### Step 4: Choose Deployment Type

#### Standard Deployment (Development/Testing)
```bash
./openshift-3node-baremetal-cluster.sh
```

#### Bare Metal Deployment (High-Performance)
```bash
./openshift-3node-baremetal-cluster.sh --bare-metal
```

#### Custom Configuration
```bash
./openshift-3node-baremetal-cluster.sh \
  --name my-cluster \
  --domain example.com \
  --region us-west-2 \
  --version 4.18.20
```

### Step 5: Monitor Deployment

The script will:
1. **Validate configuration** - Check all parameters and prerequisites
2. **Verify AWS environment** - Test credentials and permissions
3. **Check service quotas** - Ensure sufficient AWS resources
4. **Install prerequisites** - Download OpenShift tools if needed
5. **Setup SSH keys** - Generate or use existing keys
6. **Create install config** - Generate OpenShift configuration
7. **Deploy cluster** - Execute OpenShift installation (30-45 minutes)
8. **Verify deployment** - Run health checks

### Step 6: Access Your Cluster

After successful deployment:

```bash
# Set KUBECONFIG environment variable
export KUBECONFIG=$PWD/cluster/auth/kubeconfig

# Verify cluster access
oc get nodes

# Access web console
# URL and credentials will be displayed at the end of deployment
```

## 🔧 Post-Deployment Tasks

### 1. Cluster Configuration

#### Enable Cluster Monitoring
```bash
# Monitoring is enabled by default, verify it's working
oc get pods -n openshift-monitoring
```

#### Configure Storage Classes
```bash
# Check available storage classes
oc get storageclass

# Set default storage class if needed
oc patch storageclass gp3-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### 2. Security Configuration

#### Configure SSL Certificates (Required for Production)
```bash
# Configure Let's Encrypt SSL certificates with Route53 DNS validation
chmod +x configure-keys-on-openshift.sh
sudo -E ./configure-keys-on-openshift.sh AWS_ACCESS_KEY AWS_SECRET_KEY podman YOUR_EMAIL

# Verify SSL certificate configuration
oc get secret router-certs -n openshift-ingress
oc get ingresscontroller default -n openshift-ingress-operator -o yaml | grep defaultCertificate
```

#### Configure RBAC
```bash
# Create additional users and roles as needed
oc create user developer
oc adm policy add-cluster-role-to-user edit developer
```

### 3. Bare Metal Specific Tasks (if enabled)

#### Install OpenShift Virtualization
```bash
# Create namespace
oc create namespace openshift-cnv

# Install operator (via web console or CLI)
# Follow OpenShift Virtualization documentation
```

#### Configure Node Features
```bash
# Verify KVM capabilities
oc get nodes -o jsonpath='{.items[*].status.allocatable.devices\.kubevirt\.io/kvm}'

# Check CPU features
oc describe nodes | grep -A 10 "Allocatable:"
```

## ✅ Verification Steps

### 1. Basic Cluster Health

```bash
# Check cluster status
oc cluster-info

# Verify all nodes are ready
oc get nodes

# Check cluster operators
oc get clusteroperators
```

### 2. Network Connectivity

```bash
# Test internal DNS
oc run test-pod --image=busybox --rm -it -- nslookup kubernetes.default.svc.cluster.local

# Test external connectivity
oc run test-pod --image=busybox --rm -it -- wget -qO- https://www.google.com
```

### 3. SSL/TLS Security Verification

```bash
# Verify API server SSL certificate
CLUSTER_NAME=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')
BASE_DOMAIN=$(oc get infrastructure cluster -o jsonpath='{.status.platformStatus.aws.region}').compute.amazonaws.com
API_URL="api.${CLUSTER_NAME}.${BASE_DOMAIN}"

# Check SSL certificate validity
echo | openssl s_client -connect ${API_URL}:443 -servername ${API_URL} 2>/dev/null | openssl x509 -noout -text

# Verify certificate expiration (should be > 30 days)
echo | openssl s_client -connect ${API_URL}:443 -servername ${API_URL} 2>/dev/null | openssl x509 -noout -dates

# Test HTTPS enforcement on console
CONSOLE_URL=$(oc get route console -n openshift-console -o jsonpath='{.spec.host}')
curl -I https://${CONSOLE_URL}

# Verify TLS version (should be 1.2 or higher)
openssl s_client -connect ${API_URL}:443 -tls1_2 -servername ${API_URL} < /dev/null

# Check certificate chain
openssl s_client -connect ${API_URL}:443 -servername ${API_URL} -showcerts < /dev/null
```

### 4. Storage Verification

```bash
# Create test PVC
cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

# Verify PVC is bound
oc get pvc test-pvc

# Clean up
oc delete pvc test-pvc
```

### 4. Application Deployment Test

```bash
# Deploy test application
oc new-app --name hello-world --image=quay.io/redhat-developer/hello-world-nginx

# Expose service
oc expose service hello-world

# Get route URL
oc get route hello-world

# Test application
curl $(oc get route hello-world -o jsonpath='{.spec.host}')

# Clean up
oc delete all -l app=hello-world
oc delete route hello-world
```

## 🚨 Troubleshooting

### Common Issues

#### 1. AWS Permission Errors
```bash
# Error: Access denied for EC2/IAM/Route53
# Solution 1: Use configure-aws-cli.sh to reconfigure
./configure-aws-cli.sh --delete  # Remove current installation
./configure-aws-cli.sh --install NEW_ACCESS_KEY NEW_SECRET_KEY REGION

# Solution 2: Check permissions manually
aws iam list-attached-user-policies --user-name $(aws sts get-caller-identity --query Arn --output text | cut -d'/' -f2)
```

#### 2. Missing yq YAML Processor
```bash
# Error: yq is not installed. Please install it first.
# Solution 1: Use configure-aws-cli.sh (installs yq automatically)
./configure-aws-cli.sh --install $AWS_KEY $AWS_SECRET $AWS_REGION

# Solution 2: Manual yq installation
mkdir -p ~/bin
curl -L "https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_amd64" -o ~/bin/yq
chmod +x ~/bin/yq
export PATH="$HOME/bin:$PATH"
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
```

#### 3. Pull Secret Issues
```bash
# Error: Invalid pull secret
# Solution: Re-download from Red Hat Console
rm ~/pull-secret.json
# Download fresh copy from https://console.redhat.com/openshift/install/pull-secret
```

#### 3. Service Quota Limits
```bash
# Error: Instance limit exceeded
# Solution: Request quota increase or use different region
aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A
```

#### 4. Install Config Validation Errors
```bash
# Error: compute[0].name: Unsupported value: "": supported values: "worker", "edge"
# Solution: This is fixed in the latest script version
# If using an older version, ensure install-config.yaml has proper compute section:

compute:
- name: worker
  replicas: 0
controlPlane:
  name: master
  replicas: 3
```

#### 5. Route53 Hosted Zone Missing
```bash
# Error: no public route53 zone found matching name "domain.com"
# Solution 1: Create a hosted zone for your domain
aws route53 create-hosted-zone --name your-domain.com --caller-reference $(date +%s)

# Solution 2: Use an existing domain
aws route53 list-hosted-zones --query 'HostedZones[*].[Name,Id]' --output table

# Solution 3: Use a subdomain of existing zone
# If you own example.com, use dev.example.com or lab.example.com

# Solution 4: For testing only - use public DNS services
# Use domains like cluster.1.2.3.4.nip.io (replace IP as needed)
```

#### 6. DNS Resolution Issues
```bash
# Error: Cannot resolve cluster domain
# Solution: Verify domain ownership and DNS configuration
dig +short $(echo $BASE_DOMAIN)
```

### Deployment Failures

#### 1. Cluster Creation Timeout
```bash
# Check installation logs
tail -f openshift-deployment-*.log

# Monitor AWS resources
aws ec2 describe-instances --filters "Name=tag:Name,Values=*$(echo $CLUSTER_NAME)*"
```

#### 2. Bootstrap Failures
```bash
# SSH to bootstrap node (if accessible)
ssh -i ~/.ssh/openshift-key core@<bootstrap-ip>

# Check bootstrap logs
journalctl -u bootkube.service
```

#### 3. Certificate Issues
```bash
# Check certificate status
oc get csr

# Approve pending certificates if needed
oc get csr -o name | xargs oc adm certificate approve
```

#### 4. HyperShift Hosted Cluster Console Issues
```bash
# Problem: Hosted cluster console operator degraded
# Symptom: Console routes not accessible, nested subdomain issues
# Error: "RouteHealthAvailable: failed to GET route"

# Solution: Configure ingress controller wildcard policy
oc patch ingresscontroller -n openshift-ingress-operator default --type=json \
  -p '[{ "op": "add", "path": "/spec/routeAdmission", "value": {"wildcardPolicy": "WildcardsAllowed"}}]'

# Verify the fix
oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.spec.routeAdmission.wildcardPolicy}'
# Expected output: WildcardsAllowed

# Check hosted cluster console status
KUBECONFIG=/path/to/hosted-cluster-kubeconfig oc get co console

# Reference: docs/hypershift-ingress-wildcard-policy-fix.md
```

### Recovery Procedures

#### 1. Partial Deployment Cleanup
```bash
# Destroy failed deployment
openshift-install destroy cluster --dir cluster --log-level debug

# Clean up AWS resources manually if needed
aws ec2 describe-instances --filters "Name=tag:Name,Values=*$(echo $CLUSTER_NAME)*"
```

#### 2. Complete Environment Reset
```bash
# Remove cluster directory
rm -rf cluster/

# Remove SSH keys (if needed)
rm ~/.ssh/openshift-key*

# Start fresh deployment
./openshift-3node-baremetal-cluster.sh
```

## 📞 Getting Help

### Log Files
- **Deployment Log**: `openshift-deployment-YYYYMMDD-HHMMSS.log`
- **OpenShift Install Log**: `cluster/.openshift_install.log`
- **Bootstrap Log**: Available via SSH to bootstrap node

### Useful Commands
```bash
# Check cluster events
oc get events --sort-by='.lastTimestamp'

# Check pod logs
oc logs -n openshift-kube-apiserver -l app=kube-apiserver

# Check node conditions
oc describe nodes | grep -A 5 Conditions
```

### Support Resources
- [OpenShift Documentation](https://docs.openshift.com/)
- [Red Hat Customer Portal](https://access.redhat.com/)
- [OpenShift Community](https://www.openshift.com/community/)

## 📚 Next Steps

- [Validation Guide](VALIDATION.md) - Understanding health checks and verification
- [Examples](EXAMPLES.md) - Common deployment scenarios and use cases
- [Configuration Guide](CONFIGURATION.md) - Detailed configuration options
