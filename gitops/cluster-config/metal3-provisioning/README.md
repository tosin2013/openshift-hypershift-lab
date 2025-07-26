# Metal3 Provisioning Configuration

This directory contains Kustomize configurations for Metal3 bare metal provisioning in OpenShift clusters.

## Structure

```
metal3-provisioning/
├── base/                           # Base configuration
│   ├── kustomization.yaml         # Base kustomization
│   ├── baremetal-provisioning.yaml # Base Provisioning resource
│   └── agent-service-config.yaml  # AgentServiceConfig for assisted installer
├── overlays/
│   ├── baremetal/                 # Bare metal specific configuration
│   │   ├── kustomization.yaml     # Baremetal overlay
│   │   └── provisioning-patch.yaml # Managed provisioning network config
│   └── aws/                       # AWS specific configuration
│       ├── kustomization.yaml     # AWS overlay
│       ├── provisioning-patch.yaml # Disabled provisioning network config
│       └── metal3-operator-config.yaml # Metal3 operator configuration
└── README.md                      # This file
```

## Usage

### Base Configuration
```bash
kustomize build gitops/cluster-config/metal3-provisioning/base
```

### Bare Metal Environment
```bash
kustomize build gitops/cluster-config/metal3-provisioning/overlays/baremetal
```

### AWS Environment
```bash
kustomize build gitops/cluster-config/metal3-provisioning/overlays/aws
```

## Configuration Details

### Base
- **Provisioning**: Basic Metal3 provisioning configuration with disabled provisioning network
- **AgentServiceConfig**: Storage configuration for assisted installer

### Baremetal Overlay
- **Managed Provisioning Network**: Enables dedicated provisioning network
- **Network Configuration**: Configures provisioning interface, IP, CIDR, and DHCP range
- **Suitable for**: Physical bare metal environments with dedicated provisioning networks

### AWS Overlay
- **Disabled Provisioning Network**: No dedicated provisioning network
- **Metal3 Operator Config**: Includes operator.openshift.io/v1 Metal3 resource
- **Pre-provisioning URLs**: Configures RHCOS image download URLs
- **Suitable for**: AWS environments with bare metal instances (i3.metal, etc.)

## Labels

All resources are labeled with:
- `app.kubernetes.io/name: metal3-provisioning`
- `app.kubernetes.io/component: provisioning`
- `app.kubernetes.io/instance: <overlay-name>` (baremetal or aws)
