# Configuration Guide

This guide provides detailed information about all configuration options available in the OpenShift 3-Node Bare Metal Cluster Deployment script.

## 📋 Table of Contents

- [Configuration Methods](#configuration-methods)
- [Core Parameters](#core-parameters)
- [AWS Configuration](#aws-configuration)
- [OpenShift Configuration](#openshift-configuration)
- [Security Configuration](#security-configuration)
- [Validation Rules](#validation-rules)
- [Configuration Examples](#configuration-examples)

## 🔧 Configuration Methods

The script supports multiple configuration methods with the following precedence (highest to lowest):

1. **Command-line arguments** (highest priority)
2. **Environment variables**
3. **Default values** (lowest priority)

### Command-Line Arguments
```bash
./openshift-3node-baremetal-cluster.sh [OPTIONS]
```

### Environment Variables
```bash
export PARAMETER_NAME="value"
./openshift-3node-baremetal-cluster.sh
```

### Configuration File Support
Currently, the script uses environment variables and command-line arguments. Configuration file support may be added in future versions.

## 🎯 Core Parameters

### Cluster Identity

#### `CLUSTER_NAME` / `--name`
- **Description**: Name of the OpenShift cluster
- **Default**: `baremetal-lab`
- **Validation**: DNS-compatible, lowercase, max 63 characters
- **Example**: `my-production-cluster`

```bash
# Command line
./script.sh --name my-cluster

# Environment variable
export CLUSTER_NAME="my-cluster"
```

#### `BASE_DOMAIN` / `--domain`
- **Description**: Base domain for the cluster
- **Default**: `sandbox235.opentlc.com`
- **Validation**: Valid domain format
- **Example**: `example.com`

```bash
# Command line
./script.sh --domain example.com

# Environment variable
export BASE_DOMAIN="example.com"
```

### OpenShift Version

#### `OPENSHIFT_VERSION` / `--version`
- **Description**: OpenShift version to deploy
- **Default**: `4.18.20`
- **Validation**: Semantic version format (x.y.z)
- **Example**: `4.18.20`

```bash
# Command line
./script.sh --version 4.18.20

# Environment variable
export OPENSHIFT_VERSION="4.18.20"
```

## ☁️ AWS Configuration

### Region Settings

#### `AWS_REGION` / `--region`
- **Description**: AWS region for deployment
- **Default**: `us-east-2`
- **Validation**: Valid AWS region format
- **Example**: `us-west-2`

```bash
# Command line
./script.sh --region us-west-2

# Environment variable
export AWS_REGION="us-west-2"
```

### Instance Configuration

#### `INSTANCE_TYPE` / `--instance-type`
- **Description**: AWS instance type for nodes
- **Default**: `m6i.4xlarge` (standard), `c5n.metal` (bare metal)
- **Validation**: Valid AWS instance type format
- **Example**: `m6i.xlarge`

```bash
# Command line
./script.sh --instance-type m6i.xlarge

# Environment variable
export INSTANCE_TYPE="m6i.xlarge"
```

#### `BARE_METAL_ENABLED` / `--bare-metal`
- **Description**: Enable bare metal deployment mode
- **Default**: `false`
- **Effect**: Sets instance type to `c5n.metal` and enables virtualization features
- **Example**: Enable bare metal mode

```bash
# Command line
./script.sh --bare-metal

# Environment variable
export BARE_METAL_ENABLED=true
```

## 🔐 Authentication Configuration

### Pull Secret

#### `PULL_SECRET_PATH` / `--pull-secret`
- **Description**: Path to Red Hat pull secret file
- **Default**: `$HOME/pull-secret.json`
- **Validation**: File exists, readable, valid JSON format
- **Example**: `/path/to/my-pull-secret.json`

```bash
# Command line
./script.sh --pull-secret /path/to/pull-secret.json

# Environment variable
export PULL_SECRET_PATH="/path/to/pull-secret.json"
```

### SSH Configuration

#### SSH Key Management
- **Key Path**: `$HOME/.ssh/openshift-key`
- **Auto-generation**: Script creates key pair if not exists
- **Permissions**: Automatically set to 600 (private) and 644 (public)

## 🔒 Security Configuration

### SSL/TLS Requirements

#### Certificate Management
- **Requirement**: **MANDATORY** - All cluster endpoints must use secure SSL/TLS encryption
- **Certificate Authority**: Automatic provisioning via Let's Encrypt or AWS Certificate Manager
- **Validation**: Valid, trusted certificates required for all deployments
- **Enforcement**: HTTPS-only access for all web interfaces and API endpoints

#### Security Standards
- **Encryption**: All communications must be encrypted in transit
- **Certificate Validation**: Certificates must be valid and trusted by standard certificate authorities
- **HTTPS Enforcement**: HTTP redirects to HTTPS automatically
- **API Security**: All OpenShift API endpoints secured with TLS 1.2 or higher
- **Console Security**: OpenShift web console accessible only via HTTPS

#### Certificate Lifecycle
- **Automatic Renewal**: Certificates automatically renewed before expiration
- **Monitoring**: Certificate expiration monitoring and alerting
- **Backup**: Certificate backup and recovery procedures
- **Compliance**: Meets enterprise security standards and compliance requirements

```bash
# Verify SSL certificate after deployment
openssl s_client -connect api.cluster-name.domain.com:443 -servername api.cluster-name.domain.com

# Check certificate expiration
echo | openssl s_client -connect console-openshift-console.apps.cluster-name.domain.com:443 2>/dev/null | openssl x509 -noout -dates
```

## ✅ Validation Rules

### Cluster Name Validation
- Must be DNS-compatible
- Lowercase letters, numbers, and hyphens only
- Cannot start or end with hyphen
- Maximum 63 characters
- Pattern: `^[a-z0-9]([a-z0-9-]*[a-z0-9])?$`

### Domain Validation
- Must be valid domain format
- Supports subdomains
- Pattern: `^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$`

### Version Validation
- Must follow semantic versioning
- Pattern: `^[0-9]+\.[0-9]+\.[0-9]+$`
- Example: `4.18.20`

### AWS Region Validation
- Must be valid AWS region format
- Pattern: `^[a-z]{2}-[a-z]+-[0-9]+$`
- Examples: `us-east-1`, `eu-west-1`, `ap-southeast-2`

### Instance Type Validation
- Must be valid AWS instance type format
- Pattern: `^[a-z][0-9]+[a-z]*\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge|metal)$`
- Examples: `m6i.xlarge`, `c5n.metal`, `t3.medium`

### SSL Certificate Validation
- **Certificate Authority**: Must be issued by a trusted CA (Let's Encrypt, AWS Certificate Manager, or enterprise CA)
- **Certificate Chain**: Complete certificate chain must be valid and verifiable
- **Expiration**: Certificates must have at least 30 days remaining before expiration
- **Domain Matching**: Certificate subject/SAN must match cluster domain names
- **TLS Version**: Must support TLS 1.2 or higher
- **Cipher Suites**: Must use secure cipher suites (no weak or deprecated ciphers)

## 📝 Configuration Examples

### Development Environment
```bash
./openshift-3node-baremetal-cluster.sh \
  --name dev-cluster \
  --domain dev.example.com \
  --region us-east-1 \
  --instance-type m6i.large
```

### Production Environment
```bash
export CLUSTER_NAME="prod-cluster"
export BASE_DOMAIN="prod.example.com"
export AWS_REGION="us-west-2"
export OPENSHIFT_VERSION="4.18.20"

./openshift-3node-baremetal-cluster.sh --bare-metal
```

### Testing Environment with Custom Pull Secret
```bash
./openshift-3node-baremetal-cluster.sh \
  --name test-cluster \
  --domain test.example.com \
  --pull-secret /tmp/test-pull-secret.json \
  --version 4.18.20
```

### High-Performance Computing Setup
```bash
./openshift-3node-baremetal-cluster.sh \
  --bare-metal \
  --name hpc-cluster \
  --domain hpc.example.com \
  --region us-east-1
```

## 🔍 Configuration Verification

The script performs comprehensive validation of all configuration parameters before deployment:

1. **Parameter Format Validation**: Ensures all parameters follow expected formats
2. **AWS Resource Validation**: Verifies AWS credentials and permissions
3. **File Validation**: Checks pull secret file existence and format
4. **Network Validation**: Validates domain and region accessibility
5. **Quota Validation**: Checks AWS service quotas and limits

## 🚨 Common Configuration Issues

### Invalid Cluster Name
```bash
# ❌ Invalid - contains uppercase
--name MyCluster

# ✅ Valid
--name my-cluster
```

### Invalid Domain Format
```bash
# ❌ Invalid - starts with dot
--domain .example.com

# ✅ Valid
--domain example.com
```

### Missing Pull Secret
```bash
# ❌ Error if file doesn't exist
--pull-secret /nonexistent/path

# ✅ Valid - script will guide you to download
# (default path or existing file)
```

## 🔧 AWS CLI Configuration Script Reference

### `configure-aws-cli.sh` Parameters

#### Command Syntax
```bash
./configure-aws-cli.sh [OPTION] [PARAMETERS]
```

#### Options Reference
| Option | Description | Parameters Required | Example |
|--------|-------------|-------------------|---------|
| `-i, --install` | Install AWS CLI, yq, and configure credentials | `access_key secret_key region` | `./configure-aws-cli.sh -i AKIAIOSFODNN7EXAMPLE wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY us-east-1` |
| `-d, --delete` | Remove AWS CLI installation | None | `./configure-aws-cli.sh -d` |
| `-h, --help` | Display help message | None | `./configure-aws-cli.sh -h` |

#### Parameter Validation
- **Access Key**: Must be valid AWS access key format (20 characters, alphanumeric)
- **Secret Key**: Must be valid AWS secret key format (40 characters, base64)
- **Region**: Must be valid AWS region identifier (e.g., us-east-1, eu-west-2)

#### Installation Behavior
- **Prerequisites**: Automatically installs `curl` and `unzip` if missing (via package manager)
- **yq Installation**: Downloads and installs yq v4.44.3 to `~/bin/yq`
- **AWS CLI Installation**: Installs AWS CLI v2 to `/usr/local/bin/aws` (system-wide)
- **Credentials File**: Creates `$HOME/.aws/credentials`
- **PATH Update**: Adds `~/bin` to PATH in `~/.bashrc` if needed
- **Verification**: Runs `aws sts get-caller-identity` to validate setup

#### Environment Variables
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `SKIP_CHECK_CALLER_IDENTITY` | Skip AWS access validation | `false` | `export SKIP_CHECK_CALLER_IDENTITY=true` |
| `RUN_SUDO` | Force sudo usage | Auto-detected | `export RUN_SUDO=sudo` |

#### Exit Codes
| Code | Meaning | Description |
|------|---------|-------------|
| `0` | Success | Operation completed successfully |
| `1` | General Error | Invalid usage or missing parameters |
| `2` | AWS Error | AWS CLI installation or configuration failed |

## 📚 Next Steps

- [Deployment Guide](DEPLOYMENT.md) - Step-by-step deployment instructions
- [Validation Guide](VALIDATION.md) - Understanding validation and verification
- [Examples](EXAMPLES.md) - Common deployment scenarios
