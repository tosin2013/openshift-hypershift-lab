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

### **[Enterprise Pipeline: Lab Clusters → Physical Production (RHACM ZTP)](diataxis/explanations/enterprise-pipeline-architecture.md)**
```mermaid
graph TB
    subgraph "Hub Cluster (Management Infrastructure)"
        subgraph "Management Cluster"
            MC[Hub Cluster<br/>OpenShift + RHACM + HyperShift]
            ArgoCD[ArgoCD<br/>GitOps Controller]
            ODF[OpenShift Data Foundation<br/>Storage]
            ZTP[ZTP Pipeline<br/>Zero Touch Provisioning]
        end

        subgraph "Lab Environment (Hosted Clusters)"
            LAB[lab-cluster<br/>Control Plane Pods<br/>Development & Testing]
            DEV[dev-cluster<br/>Control Plane Pods<br/>Application Development]
            TEST[test-cluster<br/>Control Plane Pods<br/>Integration Testing]
        end

        subgraph "GitOps Repository"
            GIT[Git Repository<br/>SiteConfig + PolicyGenTemplate<br/>Application Manifests]
        end
    end

    subgraph "Physical Production Sites"
        subgraph "QA Environment"
            QA_SITE[QA Site<br/>Physical OpenShift Cluster]
            QA_BM1[Dell PowerEdge<br/>QA Cluster Nodes]
            QA_BM2[Cisco UCS<br/>QA Cluster Nodes]
        end

        subgraph "Production Environment"
            PROD_SITE[Production Site<br/>Physical OpenShift Cluster]
            PROD_BM1[HPE ProLiant<br/>Production Cluster Nodes]
            PROD_BM2[Dell PowerEdge<br/>Production Cluster Nodes]
            PROD_BM3[Cisco UCS<br/>Production Cluster Nodes]
        end

        subgraph "Edge Sites"
            EDGE1[Edge Site 1<br/>Single Node OpenShift]
            EDGE2[Edge Site 2<br/>Single Node OpenShift]
            EDGE_BM1[Industrial Server<br/>Edge Computing]
            EDGE_BM2[Ruggedized Hardware<br/>Edge Computing]
        end
    end

    subgraph "Enterprise Infrastructure"
        subgraph "Network & Security"
            LB[Enterprise Load Balancer<br/>F5/Cisco/HAProxy]
            FW[Enterprise Firewall<br/>Palo Alto/Fortinet]
            SW[Core Network Switch<br/>Cisco/Juniper]
        end

        subgraph "Storage & Services"
            SAN[Enterprise SAN<br/>NetApp/Pure/Dell EMC]
            DNS[Corporate DNS<br/>Bind/Windows DNS]
            LDAP[Identity Management<br/>LDAP/Active Directory]
        end
    end

    %% Development Flow
    MC --> LAB
    MC --> DEV
    MC --> TEST
    ArgoCD --> LAB
    ArgoCD --> DEV
    ArgoCD --> TEST

    %% GitOps Flow
    GIT --> ArgoCD
    GIT --> ZTP

    %% ZTP Deployment Flow
    ZTP -.->|SiteConfig + PolicyGenTemplate| QA_SITE
    ZTP -.->|SiteConfig + PolicyGenTemplate| PROD_SITE
    ZTP -.->|SiteConfig + PolicyGenTemplate| EDGE1
    ZTP -.->|SiteConfig + PolicyGenTemplate| EDGE2

    %% Physical Infrastructure
    QA_SITE --> QA_BM1
    QA_SITE --> QA_BM2
    PROD_SITE --> PROD_BM1
    PROD_SITE --> PROD_BM2
    PROD_SITE --> PROD_BM3
    EDGE1 --> EDGE_BM1
    EDGE2 --> EDGE_BM2

    %% Enterprise Services
    QA_SITE --> LB
    PROD_SITE --> LB
    EDGE1 --> LB
    EDGE2 --> LB
    LB --> SW
    SW --> FW
    MC --> SAN
    MC --> DNS
    MC --> LDAP

    %% Workflow Annotations
    LAB -.->|Develop & Test| GIT
    DEV -.->|Application Code| GIT
    TEST -.->|Validation| GIT
```

**Key Architecture Benefits:**
- **🏗️ Hub-Spoke Management**: Single hub cluster manages both hosted lab clusters and physical production sites
- **⚡ Rapid Development**: Hosted clusters provide fast, lightweight environments for development and testing
- **🏭 Zero Touch Production**: RHACM ZTP enables automated deployment to physical infrastructure at scale
- **🚀 GitOps Pipeline**: Complete development → testing → QA → production pipeline through GitOps
- **📊 Unified Governance**: RHACM policies ensure consistency across lab and production environments
- **🔒 Enterprise Integration**: Seamless integration with existing enterprise infrastructure and services

**Enterprise Workflow Pattern:**
1. **🧪 Develop & Test**: Use hosted lab clusters for rapid development and testing
2. **📝 Define Infrastructure**: Create SiteConfig and PolicyGenTemplate resources in Git
3. **🏭 Deploy to Production**: RHACM ZTP automatically provisions physical clusters
4. **📊 Manage at Scale**: Single hub cluster manages hundreds of edge and production sites

**Architecture Implementation Guides:**
- **AWS Cloud Deployment**: Start with the [Getting Started tutorial](diataxis/tutorials/getting-started-cluster.md) for cloud-based deployment
- **Enterprise Pipeline**: Follow [Deploy to Bare Metal](diataxis/how-to-guides/deploy-to-bare-metal.md) to implement the lab → production workflow

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
