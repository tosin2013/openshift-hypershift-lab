# OpenShift HyperShift Lab

A comprehensive GitOps-based framework for deploying OpenShift clusters with hosted control planes and OpenShift Virtualization.

## 🚀 Quick Start

### 🆕 **New to OpenShift HyperShift Lab?**
**[📖 Get Started](docs/diataxis/tutorials/getting-started-cluster.md)** - Complete beginner's guide

### 🏗️ **Deploy Your First Cluster**
```bash
# Make the script executable
chmod +x openshift-3node-baremetal-cluster.sh

# Deploy with your domain (requires Route53 hosted zone)
./openshift-3node-baremetal-cluster.sh --domain YOUR-DOMAIN.com --name my-cluster
```

### 🔧 **Customize for Your Environment**
**[🍴 Fork and Customize](docs/diataxis/how-to-guides/fork-and-customize.md)** - Adapt the lab for your infrastructure

### 📈 **Scale with Hosted Clusters**
**[🏗️ Modular Framework](docs/modular-hosted-clusters/README.md)** - Deploy multiple hosted clusters

## ✨ Key Features

- **🏗️ Foundation + Hosted Clusters**: Deploy a management cluster, then unlimited hosted clusters
- **🚀 GitOps Automation**: Full ArgoCD integration for declarative cluster management
- **🌐 Multi-Platform**: KubeVirt VMs, AWS instances, and extensible to other platforms
- **� Secure by Default**: SSL/TLS certificates and security hardening included
- **� Highly Configurable**: Customize everything via CLI parameters or environment variables

## 📚 Documentation

**[📖 Complete Documentation](docs/README.md)** - Your main resource for everything

### Quick Links
- **[🚀 Getting Started](docs/diataxis/tutorials/getting-started-cluster.md)** - First steps tutorial
- **[🏗️ Create Hosted Clusters](docs/diataxis/how-to-guides/create-hosted-cluster.md)** - ArgoCD setup and hosted cluster deployment
- **[🔧 Deploy to Bare Metal](docs/diataxis/how-to-guides/deploy-to-bare-metal.md)** - Bare metal deployment via RHACM
- **[🍴 Fork & Customize](docs/diataxis/how-to-guides/fork-and-customize.md)** - Adapt for your environment
- **[📋 Configuration Reference](docs/diataxis/reference/hypershift-lab-configuration.md)** - All options and parameters

## 📋 Prerequisites

- **AWS Account** with Route53 hosted zone for your domain
- **Red Hat Account** for [pull secret](https://console.redhat.com/openshift/install/pull-secret)
- **Linux system** (RHEL/CentOS/Ubuntu/Amazon Linux)

*The deployment script auto-installs required tools (AWS CLI, jq, yq, oc).*

## 🎯 Quick Start

```bash
# 1. Configure AWS CLI
chmod +x configure-aws-cli.sh
./configure-aws-cli.sh --install YOUR_ACCESS_KEY YOUR_SECRET_KEY YOUR_REGION

# 2. Deploy foundation cluster
chmod +x openshift-3node-baremetal-cluster.sh
./openshift-3node-baremetal-cluster.sh --domain YOUR-DOMAIN.com --name my-cluster --bare-metal

# 3. Configure SSL certificates (after deployment)
chmod +x configure-keys-on-openshift.sh
sudo -E ./configure-keys-on-openshift.sh AWS_ACCESS_KEY AWS_SECRET_KEY podman YOUR_EMAIL

# 4. Set up credentials for hosted clusters (REQUIRED before hosted clusters)
oc create namespace virt-creds
oc create secret generic virt-creds \
  --from-file=pullSecret=~/pull-secret.json \
  --from-file=ssh-publickey=~/.ssh/id_rsa.pub \
  -n virt-creds
```

### 📈 **Next Steps After Foundation Cluster**

**To prepare for hosted clusters, run these commands:**
```bash
# 1. Label nodes for storage (replace with your node names)
oc get nodes --no-headers -o custom-columns=NAME:.metadata.name
oc label node <nodename1> cluster.ocs.openshift.io/openshift-storage=""
oc label node <nodename2> cluster.ocs.openshift.io/openshift-storage=""
oc label node <nodename3> cluster.ocs.openshift.io/openshift-storage=""

# 2. Deploy OpenShift Data Foundation
kustomize build gitops/cluster-config/openshift-data-foundation-operator/operator/overlays/stable-4.18 | oc apply -f -
kustomize build gitops/cluster-config/openshift-data-foundation-operator/instance/overlays/aws | oc apply -f -

# 3. Deploy ArgoCD
kustomize build gitops/cluster-config/openshift-gitops | oc apply -f -
oc apply -f gitops/apps/openshift-hypershift-lab/cluster-config.yaml

# 4. Setup hosted control planes
chmod +x setup-hosted-control-planes.sh
./setup-hosted-control-planes.sh
```

**Then you can:**
- **🏗️ [Create Hosted Clusters](docs/diataxis/how-to-guides/create-hosted-cluster.md)** - Deploy multiple hosted clusters via GitOps
- **🔧 [Deploy to Bare Metal](docs/diataxis/how-to-guides/deploy-to-bare-metal.md)** - Extend to bare metal infrastructure via RHACM

**📚 [Complete step-by-step guide](docs/diataxis/tutorials/getting-started-cluster.md)**

## 🤝 Contributing

- **🍴 [Fork and Customize](docs/diataxis/how-to-guides/fork-and-customize.md)** - Adapt for your environment
- **🏗️ [Bare Metal Extension](docs/diataxis/how-to-guides/deploy-to-bare-metal.md)** - Deploy to bare metal via RHACM
- **🔧 [Development Setup](docs/diataxis/how-to-guides/developer/development-setup.md)** - Contribute to the project

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **📖 [Complete Documentation](docs/README.md)** - All guides and references
- **🐛 Create an Issue** - Report bugs or request features
- **� [HyperShift Troubleshooting](docs/HYPERSHIFT-TROUBLESHOOTING.md)** - Quick fixes for common issues

---

**💡 Tip**: Start with the [Getting Started guide](docs/diataxis/tutorials/getting-started-cluster.md) for a complete walkthrough!
