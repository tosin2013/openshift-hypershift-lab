# Script Reference

This reference provides complete documentation for all scripts in the OpenShift HyperShift Lab project.

## Main Deployment Scripts

### openshift-3node-baremetal-cluster.sh

**Purpose**: Primary deployment script for OpenShift 3-node clusters with bare metal capabilities.

**Location**: `./openshift-3node-baremetal-cluster.sh`

**Usage**:
```bash
./openshift-3node-baremetal-cluster.sh [OPTIONS]
```

**Options**:
| Option | Short | Description | Default | Required |
|--------|-------|-------------|---------|----------|
| `--instance-type` | `-i` | AWS instance type | `m6i.4xlarge` | No |
| `--version` | `-v` | OpenShift version | `4.18.20` | No |
| `--domain` | `-d` | Base domain (must have Route53 hosted zone) | None | **Yes** |
| `--name` | `-n` | Cluster name | `baremetal-lab` | No |
| `--region` | `-r` | AWS region | `us-east-2` | No |
| `--pull-secret` | `-p` | Path to pull secret file | `~/pull-secret.json` | No |
| `--bare-metal` | None | Enable bare metal mode (uses c5n.metal) | `false` | No |
| `--help` | `-h` | Show help message | N/A | No |

**Environment Variables**:
| Variable | Description | Default |
|----------|-------------|---------|
| `OPENSHIFT_VERSION` | OpenShift version to deploy | `4.18.20` |
| `BASE_DOMAIN` | Base domain for cluster | None (required) |
| `CLUSTER_NAME` | Name of the cluster | `baremetal-lab` |
| `AWS_REGION` | AWS region for deployment | `us-east-2` |
| `PULL_SECRET_PATH` | Path to Red Hat pull secret | `~/pull-secret.json` |

**Examples**:
```bash
# Basic deployment
./openshift-3node-baremetal-cluster.sh --domain example.com

# Bare metal deployment
./openshift-3node-baremetal-cluster.sh --domain example.com --bare-metal

# Custom configuration
./openshift-3node-baremetal-cluster.sh \
  --name my-cluster \
  --domain my-domain.com \
  --region us-west-2 \
  --version 4.18.20
```

**Exit Codes**:
- `0`: Success
- `1`: General error
- `2`: Invalid arguments
- `3`: Prerequisites not met
- `4`: AWS configuration error
- `5`: Deployment failure

### configure-aws-cli.sh

**Purpose**: Automated AWS CLI installation and configuration.

**Location**: `./configure-aws-cli.sh`

**Usage**:
```bash
./configure-aws-cli.sh [--install] ACCESS_KEY SECRET_KEY REGION
```

**Arguments**:
| Argument | Position | Description | Required |
|----------|----------|-------------|----------|
| `--install` | 1 | Install AWS CLI if missing | No |
| `ACCESS_KEY` | 2 | AWS access key ID | Yes |
| `SECRET_KEY` | 3 | AWS secret access key | Yes |
| `REGION` | 4 | AWS default region | Yes |

**Examples**:
```bash
# Install and configure AWS CLI
./configure-aws-cli.sh --install AKIAIOSFODNN7EXAMPLE wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY us-east-2

# Configure existing AWS CLI
./configure-aws-cli.sh AKIAIOSFODNN7EXAMPLE wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY us-west-1
```

### setup-hosted-control-planes.sh

**Purpose**: Set up hosted control planes infrastructure and dependencies.

**Location**: `./setup-hosted-control-planes.sh`

**Usage**:
```bash
./setup-hosted-control-planes.sh
```

**Prerequisites**:
- OpenShift cluster deployed and accessible
- Cluster admin permissions
- AWS credentials configured
- Route53 hosted zone available

**What it does**:
1. Installs HyperShift operator
2. Configures External DNS with Route53
3. Sets up S3 OIDC provider
4. Configures ingress wildcard policy
5. Creates necessary secrets and credentials

## Utility Scripts

### scripts/create-hosted-cluster-instance.sh

**Purpose**: Create new hosted cluster instances with External Secrets integration.

**Location**: `./scripts/create-hosted-cluster-instance.sh`

**Usage**:
```bash
./scripts/create-hosted-cluster-instance.sh [OPTIONS]
```

**Options**:
| Option | Description | Default | Required |
|--------|-------------|---------|----------|
| `--name` | Hosted cluster name | None | **Yes** |
| `--environment` | Environment type (dev/staging/prod) | `dev` | No |
| `--replicas` | Number of worker nodes | `2` | No |
| `--domain` | Override management cluster domain | Auto-detected | No |

**Examples**:
```bash
# Create development cluster
./scripts/create-hosted-cluster-instance.sh \
  --name dev-cluster-01 \
  --environment dev \
  --replicas 2

# Create production cluster
./scripts/create-hosted-cluster-instance.sh \
  --name prod-cluster-01 \
  --environment prod \
  --replicas 3
```

### scripts/setup-hosted-cluster-credentials.sh

**Purpose**: Set up External Secrets Operator and credential management.

**Location**: `./scripts/setup-hosted-cluster-credentials.sh`

**Usage**:
```bash
./scripts/setup-hosted-cluster-credentials.sh [OPTIONS]
```

**Options**:
| Option | Description |
|--------|-------------|
| `--setup-external-secrets` | Install and configure External Secrets Operator |
| `--verify` | Verify credential setup |

### scripts/validate-deployment.sh

**Purpose**: Validate cluster deployments and health.

**Location**: `./scripts/validate-deployment.sh`

**Usage**:
```bash
./scripts/validate-deployment.sh [CLUSTER_NAME]
```

**Arguments**:
| Argument | Description | Required |
|----------|-------------|----------|
| `CLUSTER_NAME` | Name of cluster to validate | No (validates current context) |

### scripts/manage-cluster-config.sh

**Purpose**: Manage cluster configurations and GitOps resources.

**Location**: `./scripts/manage-cluster-config.sh`

**Usage**:
```bash
./scripts/manage-cluster-config.sh [COMMAND] [OPTIONS]
```

**Commands**:
| Command | Description |
|---------|-------------|
| `list` | List all cluster configurations |
| `validate` | Validate configuration syntax |
| `apply` | Apply configuration changes |
| `delete` | Remove cluster configuration |

### scripts/test-hosted-cluster-config.sh

**Purpose**: Test hosted cluster configurations before deployment.

**Location**: `./scripts/test-hosted-cluster-config.sh`

**Usage**:
```bash
./scripts/test-hosted-cluster-config.sh [CLUSTER_NAME]
```

### scripts/test-kustomize-replacements.sh

**Purpose**: Test Kustomize replacement configurations.

**Location**: `./scripts/test-kustomize-replacements.sh`

**Usage**:
```bash
./scripts/test-kustomize-replacements.sh [CONFIG_PATH]
```

## Configuration Files

### cluster-template.yaml

**Purpose**: Base template for hosted cluster creation.

**Location**: `./cluster-template.yaml`

**Format**: Kubernetes YAML manifest for HostedCluster resource.

### cluster-template-with-external-secrets.yaml

**Purpose**: Enhanced template with External Secrets integration.

**Location**: `./cluster-template-with-external-secrets.yaml`

**Format**: Kubernetes YAML with ExternalSecret resources.

### external-secrets-operatorconfig.yaml

**Purpose**: External Secrets Operator configuration.

**Location**: `./external-secrets-operatorconfig.yaml`

**Format**: OperatorConfig for External Secrets Operator.

## Log Files

### Deployment Logs

**Pattern**: `openshift-deployment-YYYYMMDD-HHMMSS.log`

**Location**: Current directory

**Content**: Timestamped deployment progress and debug information.

**Example**: `openshift-deployment-20250728-011127.log`

## Exit Codes and Error Handling

### Standard Exit Codes

| Code | Meaning | Description |
|------|---------|-------------|
| `0` | Success | Operation completed successfully |
| `1` | General Error | Unspecified error occurred |
| `2` | Invalid Arguments | Command line arguments are invalid |
| `3` | Prerequisites Not Met | Required tools or permissions missing |
| `4` | AWS Configuration Error | AWS credentials or permissions issue |
| `5` | Deployment Failure | OpenShift deployment failed |
| `6` | Validation Failure | Post-deployment validation failed |
| `7` | Network Error | Network connectivity issues |
| `8` | Resource Limit | AWS quotas or resource limits exceeded |

### Error Message Format

All scripts use consistent error message formatting:

```
[YYYY-MM-DD HH:MM:SS] ERROR: Description of the error
[YYYY-MM-DD HH:MM:SS] INFO: Suggested resolution steps
```

## Script Dependencies

### Required Tools

| Tool | Purpose | Auto-Install | Version |
|------|---------|--------------|---------|
| `bash` | Shell execution | No (system) | 4.0+ |
| `jq` | JSON processing | No (manual) | 1.6+ |
| `curl` | HTTP requests | No (usually present) | 7.0+ |
| `aws` | AWS CLI | Yes | 2.0+ |
| `oc` | OpenShift CLI | Yes | 4.18+ |
| `yq` | YAML processing | Yes | 4.0+ |

### System Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| OS | RHEL 8, Ubuntu 20.04 | RHEL 9, Ubuntu 22.04 |
| RAM | 4GB | 8GB |
| Disk | 10GB free | 20GB free |
| Network | Internet access | Stable broadband |

## Best Practices

### Script Execution

1. **Always make scripts executable**: `chmod +x script.sh`
2. **Run from project root**: `cd openshift-hypershift-lab`
3. **Check prerequisites**: Verify required tools are available
4. **Use full paths**: Avoid relative path issues
5. **Monitor logs**: Check log files for detailed information

### Error Handling

1. **Check exit codes**: Always verify script success
2. **Read error messages**: Error messages include resolution steps
3. **Check log files**: Detailed information in timestamped logs
4. **Verify prerequisites**: Ensure all requirements are met

### Security

1. **Protect credentials**: Never commit secrets to Git
2. **Use environment variables**: For sensitive configuration
3. **Limit permissions**: Use least privilege access
4. **Secure log files**: Logs may contain sensitive information

## See Also

- [HyperShift Lab Configuration](hypershift-lab-configuration.md) - Complete configuration reference
- [Architecture Overview](../explanations/architecture-overview.md) - System design and component relationships
- [Development Setup](../how-to-guides/developer/development-setup.md) - Setting up development environment
