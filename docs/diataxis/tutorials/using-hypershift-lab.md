# Using the OpenShift HyperShift Lab

This tutorial teaches you how to work with the OpenShift HyperShift Lab environment, including accessing hosted clusters, using the GitOps workflow, and understanding the unique components of this lab setup.

## What You'll Learn

- How to identify and access your hosted clusters (dev-cluster-01, dev-cluster-02, etc.)
- Understanding the management cluster vs hosted clusters architecture
- Working with ArgoCD for GitOps management
- Using the External Secrets Operator for credential management
- Creating new hosted cluster instances using the lab scripts
- Monitoring hosted cluster health and status

## Prerequisites

- OpenShift HyperShift Lab environment deployed using `openshift-3node-baremetal-cluster.sh`
- Hosted control planes set up using `setup-hosted-control-planes.sh`
- Access to the management cluster console
- Basic understanding of OpenShift concepts

## Step 1: Understand Your HyperShift Lab Architecture

### What Makes This Lab Special

The OpenShift HyperShift Lab provides:
- **1 Management Cluster**: Hosts control planes for multiple clusters
- **Multiple Hosted Clusters**: Independent OpenShift clusters with shared control plane hosting
- **GitOps Automation**: ArgoCD manages all deployments
- **External Secrets**: Centralized credential management
- **Multi-Platform Support**: KubeVirt VMs and AWS instances

### Current Lab Environment

Your lab includes these hosted clusters:
- `dev-cluster-01` - Development environment
- `dev-cluster-02` - Additional development environment  
- `example-instance` - Example/template cluster
- `cluster-template` - Template for new clusters

## Step 2: Access Your Hosted Clusters

### Understanding Hosted Cluster URLs

Each hosted cluster has its own console with this URL pattern:
```
https://console-openshift-console.apps.<hosted-cluster-name>.apps.<management-cluster-name>.<domain>
```

### Access dev-cluster-01

1. **Open a new browser tab**
2. **Navigate to**:
   ```
   https://console-openshift-console.apps.dev-cluster-01.apps.management-cluster.example.com
   ```
3. **Log in with the same credentials** as the management cluster
4. **Notice this is a completely separate OpenShift cluster**:
   - Different projects/namespaces
   - Independent resources
   - Separate monitoring and metrics

### Verify Cluster Independence

1. **Create a test project** in dev-cluster-01:
   - Name: `test-isolation`
   - Deploy a simple application

2. **Switch to dev-cluster-02**:
   ```
   https://console-openshift-console.apps.dev-cluster-02.apps.management-cluster.example.com
   ```
3. **Notice the project doesn't exist** - clusters are completely isolated

## Step 3: Work with ArgoCD GitOps

### Access ArgoCD Console

1. **From the management cluster console**
2. **Navigate to Networking > Routes**
3. **Select the `openshift-gitops` project**
4. **Click on the ArgoCD route URL**

### Explore HyperShift Lab Applications

In ArgoCD, you'll see applications that manage your lab:

1. **cluster-config**: Manages the overall cluster configuration
2. **openshift-virtualization**: Deploys OpenShift Virtualization
3. **advanced-cluster-management**: Deploys RHACM
4. **multicluster-engine**: Enables multi-cluster capabilities
5. **hosted-clusters-applicationset**: Automatically manages hosted clusters

### Understanding GitOps Workflow

The lab uses this GitOps pattern:
```
Git Repository (gitops/) → ArgoCD → Management Cluster → Hosted Clusters
```

All configuration changes go through Git commits and ArgoCD synchronization.

## Step 4: Use the External Secrets Operator

### Understanding Credential Management

The lab uses External Secrets Operator to manage credentials securely:

1. **Central credential store**: `virt-creds` namespace
2. **Automatic synchronization**: Secrets sync to hosted clusters
3. **No secrets in Git**: All sensitive data managed externally

### View External Secrets

1. **In the management cluster console**
2. **Navigate to the `clusters` namespace**
3. **Go to Workloads > Secrets**
4. **Look for secrets like `dev-cluster-01-admin-kubeconfig`**

### Check External Secret Resources

1. **Go to Installed Operators**
2. **Find External Secrets Operator**
3. **View ExternalSecret resources** that sync credentials

## Step 5: Create a New Hosted Cluster Instance

### Using the Lab Script

The lab provides a script to create new hosted clusters:

```bash
# Create a new development cluster
./scripts/create-hosted-cluster-instance.sh \
  --name my-new-cluster \
  --environment dev \
  --replicas 2
```

### What the Script Does

1. **Creates GitOps configuration** in `gitops/cluster-config/virt-lab-env/overlays/instances/`
2. **Sets up External Secrets** for credential management
3. **Configures the cluster** for the management cluster domain
4. **Prepares for ArgoCD deployment**

### Deploy via GitOps

After creating the configuration:

1. **Test locally first**:
   ```bash
   oc apply -k gitops/cluster-config/virt-lab-env/overlays/instances/my-new-cluster
   ```

2. **If successful, commit to Git**:
   ```bash
   git add gitops/cluster-config/virt-lab-env/overlays/instances/my-new-cluster
   git commit -m "Add my-new-cluster hosted cluster"
   git push origin main
   ```

3. **ArgoCD will automatically deploy** the new cluster

## Step 6: Monitor Hosted Cluster Status

### Check Cluster Status

1. **In the management cluster console**
2. **Navigate to the `clusters` namespace**
3. **Go to Workloads > Pods**
4. **Look for pods with your cluster name** (e.g., `my-new-cluster-*`)

### Using the CLI

```bash
# Check hosted cluster status
oc get hostedcluster -n clusters

# Check node pools
oc get nodepool -n clusters

# Check external secrets
oc get externalsecrets -n clusters
```

### Access New Cluster Console

Once deployed, access your new cluster at:
```
https://console-openshift-console.apps.my-new-cluster.apps.management-cluster.example.com
```

## Step 7: Understand Lab-Specific Features

### OpenShift Virtualization Integration

The lab includes OpenShift Virtualization for running VMs:

1. **Check virtualization status** in the management cluster
2. **Navigate to Virtualization** in the left menu
3. **Hosted clusters can run on KubeVirt VMs** for resource efficiency

### Multi-Platform Support

The lab supports different platforms for hosted cluster workers:
- **KubeVirt**: Virtual machines on the management cluster
- **AWS**: EC2 instances in AWS
- **Extensible**: Can be extended to other platforms

### Certificate Management

The lab handles certificates automatically:
- **Wildcard policy**: Enables nested subdomain routing
- **Let's Encrypt integration**: Automatic certificate provisioning
- **Certificate inheritance**: Hosted clusters use management cluster certificates

## Step 8: Troubleshoot Common Issues

### Hosted Cluster Not Accessible

1. **Check cluster status**: `oc get hostedcluster -n clusters`
2. **Verify ingress configuration**: Ensure wildcard policy is enabled
3. **Check DNS resolution**: Verify nested subdomain routing

### ArgoCD Application Issues

1. **Check application status** in ArgoCD console
2. **Look for sync errors** and resolve configuration issues
3. **Verify Git repository access** and permissions

### External Secrets Not Syncing

1. **Check External Secrets Operator** status
2. **Verify credential store** in `virt-creds` namespace
3. **Check ExternalSecret resource** configuration

## Next Steps

Now that you understand the HyperShift Lab:

1. **Experiment with creating new hosted clusters**
2. **Deploy applications to different hosted clusters**
3. **Explore the GitOps workflow** by making configuration changes
4. **Learn about the underlying scripts** in the [Developer How-To Guides](../how-to-guides/developer/)
5. **Understand the architecture** in [Architecture Overview](../explanations/architecture-overview.md)

## Summary

You've successfully learned to:
- ✅ Understand the HyperShift Lab architecture
- ✅ Access and work with hosted clusters
- ✅ Use ArgoCD for GitOps management
- ✅ Work with External Secrets for credential management
- ✅ Create new hosted cluster instances
- ✅ Monitor and troubleshoot hosted clusters
- ✅ Understand lab-specific features and integrations

You're now ready to effectively use the OpenShift HyperShift Lab environment for development, testing, and learning about hosted OpenShift clusters!
