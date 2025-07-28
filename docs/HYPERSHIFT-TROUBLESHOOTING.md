# HyperShift Troubleshooting Guide

Quick reference for common HyperShift hosted cluster issues and solutions.

## 🚨 Critical Fixes

### 1. Ingress Wildcard Policy (REQUIRED)

**Problem**: Hosted cluster console operator degraded, routes not accessible
**Cause**: Nested subdomain routes rejected by default ingress policy
**Solution**: Enable wildcard policy on management cluster

```bash
# Apply the fix
oc patch ingresscontroller -n openshift-ingress-operator default --type=json \
  -p '[{ "op": "add", "path": "/spec/routeAdmission", "value": {"wildcardPolicy": "WildcardsAllowed"}}]'

# Verify
oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.spec.routeAdmission.wildcardPolicy}'
```

**Reference**: [Detailed Fix Documentation](hypershift-ingress-wildcard-policy-fix.md)

### 2. External DNS Domain Filter

**Problem**: Hosted cluster DNS records not created
**Cause**: External DNS domain filter too restrictive
**Solution**: Use broader domain scope

```bash
# Check current domain filter
oc get secret hypershift-operator-external-dns-credentials -n local-cluster \
  -o jsonpath='{.data.domain-filter}' | base64 -d

# Should be: sandbox1271.opentlc.com (not metal-cluster.sandbox1271.opentlc.com)
```

### 3. Node Sizing Requirements

**Problem**: Hosted cluster operators failing, resource constraints
**Cause**: Insufficient node resources
**Solution**: Ensure proper node sizing

**Minimum Requirements**:
- CPU: 5.5 vCPU per hosted control plane
- Memory: 19 GiB per hosted control plane
- Storage: 8 GiB for etcd (3 PVs)

**Recommended Node Specs**:
- CPU: 8 cores per node
- Memory: 24Gi per node
- Storage: 120Gi per node

## 🔍 Diagnostic Commands

### Hosted Cluster Status
```bash
# List all hosted clusters
oc get hostedclusters -A

# Check specific cluster status
oc get hostedcluster CLUSTER_NAME -n clusters -o yaml

# Check hosted cluster conditions
oc get hostedcluster CLUSTER_NAME -n clusters -o jsonpath='{.status.conditions[*].type}'
```

### Console Operator Issues
```bash
# Get hosted cluster kubeconfig
oc get secret CLUSTER_NAME-admin-kubeconfig -n clusters -o jsonpath='{.data.kubeconfig}' | base64 -d > /tmp/cluster-kubeconfig

# Check console operator in hosted cluster
KUBECONFIG=/tmp/cluster-kubeconfig oc get co console

# Check console operator details
KUBECONFIG=/tmp/cluster-kubeconfig oc describe co console
```

### Certificate Issues
```bash
# Check management cluster certificate
echo | openssl s_client -connect console-openshift-console.apps.MANAGEMENT-CLUSTER:443 2>/dev/null | openssl x509 -noout -text | grep -A 5 "Subject Alternative Name"

# Check hosted cluster certificate
echo | openssl s_client -connect console-openshift-console.apps.HOSTED-CLUSTER.apps.MANAGEMENT-CLUSTER:443 2>/dev/null | openssl x509 -noout -text | grep -A 5 "Subject Alternative Name"
```

### External DNS Issues
```bash
# Check External DNS logs
oc logs -f deployment/external-dns -n hypershift

# Check DNS records created
oc logs deployment/external-dns -n hypershift | grep "CREATE\|UPDATE\|DELETE"

# Verify Route53 records
aws route53 list-resource-record-sets --hosted-zone-id ZONE_ID --query 'ResourceRecordSets[?Type==`A`]'
```

## 🛠️ Common Solutions

### Reset Hosted Cluster
```bash
# Delete hosted cluster
oc delete hostedcluster CLUSTER_NAME -n clusters

# Clean up nodepool
oc delete nodepool CLUSTER_NAME -n clusters

# Redeploy with fixes applied
```

### Force Certificate Refresh
```bash
# Delete certificate secret (if using cert-manager)
oc delete secret hypershift-wildcard-cert -n openshift-ingress

# Certificate will be automatically recreated
```

### External DNS Restart
```bash
# Restart External DNS
oc rollout restart deployment/external-dns -n hypershift

# Check new logs
oc logs -f deployment/external-dns -n hypershift
```

## 📚 References

- [HyperShift Ingress Wildcard Policy Fix](hypershift-ingress-wildcard-policy-fix.md)
- [Research Documentation](research-07-26-2025.md)
- [HyperShift Official Docs](https://hypershift-docs.netlify.app/)
- [OpenShift Ingress Controller](https://docs.openshift.com/container-platform/latest/networking/ingress-operator.html)

## 🎯 Quick Checklist

Before deploying hosted clusters, ensure:

- [ ] Ingress wildcard policy configured (`WildcardsAllowed`)
- [ ] External DNS domain filter uses broad scope
- [ ] Management cluster nodes properly sized (8 cores, 24Gi memory)
- [ ] Route53 hosted zone accessible
- [ ] AWS credentials have Route53 permissions
- [ ] setup-hosted-control-planes.sh script run successfully
