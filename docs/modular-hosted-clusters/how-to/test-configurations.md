# How to Test Hosted Cluster Configurations

This guide explains how to test hosted cluster configurations before deploying them through GitOps. Understanding the testing workflow is crucial because **ArgoCD ApplicationSet uses Git discovery** - only configurations committed to Git will be deployed.

## Understanding the GitOps Workflow

### Why Git Commit is Required

The ArgoCD ApplicationSet uses a **Git generator** that scans your repository for cluster instances:

```yaml
generators:
- git:
    repoURL: https://github.com/your-org/openshift-hypershift-lab.git
    revision: main
    directories:
    - path: gitops/cluster-config/virt-lab-env/overlays/instances/*
```

This means:
- ✅ **Committed instances**: Visible to ArgoCD, will be deployed
- ❌ **Local-only instances**: Invisible to ArgoCD, won't be deployed
- ⚠️ **Uncommitted changes**: ArgoCD uses the committed version, not local changes

## Testing Workflow Overview

```
1. Create Instance → 2. Test Locally → 3. Commit to Git → 4. Test GitOps → 5. Deploy
     (Local)           (Validation)      (Required!)       (Validation)    (ArgoCD)
```

## Testing Tools

### 1. Configuration Testing Script

The `test-hosted-cluster-config.sh` script provides comprehensive testing capabilities:

```bash
# Test Kustomize build only (fastest)
./scripts/test-hosted-cluster-config.sh --build-only my-cluster

# Full local validation (recommended)
./scripts/test-hosted-cluster-config.sh my-cluster

# Validate GitOps readiness (after Git commit)
./scripts/test-hosted-cluster-config.sh --validate-gitops my-cluster
```

### 2. Deployment Validation Script

The `validate-deployment.sh` script validates actual deployed clusters:

```bash
# Validate deployed cluster
./scripts/validate-deployment.sh my-cluster

# Verbose validation with detailed output
./scripts/validate-deployment.sh --verbose my-cluster
```

## Step-by-Step Testing Guide

### Step 1: Create and Test Instance Locally

```bash
# 1. Create instance
./scripts/create-hosted-cluster-instance.sh \
  --name test-cluster \
  --environment dev \
  --domain dev.example.com

# 2. Set up credentials
./scripts/setup-hosted-cluster-credentials.sh test-cluster

# 3. Test Kustomize build
./scripts/test-hosted-cluster-config.sh --build-only test-cluster

# 4. Full local validation
./scripts/test-hosted-cluster-config.sh test-cluster
```

**Expected Output:**
```
[SUCCESS] Kustomize build successful
[SUCCESS] ✓ HostedCluster resource found
[SUCCESS] ✓ NodePool resource found
[SUCCESS] ✓ Pull secret found: pullsecret-cluster
[SUCCESS] ✓ SSH key secret found: sshkey-cluster
[SUCCESS] ✓ Infrastructure credentials found: test-cluster-infra-credentials
[SUCCESS] All tests passed! Configuration is ready for GitOps deployment.
```

### Step 2: Optional Local Deployment Testing

**⚠️ Warning**: This creates actual resources in your cluster!

```bash
# Deploy locally for testing (creates real resources)
./scripts/test-hosted-cluster-config.sh --deploy-local test-cluster

# Validate the local deployment
./scripts/validate-deployment.sh test-cluster

# Clean up test resources
./scripts/test-hosted-cluster-config.sh --cleanup test-cluster
```

### Step 3: Commit to Git (Required!)

```bash
# Add instance to Git
git add gitops/cluster-config/virt-lab-env/overlays/instances/test-cluster/

# Commit with descriptive message
git commit -m "Add test-cluster hosted cluster

- Environment: dev
- Domain: dev.example.com
- Platform: KubeVirt
- Replicas: 3"

# Push to repository
git push origin main
```

### Step 4: Validate GitOps Readiness

```bash
# Validate GitOps readiness
./scripts/test-hosted-cluster-config.sh --validate-gitops test-cluster
```

**Expected Output:**
```
[SUCCESS] ✓ Instance found in Git repository
[SUCCESS] ✓ No uncommitted changes
[SUCCESS] ✓ ApplicationSet configuration found
[SUCCESS] ✓ ApplicationSet deployed in cluster
[SUCCESS] ✓ ArgoCD Application exists: hosted-cluster-test-cluster
```

### Step 5: Deploy ApplicationSet and Monitor

```bash
# Deploy ApplicationSet (if not already deployed)
oc apply -f gitops/cluster-config/apps/openshift-hypershift-lab/hosted-clusters-applicationset.yaml

# Monitor ArgoCD Application creation
oc get applications -n openshift-gitops | grep test-cluster

# Watch Application status
oc get application hosted-cluster-test-cluster -n openshift-gitops -w
```

## Testing Scenarios

### Scenario 1: Build Validation Only

**Use Case**: Quick syntax and structure validation

```bash
./scripts/test-hosted-cluster-config.sh --build-only my-cluster
```

**What it tests**:
- Kustomize build succeeds
- Required resources are generated
- Configuration structure is valid

### Scenario 2: Comprehensive Local Testing

**Use Case**: Full validation before Git commit

```bash
./scripts/test-hosted-cluster-config.sh my-cluster
```

**What it tests**:
- Kustomize build validation
- Credential existence check
- Resource generation validation
- Configuration completeness

### Scenario 3: Local Deployment Testing

**Use Case**: Test actual resource creation (advanced)

```bash
# Deploy locally
./scripts/test-hosted-cluster-config.sh --deploy-local my-cluster

# Test the deployment
./scripts/validate-deployment.sh my-cluster

# Clean up
./scripts/test-hosted-cluster-config.sh --cleanup my-cluster
```

**What it does**:
- Creates actual HostedCluster and NodePool resources
- Allows testing of resource creation and validation
- Provides cleanup capability

### Scenario 4: GitOps Readiness Validation

**Use Case**: Ensure GitOps deployment will work

```bash
./scripts/test-hosted-cluster-config.sh --validate-gitops my-cluster
```

**What it tests**:
- Instance is committed to Git
- No uncommitted changes exist
- ApplicationSet is configured and deployed
- ArgoCD Application status

## Troubleshooting Common Issues

### Issue 1: Kustomize Build Fails

```bash
# Error: kustomize build failed
./scripts/test-hosted-cluster-config.sh --build-only --verbose my-cluster
```

**Common causes**:
- Invalid YAML syntax
- Missing base resources
- Incorrect path references
- Invalid placeholder values

### Issue 2: Missing Credentials

```bash
# Error: Pull secret not found
[ERROR] ✗ Pull secret not found: pullsecret-cluster
```

**Solution**:
```bash
./scripts/setup-hosted-cluster-credentials.sh my-cluster
```

### Issue 3: GitOps Discovery Issues

```bash
# Error: Instance not found in Git repository
[ERROR] Instance not found in Git repository
```

**Solution**:
```bash
# Commit your changes
git add gitops/cluster-config/virt-lab-env/overlays/instances/my-cluster/
git commit -m "Add my-cluster"
git push origin main
```

### Issue 4: ApplicationSet Not Finding Instance

```bash
# Check ApplicationSet logs
oc logs -n openshift-gitops deployment/openshift-gitops-applicationset-controller

# Verify ApplicationSet configuration
oc get applicationset hosted-clusters -n openshift-gitops -o yaml
```

## Best Practices

### 1. Always Test Before Committing

```bash
# Recommended workflow
./scripts/create-hosted-cluster-instance.sh --name my-cluster --domain example.com
./scripts/setup-hosted-cluster-credentials.sh my-cluster
./scripts/test-hosted-cluster-config.sh my-cluster
# Only commit after tests pass
git add . && git commit -m "Add my-cluster"
```

### 2. Use Descriptive Commit Messages

```bash
git commit -m "Add production-cluster-01 hosted cluster

- Environment: production
- Platform: AWS
- Domain: prod.example.com
- Replicas: 5
- Resources: 16Gi memory, 8 cores"
```

### 3. Validate GitOps Before Expecting Deployment

```bash
# Always validate after committing
git push origin main
./scripts/test-hosted-cluster-config.sh --validate-gitops my-cluster
```

### 4. Monitor ApplicationSet Discovery

```bash
# Check ApplicationSet status
oc get applicationset hosted-clusters -n openshift-gitops

# Monitor Application creation
watch "oc get applications -n openshift-gitops | grep hosted-cluster"
```

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Validate Hosted Cluster Configurations
on:
  pull_request:
    paths:
      - 'gitops/cluster-config/virt-lab-env/overlays/instances/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install tools
        run: |
          curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
          sudo mv kustomize /usr/local/bin/
      - name: Validate configurations
        run: |
          for instance in gitops/cluster-config/virt-lab-env/overlays/instances/*/; do
            cluster_name=$(basename "$instance")
            ./scripts/test-hosted-cluster-config.sh --build-only "$cluster_name"
          done
```

## Next Steps

After successful testing:

1. **Monitor Deployment**: Watch ArgoCD Applications and cluster status
2. **Validate Cluster**: Use deployment validation once cluster is ready
3. **Access Cluster**: Extract kubeconfig and connect to your hosted cluster
4. **Scale Operations**: Apply the same testing workflow to additional clusters

---

**Related Documentation:**
- [Getting Started Tutorial](../tutorials/getting-started.md)
- [Credential Setup Guide](setup-credentials.md)
- [Troubleshooting Guide](troubleshoot.md)
