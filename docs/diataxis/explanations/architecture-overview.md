# Architecture Overview

This document explains the high-level architecture of the OpenShift HyperShift Lab, including the design decisions, component relationships, and the progression from foundation cluster to hosted clusters platform.

## System Architecture

### Overall Design Philosophy

The OpenShift HyperShift Lab follows a **progressive architecture** that evolves from a simple foundation cluster to a sophisticated multi-tenant platform:

1. **Foundation First**: Start with a solid, production-ready OpenShift cluster
2. **Incremental Enhancement**: Add capabilities systematically
3. **GitOps Native**: Everything managed through declarative configuration
4. **Multi-Platform Support**: Extensible to different infrastructure platforms

### Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interface Layer                     │
├─────────────────────────────────────────────────────────────┤
│  OpenShift Console  │  ArgoCD UI  │  Hosted Cluster Consoles │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                   Application Layer                         │
├─────────────────────────────────────────────────────────────┤
│  User Workloads  │  System Apps  │  Hosted Control Planes   │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                   Platform Layer                            │
├─────────────────────────────────────────────────────────────┤
│  HyperShift  │  OpenShift Virt  │  ArgoCD  │  External DNS   │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                   Foundation Layer                          │
├─────────────────────────────────────────────────────────────┤
│  OpenShift Cluster  │  ODF Storage  │  Network  │  Security  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                  Infrastructure Layer                       │
├─────────────────────────────────────────────────────────────┤
│  AWS EC2  │  VPC  │  Route53  │  S3  │  Load Balancers      │
└─────────────────────────────────────────────────────────────┘
```

## Component Architecture

### Foundation Cluster

The foundation cluster provides the base platform for all operations:

**Core Components**:
- **3 Master Nodes**: Act as both control plane and workers (schedulable masters)
- **OpenShift Container Platform**: Full OpenShift functionality
- **Container Runtime**: CRI-O with Kubernetes orchestration
- **Network**: OVN-Kubernetes CNI for pod and service networking
- **Storage**: OpenShift Data Foundation (ODF) for persistent storage

**Design Rationale**:
- **Schedulable Masters**: Maximizes resource utilization in 3-node configuration
- **Bare Metal Capable**: c5n.metal instances support KVM virtualization
- **High Performance**: 64 vCPU, 256GB RAM per node for demanding workloads
- **Production Ready**: SSL/TLS encryption, monitoring, and logging

### Hosted Control Planes Architecture

The hosted clusters architecture separates control plane from data plane:

```
Management Cluster (Foundation)
├── Hosted Control Plane Pods
│   ├── kube-apiserver (dev-cluster-01)
│   ├── kube-controller-manager (dev-cluster-01)
│   ├── kube-scheduler (dev-cluster-01)
│   └── etcd (dev-cluster-01)
├── HyperShift Operator
├── External DNS Controller
└── S3 OIDC Provider

Hosted Cluster Worker Nodes
├── KubeVirt VMs (for virtualized workloads)
├── AWS EC2 Instances (for cloud workloads)
└── Bare Metal Nodes (for high-performance workloads)
```

**Benefits of This Architecture**:
- **Resource Efficiency**: Multiple control planes share management cluster resources
- **Isolation**: Each hosted cluster is completely isolated
- **Scalability**: Easy to add new clusters without additional control plane overhead
- **Cost Optimization**: Shared infrastructure reduces overall costs

### GitOps Architecture

The system uses ArgoCD for declarative cluster management:

```
Git Repository
├── gitops/cluster-config/
│   ├── base/ (Base configurations)
│   └── overlays/ (Environment-specific)
└── gitops/apps/ (ArgoCD Applications)

ArgoCD Controller
├── Monitors Git repository
├── Applies configuration changes
├── Manages application lifecycle
└── Provides drift detection

Target Clusters
├── Management cluster resources
├── Hosted cluster definitions
└── Application deployments
```

**GitOps Principles Applied**:
- **Declarative**: All configuration in Git
- **Versioned**: Full change history and rollback capability
- **Automated**: Continuous synchronization
- **Observable**: Clear visibility into system state

## Network Architecture

### Management Cluster Networking

```
Internet
    │
    ├── Route53 DNS
    │   ├── api.management-cluster.example.com
    │   └── *.apps.management-cluster.example.com
    │
    ├── AWS Load Balancer
    │   ├── API Server (6443)
    │   └── Ingress Controller (80/443)
    │
    └── VPC (10.0.0.0/16)
        ├── Public Subnets (NAT Gateway)
        ├── Private Subnets (Cluster Nodes)
        └── Security Groups (Firewall Rules)
```

### Hosted Cluster Networking

Hosted clusters use nested subdomain patterns:

```
Management Cluster Domain: apps.management-cluster.example.com
    │
    ├── Hosted Cluster 1: apps.dev-cluster-01.apps.management-cluster.example.com
    ├── Hosted Cluster 2: apps.dev-cluster-02.apps.management-cluster.example.com
    └── Hosted Cluster N: apps.cluster-name.apps.management-cluster.example.com
```

**Network Design Decisions**:
- **Wildcard DNS**: Supports dynamic subdomain creation
- **Certificate Inheritance**: Hosted clusters use management cluster certificates
- **Ingress Policy**: WildcardsAllowed enables nested subdomain routing
- **External DNS**: Automatic DNS record management

## Storage Architecture

### OpenShift Data Foundation (ODF)

```
Physical Storage
├── AWS EBS Volumes (GP3, 8000 IOPS)
│   ├── Node 1: 500GB
│   ├── Node 2: 500GB
│   └── Node 3: 500GB
│
ODF Components
├── Ceph Storage Cluster
│   ├── Object Storage (RGW)
│   ├── Block Storage (RBD)
│   └── File Storage (CephFS)
│
Storage Classes
├── ocs-storagecluster-ceph-rbd (Block)
├── ocs-storagecluster-cephfs (File)
└── ocs-storagecluster-ceph-rgw (Object)
```

**Storage Design Rationale**:
- **Distributed Storage**: Ceph provides resilience and performance
- **Multiple Access Modes**: Block, file, and object storage support
- **Dynamic Provisioning**: Automatic PV creation and management
- **Backup Integration**: Built-in snapshot and backup capabilities

## Security Architecture

### Multi-Layer Security Model

```
Network Security
├── AWS Security Groups (Firewall)
├── Network Policies (Pod-to-Pod)
└── Route53 DNS Security

Transport Security
├── TLS 1.2+ for all communications
├── Let's Encrypt certificates
└── Certificate auto-renewal

Authentication & Authorization
├── OpenShift OAuth (RBAC)
├── Service Account tokens
└── External identity providers

Data Security
├── Encrypted storage (EBS encryption)
├── Secret management (External Secrets)
└── Image scanning and policies
```

**Security Design Principles**:
- **Defense in Depth**: Multiple security layers
- **Least Privilege**: Minimal required permissions
- **Encryption Everywhere**: Data in transit and at rest
- **Automated Security**: Certificate management and updates

## Platform Integration

### AWS Integration

The system deeply integrates with AWS services:

```
Compute
├── EC2 Instances (c5n.metal, m6i.4xlarge)
├── Auto Scaling Groups
└── Placement Groups

Networking
├── VPC and Subnets
├── Internet and NAT Gateways
├── Elastic Load Balancers
└── Route53 DNS

Storage
├── EBS Volumes (GP3)
├── S3 Buckets (OIDC)
└── Backup Storage

Security
├── IAM Roles and Policies
├── Security Groups
└── Certificate Manager
```

### Multi-Platform Support

The architecture supports multiple infrastructure platforms:

**KubeVirt Platform**:
- Virtual machines on OpenShift
- Nested virtualization support
- Resource sharing with containers

**AWS Platform**:
- Native EC2 instances
- AWS service integration
- Cloud-native scaling

**Extensible Design**:
- Plugin architecture for new platforms
- Consistent API across platforms
- Platform-specific optimizations

## Scalability Architecture

### Horizontal Scaling

```
Management Cluster
├── Fixed 3-node foundation
├── Supports 100+ hosted clusters
└── Shared control plane resources

Hosted Clusters
├── Independent worker node scaling
├── Platform-specific scaling policies
└── Resource isolation per cluster

Applications
├── Kubernetes HPA/VPA
├── Cluster autoscaling
└── Multi-cluster load balancing
```

### Vertical Scaling

- **Node Sizing**: Configurable instance types per use case
- **Resource Allocation**: CPU/memory limits and requests
- **Storage Scaling**: Dynamic volume expansion
- **Network Bandwidth**: Instance type determines network performance

## Design Decisions and Trade-offs

### Key Architectural Decisions

**1. Schedulable Masters**
- **Decision**: Masters act as workers in 3-node configuration
- **Rationale**: Maximizes resource utilization
- **Trade-off**: Reduced isolation vs. better resource efficiency

**2. Hosted Control Planes**
- **Decision**: Control planes run as pods on management cluster
- **Rationale**: Resource efficiency and operational simplicity
- **Trade-off**: Shared fate vs. resource optimization

**3. GitOps-First Approach**
- **Decision**: All configuration through Git and ArgoCD
- **Rationale**: Declarative, auditable, and reproducible
- **Trade-off**: Learning curve vs. operational benefits

**4. Multi-Platform Support**
- **Decision**: Abstract platform differences behind common APIs
- **Rationale**: Flexibility and vendor independence
- **Trade-off**: Complexity vs. portability

### Performance Considerations

**Network Performance**:
- c5n.metal instances provide 100 Gbps networking
- Enhanced networking for low latency
- Placement groups for optimal network topology

**Storage Performance**:
- GP3 volumes with 8000 IOPS per node
- Ceph distributed storage for parallel I/O
- NVMe local storage for high-performance workloads

**Compute Performance**:
- 64 vCPU per node for CPU-intensive workloads
- 256GB RAM per node for memory-intensive applications
- KVM virtualization for nested workloads

## Evolution and Future Architecture

### Current State (v1.0)
- Foundation cluster with hosted clusters
- KubeVirt and AWS platform support
- GitOps-based management

### Planned Evolution (v2.0)
- Multi-cluster service mesh
- Advanced monitoring and observability
- Disaster recovery and backup automation
- Additional platform support (Azure, GCP)

### Long-term Vision (v3.0)
- Edge computing integration
- AI/ML platform capabilities
- Advanced security and compliance
- Hybrid and multi-cloud orchestration

## Summary

The OpenShift HyperShift Lab architecture provides:

- **Progressive Complexity**: Start simple, add capabilities incrementally
- **Resource Efficiency**: Shared infrastructure with complete isolation
- **Operational Excellence**: GitOps-based automation and management
- **Platform Flexibility**: Multi-platform support with consistent APIs
- **Production Readiness**: Enterprise-grade security, monitoring, and reliability

This architecture enables organizations to start with a single cluster and evolve to a sophisticated multi-tenant platform while maintaining operational simplicity and cost efficiency.
