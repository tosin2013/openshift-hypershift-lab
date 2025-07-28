# OpenShift HyperShift Lab Configuration Reference

This reference provides complete configuration options for the OpenShift HyperShift Lab project, including deployment scripts, GitOps configurations, and hosted cluster parameters.

## Foundation Cluster Configuration

### openshift-3node-baremetal-cluster.sh

The main deployment script for the foundation cluster that hosts the control planes.

#### Command Line Options

| Option | Short | Type | Default | Description |
|--------|-------|------|---------|-------------|
| `--instance-type` | `-i` | string | `m6i.4xlarge` | AWS instance type for cluster nodes |
| `--version` | `-v` | string | `4.18.20` | OpenShift version to deploy |
| `--domain` | `-d` | string | **Required** | Base domain (must have Route53 hosted zone) |
| `--name` | `-n` | string | `baremetal-lab` | Cluster name |
| `--region` | `-r` | string | `us-east-2` | AWS region for deployment |
| `--pull-secret` | `-p` | string | `~/pull-secret.json` | Path to Red Hat pull secret |
| `--bare-metal` | - | flag | `false` | Enable bare metal mode (uses c5n.metal instances) |
| `--help` | `-h` | flag | - | Show help message |

#### Environment Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `OPENSHIFT_VERSION` | string | `4.18.20` | OpenShift version to deploy |
| `BASE_DOMAIN` | string | **Required** | Base domain for the cluster |
| `CLUSTER_NAME` | string | `baremetal-lab` | Name of the cluster |
| `AWS_REGION` | string | `us-east-2` | AWS region for deployment |
| `PULL_SECRET_PATH` | string | `~/pull-secret.json` | Path to Red Hat pull secret file |

#### Instance Type Options

| Instance Type | vCPU | Memory | Network | Use Case |
|---------------|------|--------|---------|----------|
| `m6i.4xlarge` | 16 | 64 GiB | Up to 12.5 Gbps | Standard deployment |
| `c5n.metal` | 72 | 192 GiB | 100 Gbps | Bare metal with KVM support |
| `m6i.8xlarge` | 32 | 128 GiB | 12.5 Gbps | High-memory workloads |
| `c5n.4xlarge` | 16 | 42 GiB | Up to 25 Gbps | Compute-optimized |

### configure-aws-cli.sh

Automated AWS CLI installation and configuration script.

#### Usage Patterns

```bash
# Install and configure AWS CLI
./configure-aws-cli.sh --install ACCESS_KEY SECRET_KEY REGION

# Configure existing AWS CLI
./configure-aws-cli.sh ACCESS_KEY SECRET_KEY REGION
```

#### Required AWS Permissions

The AWS credentials must have these permissions:
- `ec2:*` - EC2 instance management
- `route53:*` - DNS management
- `s3:*` - S3 bucket operations
- `iam:*` - IAM role management
- `elasticloadbalancing:*` - Load balancer management

## Hosted Control Planes Configuration

### setup-hosted-control-planes.sh

Sets up the infrastructure required for hosted clusters.

#### What It Configures

1. **HyperShift Operator**: Installs the HyperShift operator
2. **External DNS**: Configures Route53 integration
3. **S3 OIDC Provider**: Sets up OIDC discovery documents
4. **Ingress Wildcard Policy**: Enables nested subdomain routing
5. **Certificate Management**: Configures SSL/TLS for hosted clusters

#### Generated Resources

| Resource | Namespace | Purpose |
|----------|-----------|---------|
| `hypershift-operator-external-dns-credentials` | `local-cluster` | Route53 credentials |
| `hypershift-operator-oidc-provider-s3-credentials` | `local-cluster` | S3 OIDC credentials |
| Ingress Controller patch | `openshift-ingress-operator` | Wildcard policy |

## Hosted Cluster Configuration

### create-hosted-cluster-instance.sh

Creates new hosted cluster instances with GitOps integration.

#### Command Line Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--name` | string | **Required** | Hosted cluster name |
| `--environment` | string | `dev` | Environment type (dev/staging/prod) |
| `--replicas` | integer | `2` | Number of worker nodes |
| `--memory` | string | `8Gi` | Memory per worker node |
| `--cores` | integer | `4` | CPU cores per worker node |
| `--storage-size` | string | `50Gi` | Storage size per worker node |
| `--storage-class` | string | `ocs-storagecluster-ceph-rbd` | Storage class for PVCs |
| `--release-image` | string | Auto-detected | OpenShift release image |
| `--domain` | string | Auto-detected | Management cluster domain |
| `--platform` | string | `kubevirt` | Platform type (kubevirt/aws) |

#### Environment Types

| Environment | Purpose | Typical Configuration |
|-------------|---------|----------------------|
| `dev` | Development | 2 replicas, 8Gi memory, 4 cores |
| `staging` | Staging/Testing | 3 replicas, 16Gi memory, 8 cores |
| `prod` | Production | 3-5 replicas, 32Gi memory, 16 cores |

### Hosted Cluster Templates

#### cluster-template.yaml

Base template for hosted cluster creation.

**Key Sections**:
```yaml
apiVersion: hypershift.openshift.io/v1beta1
kind: HostedCluster
metadata:
  name: CLUSTER_NAME
  namespace: clusters
spec:
  release:
    image: RELEASE_IMAGE
  dns:
    baseDomain: BASE_DOMAIN
  platform:
    type: KubeVirt
```

#### cluster-template-with-external-secrets.yaml

Enhanced template with External Secrets integration.

**Additional Features**:
- ExternalSecret resources for credential management
- Automatic secret synchronization
- RHACM-compatible credential patterns

## GitOps Configuration

### ArgoCD Applications

#### cluster-config Application

**Location**: `gitops/apps/openshift-hypershift-lab/cluster-config.yaml`

**Purpose**: Manages the overall cluster configuration through ArgoCD

**Sync Waves**:
1. Wave 0: Basic operators (OpenShift GitOps)
2. Wave 1: OpenShift Virtualization operator
3. Wave 2: OpenShift Virtualization instance
4. Wave 3: Advanced Cluster Management operator
5. Wave 4: Multi-cluster engine

#### Hosted Clusters ApplicationSet

**Location**: `gitops/cluster-config/apps/openshift-hypershift-lab-apps/hosted-clusters-applicationset.yaml`

**Purpose**: Automatically discovers and deploys hosted cluster instances

**Git Generator Configuration**:
```yaml
generators:
- git:
    repoURL: https://github.com/tosin2013/openshift-hypershift-lab.git
    revision: HEAD
    directories:
    - path: gitops/cluster-config/virt-lab-env/overlays/instances/*
```

### Kustomize Configuration

#### Base Configuration

**Location**: `gitops/cluster-config/virt-lab-env/base/`

**Components**:
- `hosted-cluster.yaml` - Base HostedCluster resource
- `nodepool.yaml` - Base NodePool resource
- `kustomization.yaml` - Base Kustomize configuration

#### Instance Overlays

**Location**: `gitops/cluster-config/virt-lab-env/overlays/instances/CLUSTER_NAME/`

**Files**:
- `kustomization.yaml` - Instance-specific Kustomize config
- `cluster-config.yaml` - ConfigMap with cluster parameters
- `external-secret.yaml` - External Secrets configuration
- `replacements.yaml` - Parameter replacement rules

## External Secrets Configuration

### Operator Configuration

**Location**: `external-secrets-operatorconfig.yaml`

**Purpose**: Configures the External Secrets Operator for credential management

### Credential Management

#### virt-creds Namespace

**Purpose**: Central credential store for all hosted clusters

**Required Secrets**:
```bash
# Create the virt-creds secret
oc create secret generic virt-creds \
  --from-file=pullSecret=~/pull-secret.json \
  --from-file=ssh-publickey=~/.ssh/id_rsa.pub \
  -n virt-creds
```

#### ExternalSecret Resources

**Pattern**: Each hosted cluster gets an ExternalSecret that syncs from virt-creds

**Example**:
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: CLUSTER_NAME-creds
  namespace: clusters
spec:
  secretStoreRef:
    name: virt-creds-store
    kind: SecretStore
  target:
    name: CLUSTER_NAME-creds
```

## Network Configuration

### Domain Patterns

#### Management Cluster

```
Console: https://console-openshift-console.apps.MGMT_CLUSTER.DOMAIN
API: https://api.MGMT_CLUSTER.DOMAIN:6443
```

#### Hosted Clusters

```
Console: https://console-openshift-console.apps.HOSTED_CLUSTER.apps.MGMT_CLUSTER.DOMAIN
API: https://api.HOSTED_CLUSTER.apps.MGMT_CLUSTER.DOMAIN:6443
```

### Certificate Configuration

#### Wildcard Policy

**Required Configuration**:
```bash
oc patch ingresscontroller -n openshift-ingress-operator default --type=json \
  -p '[{ "op": "add", "path": "/spec/routeAdmission", "value": {"wildcardPolicy": "WildcardsAllowed"}}]'
```

**Purpose**: Enables nested subdomain routing for hosted cluster consoles

## Storage Configuration

### OpenShift Data Foundation

#### Node Labeling

**Required Labels**:
```bash
oc label node NODE_NAME cluster.ocs.openshift.io/openshift-storage=""
```

**Purpose**: Identifies nodes for ODF storage cluster

#### Storage Classes

| Storage Class | Type | Use Case |
|---------------|------|----------|
| `ocs-storagecluster-ceph-rbd` | Block | Databases, file systems |
| `ocs-storagecluster-cephfs` | File | Shared storage |
| `ocs-storagecluster-ceph-rgw` | Object | S3-compatible storage |

## Validation and Monitoring

### Health Checks

#### Hosted Cluster Status

```bash
# Check hosted cluster status
oc get hostedcluster -n clusters

# Check node pool status  
oc get nodepool -n clusters

# Check external secrets
oc get externalsecrets -n clusters
```

#### ArgoCD Application Status

```bash
# Check ArgoCD applications
oc get applications -n openshift-gitops

# Check ApplicationSet status
oc get applicationset -n openshift-gitops
```

### Log Locations

| Component | Log Location |
|-----------|--------------|
| Deployment Script | `openshift-deployment-YYYYMMDD-HHMMSS.log` |
| ArgoCD Applications | ArgoCD console > Application > Logs |
| Hosted Cluster Events | `oc get events -n clusters` |
| HyperShift Operator | `oc logs -n hypershift deployment/operator` |

## See Also

- [Script Reference](script-reference.md) - Complete script documentation
- [GitOps Configuration](gitops-configuration.md) - ArgoCD setup details
- [Security Configuration](security-configuration.md) - SSL/TLS and security settings
