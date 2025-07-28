# Getting Started with OpenShift HyperShift Lab

This tutorial will guide you through your first steps with the OpenShift HyperShift Lab environment. You'll learn how to access the management cluster, understand the hosted clusters architecture, and work with the unique components of this lab environment.

## What You'll Learn

- How to access your HyperShift Lab management cluster
- Understanding the difference between management and hosted clusters
- How to identify and access hosted clusters (dev-cluster-01, dev-cluster-02, etc.)
- Working with the ArgoCD GitOps interface
- Understanding the External Secrets Operator integration
- Basic operations specific to the HyperShift Lab environment

## Prerequisites

### If You Have Access to an Existing Lab Environment
- You have access to a deployed OpenShift HyperShift Lab environment
- The foundation cluster has been deployed using `openshift-3node-baremetal-cluster.sh`
- The hosted control planes have been set up using `setup-hosted-control-planes.sh`
- You have cluster access credentials

### If You Need to Deploy Your Own Lab Environment
- **Fork the repository first**: See [Fork and Customize the Repository](../how-to-guides/fork-and-customize.md) to adapt the lab for your own infrastructure
- **Deploy the foundation cluster**: Follow the deployment instructions in your forked repository
- **Set up hosted control planes**: Run the setup scripts in your customized environment
- **Then return to this tutorial** to learn how to use your deployed lab

## Step 1: Access Your HyperShift Lab Management Cluster

### Understanding the Management Cluster

The OpenShift HyperShift Lab uses a **management cluster** that hosts the control planes for multiple **hosted clusters**. Your management cluster was deployed using the `openshift-3node-baremetal-cluster.sh` script.

### Finding Your Management Cluster Console URL

Your management cluster console URL follows this pattern:

```
https://console-openshift-console.apps.<management-cluster-name>.<domain>
```

**Example**: `https://console-openshift-console.apps.management-cluster.example.com`

### Logging In

1. **Open your web browser** and navigate to your management cluster console URL
2. **Choose your authentication method**:
   - **OpenShift OAuth**: Use your OpenShift credentials
   - **Identity Provider**: If configured, use your organization's SSO
3. **Enter your credentials** and click "Log in"

> **Note**: If you see a certificate warning, this is normal for lab environments. The `configure-keys-on-openshift.sh` script sets up SSL certificates after deployment.

## Step 2: Explore the HyperShift Lab Management Console

### Dashboard Overview

Once logged in to the management cluster, you'll see the OpenShift console dashboard. This management cluster is special because it hosts the control planes for your hosted clusters.

### Key HyperShift Lab Components to Explore

1. **Navigate to the `clusters` namespace**:
   - Click the project dropdown and select `clusters`
   - This namespace contains all your hosted cluster resources

2. **View Hosted Clusters**:
   - Go to **Workloads > Pods** in the `clusters` namespace
   - You'll see pods like `dev-cluster-01-*`, `dev-cluster-02-*`
   - These are the control plane components for your hosted clusters

3. **Check ArgoCD Applications**:
   - Switch to the `openshift-gitops` namespace
   - Go to **Workloads > Pods** to see ArgoCD components
   - ArgoCD manages the GitOps deployment of your lab components

## Step 3: Understanding Your Cluster Structure

### Cluster Information

1. **Navigate to Home > Overview** to see cluster details:
   - Cluster version and status
   - Node count and health
   - Resource utilization
   - Recent events

2. **Check cluster nodes** by going to **Compute > Nodes**:
   - View all cluster nodes
   - Check node status and resources
   - See node roles (master, worker, or both)

### Projects and Namespaces

OpenShift organizes resources into projects (Kubernetes namespaces):

1. **View all projects**: Click the project dropdown at the top
2. **Default projects** you'll see:
   - `default`: Default namespace for resources
   - `openshift-*`: System projects (read-only)
   - `kube-*`: Kubernetes system projects

## Step 4: Explore Basic Resources

### Viewing Workloads

1. **Navigate to Workloads > Pods** to see running applications
2. **Click on a pod** to view details:
   - Resource usage
   - Logs
   - Events
   - Configuration

### Understanding Services and Routes

1. **Go to Networking > Services** to see internal services
2. **Check Networking > Routes** for external access points
3. **Routes** provide external URLs for accessing applications

## Step 5: Working with Hosted Clusters (If Available)

If your environment includes hosted clusters, you'll have access to multiple OpenShift clusters:

### Identifying Hosted Clusters

1. **Check for hosted clusters** by looking for additional console URLs:
   - Management cluster: `console-openshift-console.apps.<mgmt-cluster>.<domain>`
   - Hosted cluster: `console-openshift-console.apps.<hosted-cluster>.apps.<mgmt-cluster>.<domain>`

### Accessing Hosted Clusters

1. **Each hosted cluster has its own console** with the same interface
2. **Switch between clusters** by changing the URL or using provided links
3. **Each cluster is independent** with its own projects and resources

## Step 6: Basic Operations

### Creating Your First Project

1. **Click the project dropdown** and select "Create Project"
2. **Enter project details**:
   - Name: `my-first-project`
   - Display Name: `My First Project`
   - Description: `Learning OpenShift basics`
3. **Click "Create"**

### Viewing Cluster Events

1. **Navigate to Home > Events** to see cluster activity
2. **Filter events** by type, namespace, or time
3. **Use events** to troubleshoot issues or monitor activity

## Next Steps

Now that you're familiar with the basics:

1. **Try the other tutorials**:
   - [Accessing Cluster Consoles](accessing-consoles.md)
   - [Working with Hosted Clusters](working-with-hosted-clusters.md)
   - [Managing Workloads](managing-workloads.md)

2. **Explore specific tasks** in the [How-To Guides](../how-to-guides/)

3. **Learn more about the architecture** in [Explanations](../explanations/)

## Troubleshooting

### Common Issues

**Cannot access console URL**:
- Verify the URL is correct
- Check your network connection
- Ensure you have the right permissions

**Certificate warnings**:
- Normal for development environments
- Click "Advanced" and proceed to continue

**Login failures**:
- Verify your credentials
- Check with your administrator
- Try different authentication methods

### Getting Help

- Check the [How-To Guides](../how-to-guides/) for specific problems
- Review [Reference documentation](../reference/) for detailed information
- Contact your cluster administrator for access issues

## Summary

You've successfully:
- ✅ Accessed your OpenShift cluster console
- ✅ Explored the console interface
- ✅ Understood the cluster structure
- ✅ Viewed basic resources and workloads
- ✅ Created your first project
- ✅ Learned about hosted clusters (if available)

You're now ready to start working with OpenShift clusters and exploring more advanced features!
