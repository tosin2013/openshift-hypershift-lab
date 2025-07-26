# Metal3 Provisioning Overlays

This directory contains environment-specific overlays for Metal3 bare metal provisioning configurations.

## Structure

```
overlays/
├── baremetal/                    # Physical bare metal environments
│   ├── kustomization.yaml
│   └── provisioning-patch.yaml
├── aws-base/                     # Base AWS configuration (shared)
│   ├── kustomization.yaml
│   ├── provisioning-patch.yaml
│   ├── metal3-operator-config.yaml
│   ├── ingresscontroller-nlb.yaml
│   └── assisted-image-service-route-patch.yaml
├── aws-dev/                      # AWS Development environment
│   ├── kustomization.yaml
│   └── domain-patch.yaml        # dev.example.com
├── aws-staging/                  # AWS Staging environment
│   ├── kustomization.yaml
│   └── domain-patch.yaml        # staging.example.com
├── aws-prod/                     # AWS Production environment
│   ├── kustomization.yaml
│   └── domain-patch.yaml        # prod.example.com
└── aws/                          # Legacy AWS overlay (deprecated)
```

## Environment-Specific Configurations

### Bare Metal
- **Path**: `overlays/baremetal`
- **Use Case**: Physical bare metal environments
- **Features**: Managed provisioning network, dedicated provisioning interface

### AWS Development
- **Path**: `overlays/aws-dev`
- **Domain**: `nlb-apps.dev.example.com`
- **Use Case**: Development and testing environments
- **Labels**: `environment: dev`

### AWS Staging
- **Path**: `overlays/aws-staging`
- **Domain**: `nlb-apps.staging.example.com`
- **Use Case**: Pre-production testing and validation
- **Labels**: `environment: staging`

### AWS Production
- **Path**: `overlays/aws-prod`
- **Domain**: `nlb-apps.prod.example.com`
- **Use Case**: Production workloads
- **Labels**: `environment: prod`

## Usage Examples

### Development Environment
```bash
kustomize build gitops/cluster-config/metal3-provisioning/overlays/aws-dev
```

### Staging Environment
```bash
kustomize build gitops/cluster-config/metal3-provisioning/overlays/aws-staging
```

### Production Environment
```bash
kustomize build gitops/cluster-config/metal3-provisioning/overlays/aws-prod
```

## ArgoCD Application Configuration

Update your ArgoCD Application to point to the appropriate overlay:

```yaml
# For development
spec:
  source:
    path: gitops/cluster-config/metal3-provisioning/overlays/aws-dev

# For staging
spec:
  source:
    path: gitops/cluster-config/metal3-provisioning/overlays/aws-staging

# For production
spec:
  source:
    path: gitops/cluster-config/metal3-provisioning/overlays/aws-prod
```

## Customizing Domains

To use your own domains, update the `domain-patch.yaml` files in each environment:

1. **Development**: Edit `aws-dev/domain-patch.yaml`
2. **Staging**: Edit `aws-staging/domain-patch.yaml`
3. **Production**: Edit `aws-prod/domain-patch.yaml`

Replace `example.com` with your actual domain name.

## Benefits of This Structure

- **Environment Isolation**: Each environment has its own domain configuration
- **Scalability**: Easy to add new environments (aws-test, aws-dr, etc.)
- **Maintainability**: Shared base configuration with environment-specific patches
- **GitOps Ready**: All configurations are committed to git for ArgoCD deployment
