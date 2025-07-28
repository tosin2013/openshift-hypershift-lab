# HyperShift Ingress Wildcard Policy Fix

## Overview

HyperShift hosted clusters create nested subdomain patterns that require special ingress controller configuration to work properly. This document describes the critical fix needed for hosted cluster console access.

## Problem Description

### Nested Subdomain Issue

HyperShift hosted clusters create console URLs with nested subdomain patterns:
```
console-openshift-console.apps.HOSTED-CLUSTER-NAME.apps.MANAGEMENT-CLUSTER-DOMAIN
```

Example:
```
console-openshift-console.apps.manual-test-cluster.apps.tosins-cluster.sandbox1271.opentlc.com
```

### Default Ingress Controller Limitation

By default, OpenShift ingress controllers do not allow wildcard routes with nested patterns, causing hosted cluster console routes to be rejected.

### Symptoms

- Hosted cluster console operator shows `Degraded: True`
- Console operator error: `RouteHealthAvailable: failed to GET route`
- Hosted cluster status shows `ClusterVersionSucceeding: False`
- Console routes are not created or accessible

## Solution

### Required Configuration

Configure the management cluster's ingress controller to allow wildcard routes:

```bash
oc patch ingresscontroller -n openshift-ingress-operator default --type=json \
  -p '[{ "op": "add", "path": "/spec/routeAdmission", "value": {"wildcardPolicy": "WildcardsAllowed"}}]'
```

### Verification

Check that the wildcard policy is applied:

```bash
oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.spec.routeAdmission.wildcardPolicy}'
```

Expected output: `WildcardsAllowed`

### Result

After applying this fix:
- ✅ Hosted cluster console routes are accepted
- ✅ Console operator becomes Available
- ✅ ClusterVersion progresses successfully
- ✅ Hosted cluster consoles are accessible

## Implementation

### Automated Setup

This fix is now included in the `setup-hosted-control-planes.sh` script:

```bash
# Configure ingress controller wildcard policy for hosted clusters
configure_wildcard_policy() {
    # Check current policy and apply if needed
    oc patch ingresscontroller -n openshift-ingress-operator default --type=json \
       -p '[{ "op": "add", "path": "/spec/routeAdmission", "value": {"wildcardPolicy": "WildcardsAllowed"}}]'
}
```

### Manual Application

For existing clusters, apply the patch manually:

1. **Check current configuration**:
   ```bash
   oc get ingresscontroller default -n openshift-ingress-operator -o yaml | grep -A 2 routeAdmission
   ```

2. **Apply the fix**:
   ```bash
   oc patch ingresscontroller -n openshift-ingress-operator default --type=json \
     -p '[{ "op": "add", "path": "/spec/routeAdmission", "value": {"wildcardPolicy": "WildcardsAllowed"}}]'
   ```

3. **Verify hosted cluster console**:
   ```bash
   KUBECONFIG=/path/to/hosted-cluster-kubeconfig oc get co console
   ```

## References

- **Source**: [HyperShift KubeVirt Documentation](https://hypershift-docs.netlify.app/how-to/kubevirt/create-kubevirt-cluster/)
- **Related**: OpenShift Ingress Controller wildcard route policies
- **Issue**: Nested subdomain route admission in HyperShift environments

## Notes

- This configuration is **required** for all HyperShift deployments using nested subdomains
- The fix applies to the **management cluster** ingress controller
- No restart of ingress controller pods is required
- The setting persists across cluster reboots and upgrades
