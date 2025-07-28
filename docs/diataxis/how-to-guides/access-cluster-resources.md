# How to Access Cluster Resources

This guide shows you how to access various resources in your OpenShift cluster, including APIs, services, applications, and storage resources.

## Prerequisites

- Access to an OpenShift cluster console
- Basic familiarity with OpenShift concepts
- Appropriate permissions for the resources you want to access

## Accessing the OpenShift API

### Using the Web Console

1. **Navigate to your cluster console**:
   ```
   https://console-openshift-console.apps.<cluster-name>.<domain>
   ```

2. **Access API information**:
   - Go to **Administration > Cluster Settings**
   - Click on **Configuration** tab
   - Find **API Server** section for API endpoint details

### Getting API Server URL

The API server URL follows this pattern:
```
https://api.<cluster-name>.<domain>:6443
```

**Example**: `https://api.management-cluster.example.com:6443`

## Accessing Applications and Services

### Through Routes (External Access)

1. **Find application routes**:
   - Navigate to **Networking > Routes**
   - Select your project from the dropdown
   - Click on route URLs to access applications

2. **Route URL pattern**:
   ```
   https://<route-name>-<project>.<cluster-apps-domain>
   ```

### Through Services (Internal Access)

1. **View services**:
   - Go to **Networking > Services**
   - Select your project
   - Note service names and ports

2. **Service DNS pattern** (from within the cluster):
   ```
   <service-name>.<project>.svc.cluster.local:<port>
   ```

## Accessing Storage Resources

### Persistent Volume Claims

1. **View your storage**:
   - Navigate to **Storage > PersistentVolumeClaims**
   - Select your project
   - Click on PVC names to see details

2. **Check storage usage**:
   - View capacity and usage statistics
   - Monitor storage class and access modes
   - Check bound persistent volumes

### Storage Classes

1. **View available storage options**:
   - Go to **Storage > StorageClasses**
   - See available storage types
   - Note default storage class

## Accessing Workload Resources

### Pods and Containers

1. **View running pods**:
   - Navigate to **Workloads > Pods**
   - Select your project
   - Click on pod names for details

2. **Access pod logs**:
   - Click on a pod name
   - Go to **Logs** tab
   - Select container if multiple containers exist

3. **Access pod terminal**:
   - Click on a pod name
   - Go to **Terminal** tab
   - Execute commands directly in the container

### Deployments and Applications

1. **View deployments**:
   - Go to **Workloads > Deployments**
   - Click on deployment names for details
   - Monitor replica status and health

2. **Scale applications**:
   - Click on a deployment
   - Use the scale controls to adjust replicas
   - Monitor scaling progress

## Accessing Configuration Resources

### ConfigMaps

1. **View configuration data**:
   - Navigate to **Workloads > ConfigMaps**
   - Select your project
   - Click on ConfigMap names to view data

2. **Edit configuration**:
   - Click on a ConfigMap
   - Use **Actions > Edit ConfigMap** to modify

### Secrets

1. **View secrets** (with appropriate permissions):
   - Go to **Workloads > Secrets**
   - Select your project
   - Click on secret names for details

2. **Secret types**:
   - **Opaque**: Generic secrets
   - **kubernetes.io/tls**: TLS certificates
   - **kubernetes.io/dockerconfigjson**: Registry credentials

## Accessing Monitoring and Metrics

### Cluster Metrics

1. **View cluster overview**:
   - Go to **Home > Overview**
   - See cluster-wide resource usage
   - Monitor node health and capacity

2. **Detailed metrics**:
   - Navigate to **Observe > Metrics**
   - Use PromQL queries for custom metrics
   - Create custom dashboards

### Application Metrics

1. **Pod-level metrics**:
   - Go to **Workloads > Pods**
   - Click on a pod name
   - View **Metrics** tab for resource usage

2. **Project-level metrics**:
   - Select your project
   - Go to **Home > Overview** (project view)
   - See project resource consumption

## Accessing Logs

### Application Logs

1. **Pod logs**:
   - Navigate to **Workloads > Pods**
   - Click on pod name
   - Go to **Logs** tab

2. **Log filtering**:
   - Use the search box to filter log entries
   - Select specific containers in multi-container pods
   - Download logs for offline analysis

### Cluster Logs

1. **Event logs**:
   - Go to **Home > Events**
   - Filter by namespace, type, or time
   - Monitor cluster-wide events

## Accessing Network Resources

### Network Policies

1. **View network policies**:
   - Navigate to **Networking > NetworkPolicies**
   - Select your project
   - Review ingress and egress rules

### Ingress Controllers

1. **View ingress configuration**:
   - Go to **Networking > Ingress**
   - See routing rules and backends
   - Monitor ingress controller status

## Troubleshooting Access Issues

### Permission Denied

**Problem**: Cannot access certain resources
**Solution**:
1. Check your role-based access control (RBAC) permissions
2. Contact your cluster administrator
3. Verify you're in the correct project/namespace

### Resource Not Found

**Problem**: Cannot find expected resources
**Solution**:
1. Verify you're in the correct project
2. Check if resources exist in other namespaces
3. Confirm resource names and spelling

### Network Connectivity Issues

**Problem**: Cannot reach applications or services
**Solution**:
1. Check route configuration and status
2. Verify service endpoints are healthy
3. Test network policies and firewall rules
4. Confirm DNS resolution

## Security Considerations

### Access Control

- **Use least privilege**: Only request access to resources you need
- **Regular review**: Periodically review your access permissions
- **Secure credentials**: Never share login credentials or tokens

### Network Security

- **Use HTTPS**: Always use secure connections for external access
- **VPN access**: Use VPN when required by your organization
- **Certificate validation**: Verify SSL certificates in production

## Best Practices

### Resource Management

1. **Use projects** to organize related resources
2. **Apply labels** for better resource organization
3. **Monitor usage** to optimize resource allocation
4. **Clean up** unused resources regularly

### Access Patterns

1. **Bookmark frequently accessed resources**
2. **Use browser tabs** to work with multiple resources
3. **Learn keyboard shortcuts** for faster navigation
4. **Use CLI tools** for repetitive tasks (see developer guides)

## Next Steps

- Learn about [creating hosted clusters](create-hosted-cluster.md)
- Explore [forking and customizing](fork-and-customize.md) the lab for your environment
- Understand [bare metal deployment](deploy-to-bare-metal.md)
- Review [HyperShift Lab configuration](../reference/hypershift-lab-configuration.md)

## Summary

You now know how to access:
- ✅ OpenShift APIs and endpoints
- ✅ Applications through routes and services
- ✅ Storage resources and persistent volumes
- ✅ Workload resources like pods and deployments
- ✅ Configuration data in ConfigMaps and Secrets
- ✅ Monitoring metrics and logs
- ✅ Network resources and policies

Use these access patterns to effectively work with your OpenShift cluster resources.
