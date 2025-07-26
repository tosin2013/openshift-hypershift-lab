# AWS Overlay for Metal3 Provisioning

This overlay configures Metal3 provisioning for AWS environments with central infrastructure management support.

## Components

### Core Resources
- **Provisioning**: Configured with disabled provisioning network for AWS
- **AgentServiceConfig**: Storage configuration for assisted installer
- **Metal3 Operator**: operator.openshift.io/v1 Metal3 resource

### AWS-Specific Infrastructure Management
- **IngressController with NLB**: Network Load Balancer for assisted-image-service
- **Route Configuration**: Routes assisted-image-service through NLB

## Usage

1. **Replace Domain Placeholder**: Before applying, replace `DOMAIN_PLACEHOLDER` in the generated YAML with your actual domain:
   ```bash
   kustomize build . | sed 's/DOMAIN_PLACEHOLDER/yourdomain/g' | oc apply -f -
   ```

2. **Direct Application**:
   ```bash
   kustomize build gitops/cluster-config/metal3-provisioning/overlays/aws
   ```

## Configuration Details

### IngressController
- **Type**: AWS Network Load Balancer (NLB)
- **Domain**: `nlb-apps.<yourdomain>.com`
- **Route Selector**: Routes with `router-type: nlb` label

### Assisted Image Service Route
- **Host**: `assisted-image-service-multicluster-engine.nlb-apps.<yourdomain>.com`
- **Labels**: `router-type: nlb` for NLB routing

## Prerequisites

- OpenShift cluster running on AWS
- MultiCluster Engine operator installed
- Appropriate AWS permissions for NLB creation

## Post-Deployment

After applying this configuration:

1. Verify the IngressController is created:
   ```bash
   oc get ingresscontroller -n openshift-ingress-operator
   ```

2. Check the assisted-image-service route:
   ```bash
   oc get route assisted-image-service -n multicluster-engine
   ```

3. Verify pods are healthy:
   ```bash
   oc get pods -n multicluster-engine | grep assist
   ```
