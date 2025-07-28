# Managing Workloads Tutorial

This tutorial teaches you how to deploy, manage, and monitor applications (workloads) in your OpenShift cluster. You'll learn the fundamental concepts and practical skills needed to run applications successfully.

## What You'll Learn

- How to create and manage projects for organizing workloads
- Deploying applications from container images
- Understanding pods, deployments, and services
- Scaling applications up and down
- Monitoring application health and performance
- Managing application configuration and secrets
- Exposing applications to external users

## Prerequisites

- Completed [Getting Started with Your OpenShift Cluster](getting-started-cluster.md)
- Access to an OpenShift cluster with permissions to create projects
- Basic understanding of containers and web applications

## Step 1: Create a Project for Your Workloads

Projects in OpenShift organize and isolate your applications.

### Create Your First Project

1. **Access the OpenShift console** and log in
2. **Click the project dropdown** at the top of the page
3. **Select "Create Project"**
4. **Fill in the project details**:
   - **Name**: `my-workloads`
   - **Display Name**: `My Application Workloads`
   - **Description**: `Learning to manage applications in OpenShift`
5. **Click "Create"**

### Verify Project Creation

1. **Check that you're in the new project** - the project name should appear in the dropdown
2. **Navigate to Home > Overview** to see the empty project dashboard
3. **Note the project namespace** - it matches your project name

## Step 2: Deploy Your First Application

Let's deploy a simple web application to learn the basics.

### Deploy from Container Image

1. **Navigate to +Add** in the left sidebar
2. **Click "Container Image"**
3. **Enter the image details**:
   - **Image name**: `quay.io/redhattraining/hello-world-nginx:v1.0`
   - **Application name**: `hello-world-app`
   - **Name**: `hello-world`
4. **Leave other settings as default**
5. **Click "Create"**

### Watch the Deployment

1. **Go to Topology view** (Developer perspective)
2. **Watch the deployment progress**:
   - Blue ring indicates building/deploying
   - Green ring indicates running successfully
   - Red indicates errors

3. **Click on the deployment** to see details:
   - Pod status and count
   - Resource usage
   - Events and logs

## Step 3: Understand Your Application Components

### Explore the Created Resources

1. **Navigate to Workloads > Deployments**:
   - See your `hello-world` deployment
   - Note replica count and status
   - Click on the deployment name for details

2. **Check Workloads > Pods**:
   - See the running pod(s)
   - Click on a pod name to see details
   - Explore the **Logs** and **Terminal** tabs

3. **View Networking > Services**:
   - See the service created for your application
   - Note the internal cluster IP and ports
   - Understand how services provide stable networking

### Understanding the Relationship

```
Deployment (hello-world)
    ├── ReplicaSet (manages pod replicas)
    │   └── Pod (hello-world-xxx-yyy)
    │       └── Container (nginx)
    └── Service (hello-world)
        └── Routes traffic to healthy pods
```

## Step 4: Scale Your Application

Learn how to handle increased load by scaling your application.

### Scale Up Using the Console

1. **Go to Workloads > Deployments**
2. **Click on your `hello-world` deployment**
3. **Find the "Replicas" section**
4. **Click the up arrow** to increase replicas to 3
5. **Watch the scaling process**:
   - New pods being created
   - Load balancing across pods
   - All pods showing as ready

### Scale Down

1. **Reduce replicas back to 1** using the down arrow
2. **Observe the scale-down process**:
   - Excess pods being terminated gracefully
   - Service continues to work during scaling

### Scale Using YAML

1. **Click on the deployment name**
2. **Go to the YAML tab**
3. **Find the `spec.replicas` field**
4. **Change the value** (e.g., to 2)
5. **Click "Save"**
6. **Watch the changes take effect**

## Step 5: Expose Your Application to External Users

Make your application accessible from outside the cluster.

### Create a Route

1. **Navigate to Networking > Routes**
2. **Click "Create Route"**
3. **Configure the route**:
   - **Name**: `hello-world-route`
   - **Service**: Select `hello-world`
   - **Target Port**: `8080 → 8080 (TCP)`
   - **Security**: Check "Secure Route" for HTTPS
4. **Click "Create"**

### Test External Access

1. **Find your route URL** in the Routes list
2. **Click on the URL** to open in a new tab
3. **Verify the application loads** - you should see the hello world page
4. **Note the HTTPS certificate** (may show warnings in development)

### Understanding Routes

Routes provide external access to services:
```
Internet → Route (hello-world-route) → Service (hello-world) → Pods
```

## Step 6: Monitor Application Health

Learn to monitor your application's performance and health.

### View Application Metrics

1. **Go to Workloads > Deployments**
2. **Click on your deployment**
3. **Navigate to the Metrics tab**:
   - CPU usage over time
   - Memory consumption
   - Network traffic
   - Pod restart counts

### Check Application Logs

1. **Go to Workloads > Pods**
2. **Click on a pod name**
3. **Navigate to the Logs tab**:
   - View real-time application logs
   - Filter logs by time or search terms
   - Download logs for analysis

### Monitor Events

1. **Navigate to Home > Events**
2. **Filter by your project**
3. **Review recent events**:
   - Pod creation and deletion
   - Scaling events
   - Error conditions

## Step 7: Manage Application Configuration

Learn to configure applications without rebuilding container images.

### Create a ConfigMap

1. **Navigate to Workloads > ConfigMaps**
2. **Click "Create ConfigMap"**
3. **Configure the ConfigMap**:
   - **Name**: `app-config`
   - **Key**: `message`
   - **Value**: `Hello from OpenShift!`
4. **Click "Create"**

### Create a Secret

1. **Navigate to Workloads > Secrets**
2. **Click "Create" > "Key/value secret"**
3. **Configure the secret**:
   - **Secret name**: `app-secrets`
   - **Key**: `api-key`
   - **Value**: `secret-api-key-123`
4. **Click "Create"**

### Use Configuration in Applications

For future deployments, you can:
- Mount ConfigMaps as environment variables or files
- Mount Secrets as environment variables or files
- Update configuration without redeploying applications

## Step 8: Application Lifecycle Management

Learn to update and manage application versions.

### Update Application Image

1. **Go to Workloads > Deployments**
2. **Click on your deployment**
3. **Navigate to the YAML tab**
4. **Find the container image specification**
5. **Change the image tag** (e.g., from `v1.0` to `v1.1`)
6. **Click "Save"**
7. **Watch the rolling update process**

### Rollback if Needed

1. **Go to the deployment details**
2. **Click on "History" tab**
3. **See previous deployment versions**
4. **Click "Rollback" on a previous version** if needed

## Step 9: Clean Up Resources

Learn to properly clean up when you're done.

### Delete Individual Resources

1. **Delete the route**: Networking > Routes > Actions > Delete
2. **Delete the deployment**: Workloads > Deployments > Actions > Delete
3. **Delete ConfigMaps and Secrets**: Workloads > ConfigMaps/Secrets > Actions > Delete

### Delete the Entire Project

1. **Go to Home > Projects**
2. **Find your project** (`my-workloads`)
3. **Click the three dots** (Actions menu)
4. **Select "Delete Project"**
5. **Type the project name** to confirm
6. **Click "Delete"**

## Common Workload Patterns

### Web Applications
- Use Deployments for stateless web apps
- Create Services for internal communication
- Create Routes for external access
- Use ConfigMaps for configuration

### Databases
- Use StatefulSets for databases
- Use PersistentVolumeClaims for data storage
- Use Secrets for database credentials
- Consider backup strategies

### Background Jobs
- Use Jobs for one-time tasks
- Use CronJobs for scheduled tasks
- Use appropriate resource limits
- Monitor job completion

## Troubleshooting Common Issues

### Pod Won't Start
1. **Check pod events**: Workloads > Pods > Pod Name > Events
2. **Review pod logs**: Logs tab
3. **Verify image name and availability**
4. **Check resource limits and quotas**

### Application Not Accessible
1. **Verify route configuration**
2. **Check service endpoints**
3. **Confirm pod health and readiness**
4. **Test internal service connectivity**

### Performance Issues
1. **Monitor resource usage**: Metrics tab
2. **Check for resource limits**
3. **Review application logs for errors**
4. **Consider scaling up replicas**

## Next Steps

Now that you understand workload management:

1. **Explore advanced deployment strategies** (blue-green, canary)
2. **Learn about persistent storage** for stateful applications
3. **Study application monitoring and alerting**
4. **Practice with different application types**
5. **Learn about CI/CD pipelines** for automated deployments

## Summary

You've successfully learned to:
- ✅ Create projects to organize workloads
- ✅ Deploy applications from container images
- ✅ Understand pods, deployments, and services
- ✅ Scale applications up and down
- ✅ Expose applications externally with routes
- ✅ Monitor application health and performance
- ✅ Manage configuration with ConfigMaps and Secrets
- ✅ Update applications and manage versions
- ✅ Clean up resources properly

You now have the fundamental skills to deploy and manage applications in OpenShift. These concepts apply to any OpenShift cluster, whether it's a foundation cluster or a hosted cluster in the HyperShift Lab environment.
