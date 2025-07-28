# How to Deploy to Bare Metal Clusters via RHACM ZTP

This guide explains how to implement an enterprise-grade pipeline using the OpenShift HyperShift Lab for development and testing, then deploying to physical bare metal clusters using Red Hat Advanced Cluster Management (RHACM) Zero Touch Provisioning (ZTP).

> **⚠️ Community Implementation Needed**: This enterprise pipeline workflow is not yet fully implemented in the current HyperShift Lab environment. The architecture and workflow patterns described here represent the target state that we welcome community contributions to achieve. Please share your implementations, SiteConfig templates, and PolicyGenTemplate configurations via pull requests.

## 🏗️ Architecture Overview

This workflow implements the enterprise pattern shown in the [Architecture Overview](../../README.md#architecture-overview):

```
Lab Clusters (Hosted) → GitOps Repository → RHACM ZTP → Physical Production
     ↓                        ↓                ↓              ↓
  Development            SiteConfig +      Automated      Dell/Cisco/HPE
   & Testing           PolicyGenTemplate   Deployment     Infrastructure
```

## Prerequisites

### Current Implementation
- OpenShift HyperShift Lab environment with hosted clusters deployed
- RHACM (Advanced Cluster Management) installed and configured
- Familiarity with the HyperShift Lab GitOps workflow

### Additional Requirements for Full Enterprise Pipeline
- **Physical Infrastructure**: Dell PowerEdge, Cisco UCS, or HPE ProLiant servers
- **RHACM ZTP Components**: Zero Touch Provisioning pipeline configured
- **GitOps Repository**: SiteConfig and PolicyGenTemplate resources
- **Network Infrastructure**: Enterprise networking (switches, load balancers, firewalls)
- **Storage Infrastructure**: SAN storage (NetApp, Pure Storage, Dell EMC)
- **Identity Integration**: LDAP/Active Directory integration

## Enterprise Pipeline Workflow

### The Complete Lab-to-Production Pipeline

```
1. Lab Environment (Hosted Clusters)
   ├── lab-cluster: Development and experimentation
   ├── dev-cluster: Application development
   ├── test-cluster: Integration testing
   └── Validate all configurations in lightweight hosted clusters

2. GitOps Repository (Infrastructure as Code)
   ├── SiteConfig: Define physical cluster specifications
   ├── PolicyGenTemplate: Define cluster policies and configurations
   ├── Application Manifests: Tested application deployments
   └── RHACM Policies: Governance and compliance rules

3. RHACM ZTP Pipeline (Zero Touch Provisioning)
   ├── Automated bare metal discovery
   ├── Cluster provisioning via SiteConfig
   ├── Policy application via PolicyGenTemplate
   └── Application deployment via GitOps

4. Physical Production Sites
   ├── QA Environment: Physical clusters for quality assurance
   ├── Production Environment: Full production clusters
   ├── Edge Sites: Single-node OpenShift for edge computing
   └── Enterprise integration (DNS, LDAP, SAN storage)
```

### Why This Enterprise Approach?

- **🧪 Rapid Development**: Lightweight hosted clusters for fast iteration
- **💰 Cost Efficiency**: Reserve expensive physical hardware for production
- **🏭 Zero Touch Production**: Automated deployment eliminates manual errors
- **📊 Centralized Management**: Single hub cluster manages all environments
- **🔒 Consistent Governance**: Same policies from lab to production
- **📈 Enterprise Scale**: Manage hundreds of edge and production sites

## 🚧 Implementation Status & Community Contributions Needed

### What's Currently Implemented ✅
- **Hub Cluster**: OpenShift cluster with RHACM and HyperShift
- **Hosted Lab Clusters**: Lightweight clusters for development and testing
- **GitOps Foundation**: ArgoCD and basic GitOps workflows
- **Basic RHACM**: Cluster management capabilities

### What Needs Community Implementation 🔨

#### 1. RHACM ZTP Pipeline Components
```yaml
# Example SiteConfig template needed
apiVersion: ran.openshift.io/v1
kind: SiteConfig
metadata:
  name: production-site-01
spec:
  baseDomain: "production.company.com"
  clusters:
  - clusterName: "prod-cluster-01"
    networkType: "OVNKubernetes"
    nodes:
    - hostName: "dell-server-01.company.com"
      role: "master"
      bmcAddress: "idrac-ip://192.168.1.10/system/1"
      # Additional bare metal configuration
```

#### 2. PolicyGenTemplate Resources
```yaml
# Example PolicyGenTemplate needed
apiVersion: ran.openshift.io/v1
kind: PolicyGenTemplate
metadata:
  name: "production-policies"
spec:
  bindingRules:
    sites: "production"
  mcp: "master"
  sourceFiles:
    - fileName: "ClusterLogForwarder.yaml"
      policyName: "logging-policy"
    # Additional policy configurations
```

#### 3. Integration Scripts and Automation
- **Bare metal discovery automation**
- **SiteConfig generation from infrastructure inventory**
- **PolicyGenTemplate creation from lab cluster configurations**
- **Application migration scripts from hosted to physical clusters**

#### 4. Enterprise Infrastructure Integration
- **DNS integration** (Bind, Windows DNS)
- **LDAP/Active Directory** authentication
- **SAN storage** configuration (NetApp, Pure, Dell EMC)
- **Network automation** (Cisco, Juniper switch configuration)

### How to Contribute 🤝

1. **Fork the Repository**: Start with the [Fork and Customize guide](fork-and-customize.md)
2. **Implement Components**: Choose one of the needed components above
3. **Test in Your Environment**: Validate with real bare metal infrastructure
4. **Document Your Implementation**: Include configuration examples and troubleshooting
5. **Submit Pull Request**: Share your implementation with the community

### Community Implementation Examples Needed

- **Dell PowerEdge** SiteConfig templates
- **Cisco UCS** integration examples
- **HPE ProLiant** configuration patterns
- **Edge computing** Single Node OpenShift deployments
- **Network automation** scripts for enterprise switches
- **Storage integration** with enterprise SAN systems

## Step 1: Current Implementation - Test and Validate in Hosted Clusters

### Develop in Hosted Clusters

First, use the existing HyperShift Lab workflow to develop and test:

```bash
# Create a development hosted cluster
./scripts/create-hosted-cluster-instance.sh \
  --name dev-app-testing \
  --environment dev \
  --replicas 2

# Deploy and test your applications
oc apply -f your-application-manifests/ --context dev-app-testing
```

### Validate GitOps Configurations

Ensure your GitOps configurations work correctly:

1. **Test ArgoCD Applications** in hosted clusters
2. **Validate Kustomize overlays** for different environments
3. **Verify External Secrets** integration
4. **Test scaling and resource requirements**

### Document Requirements

Based on hosted cluster testing, document:
- **Resource requirements** (CPU, memory, storage)
- **Network requirements** (ingress, egress, DNS)
- **Storage requirements** (persistent volumes, storage classes)
- **Security requirements** (RBAC, network policies)

## Step 2: Prepare RHACM Host Inventory

### Install and Configure RHACM

> **📚 Reference**: [RHACM Installation Guide](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.13/html/install/installing)

The HyperShift Lab already includes RHACM components:

```bash
# Verify RHACM installation
oc get pods -n open-cluster-management

# Access RHACM console
oc get route multicloud-console -n open-cluster-management
```

### Discover Bare Metal Hosts

> **📚 Reference**: [Host Inventory Documentation](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.13/html/clusters/cluster_mce_overview#host-inventory-intro)

#### Option 1: Manual Host Discovery

```yaml
# Example: bare-metal-host.yaml
apiVersion: agent-install.openshift.io/v1beta1
kind: InfraEnv
metadata:
  name: bare-metal-infra
  namespace: bare-metal-clusters
spec:
  clusterRef:
    name: bare-metal-production
    namespace: bare-metal-clusters
  sshAuthorizedKey: |
    ssh-rsa AAAAB3NzaC1yc2EAAAA... # Your SSH public key
  pullSecretRef:
    name: pull-secret
```

#### Option 2: Automated Discovery

```bash
# Create discovery ISO for bare metal hosts
# This would be done through RHACM console or CLI
# Hosts boot from ISO and auto-register with RHACM
```

### Create Host Inventory

> **📚 Reference**: [Creating Host Inventory](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.13/html/clusters/cluster_mce_overview#creating-host-inventory)

```yaml
# Example: host-inventory.yaml
apiVersion: extensions.hive.openshift.io/v1beta1
kind: AgentClusterInstall
metadata:
  name: bare-metal-production
  namespace: bare-metal-clusters
spec:
  clusterDeploymentRef:
    name: bare-metal-production
  imageSetRef:
    name: openshift-v4.18.20
  networking:
    clusterNetwork:
    - cidr: 10.128.0.0/14
      hostPrefix: 23
    serviceNetwork:
    - 172.30.0.0/16
  provisionRequirements:
    controlPlaneAgents: 3
    workerAgents: 3
```

## Step 3: Deploy OpenShift to Bare Metal

### Create Cluster Deployment

> **📚 Reference**: [Deploying Clusters with RHACM](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.13/html/clusters/cluster_mce_overview#creating-a-cluster-on-bare-metal)

```yaml
# Example: bare-metal-cluster-deployment.yaml
apiVersion: hive.openshift.io/v1
kind: ClusterDeployment
metadata:
  name: bare-metal-production
  namespace: bare-metal-clusters
spec:
  baseDomain: production.example.com
  clusterName: bare-metal-production
  platform:
    agentBareMetal:
      agentSelector:
        matchLabels:
          cluster-name: bare-metal-production
  provisioning:
    installConfigSecretRef:
      name: bare-metal-install-config
    sshPrivateKeySecretRef:
      name: bare-metal-ssh-key
    imageSetRef:
      name: openshift-v4.18.20
```

### Monitor Deployment Progress

```bash
# Monitor cluster deployment
oc get clusterdeployment -n bare-metal-clusters

# Check agent status
oc get agents -n bare-metal-clusters

# Monitor installation progress
oc get agentclusterinstall bare-metal-production -n bare-metal-clusters -o yaml
```

## Step 4: Apply Tested Configurations

### Prepare GitOps for Bare Metal

Create bare metal overlays based on hosted cluster testing:

```bash
# Create bare metal overlay directory
mkdir -p gitops/cluster-config/bare-metal-production/overlays/production

# Copy and adapt configurations from hosted cluster testing
cp -r gitops/cluster-config/virt-lab-env/overlays/instances/dev-app-testing/* \
      gitops/cluster-config/bare-metal-production/overlays/production/

# Modify for bare metal specifications
# - Update resource limits based on bare metal capacity
# - Adjust storage classes for bare metal storage
# - Configure networking for bare metal environment
```

### Create ArgoCD Application for Bare Metal

```yaml
# bare-metal-production-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bare-metal-production
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: https://github.com/tosin2013/openshift-hypershift-lab.git
    targetRevision: main
    path: gitops/cluster-config/bare-metal-production/overlays/production
  destination:
    server: https://api.bare-metal-production.production.example.com:6443
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Deploy Applications

```bash
# Apply the ArgoCD application
oc apply -f bare-metal-production-app.yaml

# Monitor deployment
argocd app get bare-metal-production
argocd app sync bare-metal-production
```

## Step 5: Validate Production Deployment

### Health Checks

```bash
# Check cluster health
oc get nodes --context bare-metal-production

# Verify applications
oc get applications -n openshift-gitops

# Check resource utilization
oc top nodes --context bare-metal-production
oc top pods --all-namespaces --context bare-metal-production
```

### Performance Validation

Compare performance between hosted clusters and bare metal:

1. **Application Response Times**
2. **Resource Utilization**
3. **Storage Performance**
4. **Network Throughput**

## Implementation Examples

### Example 1: Web Application Pipeline

```bash
# 1. Test in hosted cluster
./scripts/create-hosted-cluster-instance.sh --name web-app-dev --environment dev
oc apply -f web-app-manifests/ --context web-app-dev

# 2. Validate and tune
# - Test load balancing
# - Validate persistent storage
# - Check resource requirements

# 3. Deploy to bare metal
# - Create bare metal cluster via RHACM
# - Apply tuned configurations
# - Monitor production metrics
```

### Example 2: Database Workload

```bash
# 1. Test database in hosted cluster with limited resources
# 2. Document storage and performance requirements
# 3. Deploy to bare metal with high-performance storage
# 4. Migrate data from hosted cluster to bare metal
```

## Troubleshooting

### Common Issues

**Host Discovery Problems**:
- Verify network connectivity between RHACM and bare metal hosts
- Check DHCP/PXE boot configuration
- Validate SSH key access

**Cluster Deployment Failures**:
- Review agent logs: `oc logs -n bare-metal-clusters agent-xxx`
- Check hardware compatibility
- Verify network configuration

**Application Deployment Issues**:
- Compare resource requests between hosted and bare metal
- Validate storage class availability
- Check network policies and ingress configuration

## Contributing Your Implementation

### What We Need

If you implement this workflow, please contribute:

1. **Working Configuration Examples**:
   - RHACM Host Inventory configurations
   - Cluster deployment manifests
   - GitOps overlay examples

2. **Documentation Updates**:
   - Step-by-step implementation details
   - Troubleshooting scenarios you encountered
   - Performance comparisons and optimizations

3. **Automation Scripts**:
   - Scripts to automate host discovery
   - Cluster deployment automation
   - Configuration migration tools

### How to Fork and Customize for Your Environment

> **📝 Note**: These instructions are for **community users** who want to implement bare metal deployment in their own environments. For direct contributions to the main repository, work with feature branches instead of forks.

#### Step 1: Fork the Repository

```bash
# 1. Fork the repository on GitHub
# Go to: https://github.com/tosin2013/openshift-hypershift-lab
# Click "Fork" button to create your own copy

# 2. Clone your fork
git clone https://github.com/YOUR-USERNAME/openshift-hypershift-lab.git
cd openshift-hypershift-lab

# 3. Add upstream remote for updates
git remote add upstream https://github.com/tosin2013/openshift-hypershift-lab.git
```

#### Step 2: Customize for Your Environment

```bash
# Create your environment-specific branch
git checkout -b my-environment-setup

# Update configuration files for your environment
# 1. Modify domain settings
find . -name "*.yaml" -o -name "*.sh" | xargs sed -i 's/sandbox1271.opentlc.com/YOUR-DOMAIN.com/g'

# 2. Update cluster names
find . -name "*.yaml" -o -name "*.sh" | xargs sed -i 's/tosins-dev-cluster/YOUR-CLUSTER-NAME/g'

# 3. Customize AWS region (if different)
find . -name "*.sh" | xargs sed -i 's/us-east-2/YOUR-AWS-REGION/g'

# 4. Update Git repository URLs in ArgoCD applications
find gitops/ -name "*.yaml" | xargs sed -i 's|tosin2013/openshift-hypershift-lab|YOUR-USERNAME/openshift-hypershift-lab|g'
```

#### Step 3: Environment-Specific Configuration

Create your own configuration overlay:

```bash
# Create your environment directory
mkdir -p gitops/cluster-config/my-environment/

# Copy and customize base configurations
cp -r gitops/cluster-config/virt-lab-env/base/ gitops/cluster-config/my-environment/base/
cp -r gitops/cluster-config/virt-lab-env/overlays/ gitops/cluster-config/my-environment/overlays/

# Update kustomization files to point to your configurations
# Edit gitops/cluster-config/my-environment/overlays/*/kustomization.yaml
```

#### Step 4: Bare Metal Implementation

```bash
# Create bare metal configuration directory
mkdir -p gitops/cluster-config/bare-metal-production/
mkdir -p scripts/bare-metal/

# Add your bare metal host inventory
cat > gitops/cluster-config/bare-metal-production/host-inventory.yaml << 'EOF'
# Your RHACM 2.13 host inventory configuration
apiVersion: agent-install.openshift.io/v1beta1
kind: InfraEnv
metadata:
  name: my-bare-metal-infra
  namespace: my-bare-metal-clusters
spec:
  clusterRef:
    name: my-production-cluster
    namespace: my-bare-metal-clusters
  sshAuthorizedKey: |
    # Your SSH public key
  pullSecretRef:
    name: pull-secret
EOF

# Add your cluster deployment configuration
cat > gitops/cluster-config/bare-metal-production/cluster-deployment.yaml << 'EOF'
# Your RHACM 2.13 cluster deployment configuration
apiVersion: hive.openshift.io/v1
kind: ClusterDeployment
metadata:
  name: my-production-cluster
  namespace: my-bare-metal-clusters
spec:
  baseDomain: production.YOUR-DOMAIN.com
  clusterName: my-production-cluster
  # Add your specific configuration
EOF
```

#### Step 5: Test Your Configuration

```bash
# Test the foundation cluster deployment with your settings
./openshift-3node-baremetal-cluster.sh \
  --name YOUR-CLUSTER-NAME \
  --domain YOUR-DOMAIN.com \
  --region YOUR-AWS-REGION \
  --bare-metal

# Test hosted cluster creation
./scripts/create-hosted-cluster-instance.sh \
  --name test-cluster \
  --environment dev \
  --domain apps.YOUR-CLUSTER-NAME.YOUR-DOMAIN.com
```

#### Step 6: Document Your Implementation

```bash
# Create your implementation documentation
cat > docs/my-implementation.md << 'EOF'
# My Bare Metal Implementation

## Environment Details
- **Infrastructure**: [Describe your bare metal setup]
- **RHACM Version**: 2.13
- **OpenShift Version**: 4.18.20
- **Domain**: YOUR-DOMAIN.com
- **AWS Region**: YOUR-AWS-REGION

## Implementation Steps
[Document your specific implementation steps]

## Challenges and Solutions
[Document issues you encountered and how you solved them]

## Performance Results
[Include performance comparisons between hosted and bare metal]

## Configuration Files
[Reference your working configuration files]
EOF
```

### How to Contribute Back to the Community

```bash
# After successful implementation in your fork, contribute back:

# 1. Create a feature branch for your contribution
git checkout -b feature/bare-metal-implementation

# 2. Add your working examples (without sensitive data)
mkdir -p gitops/cluster-config/bare-metal-examples/
cp your-working-configs/* gitops/cluster-config/bare-metal-examples/

# 3. Update the main documentation with your findings
# Edit docs/diataxis/how-to-guides/deploy-to-bare-metal.md
# Add your troubleshooting scenarios and solutions

# 4. Create automation scripts based on your experience
cp your-automation-scripts/* scripts/bare-metal/

# 5. Submit a pull request to the upstream repository
git add .
git commit -m "Add bare metal deployment implementation

- Working RHACM 2.13 configurations
- Automation scripts for host discovery
- Performance benchmarks and optimizations
- Troubleshooting guide based on real implementation"

git push origin feature/bare-metal-implementation

# 6. Create pull request on GitHub
# Go to your fork on GitHub and click "New Pull Request"
# Target: tosin2013/openshift-hypershift-lab (main branch)
```

### Keeping Your Fork Updated

```bash
# Regularly sync with upstream changes
git checkout main
git fetch upstream
git merge upstream/main
git push origin main

# Rebase your feature branches on latest main
git checkout feature/bare-metal-implementation
git rebase main
```

### Documentation Template

When contributing, please include:

```markdown
## Implementation Details
- **Environment**: Describe your bare metal setup
- **RHACM Version**: 2.13 (or specify version used)
- **Challenges**: Issues encountered and solutions
- **Performance**: Comparison data between hosted and bare metal
- **Configurations**: Working configuration files
```

## External Resources

### Red Hat Documentation
- [RHACM Host Inventory](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.13/html/clusters/cluster_mce_overview#host-inventory-intro)
- [Bare Metal Cluster Deployment](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.13/html/clusters/cluster_mce_overview#creating-a-cluster-on-bare-metal)
- [Agent-Based Installation](https://docs.openshift.com/container-platform/4.18/installing/installing_bare_metal_ipi/ipi-install-overview.html)

### Community Resources
- [OpenShift Bare Metal Documentation](https://docs.openshift.com/container-platform/4.18/installing/installing_bare_metal/installing-bare-metal.html)
- [RHACM Community Examples](https://github.com/stolostron/rhacm-docs)

## Next Steps

1. **Implement in Your Environment**: Follow this guide to implement bare metal deployment
2. **Test and Validate**: Thoroughly test the workflow in your environment
3. **Document Your Experience**: Record challenges, solutions, and optimizations
4. **Contribute Back**: Share your implementation with the community
5. **Iterate and Improve**: Help refine this documentation based on real-world usage

## Summary

This guide provides a framework for extending the OpenShift HyperShift Lab to include bare metal deployment via RHACM Host Inventory. The workflow enables:

- ✅ **Cost-effective testing** in hosted clusters
- ✅ **Risk reduction** through validation before bare metal deployment
- ✅ **Consistent GitOps patterns** from development to production
- ✅ **Community collaboration** for implementation and improvement

**We welcome your contributions** to make this workflow a reality in the OpenShift HyperShift Lab environment!
