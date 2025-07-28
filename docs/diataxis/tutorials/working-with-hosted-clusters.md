# Working with Hosted Clusters

This tutorial introduces you to working with hosted clusters in the OpenShift HyperShift Lab environment. You'll learn how to identify, access, and work with multiple OpenShift clusters managed by a single management cluster.

## What You'll Learn

- Understanding the hosted cluster architecture
- How to identify available hosted clusters
- Accessing different hosted cluster consoles
- Switching between cluster contexts
- Understanding cluster relationships and isolation
- Basic operations across multiple clusters

## Prerequisites

- Completed the [Getting Started with Your OpenShift Cluster](getting-started-cluster.md) tutorial
- Access to an OpenShift HyperShift Lab environment with hosted clusters
- Basic familiarity with the OpenShift console

## Understanding Hosted Clusters

### What Are Hosted Clusters?

Hosted clusters are lightweight OpenShift clusters where:
- **Control plane** runs as pods on a management cluster
- **Worker nodes** can run on various platforms (KubeVirt VMs, AWS instances, etc.)
- **Each cluster** is fully isolated and independent
- **Management** is centralized through the management cluster

### Architecture Overview

```
Management Cluster (management-cluster.example.com)
├── Control Plane for dev-cluster-01
├── Control Plane for dev-cluster-02
├── Control Plane for example-instance
└── Control Plane for cluster-template

Each hosted cluster has its own:
├── Console URL
├── API endpoint
├── Worker nodes
└── Complete OpenShift functionality
```

## Step 1: Identify Available Hosted Clusters

### From the Management Cluster Console

1. **Access the management cluster console**:
   ```
   https://console-openshift-console.apps.management-cluster.example.com
   ```

2. **Navigate to the clusters view**:
   - Look for "Hosted Clusters" or "HyperShift" sections
   - Check the `clusters` namespace for hosted cluster resources

3. **Available hosted clusters** in this environment:
   - `dev-cluster-01` - Development environment
   - `dev-cluster-02` - Additional development environment  
   - `example-instance` - Example/template cluster
   - `cluster-template` - Template cluster

### Understanding Cluster URLs

Hosted cluster consoles follow this pattern:
```
https://console-openshift-console.apps.<hosted-cluster-name>.apps.<management-cluster>.<domain>
```

**Examples**:
- dev-cluster-01: `https://console-openshift-console.apps.dev-cluster-01.apps.management-cluster.example.com`
- dev-cluster-02: `https://console-openshift-console.apps.dev-cluster-02.apps.management-cluster.example.com`

## Step 2: Access Your First Hosted Cluster

### Accessing dev-cluster-01

1. **Open a new browser tab** (keep the management cluster tab open)

2. **Navigate to the hosted cluster console**:
   ```
   https://console-openshift-console.apps.dev-cluster-01.apps.management-cluster.example.com
   ```

3. **Log in using the same credentials** as the management cluster

4. **Notice the differences**:
   - Different cluster name in the interface
   - Separate set of projects and resources
   - Independent cluster status and metrics

### Exploring the Hosted Cluster

1. **Check the cluster overview** (Home > Overview):
   - Note the cluster name: `dev-cluster-01`
   - Different resource utilization
   - Separate node information

2. **View the nodes** (Compute > Nodes):
   - Hosted clusters typically have fewer nodes
   - Nodes may be virtual machines (KubeVirt) or cloud instances

3. **Explore projects**:
   - Each hosted cluster has its own set of projects
   - System projects are independent from the management cluster

## Step 3: Work Across Multiple Clusters

### Opening Multiple Cluster Consoles

1. **Use browser tabs** to keep multiple clusters open:
   - Tab 1: Management cluster
   - Tab 2: dev-cluster-01
   - Tab 3: dev-cluster-02

2. **Bookmark frequently used clusters** for easy access

### Understanding Cluster Isolation

Each hosted cluster is completely isolated:

- **Resources**: Pods, services, and storage are separate
- **Users**: User access is managed independently
- **Networking**: Each cluster has its own network configuration
- **Storage**: Persistent volumes are cluster-specific

### Practical Exercise: Compare Clusters

1. **Create a project in dev-cluster-01**:
   - Name: `test-isolation`
   - Deploy a simple application

2. **Switch to dev-cluster-02**:
   - Notice the project doesn't exist
   - Create a project with the same name
   - Deploy a different application

3. **Verify isolation**:
   - Applications in each cluster are completely separate
   - Same project names can exist in different clusters
   - Resources don't interfere with each other

## Step 4: Understanding Cluster Management

### Management Cluster Responsibilities

The management cluster handles:
- **Hosted cluster lifecycle** (creation, deletion, updates)
- **Control plane hosting** (API servers, etcd, controllers)
- **Resource scheduling** for control plane components
- **Networking coordination** between clusters

### Hosted Cluster Independence

Each hosted cluster provides:
- **Full OpenShift functionality** (same as standalone clusters)
- **Independent workload scheduling** on its worker nodes
- **Separate resource quotas** and limits
- **Individual monitoring** and logging

## Step 5: Best Practices for Multi-Cluster Work

### Organization Strategies

1. **Use clear naming conventions**:
   - `dev-*` for development clusters
   - `staging-*` for staging environments
   - `prod-*` for production workloads

2. **Bookmark cluster consoles** with descriptive names:
   - "HyperShift Management"
   - "Dev Cluster 01"
   - "Staging Environment"

3. **Use browser profiles** for different environments:
   - Development profile for dev clusters
   - Production profile for prod access

### Workflow Recommendations

1. **Start with the management cluster** to get an overview
2. **Switch to specific hosted clusters** for detailed work
3. **Use the management cluster** for cluster lifecycle operations
4. **Work in hosted clusters** for application deployment and management

## Step 6: Common Operations

### Deploying Applications

1. **Choose the appropriate cluster** for your workload:
   - Development work → dev-cluster-01 or dev-cluster-02
   - Testing → staging clusters
   - Production → production clusters

2. **Deploy as you would in any OpenShift cluster**:
   - Create projects
   - Deploy applications
   - Configure networking and storage

### Monitoring Multiple Clusters

1. **Use the management cluster** for overall health monitoring
2. **Access individual clusters** for detailed application monitoring
3. **Set up centralized monitoring** if needed (advanced topic)

## Troubleshooting

### Common Issues

**Cannot access hosted cluster console**:
- Verify the URL pattern is correct
- Check that the hosted cluster is running
- Ensure network connectivity

**Different behavior between clusters**:
- This is expected - each cluster is independent
- Check cluster-specific configuration
- Verify resource availability in each cluster

**Confusion about which cluster you're in**:
- Check the cluster name in the console header
- Look at the URL to identify the cluster
- Use browser tab titles to stay organized

## Next Steps

Now that you understand hosted clusters:

1. **Try deploying applications** in different clusters
2. **Explore cluster-specific features** in each environment
3. **Learn about cluster management** in the [How-To Guides](../how-to-guides/)
4. **Understand the architecture** in [Architecture Overview](../explanations/architecture-overview.md)

## Summary

You've successfully:
- ✅ Understood hosted cluster architecture
- ✅ Identified available hosted clusters
- ✅ Accessed multiple cluster consoles
- ✅ Explored cluster isolation and independence
- ✅ Learned best practices for multi-cluster work
- ✅ Performed basic operations across clusters

You're now ready to work effectively with multiple OpenShift clusters in the HyperShift Lab environment!
