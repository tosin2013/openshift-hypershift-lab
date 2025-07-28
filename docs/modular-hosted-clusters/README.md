# Modular Hosted Clusters Framework

A comprehensive GitOps-based framework for deploying and managing multiple OpenShift hosted control plane clusters with OpenShift Virtualization support.

## Overview

This framework transforms the existing `gitops/cluster-config/virt-lab-env` structure into a scalable, modular system that supports:

- **Multiple Hosted Cluster Instances**: Deploy unlimited hosted clusters with different configurations
- **GitOps Automation**: Full ArgoCD ApplicationSet integration for automated deployment
- **Platform Support**: KubeVirt and AWS platforms with extensible architecture
- **Template-Based Creation**: Easy instance creation using standardized templates
- **Centralized Configuration**: Unified configuration management and validation
- **Self-Service Deployment**: Users can create new clusters through simple configuration changes

## Architecture

```
gitops/cluster-config/virt-lab-env/
├── base/                          # Enhanced parameterized base configurations
│   ├── hosted-cluster.yaml        # Base HostedCluster template
│   ├── nodepool.yaml              # Base NodePool template
│   ├── kustomization.yaml         # Base Kustomize configuration
│   └── ...
├── overlays/
│   ├── template/                  # Instance template for new clusters
│   ├── aws-template/              # AWS-specific template
│   └── instances/                 # Multiple cluster instances
│       ├── dev-cluster-01/
│       ├── staging-cluster-01/
│       ├── prod-cluster-01/
│       └── ...
├── applicationsets/               # ArgoCD ApplicationSets for automation
│   └── hosted-clusters-appset.yaml
└── config/                       # Centralized configuration management
    └── cluster-registry.yaml
```

## Quick Start

### Prerequisites

- OpenShift cluster with GitOps operator installed
- HyperShift operator installed
- OpenShift Virtualization (for KubeVirt platform)
- `oc`, `yq`, and `jq` CLI tools

### 1. Create Your First Hosted Cluster

```bash
# Create a development cluster
./scripts/create-hosted-cluster-instance.sh \
  --name dev-cluster-01 \
  --environment dev \
  --domain dev.example.com \
  --replicas 3

# Create a production cluster with custom resources
./scripts/create-hosted-cluster-instance.sh \
  --name prod-cluster-01 \
  --environment prod \
  --domain prod.example.com \
  --replicas 5 \
  --memory 16Gi \
  --cores 8
```

### 2. Deploy the ApplicationSet

```bash
# Apply the ApplicationSet to manage all instances
oc apply -f gitops/cluster-config/apps/openshift-hypershift-lab/hosted-clusters-applicationset.yaml
```

### 3. Validate Deployment

```bash
# Validate cluster deployment
./scripts/validate-deployment.sh dev-cluster-01

# Check all clusters
./scripts/manage-cluster-config.sh list
```

## Documentation Structure

This documentation follows the [Diátaxis framework](https://diataxis.fr/) for comprehensive coverage:

### 📚 Learning-Oriented (Tutorials)
- [Getting Started Tutorial](tutorials/getting-started.md) - Your first hosted cluster
- [Multi-Environment Setup](tutorials/multi-environment.md) - Dev/Staging/Prod workflow
- [AWS Integration Tutorial](tutorials/aws-integration.md) - Using AWS platform

### 🛠️ Problem-Oriented (How-To Guides)
- [Create New Instances](how-to/create-instances.md) - Step-by-step instance creation
- [Configure AWS Clusters](how-to/configure-aws.md) - AWS-specific configuration
- [Troubleshoot Deployments](how-to/troubleshoot.md) - Common issues and solutions
- [Scale Clusters](how-to/scale-clusters.md) - Scaling node pools
- [Backup and Recovery](how-to/backup-recovery.md) - Backup strategies

### 📖 Information-Oriented (Reference)
- [Configuration Reference](reference/configuration.md) - All configuration options
- [API Reference](reference/api.md) - Resource specifications
- [CLI Reference](reference/cli.md) - Script usage and options
- [Template Reference](reference/templates.md) - Template structure and variables

### 🧠 Understanding-Oriented (Explanation)
- [Architecture Overview](explanation/architecture.md) - System design and decisions
- [GitOps Patterns](explanation/gitops-patterns.md) - GitOps implementation details
- [Security Model](explanation/security.md) - Security considerations
- [Platform Comparison](explanation/platforms.md) - KubeVirt vs AWS vs others

## Key Features

### 🚀 **Automated Multi-Instance Management**
- ArgoCD ApplicationSets automatically discover and deploy new instances
- Git-based configuration with automatic synchronization
- Proper dependency management and sync waves

### 🔧 **Template-Based Instance Creation**
- Standardized templates for consistent deployments
- Platform-specific overlays (KubeVirt, AWS)
- Parameterized configurations with validation

### 📊 **Centralized Configuration Management**
- Unified cluster registry with JSON schema validation
- Default configuration values and overrides
- Configuration management CLI tools

### 🛡️ **Production-Ready Features**
- Comprehensive validation and health checks
- Rollback and recovery procedures
- Monitoring and observability integration

### 🌐 **Multi-Platform Support**
- KubeVirt platform for virtualized workloads
- AWS platform for cloud deployments
- Extensible architecture for additional platforms

## Scripts and Tools

| Script | Purpose | Usage |
|--------|---------|-------|
| `create-hosted-cluster-instance.sh` | Create new cluster instances | `./scripts/create-hosted-cluster-instance.sh --help` |
| `manage-cluster-config.sh` | Manage cluster configurations | `./scripts/manage-cluster-config.sh --help` |
| `validate-deployment.sh` | Validate cluster deployments | `./scripts/validate-deployment.sh --help` |

## Contributing

1. **Follow GitOps Principles**: All changes through Git pull requests
2. **Use Templates**: Extend existing templates rather than creating from scratch
3. **Validate Changes**: Run validation scripts before committing
4. **Update Documentation**: Follow Diátaxis framework for documentation updates
5. **Test Thoroughly**: Use the testing framework for validation

## Support and Troubleshooting

- **Documentation**: Check the [troubleshooting guide](how-to/troubleshoot.md)
- **Validation**: Use `validate-deployment.sh` for health checks
- **Configuration**: Use `manage-cluster-config.sh` for configuration management
- **Logs**: Check ArgoCD application logs for deployment issues

## Migration from Existing Setup

The framework is designed to be backward compatible with the existing `example-instance` overlay. Your current setup will continue to work while you migrate to the new modular approach.

See the [migration guide](how-to/migrate-existing.md) for detailed steps.

## License

This project follows the same license as the parent OpenShift HyperShift Lab project.

---

**Next Steps**: Start with the [Getting Started Tutorial](tutorials/getting-started.md) to deploy your first modular hosted cluster.
