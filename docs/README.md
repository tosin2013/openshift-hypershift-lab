# OpenShift HyperShift Lab Documentation

Welcome to the OpenShift HyperShift Lab documentation! This directory contains comprehensive documentation for the project.

## 🎯 **Primary Documentation** (Start Here)

### **[📖 Complete User Documentation](diataxis/README.md)**
**Comprehensive documentation following the Diátaxis framework** - the main documentation for all users:

- **📚 [Tutorials](diataxis/tutorials/)**: Learning-oriented guides for getting started
- **🛠️ [How-To Guides](diataxis/how-to-guides/)**: Problem-oriented solutions for specific tasks  
- **🔧 [Developer Guides](diataxis/how-to-guides/developer/)**: Contribution-oriented development setup
- **📖 [Reference](diataxis/reference/)**: Information-oriented technical specifications
- **🧠 [Explanations](diataxis/explanations/)**: Understanding-oriented architectural concepts

## 🏗️ **Specialized Documentation**

### **[Modular Hosted Clusters Framework](modular-hosted-clusters/README.md)**
Advanced multi-instance deployment patterns and GitOps automation for scaling hosted clusters.

## 🔧 **Technical Reference Files**

The following files provide specific technical fixes and troubleshooting:

- **[HyperShift Troubleshooting](HYPERSHIFT-TROUBLESHOOTING.md)**: Quick fixes for hosted cluster issues
- **[Ingress Wildcard Policy Fix](hypershift-ingress-wildcard-policy-fix.md)**: Critical fix for hosted cluster consoles
- **[Kustomize Replacements Fix](KUSTOMIZE-REPLACEMENTS-FIX.md)**: Fix for Kustomize parameter replacement issues

## 🏗️ **Architecture Overview**

The OpenShift HyperShift Lab supports two primary deployment architectures:

### **AWS Cloud Deployment**
```mermaid
graph TB
    subgraph "AWS Cloud"
        subgraph "Management Cluster (AWS)"
            MC[Management Cluster<br/>3x c5n.metal instances<br/>OpenShift + HyperShift]
            ArgoCD[ArgoCD<br/>GitOps Controller]
            ODF[OpenShift Data Foundation<br/>Storage]
        end

        subgraph "Hosted Clusters (AWS)"
            HC1[dev-cluster-01<br/>Control Plane Pods]
            HC2[staging-cluster-01<br/>Control Plane Pods]
            HC3[prod-cluster-01<br/>Control Plane Pods]

            WN1[Worker Nodes<br/>AWS EC2 Instances]
            WN2[Worker Nodes<br/>AWS EC2 Instances]
            WN3[Worker Nodes<br/>AWS EC2 Instances]
        end

        subgraph "AWS Services"
            R53[Route53<br/>DNS Management]
            S3[S3 Bucket<br/>OIDC Provider]
            ELB[Elastic Load Balancer<br/>Ingress]
        end
    end

    MC --> HC1
    MC --> HC2
    MC --> HC3
    HC1 --> WN1
    HC2 --> WN2
    HC3 --> WN3
    ArgoCD --> HC1
    ArgoCD --> HC2
    ArgoCD --> HC3
    MC --> R53
    MC --> S3
    WN1 --> ELB
    WN2 --> ELB
    WN3 --> ELB
```

### **On-Premises Deployment (Dell/Cisco/HPE Infrastructure)**
```mermaid
graph TB
    subgraph "On-Premises Data Center"
        subgraph "Management Cluster (Dell/Cisco/HPE)"
            MC[Management Cluster<br/>3x Physical Servers<br/>OpenShift + HyperShift]
            ArgoCD[ArgoCD<br/>GitOps Controller]
            ODF[OpenShift Data Foundation<br/>Storage]
            RHACM[Red Hat ACM<br/>Host Inventory]
        end

        subgraph "Hosted Clusters (Bare Metal)"
            HC1[dev-cluster-01<br/>Control Plane Pods<br/>Running on Management Cluster]
            HC2[staging-cluster-01<br/>Control Plane Pods<br/>Running on Management Cluster]
            HC3[prod-cluster-01<br/>Control Plane Pods<br/>Running on Management Cluster]
        end

        subgraph "Physical Infrastructure"
            BM1[Dell PowerEdge Server<br/>Worker Nodes]
            BM2[Cisco UCS Server<br/>Worker Nodes]
            BM3[HPE ProLiant Server<br/>Worker Nodes]
            BM4[Additional Servers<br/>Worker Nodes]
        end

        subgraph "Network Infrastructure"
            LB[Load Balancer<br/>HAProxy/F5/Cisco]
            SW[Network Switch<br/>Cisco/Juniper]
            FW[Firewall<br/>Palo Alto/Fortinet]
        end

        subgraph "Storage Infrastructure"
            SAN[SAN Storage<br/>NetApp/Pure/Dell EMC]
            NFS[NFS Storage<br/>Shared Storage]
        end

        subgraph "DNS & External Services"
            DNS[Internal DNS<br/>Bind/Windows DNS]
            LDAP[LDAP/AD<br/>Authentication]
        end
    end

    MC --> HC1
    MC --> HC2
    MC --> HC3
    HC1 --> BM1
    HC2 --> BM2
    HC3 --> BM3
    HC1 --> BM4
    ArgoCD --> HC1
    ArgoCD --> HC2
    ArgoCD --> HC3
    RHACM --> BM1
    RHACM --> BM2
    RHACM --> BM3
    RHACM --> BM4
    BM1 --> LB
    BM2 --> LB
    BM3 --> LB
    BM4 --> LB
    LB --> SW
    SW --> FW
    MC --> SAN
    MC --> NFS
    MC --> DNS
    MC --> LDAP
```

**Key Architecture Benefits:**
- **🏗️ Centralized Management**: Single management cluster controls multiple hosted clusters
- **🌐 Flexible Deployment**: Choose between AWS cloud or on-premises infrastructure
- **🚀 GitOps Automation**: ArgoCD manages all cluster deployments declaratively
- **📊 Unified Monitoring**: RHACM provides visibility across all clusters
- **🔒 Enterprise Integration**: Integrate with existing enterprise infrastructure (DNS, LDAP, SAN)

**Architecture Implementation Guides:**
- **AWS Cloud Deployment**: Start with the [Getting Started tutorial](diataxis/tutorials/getting-started-cluster.md) for cloud-based deployment
- **On-Premises Deployment**: Follow [Deploy to Bare Metal](diataxis/how-to-guides/deploy-to-bare-metal.md) to deploy on Dell/Cisco/HPE infrastructure

## 🧭 **Navigation Guide**

### **New to the HyperShift Lab?**
Start with **[Getting Started](diataxis/tutorials/getting-started-cluster.md)** to learn the basics.

### **Want to deploy to bare metal?**
Follow **[Deploy to Bare Metal](diataxis/how-to-guides/deploy-to-bare-metal.md)** to extend from AWS to on-premises infrastructure.

### **Want to customize for your environment?**
See **[Fork and Customize](diataxis/how-to-guides/fork-and-customize.md)** to adapt the lab for your infrastructure.

### **Need to solve a specific problem?**
Browse the **[How-To Guides](diataxis/how-to-guides/)** for step-by-step solutions.

### **Looking for technical details?**
Check the **[Reference Documentation](diataxis/reference/)** for complete configuration options.

### **Want to understand the architecture?**
Read the **[Explanations](diataxis/explanations/)** for design decisions and concepts.

### **Contributing to the project?**
Start with **[Development Setup](diataxis/how-to-guides/developer/development-setup.md)**.

## 📋 **Documentation Principles**

This documentation follows the **[Diátaxis framework](https://diataxis.fr/)** which organizes documentation by user needs:

- **Learning** (Tutorials): "I want to learn how to use this"
- **Problem-solving** (How-to guides): "I have a specific problem to solve"  
- **Information** (Reference): "I need to look up specific details"
- **Understanding** (Explanation): "I want to understand how this works"

## 🤝 **Contributing to Documentation**

Documentation contributions are welcome! Please:

1. **Follow the Diátaxis framework** - put content in the right category
2. **Maintain audience separation** - keep end-user and developer docs separate
3. **Use generic examples** - avoid environment-specific details
4. **Test all links** - ensure cross-references work correctly

See **[Development Setup](diataxis/how-to-guides/developer/development-setup.md)** for contribution guidelines.

## 🔗 **External Links**

- **[Main Project Repository](../README.md)**: Project overview and quick start
- **[OpenShift Documentation](https://docs.openshift.com/)**: Official OpenShift documentation
- **[HyperShift Documentation](https://hypershift-docs.netlify.app/)**: Official HyperShift documentation
- **[Red Hat Advanced Cluster Management](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/)**: RHACM documentation

---

**💡 Tip**: The **[Diátaxis documentation](diataxis/README.md)** is your primary resource. The technical reference files in this directory supplement it with specific fixes and troubleshooting information.
