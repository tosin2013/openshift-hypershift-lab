# How to Create a New Hosted Cluster

This guide shows you how to create a new hosted cluster in the OpenShift HyperShift Lab using the provided scripts and GitOps workflow.

## Prerequisites

- Access to the OpenShift HyperShift Lab management cluster
- The `setup-hosted-control-planes.sh` script has been run successfully
- Git access to the repository
- Basic understanding of the HyperShift Lab architecture

## Quick Start

```bash
# Create a new development cluster
./scripts/create-hosted-cluster-instance.sh \
  --name my-dev-cluster \
  --environment dev \
  --replicas 2

# Test the configuration
oc apply -k gitops/cluster-config/virt-lab-env/overlays/instances/my-dev-cluster

# If successful, commit to Git
git add gitops/cluster-config/virt-lab-env/overlays/instances/my-dev-cluster
git commit -m "Add my-dev-cluster hosted cluster"
git push origin main
```

## Step-by-Step Process

### Step 1: Plan Your Hosted Cluster

#### Choose Cluster Specifications

Decide on these parameters:
- **Name**: Unique cluster name (e.g., `staging-cluster-01`)
- **Environment**: `dev`, `staging`, or `prod`
- **Replicas**: Number of worker nodes (2-5 recommended)
- **Resources**: Memory and CPU per node
- **Platform**: KubeVirt (default) or AWS

#### Naming Conventions

Follow these patterns:
- Development: `dev-cluster-01`, `dev-cluster-02`
- Staging: `staging-cluster-01`, `staging-cluster-02`
- Production: `prod-cluster-01`, `prod-cluster-02`

### Step 2: Use the Creation Script

#### Basic Cluster Creation

```bash
# Navigate to the project root
cd openshift-hypershift-lab

# Create a development cluster
./scripts/create-hosted-cluster-instance.sh \
  --name dev-cluster-03 \
  --environment dev \
  --replicas 2
```

#### Advanced Configuration

```bash
# Create a production cluster with custom resources
./scripts/create-hosted-cluster-instance.sh \
  --name prod-cluster-01 \
  --environment prod \
  --replicas 3 \
  --memory 16Gi \
  --cores 8 \
  --storage-size 100Gi
```

#### Script Options

| Option | Description | Default |
|--------|-------------|---------|
| `--name` | Cluster name | Required |
| `--environment` | Environment type | `dev` |
| `--replicas` | Worker node count | `2` |
| `--memory` | Memory per node | `8Gi` |
| `--cores` | CPU cores per node | `4` |
| `--storage-size` | Storage per node | `50Gi` |
| `--domain` | Override domain | Auto-detected |

### Step 3: Verify Generated Configuration

#### Check Created Files

The script creates these files:
```
gitops/cluster-config/virt-lab-env/overlays/instances/my-dev-cluster/
├── kustomization.yaml          # Kustomize configuration
├── cluster-config.yaml         # ConfigMap with cluster parameters
├── external-secret.yaml        # External Secrets configuration
└── replacements.yaml           # Parameter replacements
```

#### Review Configuration

1. **Check the kustomization.yaml**:
   ```bash
   cat gitops/cluster-config/virt-lab-env/overlays/instances/my-dev-cluster/kustomization.yaml
   ```

2. **Verify cluster parameters**:
   ```bash
   cat gitops/cluster-config/virt-lab-env/overlays/instances/my-dev-cluster/cluster-config.yaml
   ```

3. **Check External Secrets setup**:
   ```bash
   cat gitops/cluster-config/virt-lab-env/overlays/instances/my-dev-cluster/external-secret.yaml
   ```

### Step 4: Test Configuration Locally

#### Apply Configuration

```bash
# Test the configuration without committing
oc apply -k gitops/cluster-config/virt-lab-env/overlays/instances/my-dev-cluster
```

#### Check Deployment Status

```bash
# Check hosted cluster status
oc get hostedcluster -n clusters

# Check node pool status
oc get nodepool -n clusters

# Check external secrets
oc get externalsecrets -n clusters | grep my-dev-cluster
```

#### Monitor Deployment Progress

```bash
# Watch hosted cluster events
oc get events -n clusters --field-selector involvedObject.name=my-dev-cluster

# Check control plane pods
oc get pods -n clusters | grep my-dev-cluster
```

### Step 5: Commit to Git for GitOps

#### Add Files to Git

```bash
# Add the new cluster configuration
git add gitops/cluster-config/virt-lab-env/overlays/instances/my-dev-cluster

# Check what will be committed
git status
```

#### Commit Changes

```bash
# Commit with descriptive message
git commit -m "Add my-dev-cluster hosted cluster

- Environment: dev
- Replicas: 2
- Platform: KubeVirt
- Resources: 8Gi memory, 4 cores per node"
```

#### Push to Repository

```bash
# Push to main branch
git push origin main
```

### Step 6: Verify ArgoCD Deployment

#### Check ArgoCD Applications

1. **Access ArgoCD console** from the management cluster
2. **Look for new applications** related to your cluster
3. **Verify sync status** - should show as "Synced" and "Healthy"

#### Monitor ApplicationSet

```bash
# Check ApplicationSet status
oc get applicationset -n openshift-gitops

# Check generated applications
oc get applications -n openshift-gitops | grep my-dev-cluster
```

### Step 7: Access Your New Hosted Cluster

#### Wait for Deployment

```bash
# Wait for cluster to be ready
oc wait --for=condition=Available hostedcluster/my-dev-cluster -n clusters --timeout=20m
```

#### Get Cluster Console URL

Your new cluster console will be available at:
```
https://console-openshift-console.apps.my-dev-cluster.apps.management-cluster.example.com
```

#### Access the Cluster

1. **Open the console URL** in your browser
2. **Log in with the same credentials** as the management cluster
3. **Verify it's a separate cluster** with its own projects and resources

### Step 8: Get Cluster Credentials

#### Extract Kubeconfig

```bash
# Get the admin kubeconfig
oc get secret my-dev-cluster-admin-kubeconfig -n clusters \
  -o jsonpath='{.data.kubeconfig}' | base64 -d > my-dev-cluster-kubeconfig

# Use the kubeconfig
export KUBECONFIG=my-dev-cluster-kubeconfig

# Verify access
oc get nodes
oc get projects
```

#### Switch Back to Management Cluster

```bash
# Unset the kubeconfig to return to management cluster
unset KUBECONFIG

# Or set it back to your original kubeconfig
export KUBECONFIG=~/.kube/config
```

## Troubleshooting

### Cluster Creation Fails

**Check script output**:
```bash
# Run with verbose output
./scripts/create-hosted-cluster-instance.sh --name test-cluster --environment dev -v
```

**Common issues**:
- Domain detection failure
- Missing prerequisites
- Invalid cluster name

### Deployment Stuck

**Check hosted cluster status**:
```bash
oc describe hostedcluster my-dev-cluster -n clusters
```

**Check node pool status**:
```bash
oc describe nodepool my-dev-cluster -n clusters
```

**Check external secrets**:
```bash
oc describe externalsecret my-dev-cluster-creds -n clusters
```

### ArgoCD Sync Issues

**Check application status**:
```bash
oc describe application my-dev-cluster -n openshift-gitops
```

**Force sync**:
```bash
# From ArgoCD console, click "Sync" on the application
# Or use CLI:
argocd app sync my-dev-cluster
```

### Console Not Accessible

**Check ingress configuration**:
```bash
# Verify wildcard policy is enabled
oc get ingresscontroller default -n openshift-ingress-operator -o yaml | grep -A5 routeAdmission
```

**Check route creation**:
```bash
# Look for console route in hosted cluster namespace
oc get routes -A | grep my-dev-cluster
```

## Best Practices

### Naming and Organization

1. **Use consistent naming**: Follow environment-based patterns
2. **Document purpose**: Include cluster purpose in commit messages
3. **Group by environment**: Organize clusters by dev/staging/prod

### Resource Management

1. **Start small**: Begin with 2 replicas and scale up if needed
2. **Monitor resources**: Check management cluster capacity
3. **Clean up unused clusters**: Remove test clusters when done

### GitOps Workflow

1. **Test locally first**: Always test with `oc apply -k` before committing
2. **Use descriptive commits**: Include cluster specifications in commit messages
3. **Monitor ArgoCD**: Ensure applications sync successfully

## Next Steps

After creating your hosted cluster:

1. **Deploy applications** to test functionality
2. **Set up monitoring** and logging
3. **Configure networking** and ingress
4. **Implement backup strategies**
5. **Scale resources** as needed

## Summary

You've successfully learned to:
- ✅ Plan and configure a new hosted cluster
- ✅ Use the creation script with appropriate parameters
- ✅ Test configuration locally before committing
- ✅ Deploy through GitOps workflow
- ✅ Access and verify the new cluster
- ✅ Troubleshoot common issues

Your new hosted cluster is now ready for use in the OpenShift HyperShift Lab environment!
