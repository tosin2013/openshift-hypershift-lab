# OpenShift HyperShift Lab Documentation

This documentation follows the [Diátaxis framework](https://diataxis.fr/) to provide clear, structured, and user-centric documentation specifically for the **OpenShift HyperShift Lab** project - a comprehensive GitOps-based framework for deploying and managing hosted OpenShift clusters.

## Documentation Structure

### 📚 Tutorials (Learning-Oriented)
**For users learning to work with the HyperShift Lab environment**

- [Getting Started with OpenShift HyperShift Lab](tutorials/getting-started-cluster.md) - First steps with the lab environment
- [Using the HyperShift Lab](tutorials/using-hypershift-lab.md) - Working with hosted clusters and GitOps
- [Enterprise Pipeline Workflow](tutorials/enterprise-pipeline-workflow.md) - Lab → Production pipeline (community implementation needed)
- [Accessing Cluster Consoles](tutorials/accessing-consoles.md) - Navigating management and hosted cluster consoles
- [Working with Hosted Clusters](tutorials/working-with-hosted-clusters.md) - Understanding the hosted cluster architecture
- [Managing Workloads](tutorials/managing-workloads.md) - Deploying and managing applications

### 🛠️ How-To Guides (Problem-Oriented)
**For users solving specific problems with the HyperShift Lab**

- [Fork and Customize the Repository](how-to-guides/fork-and-customize.md) - Adapt the lab for your own environment *(for community users)*
- [Create a New Hosted Cluster](how-to-guides/create-hosted-cluster.md) - Step-by-step hosted cluster creation
- [Deploy to Bare Metal Clusters](how-to-guides/deploy-to-bare-metal.md) - Extend to bare metal via RHACM Host Inventory
- [Access Cluster Resources](how-to-guides/access-cluster-resources.md) - Working with management and hosted cluster resources

### 🔧 Developer How-To Guides (Contribution-Oriented)
**For developers contributing to the OpenShift HyperShift Lab project**

- [Development Environment Setup](how-to-guides/developer/development-setup.md) - Setting up HyperShift Lab development environment
- [Testing Deployment Scripts](how-to-guides/developer/testing-deployment-scripts.md) - Testing the lab deployment automation
- [Modifying GitOps Configurations](how-to-guides/developer/modifying-gitops-configs.md) - Working with ArgoCD applications
- [Contributing Code](how-to-guides/developer/contributing-code.md) - Contribution guidelines and workflow
- [Debugging Hosted Clusters](how-to-guides/developer/debugging-hosted-clusters.md) - Troubleshooting cluster deployment issues
- [Extending Platform Support](how-to-guides/developer/extending-platform-support.md) - Adding new platform integrations

### 📖 Reference (Information-Oriented)
**Detailed factual information about HyperShift Lab components**

- [HyperShift Lab Configuration](reference/hypershift-lab-configuration.md) - Complete configuration reference
- [Script Reference](reference/script-reference.md) - All deployment and management scripts

### 🧠 Explanations (Understanding-Oriented)
**High-level concepts and design decisions specific to the HyperShift Lab**

- [HyperShift Lab Design](explanations/hypershift-lab-design.md) - Project philosophy and architectural decisions
- [Architecture Overview](explanations/architecture-overview.md) - System design and component relationships

## Audience Separation

### End-User Documentation
- **Tutorials**: Learning to use deployed clusters
- **How-To Guides**: Solving problems with running clusters
- **Reference**: Information about cluster features and APIs
- **Explanations**: Understanding cluster architecture and concepts

### Developer Documentation
- **Developer How-To Guides**: Contributing to the project
- All development setup, building, testing, and contribution information

## Navigation

- **New to the HyperShift Lab?** Start with [Getting Started](tutorials/getting-started-cluster.md)
- **Want to use the lab effectively?** Try [Using the HyperShift Lab](tutorials/using-hypershift-lab.md)
- **Need to solve a specific problem?** Check the [How-To Guides](how-to-guides/)
- **Want to customize for your environment?** See [Fork and Customize](how-to-guides/fork-and-customize.md)
- **Want to contribute to the project?** See [Developer Setup](how-to-guides/developer/development-setup.md)
- **Looking for specific information?** Browse the [Reference](reference/) section
- **Want to understand the system better?** Read the [Explanations](explanations/)

## Contributing to Documentation

This documentation follows the Diátaxis framework principles:

1. **Strict Audience Separation**: End-user docs never contain development instructions
2. **Purpose-Driven Content**: Each section serves a specific user need
3. **Factual Accuracy**: Reference documentation is directly verifiable from code
4. **Clear Uncertainty**: When making inferences, we state them clearly

For documentation contributions, see [Development Setup](how-to-guides/developer/development-setup.md).

## Related Documentation

- **[Modular Hosted Clusters Framework](../modular-hosted-clusters/README.md)**: Advanced multi-instance deployment patterns
- **[Main Project README](../../README.md)**: Project overview and quick start guide
- **[Technical Documentation](../HYPERSHIFT-TROUBLESHOOTING.md)**: HyperShift-specific troubleshooting and fixes
