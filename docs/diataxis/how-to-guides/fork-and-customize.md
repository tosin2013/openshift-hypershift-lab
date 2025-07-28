# How to Fork and Customize the OpenShift HyperShift Lab

This guide shows you how to fork the OpenShift HyperShift Lab repository and customize it for your own environment, infrastructure, and requirements.

> **📝 Note**: This guide is for **community users** who want to adapt the HyperShift Lab for their own environments. If you're contributing directly to the main repository, you can work with branches on the original repository instead of forking.

## Why Fork the Repository?

Forking allows you to:
- **Customize configurations** for your specific domain, AWS region, and infrastructure
- **Add your own implementations** like bare metal deployment or additional platforms
- **Maintain your own version** while staying synchronized with upstream updates
- **Contribute back** improvements and new features to the community
- **Experiment safely** without affecting the original repository

## Prerequisites

- GitHub account
- Git installed and configured
- Basic understanding of the HyperShift Lab architecture
- Access to your target infrastructure (AWS, bare metal, etc.)

## Step 1: Fork the Repository

### Create Your Fork

1. **Go to the original repository**: https://github.com/tosin2013/openshift-hypershift-lab
2. **Click the "Fork" button** in the top-right corner
3. **Choose your account** as the destination for the fork
4. **Wait for the fork to complete**

### Clone Your Fork

```bash
# Clone your forked repository
git clone https://github.com/YOUR-USERNAME/openshift-hypershift-lab.git
cd openshift-hypershift-lab

# Add the original repository as upstream remote
git remote add upstream https://github.com/tosin2013/openshift-hypershift-lab.git

# Verify remotes
git remote -v
# Should show:
# origin    https://github.com/YOUR-USERNAME/openshift-hypershift-lab.git (fetch)
# origin    https://github.com/YOUR-USERNAME/openshift-hypershift-lab.git (push)
# upstream  https://github.com/tosin2013/openshift-hypershift-lab.git (fetch)
# upstream  https://github.com/tosin2013/openshift-hypershift-lab.git (push)
```

## Step 2: Customize for Your Environment

### Create Your Environment Branch

```bash
# Create and switch to your customization branch
git checkout -b my-environment-setup

# Or use a more specific name
git checkout -b production-environment-2024
```

### Update Domain and Cluster Names

```bash
# Replace the example domain with your domain
find . -name "*.yaml" -o -name "*.sh" -o -name "*.md" | \
  xargs sed -i 's/sandbox1271\.opentlc\.com/YOUR-DOMAIN.com/g'

# Replace the example cluster name
find . -name "*.yaml" -o -name "*.sh" -o -name "*.md" | \
  xargs sed -i 's/tosins-dev-cluster/YOUR-CLUSTER-NAME/g'

# Update AWS region if different
find . -name "*.sh" | \
  xargs sed -i 's/us-east-2/YOUR-AWS-REGION/g'
```

### Update Git Repository References

```bash
# Update ArgoCD applications to point to your fork
find gitops/ -name "*.yaml" | \
  xargs sed -i 's|tosin2013/openshift-hypershift-lab|YOUR-USERNAME/openshift-hypershift-lab|g'

# Update any documentation references
find docs/ -name "*.md" | \
  xargs sed -i 's|tosin2013/openshift-hypershift-lab|YOUR-USERNAME/openshift-hypershift-lab|g'
```

## Step 3: Create Environment-Specific Configurations

### Create Your Environment Directory

```bash
# Create your environment-specific configuration
mkdir -p gitops/cluster-config/my-production-env/
mkdir -p gitops/cluster-config/my-production-env/base/
mkdir -p gitops/cluster-config/my-production-env/overlays/

# Copy base configurations as starting point
cp -r gitops/cluster-config/virt-lab-env/base/* \
      gitops/cluster-config/my-production-env/base/

# Create your production overlay
mkdir -p gitops/cluster-config/my-production-env/overlays/production/
```

### Customize Base Configurations

```bash
# Edit the base hosted cluster template for your environment
cat > gitops/cluster-config/my-production-env/base/hosted-cluster.yaml << 'EOF'
apiVersion: hypershift.openshift.io/v1beta1
kind: HostedCluster
metadata:
  name: CLUSTER_NAME
  namespace: clusters
spec:
  release:
    image: RELEASE_IMAGE
  dns:
    baseDomain: BASE_DOMAIN
  platform:
    type: KubeVirt
    kubevirt:
      baseDomainPassthrough: true
  # Add your specific requirements
  networking:
    clusterNetwork:
    - cidr: 10.132.0.0/14
      hostPrefix: 23
    serviceNetwork:
    - 172.31.0.0/16
  # Customize for your environment
EOF
```

### Create Production Overlay

```bash
# Create production-specific configurations
cat > gitops/cluster-config/my-production-env/overlays/production/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

configMapGenerator:
- name: cluster-config
  literals:
  - CLUSTER_NAME=my-production-cluster
  - BASE_DOMAIN=apps.my-cluster.YOUR-DOMAIN.com
  - REPLICAS=5
  - MEMORY=32Gi
  - CORES=16
  - STORAGE_SIZE=200Gi
  - ENVIRONMENT=production

replacements:
- source:
    kind: ConfigMap
    name: cluster-config
    fieldPath: data.CLUSTER_NAME
  targets:
  - select:
      kind: HostedCluster
    fieldPaths:
    - metadata.name
# Add more replacements as needed
EOF
```

## Step 4: Add Your Custom Features

### Add Bare Metal Support

```bash
# Create bare metal configuration directory
mkdir -p gitops/cluster-config/bare-metal-production/
mkdir -p scripts/bare-metal/

# Create your bare metal host inventory
cat > gitops/cluster-config/bare-metal-production/host-inventory.yaml << 'EOF'
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
    ssh-rsa AAAAB3NzaC1yc2EAAAA... # Your SSH public key
  pullSecretRef:
    name: pull-secret
  # Add your bare metal specific configuration
EOF
```

### Create Custom Scripts

```bash
# Create environment-specific deployment script
cat > deploy-my-environment.sh << 'EOF'
#!/bin/bash

# Custom deployment script for my environment
set -euo pipefail

# Source common functions
source ./openshift-3node-baremetal-cluster.sh --help > /dev/null 2>&1 || true

# Set environment-specific defaults
export CLUSTER_NAME="${CLUSTER_NAME:-my-production-cluster}"
export BASE_DOMAIN="${BASE_DOMAIN:-YOUR-DOMAIN.com}"
export AWS_REGION="${AWS_REGION:-YOUR-AWS-REGION}"

echo "Deploying HyperShift Lab for my environment..."
echo "Cluster: $CLUSTER_NAME"
echo "Domain: $BASE_DOMAIN"
echo "Region: $AWS_REGION"

# Deploy foundation cluster
./openshift-3node-baremetal-cluster.sh \
  --name "$CLUSTER_NAME" \
  --domain "$BASE_DOMAIN" \
  --region "$AWS_REGION" \
  --bare-metal

# Setup hosted control planes
./setup-hosted-control-planes.sh

# Deploy custom applications
echo "Deploying custom applications..."
oc apply -f gitops/cluster-config/my-production-env/

echo "Deployment completed successfully!"
EOF

chmod +x deploy-my-environment.sh
```

## Step 5: Test Your Customizations

### Validate Configurations

```bash
# Test YAML syntax
find gitops/ -name "*.yaml" | xargs -I {} sh -c 'echo "Checking {}" && yq eval . {} > /dev/null'

# Test Kustomize builds
kustomize build gitops/cluster-config/my-production-env/overlays/production/

# Validate scripts
bash -n deploy-my-environment.sh
bash -n scripts/create-hosted-cluster-instance.sh
```

### Deploy in Test Environment

```bash
# Deploy to test environment first
export CLUSTER_NAME="test-cluster"
export BASE_DOMAIN="test.YOUR-DOMAIN.com"

./deploy-my-environment.sh
```

## Step 6: Document Your Implementation

### Create Implementation Documentation

```bash
# Create your implementation guide
cat > docs/my-implementation.md << 'EOF'
# My OpenShift HyperShift Lab Implementation

## Environment Overview
- **Organization**: Your Organization Name
- **Infrastructure**: AWS + Bare Metal
- **Domain**: YOUR-DOMAIN.com
- **Regions**: YOUR-AWS-REGION
- **RHACM Version**: 2.13
- **OpenShift Version**: 4.18.20

## Customizations Made
1. **Domain Configuration**: Updated all references to use YOUR-DOMAIN.com
2. **Cluster Naming**: Changed to my-production-cluster pattern
3. **Resource Sizing**: Increased production cluster resources
4. **Bare Metal Integration**: Added RHACM 2.13 host inventory
5. **Custom Scripts**: Created deploy-my-environment.sh

## Deployment Process
[Document your specific deployment steps]

## Lessons Learned
[Document challenges and solutions]

## Performance Results
[Include benchmarks and performance data]
EOF
```

### Update README

```bash
# Add your customization notes to README
cat >> README.md << 'EOF'

## My Environment Customizations

This fork has been customized for:
- Domain: YOUR-DOMAIN.com
- AWS Region: YOUR-AWS-REGION
- Production cluster sizing
- Bare metal integration with RHACM 2.13

See [docs/my-implementation.md](docs/my-implementation.md) for details.
EOF
```

## Step 7: Maintain Your Fork

### Keep Synchronized with Upstream

```bash
# Regularly sync with upstream changes
git checkout main
git fetch upstream
git merge upstream/main

# Resolve any conflicts
# git mergetool  # if conflicts exist

# Push updates to your fork
git push origin main
```

### Rebase Your Feature Branches

```bash
# Update your customization branch
git checkout my-environment-setup
git rebase main

# Resolve conflicts if any
# Test your customizations still work
./deploy-my-environment.sh --help

# Push updated branch
git push origin my-environment-setup --force-with-lease
```

### Create Release Tags

```bash
# Tag stable versions of your implementation
git tag -a v1.0-my-env -m "My environment v1.0 - stable production deployment"
git push origin v1.0-my-env
```

## Step 8: Contribute Back to Community

### Prepare Your Contributions

```bash
# Create a contribution branch
git checkout -b feature/bare-metal-rhacm-2.13

# Add only the generic, reusable parts (no sensitive data)
mkdir -p contributions/bare-metal-examples/
cp gitops/cluster-config/bare-metal-production/host-inventory.yaml \
   contributions/bare-metal-examples/host-inventory-example.yaml

# Sanitize the example (remove sensitive data)
sed -i 's/YOUR-DOMAIN.com/example.com/g' contributions/bare-metal-examples/*
sed -i 's/ssh-rsa AAAAB3NzaC1yc2EAAAA.*/ssh-rsa AAAAB3NzaC1yc2EAAAA... # Your SSH public key/g' contributions/bare-metal-examples/*
```

### Submit Pull Request

```bash
# Commit your contributions
git add contributions/
git add docs/diataxis/how-to-guides/deploy-to-bare-metal.md  # if you updated it
git commit -m "Add RHACM 2.13 bare metal implementation examples

- Working host inventory configurations
- Cluster deployment examples
- Implementation documentation
- Troubleshooting guide based on real deployment"

# Push to your fork
git push origin feature/bare-metal-rhacm-2.13

# Create pull request on GitHub
# Go to your fork and click "New Pull Request"
```

## Best Practices

### Security Considerations

1. **Never commit sensitive data**: Use `.gitignore` for secrets, keys, and credentials
2. **Use environment variables**: For sensitive configuration values
3. **Sanitize examples**: Remove real domains, IPs, and keys before sharing
4. **Review before pushing**: Always review changes before pushing to public repositories

### Maintenance Tips

1. **Regular updates**: Sync with upstream monthly or when new features are released
2. **Test before merging**: Always test upstream changes in your environment
3. **Document changes**: Keep your implementation documentation current
4. **Backup configurations**: Maintain backups of working configurations

### Collaboration

1. **Use descriptive branch names**: `feature/bare-metal-support`, `fix/domain-configuration`
2. **Write clear commit messages**: Explain what and why, not just what
3. **Create issues**: Use GitHub issues to track problems and enhancements
4. **Share knowledge**: Contribute documentation and examples back to the community

## Summary

You now have:
- ✅ **Your own fork** of the OpenShift HyperShift Lab
- ✅ **Customized configurations** for your environment
- ✅ **Custom deployment scripts** tailored to your needs
- ✅ **Documentation** of your implementation
- ✅ **Maintenance workflow** to stay current with upstream
- ✅ **Contribution process** to share improvements with the community

Your fork serves as both a working environment for your organization and a potential source of contributions to help the broader OpenShift community!
