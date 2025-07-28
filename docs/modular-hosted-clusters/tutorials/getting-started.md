# Getting Started with Modular Hosted Clusters

This tutorial will guide you through deploying your first hosted cluster using the modular framework. By the end of this tutorial, you'll have a working hosted cluster and understand the basic workflow.

## What You'll Learn

- How to create a new hosted cluster instance
- How to deploy it using GitOps
- How to validate the deployment
- How to access your hosted cluster

## Prerequisites

Before starting this tutorial, ensure you have:

- ✅ OpenShift cluster with admin access
- ✅ OpenShift GitOps operator installed
- ✅ HyperShift operator installed
- ✅ OpenShift Virtualization installed (for KubeVirt platform)
- ✅ CLI tools: `oc`, `git`, `yq`, `jq`

### Verify Prerequisites

```bash
# Check if you're logged in to OpenShift
oc whoami

# Check if GitOps operator is installed
oc get csv -n openshift-gitops | grep gitops

# Check if HyperShift operator is installed
oc get csv -n hypershift | grep hypershift

# Check if OpenShift Virtualization is installed
oc get csv -n openshift-cnv | grep kubevirt
```

## Step 1: Understand the Framework Structure

First, let's explore the modular framework structure:

```bash
# Navigate to the project directory
cd openshift-hypershift-lab

# Explore the modular structure
tree gitops/cluster-config/virt-lab-env/
```

You should see:
```
gitops/cluster-config/virt-lab-env/
├── base/                    # Base configurations (enhanced)
├── overlays/
│   ├── template/           # Template for new instances
│   ├── aws-template/       # AWS-specific template
│   └── example-instance/   # Existing example (unchanged)
├── applicationsets/        # ArgoCD ApplicationSets
└── config/                # Configuration management
```

## Step 2: Set Up Credentials

Before creating hosted clusters, you need to set up the required credentials:

### Quick Credential Setup (Interactive)

```bash
# Set up credentials interactively (recommended for first time)
./scripts/setup-hosted-cluster-credentials.sh \
  --interactive \
  --create-ssh-key \
  my-first-cluster
```

This will:
- Guide you through downloading the pull secret from Red Hat
- Create SSH keys automatically
- Set up all required secrets in OpenShift

### Manual Credential Setup

If you prefer manual setup or already have the files:

```bash
# 1. Download pull secret from Red Hat Console
# Visit: https://console.redhat.com/openshift/install/pull-secret
# Save as: ~/pull-secret.json

# 2. Set up credentials with existing files
./scripts/setup-hosted-cluster-credentials.sh \
  --pull-secret-path ~/pull-secret.json \
  --ssh-key-path ~/.ssh/id_rsa \
  my-first-cluster
```

**📚 [Detailed Credential Setup Guide](../how-to/setup-credentials.md)**

## Step 3: Create Your First Hosted Cluster

Now let's create a development cluster named `my-first-cluster`:

### Option A: Create Instance with Integrated Credential Setup

```bash
# Create instance and set up credentials in one command
./scripts/create-hosted-cluster-instance.sh \
  --name my-first-cluster \
  --environment dev \
  --domain dev.example.com \
  --replicas 2 \
  --memory 8Gi \
  --cores 4 \
  --setup-credentials \
  --interactive-credentials
```

### Option B: Create Instance Only (if credentials already set up)

```bash
# Create a new hosted cluster instance
./scripts/create-hosted-cluster-instance.sh \
  --name my-first-cluster \
  --environment dev \
  --domain dev.example.com \
  --replicas 2 \
  --memory 8Gi \
  --cores 4

# Verify the instance was created
ls -la gitops/cluster-config/virt-lab-env/overlays/instances/my-first-cluster/
```

You should see three files created:
- `kustomization.yaml` - Main configuration
- `hosted-cluster-patch.yaml` - HostedCluster customizations
- `nodepool-patch.yaml` - NodePool customizations

## Step 4: Review the Generated Configuration

Let's examine what was created:

```bash
# View the main configuration
cat gitops/cluster-config/virt-lab-env/overlays/instances/my-first-cluster/kustomization.yaml

# Check the hosted cluster patch
cat gitops/cluster-config/virt-lab-env/overlays/instances/my-first-cluster/hosted-cluster-patch.yaml
```

**Key Configuration Elements:**
- **Cluster Name**: `my-first-cluster`
- **Environment**: `dev`
- **Base Domain**: `dev.example.com`
- **Node Replicas**: 2 worker nodes
- **Resources**: 8Gi memory, 4 CPU cores per node

## Step 5: Test the Configuration

Before deploying, let's validate the configuration locally:

```bash
# Test Kustomize build only
./scripts/test-hosted-cluster-config.sh --build-only my-first-cluster

# Run comprehensive local test (checks credentials, build, etc.)
./scripts/test-hosted-cluster-config.sh my-first-cluster
```

This will:
- Validate the Kustomize build
- Check that all required credentials exist
- Verify resource generation
- Provide next steps guidance

**⚠️ Important**: The local test does NOT deploy actual resources. For GitOps deployment, you must commit to Git first.

## Step 6: Commit Your Configuration

**🚨 CRITICAL**: ArgoCD ApplicationSet uses Git discovery - your instance MUST be committed to Git before ArgoCD can see it!

```bash
# Add the new instance to Git
git add gitops/cluster-config/virt-lab-env/overlays/instances/my-first-cluster/

# Commit the changes
git commit -m "Add my-first-cluster hosted cluster instance

- Environment: dev
- Domain: dev.example.com
- Replicas: 2
- Resources: 8Gi memory, 4 cores"

# Push to your repository (adjust remote as needed)
git push origin main
```

**Why Git is Required:**
- The ApplicationSet uses a Git generator that scans the repository
- Only committed instances in Git will be discovered by ArgoCD
- Local files are invisible to the GitOps workflow

## Step 7: Validate GitOps Readiness

After committing to Git, validate that your instance is ready for GitOps deployment:

```bash
# Validate GitOps readiness
./scripts/test-hosted-cluster-config.sh --validate-gitops my-first-cluster
```

This will check:
- ✅ Instance is committed to Git
- ✅ No uncommitted changes
- ✅ ApplicationSet configuration exists
- ✅ ApplicationSet is deployed (if applicable)

## Step 8: Deploy the ApplicationSet

Now let's deploy the ApplicationSet that will manage all hosted cluster instances:

```bash
# Deploy the ApplicationSet (if not already deployed)
oc apply -f gitops/cluster-config/apps/openshift-hypershift-lab/hosted-clusters-applicationset.yaml

# Verify the ApplicationSet was created
oc get applicationset -n openshift-gitops hosted-clusters
```

## Step 9: Monitor the Deployment

The ApplicationSet will automatically discover your new instance and create an ArgoCD Application:

```bash
# Watch for the new Application to be created
oc get applications -n openshift-gitops | grep my-first-cluster

# Monitor the deployment progress
oc get applications -n openshift-gitops hosted-cluster-my-first-cluster -w
```

You can also monitor through the ArgoCD UI:

```bash
# Get the ArgoCD route
oc get route openshift-gitops-server -n openshift-gitops --template='https://{{.spec.host}}'
```

## Step 10: Validate the Deployment

Once the Application shows as "Synced" and "Healthy", validate the hosted cluster:

```bash
# Check if the HostedCluster was created
oc get hostedcluster my-first-cluster -n clusters

# Check the NodePool
oc get nodepool -n clusters | grep my-first-cluster

# Run comprehensive validation
./scripts/validate-deployment.sh my-first-cluster
```

## Step 11: Access Your Hosted Cluster

Once validation passes, you can access your hosted cluster:

```bash
# Extract the kubeconfig
oc get secret my-first-cluster-admin-kubeconfig -n clusters \
  -o jsonpath='{.data.kubeconfig}' | base64 -d > my-first-cluster-kubeconfig

# Use the kubeconfig to access the hosted cluster
export KUBECONFIG=my-first-cluster-kubeconfig

# Check the cluster status
oc get nodes
oc get clusteroperators

# Check cluster version
oc get clusterversion
```

## Step 12: Explore Your Hosted Cluster

Now that you have access, explore your new cluster:

```bash
# List all namespaces
oc get namespaces

# Check running pods
oc get pods -A

# View cluster information
oc cluster-info

# Check the console URL
oc get route console -n openshift-console --template='https://{{.spec.host}}'
```

## What You've Accomplished

Congratulations! You've successfully:

1. ✅ Created a new hosted cluster instance using the modular framework
2. ✅ Deployed it using GitOps with ArgoCD ApplicationSets
3. ✅ Validated the deployment using automated scripts
4. ✅ Accessed and explored your hosted cluster

## Next Steps

Now that you have a working hosted cluster, you can:

- **Scale Your Cluster**: Learn how to [scale node pools](../how-to/scale-clusters.md)
- **Create More Instances**: Try creating staging and production clusters
- **Explore AWS Platform**: Follow the [AWS integration tutorial](aws-integration.md)
- **Set Up Monitoring**: Configure monitoring and alerting for your clusters
- **Deploy Applications**: Start deploying applications to your hosted cluster

## Troubleshooting

If you encounter issues:

1. **Check ArgoCD Application Status**:
   ```bash
   oc describe application hosted-cluster-my-first-cluster -n openshift-gitops
   ```

2. **Check HostedCluster Events**:
   ```bash
   oc describe hostedcluster my-first-cluster -n clusters
   ```

3. **Run Validation Script**:
   ```bash
   ./scripts/validate-deployment.sh my-first-cluster --verbose
   ```

4. **Check the [troubleshooting guide](../how-to/troubleshoot.md)** for common issues and solutions.

## Clean Up (Optional)

If you want to remove the test cluster:

```bash
# Delete the ArgoCD Application (this will clean up the hosted cluster)
oc delete application hosted-cluster-my-first-cluster -n openshift-gitops

# Remove the instance configuration
rm -rf gitops/cluster-config/virt-lab-env/overlays/instances/my-first-cluster/

# Commit the removal
git add -A
git commit -m "Remove my-first-cluster test instance"
git push origin main
```

---

**Next Tutorial**: [Multi-Environment Setup](multi-environment.md) - Learn how to set up development, staging, and production environments.
