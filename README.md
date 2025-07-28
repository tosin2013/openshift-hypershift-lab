# OpenShift HyperShift Lab

A comprehensive GitOps-based framework for deploying OpenShift clusters with hosted control planes and OpenShift Virtualization. This project includes both traditional 3-node cluster deployment capabilities and a new **Modular Hosted Clusters Framework** for scalable multi-instance deployments.

## 🚀 **Getting Started (Choose Your Path)**

### 🆕 **First-Time Deployment** (Start Here if You Have No OpenShift Cluster)

Deploy your first OpenShift cluster using the primary deployment script:

- **🏗️ Foundation Cluster**: Create a 3-node OpenShift cluster as your foundation
- **🔧 Primary Script**: `openshift-3node-baremetal-cluster.sh` - THE deployment tool for new clusters
- **🔒 Secure by Default**: Automatic SSL/TLS certificate configuration post-deployment
- **☁️ AWS Integration**: Full AWS cloud integration with proper resource management
- **✅ Production Ready**: Comprehensive validation and health checks

**👉 [Jump to First-Time Deployment](#first-time-deployment)**

### 📈 **Expanding with Hosted Clusters** (After You Have a Management Cluster)

Transform your foundation cluster into a scalable, multi-tenant platform:

- **🏗️ Multiple Hosted Clusters**: Deploy unlimited hosted control plane clusters with different configurations
- **🚀 GitOps Automation**: Full ArgoCD ApplicationSet integration for automated deployment and management
- **📋 Template-Based Creation**: Standardized templates for consistent, repeatable deployments
- **🌐 Multi-Platform Support**: KubeVirt and AWS platforms with extensible architecture

**👉 [Get Started with Modular Hosted Clusters](docs/modular-hosted-clusters/README.md)**

## 🚀 Features

### Core Capabilities
- **3-Node Cluster Architecture**: Masters act as both control plane and workers (no dedicated worker nodes)
- **Bare Metal Support**: Optional deployment with metal instances for high-performance workloads
- **AWS Integration**: Full AWS cloud integration with proper resource management
- **Automated AWS Setup**: Includes `configure-aws-cli.sh` for streamlined AWS CLI installation and configuration
- **OpenShift Virtualization Ready**: Configured for virtualization workloads when bare metal is enabled

### Enhanced Functionality
- **🔧 Configurable Parameters**: All deployment settings can be customized via CLI or environment variables
- **🛡️ Comprehensive Validation**: Pre-flight checks for AWS permissions, quotas, and configuration
- **👥 Interactive Setup**: Guided pull secret setup with automatic browser integration
- **✅ Health Verification**: Post-deployment cluster health checks and validation
- **📊 Detailed Logging**: Comprehensive logging with timestamped entries and color-coded output
- **🔄 Error Recovery**: Graceful error handling with helpful guidance and recovery options

## 🏗️ Deployment Journey

This project follows a natural progression from foundation to advanced deployments:

### 1. **Foundation Cluster** (Start Here)
```
Primary Deployment: openshift-3node-baremetal-cluster.sh --bare-metal
├── 3 Master Nodes (schedulable, bare metal)
├── AWS Infrastructure (c5n.metal instances)
├── SSL/TLS Security (configure-keys-on-openshift.sh)
└── Production-Ready Foundation
```

**Key Capabilities:**
- **Complete OpenShift Cluster**: Fully functional 3-node bare metal cluster
- **High Performance**: c5n.metal instances with KVM virtualization support
- **Secure by Default**: SSL/TLS certificates via Let's Encrypt
- **AWS Optimized**: Proper resource management and networking
- **Virtualization Ready**: OpenShift Virtualization capabilities enabled

### 2. **Foundation Cluster Preparation** (Required for Hosted Clusters)
```
Foundation Cluster + Storage + GitOps + Applications + HCP Infrastructure
├── Node Labeling (cluster.ocs.openshift.io/openshift-storage)
├── OpenShift Data Foundation (ODF)
├── OpenShift GitOps (ArgoCD)
├── ArgoCD Applications (openshift-hypershift-lab)
├── Hosted Control Planes Setup (External DNS, S3 OIDC, HCP CLI)
└── Ready for Management Capabilities
```

### 3. **Management Cluster Evolution** (Optional Expansion)
```
Prepared Foundation + Management Components
├── HyperShift Operator
├── OpenShift Virtualization
├── ArgoCD GitOps (already installed)
└── Ready for Hosted Clusters
```

### 4. **Hosted Clusters Platform** (Advanced Multi-Tenancy)
```
Management Cluster + Hosted Clusters
├── dev-cluster-01 (KubeVirt)
├── staging-cluster-01 (KubeVirt)
├── prod-cluster-01 (AWS)
└── ... (unlimited instances)
```

**Benefits of Progression:**
- **Start Simple**: Begin with a single, solid foundation
- **Prepare Systematically**: Add storage and GitOps capabilities
- **Scale Gradually**: Add complexity only when needed
- **Cost-Effective**: Shared infrastructure for multiple workloads
- **GitOps-Native**: Full automation with ArgoCD

## 📋 Prerequisites

### System Requirements
- **Operating System**: Linux (tested on RHEL/CentOS/Amazon Linux)
- **Architecture**: x86_64
- **Memory**: Minimum 4GB RAM for script execution
- **Disk Space**: Minimum 10GB free space

### Required Tools
The script will automatically install missing tools, but you can pre-install:
- `aws` CLI (v2 recommended) - *Use `configure-aws-cli.sh` for automated installation*
- `jq` (JSON processor) - *Required, install manually if not available*
- `yq` (YAML processor) - *Auto-installed if missing*
- `ssh-keygen` - *Usually pre-installed on Linux systems*
- `curl` - *Usually pre-installed on Linux systems*

### AWS Requirements
- **AWS Account**: Active AWS account with appropriate permissions
- **AWS CLI**: Configured with credentials (`aws configure`)
- **Route53 Hosted Zone**: **REQUIRED** - Must have a hosted zone for your domain
- **IAM Permissions**: See [AWS Permissions](#aws-permissions) section
- **Service Quotas**: Sufficient quotas for EC2 instances, VPCs, and EIPs

### Domain Requirements
- **Route53 Hosted Zone**: You must own a domain with a Route53 hosted zone
- **Domain Examples**: `example.com`, `dev.example.com`, `lab.mydomain.org`
- **Testing Options**: For testing only, you can use services like `nip.io` or `xip.io`

### Security Requirements
- **SSL/TLS Certificates**: **REQUIRED** - All cluster endpoints must use secure SSL/TLS encryption
- **Post-Deployment Configuration**: SSL certificates configured using `configure-keys-on-openshift.sh` after cluster deployment
- **Let's Encrypt Integration**: Automatic certificate provisioning via Let's Encrypt with Route53 DNS validation
- **HTTPS Enforcement**: All web interfaces (console, API endpoints) enforce HTTPS-only access
- **Certificate Validation**: Valid, trusted certificates required for production deployments
- **Security Compliance**: Clusters meet enterprise security standards with encrypted communications

### Red Hat Requirements
- **Red Hat Account**: For downloading pull secret
- **Pull Secret**: Downloaded from [Red Hat Console](https://console.redhat.com/openshift/install/pull-secret)

## 🎯 Quick Start

### 🆕 **First-Time Deployment** (Primary Path)

Deploy your first OpenShift cluster using the primary deployment script:

```bash
# Configure AWS CLI automatically
chmod +x configure-aws-cli.sh
./configure-aws-cli.sh --install YOUR_ACCESS_KEY YOUR_SECRET_KEY YOUR_REGION

# Step 1: Make the primary deployment script executable
chmod +x openshift-3node-baremetal-cluster.sh

# Step 2: Deploy your foundation cluster (DOMAIN AND NAME ARE REQUIRED)
./openshift-3node-baremetal-cluster.sh --name YOUR_CLUSTER_NAME --domain YOUR_DOMAIN.com --bare-metal

# Step 3: Configure SSL certificates (after cluster deployment)
# Option A: With sudo privileges
chmod +x configure-keys-on-openshift.sh
sudo -E ./configure-keys-on-openshift.sh AWS_ACCESS_KEY AWS_SECRET_KEY podman YOUR_EMAIL

# Step 4: Verify secure access and get cluster information
oc get nodes

# Get your cluster and base domain for future reference
CLUSTER_DOMAIN=$(oc get route console -n openshift-console -o jsonpath='{.spec.host}' | sed 's/console-openshift-console.apps.//')
BASE_DOMAIN=$(echo $CLUSTER_DOMAIN | cut -d'.' -f2-)
echo "Your cluster domain: $CLUSTER_DOMAIN"
echo "Your base domain: $BASE_DOMAIN (use this for hosted clusters)"

# Access console
CONSOLE_URL=$(oc get route console -n openshift-console -o jsonpath='{.spec.host}')
echo "Console URL: https://$CONSOLE_URL"
```

**📚 [Complete Deployment Guide](docs/DEPLOYMENT.md)**

### 🔧 **Prepare Foundation for Hosted Clusters** (Required Before Expansion)

Before expanding to hosted clusters, configure your foundation cluster with storage and GitOps:

```bash
# Step 1: Label nodes for OpenShift Data Foundation
# Get node names first
oc get nodes --no-headers -o custom-columns=NAME:.metadata.name

# Label each node for storage (replace nodename with actual node names)
oc label node <nodename1> cluster.ocs.openshift.io/openshift-storage=""
oc label node <nodename2> cluster.ocs.openshift.io/openshift-storage=""
oc label node <nodename3> cluster.ocs.openshift.io/openshift-storage=""

# Step 2: Deploy OpenShift Data Foundation operator
kustomize build gitops/cluster-config/openshift-data-foundation-operator/operator/overlays/stable-4.18 | oc apply -f -

# Step 3: Deploy OpenShift Data Foundation instance
kustomize build gitops/cluster-config/openshift-data-foundation-operator/instance/overlays/aws | oc apply -f -

# Step 4: Deploy OpenShift GitOps (ArgoCD)
kustomize build gitops/cluster-config/openshift-gitops | oc apply -f -

# Step 5: Wait for operators to be ready
oc get csv -n openshift-storage
oc get pods -n openshift-gitops

# Step 6: Deploy ArgoCD applications for OpenShift HyperShift Lab
oc apply -f gitops/apps/openshift-hypershift-lab/cluster-config.yaml

# Step 7: Verify ArgoCD applications are synced
oc get applications -n openshift-gitops

# Step 8: Setup Hosted Control Planes Infrastructure
chmod +x setup-hosted-control-planes.sh
./setup-hosted-control-planes.sh

# Step 9: Verify hosted control planes setup
oc get secret hypershift-operator-external-dns-credentials -n local-cluster
oc get secret hypershift-operator-oidc-provider-s3-credentials -n local-cluster

# Note: The script includes critical fixes for hosted cluster support:
# - External DNS domain filter configuration with broader domain scope
# - Ingress controller wildcard policy configuration for nested subdomains
# - Certificate management guidance and node sizing requirements
# See script output for complete setup details and troubleshooting guidance
```



### 📈 **Expanding with Hosted Clusters** (After Foundation is Prepared)

Once you have a foundation cluster, you can expand it into a multi-tenant platform:

### 🔒 **Important: Certificate Management for Hosted Clusters**

**Certificate Limitation Notice**: Hosted clusters use nested subdomain patterns that exceed standard wildcard certificate coverage.

**Example Issue**:
- Standard wildcard certificate: `*.apps.metal-cluster.sandbox1271.opentlc.com`
- Hosted cluster console URL: `console-openshift-console.apps.dev-cluster-01.apps.metal-cluster.sandbox1271.opentlc.com`
- **Result**: Certificate mismatch causing SSL errors

**✅ Automated Solution (Applied by Setup Script)**:
The setup script automatically configures the ingress controller wildcard policy (`WildcardsAllowed`) which enables hosted cluster console routes to work properly with existing management cluster certificates.

**How It Works**:
- Hosted clusters inherit certificates from the management cluster
- Wildcard policy allows nested subdomain routes to be accepted
- No additional certificate management required
- Console access works immediately after deployment

**For Testing/Development**: All functionality works with standard cluster certificates

**⚠️ Certificate Management Notes**:
- The ingress wildcard policy fix resolves hosted cluster console access issues
- Hosted clusters use the management cluster's certificate infrastructure
- No additional certificate configuration needed
- All cluster functionality works properly with the automated configuration

**References**:
- [Certificate Management for Multi-Level Subdomains](https://www.ssldragon.com/blog/wildcard-certificate-multiple-level-subdomains/)
- [DNS Wildcard Certificate Limitations](https://serverfault.com/questions/104160/wildcard-ssl-certificate-for-second-level-subdomain)

```bash
# 1. Set up shared credentials once (reusable across all hosted clusters)
./scripts/setup-hosted-cluster-credentials.sh \
  --interactive \
  --create-ssh-key \
  --namespace clusters \
  test-hosted-cluster

# 2. Get the base domain from your existing cluster
BASE_DOMAIN=$(oc get route console -n openshift-console -o jsonpath='{.spec.host}' | sed 's/console-openshift-console.apps.//' | cut -d'.' -f2-)
echo "Using base domain: $BASE_DOMAIN"

# 3. Create hosted cluster instances (reuses shared credentials)
./scripts/create-hosted-cluster-instance.sh \
  --name dev-cluster-01 \
  --environment dev \
  --domain $BASE_DOMAIN \
  --replicas 2

# 4. Test the configuration locally before GitOps deployment
oc apply -k gitops/cluster-config/virt-lab-env/overlays/instances/dev-cluster-01

# 5. Verify the hosted cluster is deploying
oc get hostedcluster -n clusters
oc get nodepool -n clusters

# 6. Check ManagedCluster resources (compare with existing clusters)
oc get managedcluster
oc get managedcluster dev-cluster-01 -o yaml

# 7. If local test is successful, commit to Git for ArgoCD
git add gitops/cluster-config/virt-lab-env/overlays/instances/dev-cluster-01
git commit -m "Add dev-cluster-01 hosted cluster configuration"
git push origin main

# 7. Deploy additional clusters (optional)
./scripts/create-hosted-cluster-instance.sh \
  --name staging-cluster-01 \
  --environment staging \
  --domain $BASE_DOMAIN \
  --replicas 3

# 8. Deploy using GitOps (if not already deployed)
oc apply -f gitops/apps/openshift-hypershift-lab/cluster-config.yaml

# 5. Access your hosted clusters
oc get secret dev-cluster-01-admin-kubeconfig -n clusters \
  -o jsonpath='{.data.kubeconfig}' | base64 -d > dev-cluster-kubeconfig
export KUBECONFIG=dev-cluster-kubeconfig
oc get nodes
```

**📚 [Complete Hosted Clusters Tutorial](docs/modular-hosted-clusters/tutorials/getting-started.md)**

### Advanced Deployments

#### Bare Metal Deployment
```bash
# Deploy with bare metal capabilities
./openshift-3node-baremetal-cluster.sh --bare-metal
```

#### Custom Configuration
```bash
# Deploy with custom settings
./openshift-3node-baremetal-cluster.sh \
  --name my-cluster \
  --domain example.com \
  --region us-west-2 \
  --version 4.18.20
```

#### Automated CI/CD Setup
```bash
# Automated setup for CI/CD pipelines
./configure-aws-cli.sh --install $AWS_KEY $AWS_SECRET $AWS_REGION
./openshift-3node-baremetal-cluster.sh --name ci-cluster --domain ci.example.com
```

## ⚙️ Configuration Options

### Command Line Options
| Option | Description | Default |
|--------|-------------|---------|
| `-i, --instance-type` | AWS instance type | `m6i.4xlarge` |
| `-v, --version` | OpenShift version | `4.18.20` |
| `-d, --domain` | Base domain | `sandbox235.opentlc.com` |
| `-n, --name` | Cluster name | `baremetal-lab` |
| `-r, --region` | AWS region | `us-east-2` |
| `-p, --pull-secret` | Pull secret file path | `~/pull-secret.json` |
| `--bare-metal` | Enable bare metal mode | `false` |
| `-h, --help` | Show help message | - |

### Environment Variables
All options can be set via environment variables:
```bash
export OPENSHIFT_VERSION="4.18.20"
export BASE_DOMAIN="example.com"
export CLUSTER_NAME="my-cluster"
export AWS_REGION="us-west-2"
export PULL_SECRET_PATH="/path/to/pull-secret.json"
```

## 🏗️ Architecture

### Default Deployment (Bare Metal)
- **Instance Type**: c5n.metal (64 vCPU, 256GB RAM)
- **Node Count**: 3 master nodes (schedulable)
- **Storage**: 500GB GP3 with 8000 IOPS per node
- **Network**: OVN-Kubernetes CNI
- **Capabilities**: KVM virtualization, high-performance workloads
- **Security**: SSL/TLS encryption for all endpoints, automatic certificate management

### Alternative Standard Deployment
- **Instance Type**: m6i.xlarge (4 vCPU, 16GB RAM)
- **Node Count**: 3 master nodes (schedulable)
- **Storage**: 200GB GP3 per node
- **Network**: OVN-Kubernetes CNI
- **Use Case**: Development/testing environments
- **Security**: SSL/TLS encryption for all endpoints, automatic certificate management

## 🔍 Validation & Verification

### Pre-Deployment Checks
- ✅ Configuration parameter validation
- ✅ System prerequisites verification
- ✅ AWS credentials and permissions
- ✅ Service quotas and limits
- ✅ Pull secret validation
- ✅ SSL certificate requirements validation

### Post-Deployment Verification
- ✅ Cluster API accessibility
- ✅ Node status and readiness
- ✅ Cluster operator health
- ✅ Console accessibility
- ✅ Storage class availability
- ✅ SSL/TLS certificate configuration (via configure-keys-on-openshift.sh)
- ✅ HTTPS endpoint security verification
- ✅ Let's Encrypt certificate validation
- ✅ Bare metal capabilities (when enabled)

## 📚 Documentation Structure

- **[Configuration Guide](docs/CONFIGURATION.md)**: Detailed configuration options
- **[Deployment Guide](docs/DEPLOYMENT.md)**: Step-by-step deployment instructions
- **[Validation Guide](docs/VALIDATION.md)**: Validation and verification features
- **[Examples](docs/EXAMPLES.md)**: Common deployment scenarios and use cases
- **[HyperShift Troubleshooting](docs/HYPERSHIFT-TROUBLESHOOTING.md)**: Quick fixes for hosted cluster issues
- **[Ingress Wildcard Policy Fix](docs/hypershift-ingress-wildcard-policy-fix.md)**: Critical fix for hosted cluster consoles
- **[Troubleshooting](docs/TROUBLESHOOTING.md)**: Common issues and solutions

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in this repository
- Check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- Review OpenShift documentation

---

**Note**: This script is designed for development and testing environments. For production deployments, please review and adapt the configuration according to your organization's requirements and security policies.
