# Configuration Reference

This document provides a comprehensive reference for all configuration options available in the Modular Hosted Clusters framework.

## Table of Contents

- [Instance Configuration](#instance-configuration)
- [Base Configuration Parameters](#base-configuration-parameters)
- [Platform-Specific Configuration](#platform-specific-configuration)
- [Network Configuration](#network-configuration)
- [Resource Configuration](#resource-configuration)
- [Security Configuration](#security-configuration)
- [Availability Configuration](#availability-configuration)

## Instance Configuration

### ConfigMap Generator Parameters

Each hosted cluster instance uses a `configMapGenerator` to define its configuration. Here are all available parameters:

#### Core Identity Parameters

| Parameter | Type | Default | Description | Required |
|-----------|------|---------|-------------|----------|
| `CLUSTER_NAME` | string | - | DNS-compatible cluster name (max 63 chars) | ✅ |
| `CLUSTER_NAMESPACE` | string | `clusters` | Namespace where cluster resources are created | ❌ |
| `ENVIRONMENT` | string | `dev` | Environment type (dev, staging, prod, lab, test) | ❌ |
| `CLUSTERSET` | string | `default` | OpenShift cluster set name | ❌ |

**Example:**
```yaml
configMapGenerator:
  - name: cluster-config
    literals:
      - CLUSTER_NAME=my-cluster
      - CLUSTER_NAMESPACE=clusters
      - ENVIRONMENT=prod
      - CLUSTERSET=production
```

#### Release Configuration

| Parameter | Type | Default | Description | Required |
|-----------|------|---------|-------------|----------|
| `RELEASE_IMAGE` | string | `quay.io/openshift-release-dev/ocp-release:4.18.20-x86_64` | OpenShift release image | ❌ |

**Example:**
```yaml
- RELEASE_IMAGE=quay.io/openshift-release-dev/ocp-release:4.19.0-x86_64
```

#### DNS and Domain Configuration

| Parameter | Type | Default | Description | Required |
|-----------|------|---------|-------------|----------|
| `BASE_DOMAIN` | string | - | Base domain for the cluster | ✅ |
| `BASE_DOMAIN_PASSTHROUGH` | boolean | `true` | Enable base domain passthrough | ❌ |

**Example:**
```yaml
- BASE_DOMAIN=prod.example.com
- BASE_DOMAIN_PASSTHROUGH=true
```

## Base Configuration Parameters

### Network Configuration

| Parameter | Type | Default | Description | Required |
|-----------|------|---------|-------------|----------|
| `CLUSTER_NETWORK_CIDR` | string | `10.132.0.0/14` | Cluster network CIDR | ❌ |
| `SERVICE_NETWORK_CIDR` | string | `172.31.0.0/16` | Service network CIDR | ❌ |
| `NETWORK_TYPE` | string | `OVNKubernetes` | Network plugin type | ❌ |

**Valid Network Types:**
- `OVNKubernetes` (recommended)
- `OpenShiftSDN` (deprecated)

**Example:**
```yaml
- CLUSTER_NETWORK_CIDR=10.128.0.0/14
- SERVICE_NETWORK_CIDR=172.30.0.0/16
- NETWORK_TYPE=OVNKubernetes
```

### Security Configuration

#### Authentication and Access Control

| Parameter | Type | Default | Description | Required |
|-----------|------|---------|-------------|----------|
| `PULL_SECRET_NAME` | string | `pullsecret-cluster` | Pull secret name | ❌ |
| `SSH_KEY_NAME` | string | `sshkey-cluster` | SSH key secret name | ❌ |
| `INFRA_CREDENTIALS_NAME` | string | `{CLUSTER_NAME}-infra-credentials` | Infrastructure credentials secret | ❌ |
| `INFRA_NAMESPACE` | string | `clusters-{CLUSTER_NAME}` | Infrastructure namespace | ❌ |

#### SSL/TLS Security Requirements

**MANDATORY REQUIREMENTS:**
- **SSL/TLS Encryption**: All cluster endpoints MUST use secure SSL/TLS encryption
- **Certificate Authority**: Certificates MUST be issued by trusted CA (Let's Encrypt, AWS Certificate Manager, or enterprise CA)
- **HTTPS Enforcement**: All web interfaces and API endpoints MUST enforce HTTPS-only access
- **TLS Version**: MUST support TLS 1.2 or higher
- **Certificate Validation**: Certificates MUST be valid, trusted, and not expired

**Security Standards:**
- **Cipher Suites**: Only strong, modern cipher suites allowed
- **Certificate Chain**: Complete and valid certificate chain required
- **Domain Validation**: Certificates must match cluster domain names
- **Automatic Renewal**: Certificate lifecycle management with automatic renewal
- **Compliance**: Must meet enterprise security standards

**Example:**
```yaml
- PULL_SECRET_NAME=my-pull-secret
- SSH_KEY_NAME=my-ssh-key
- INFRA_CREDENTIALS_NAME=my-cluster-infra-creds
- INFRA_NAMESPACE=clusters-my-cluster
# SSL/TLS is automatically configured and enforced
```

### Service Publishing Configuration

| Parameter | Type | Default | Description | Required |
|-----------|------|---------|-------------|----------|
| `API_SERVER_PUBLISHING_TYPE` | string | `LoadBalancer` | API server publishing strategy | ❌ |
| `OAUTH_SERVER_PUBLISHING_TYPE` | string | `Route` | OAuth server publishing strategy | ❌ |
| `OIDC_PUBLISHING_TYPE` | string | `Route` | OIDC publishing strategy | ❌ |
| `KONNECTIVITY_PUBLISHING_TYPE` | string | `Route` | Konnectivity publishing strategy | ❌ |
| `IGNITION_PUBLISHING_TYPE` | string | `Route` | Ignition publishing strategy | ❌ |

**Valid Publishing Types:**
- `LoadBalancer` - External load balancer
- `Route` - OpenShift route
- `NodePort` - Node port service

**Example:**
```yaml
- API_SERVER_PUBLISHING_TYPE=LoadBalancer
- OAUTH_SERVER_PUBLISHING_TYPE=Route
- OIDC_PUBLISHING_TYPE=Route
- KONNECTIVITY_PUBLISHING_TYPE=Route
- IGNITION_PUBLISHING_TYPE=Route
```

### Availability Configuration

| Parameter | Type | Default | Description | Required |
|-----------|------|---------|-------------|----------|
| `CONTROLLER_AVAILABILITY_POLICY` | string | `HighlyAvailable` | Controller availability policy | ❌ |
| `INFRASTRUCTURE_AVAILABILITY_POLICY` | string | `HighlyAvailable` | Infrastructure availability policy | ❌ |

**Valid Availability Policies:**
- `HighlyAvailable` - Multiple replicas for high availability
- `SingleReplica` - Single replica (for development/testing)

**Example:**
```yaml
- CONTROLLER_AVAILABILITY_POLICY=HighlyAvailable
- INFRASTRUCTURE_AVAILABILITY_POLICY=HighlyAvailable
```

## NodePool Configuration

### Basic NodePool Parameters

| Parameter | Type | Default | Description | Required |
|-----------|------|---------|-------------|----------|
| `NODEPOOL_NAME` | string | `pool-1` | NodePool name suffix | ❌ |
| `NODEPOOL_TYPE` | string | `worker` | NodePool type label | ❌ |
| `NODEPOOL_REPLICAS` | integer | `3` | Number of worker nodes | ❌ |

**Example:**
```yaml
- NODEPOOL_NAME=workers
- NODEPOOL_TYPE=worker
- NODEPOOL_REPLICAS=5
```

### Resource Configuration

| Parameter | Type | Default | Description | Required |
|-----------|------|---------|-------------|----------|
| `NODEPOOL_MEMORY` | string | `8Gi` | Memory per worker node | ❌ |
| `NODEPOOL_CORES` | integer | `4` | CPU cores per worker node | ❌ |
| `VOLUME_TYPE` | string | `Persistent` | Root volume type | ❌ |
| `VOLUME_SIZE` | string | `32Gi` | Root volume size | ❌ |
| `STORAGE_CLASS` | string | `gp3-csi` | Storage class name | ❌ |

**Valid Volume Types:**
- `Persistent` - Persistent volume
- `Ephemeral` - Ephemeral volume

**Example:**
```yaml
- NODEPOOL_MEMORY=16Gi
- NODEPOOL_CORES=8
- VOLUME_TYPE=Persistent
- VOLUME_SIZE=100Gi
- STORAGE_CLASS=fast-ssd
```

### Management Configuration

| Parameter | Type | Default | Description | Required |
|-----------|------|---------|-------------|----------|
| `UPGRADE_TYPE` | string | `Replace` | Node upgrade strategy | ❌ |
| `AUTO_REPAIR` | boolean | `false` | Enable automatic node repair | ❌ |
| `NODE_DRAIN_TIMEOUT` | string | `0s` | Node drain timeout | ❌ |

**Valid Upgrade Types:**
- `Replace` - Replace nodes during upgrades
- `InPlace` - Upgrade nodes in place

**Example:**
```yaml
- UPGRADE_TYPE=Replace
- AUTO_REPAIR=true
- NODE_DRAIN_TIMEOUT=300s
```

### Network Configuration

| Parameter | Type | Default | Description | Required |
|-----------|------|---------|-------------|----------|
| `NETWORK_MULTIQUEUE` | string | `Enable` | Network interface multiqueue | ❌ |
| `ADDITIONAL_NETWORKS` | array | `[]` | Additional network configurations | ❌ |

**Valid Multiqueue Options:**
- `Enable` - Enable multiqueue
- `Disable` - Disable multiqueue

**Example:**
```yaml
- NETWORK_MULTIQUEUE=Enable
- ADDITIONAL_NETWORKS=[]
```

## Platform-Specific Configuration

### KubeVirt Platform

For KubeVirt-based hosted clusters, the following additional parameters are available:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `KUBEVIRT_STORAGE_CLASS` | string | `gp3-csi` | Storage class for KubeVirt VMs |
| `KUBEVIRT_NETWORK_NAME` | string | - | Additional network name |

### AWS Platform

For AWS-based hosted clusters, use the AWS template with these parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `AWS_REGION` | string | `us-east-1` | AWS region |
| `AWS_INSTANCE_TYPE` | string | `m5.xlarge` | EC2 instance type |
| `AWS_SUBNET_ID` | string | - | Subnet ID for instances |
| `AWS_SECURITY_GROUP_IDS` | string | - | Security group IDs |
| `AWS_IAM_INSTANCE_PROFILE` | string | - | IAM instance profile |
| `AWS_ROOT_VOLUME_TYPE` | string | `gp3` | Root volume type |
| `AWS_ROOT_VOLUME_SIZE` | integer | `120` | Root volume size in GB |
| `AWS_ROOT_VOLUME_IOPS` | integer | `3000` | Root volume IOPS |

## Configuration Validation

The framework includes JSON schema validation for all configurations. The schema is defined in `gitops/cluster-config/virt-lab-env/config/cluster-registry.yaml`.

### Validation Rules

- **Cluster Name**: Must be DNS-compatible (lowercase, alphanumeric, hyphens only, max 63 chars)
- **Domain**: Must be valid domain format
- **Memory/Storage**: Must use Kubernetes resource format (e.g., `8Gi`, `32Gi`)
- **CIDR**: Must be valid CIDR notation
- **Environment**: Must be one of: `dev`, `staging`, `prod`, `lab`, `test`

### Validation Commands

```bash
# Validate a specific cluster configuration
./scripts/manage-cluster-config.sh validate my-cluster

# Validate all configurations
./scripts/manage-cluster-config.sh validate-all
```

## Configuration Examples

### Development Cluster
```yaml
configMapGenerator:
  - name: cluster-config
    literals:
      - CLUSTER_NAME=dev-cluster-01
      - ENVIRONMENT=dev
      - BASE_DOMAIN=dev.example.com
      - NODEPOOL_REPLICAS=2
      - NODEPOOL_MEMORY=8Gi
      - NODEPOOL_CORES=4
      - CONTROLLER_AVAILABILITY_POLICY=SingleReplica
      - INFRASTRUCTURE_AVAILABILITY_POLICY=SingleReplica
```

### Production Cluster
```yaml
configMapGenerator:
  - name: cluster-config
    literals:
      - CLUSTER_NAME=prod-cluster-01
      - ENVIRONMENT=prod
      - BASE_DOMAIN=prod.example.com
      - NODEPOOL_REPLICAS=5
      - NODEPOOL_MEMORY=16Gi
      - NODEPOOL_CORES=8
      - VOLUME_SIZE=100Gi
      - CONTROLLER_AVAILABILITY_POLICY=HighlyAvailable
      - INFRASTRUCTURE_AVAILABILITY_POLICY=HighlyAvailable
      - AUTO_REPAIR=true
```

### High-Performance Cluster
```yaml
configMapGenerator:
  - name: cluster-config
    literals:
      - CLUSTER_NAME=hpc-cluster-01
      - ENVIRONMENT=prod
      - BASE_DOMAIN=hpc.example.com
      - NODEPOOL_REPLICAS=10
      - NODEPOOL_MEMORY=32Gi
      - NODEPOOL_CORES=16
      - VOLUME_SIZE=200Gi
      - STORAGE_CLASS=fast-nvme
      - NETWORK_MULTIQUEUE=Enable
```

## See Also

- [CLI Reference](cli.md) - Command-line tool usage
- [Template Reference](templates.md) - Template structure and customization
- [API Reference](api.md) - Kubernetes resource specifications
