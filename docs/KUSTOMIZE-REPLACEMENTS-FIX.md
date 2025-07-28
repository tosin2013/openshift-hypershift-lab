# Kustomize Replacements Fix: Moving to Instance Level

## Problem Summary

The original issue was that Kustomize replacements were not working correctly for complex field paths in HyperShift hosted cluster configurations. The replacements were defined in the template layer but couldn't access values that were being set by parent kustomizations.

## Root Cause

**Kustomize Execution Order Issue**: Replacements run at the layer where they're defined and cannot access fields that are modified by parent kustomizations. The original configuration had:

1. **Base layer**: Contains resources with placeholders
2. **Template layer**: Contains replacements trying to replace placeholders
3. **Instance layer**: Contains final values set by `sed` commands

The replacements in the template layer couldn't see the final values because they execute before the parent layer transformations.

## Solution: Move Replacements to Instance Level

The fix moves the replacements from the template level to the instance level where the final values are available.

### Changes Made

#### 1. Updated Template Kustomization (`overlays/template/kustomization.yaml`)
- Removed the `replacements:` section
- Added placeholder comment `# REPLACEMENTS_PLACEHOLDER` for script insertion
- Added `NODEPOOL_FULL_NAME` to ConfigMap for proper nodepool naming

#### 2. Created Replacements Template (`overlays/template/replacements-template.yaml`)
- Contains all replacement definitions that will be inserted into instance kustomizations
- Fixed field path syntax issues:
  - `metadata.labels.[cluster]` → `metadata.labels.cluster`
  - `spec.networking.clusterNetwork.[cidr=X].cidr` → `spec.networking.clusterNetwork.0.cidr`
  - `spec.template.spec.compute.memory` → `spec.platform.kubevirt.compute.memory`

#### 3. Updated Creation Script (`scripts/create-hosted-cluster-instance.sh`)
- Added logic to insert replacements from template into instance kustomization
- Added handling for `NODEPOOL_FULL_NAME` placeholder replacement

#### 4. Created Test Script (`scripts/test-kustomize-replacements.sh`)
- Validates that replacements work correctly
- Tests kustomize build without applying to cluster
- Checks for unreplaced placeholders and validates specific values

### Replacement Definitions

The following replacements are now working correctly at the instance level:

```yaml
replacements:
  # Cluster name in multiple locations
  - source:
      kind: ConfigMap
      name: cluster-config
      fieldPath: data.CLUSTER_NAME
    targets:
      - select:
          kind: HostedCluster
        fieldPaths:
          - metadata.name
          - spec.infraID
          - spec.platform.kubevirt.credentials.infraKubeConfigSecret.name
          - spec.platform.kubevirt.infraNamespace
      - select:
          kind: NodePool
        fieldPaths:
          - spec.clusterName
          - metadata.labels.cluster

  # Cluster namespace
  - source:
      kind: ConfigMap
      name: cluster-config
      fieldPath: data.CLUSTER_NAMESPACE
    targets:
      - select:
          kind: HostedCluster
        fieldPaths:
          - metadata.namespace
      - select:
          kind: NodePool
        fieldPaths:
          - metadata.namespace

  # NodePool full name (cluster-name-pool-name)
  - source:
      kind: ConfigMap
      name: cluster-config
      fieldPath: data.NODEPOOL_FULL_NAME
    targets:
      - select:
          kind: NodePool
        fieldPaths:
          - metadata.name

  # Network CIDRs (using array index syntax)
  - source:
      kind: ConfigMap
      name: cluster-config
      fieldPath: data.CLUSTER_NETWORK_CIDR
    targets:
      - select:
          kind: HostedCluster
        fieldPaths:
          - spec.networking.clusterNetwork.0.cidr

  # NodePool compute resources
  - source:
      kind: ConfigMap
      name: cluster-config
      fieldPath: data.NODEPOOL_MEMORY
    targets:
      - select:
          kind: NodePool
        fieldPaths:
          - spec.platform.kubevirt.compute.memory
```

## Validation

The fix has been validated with a comprehensive test that:

1. ✅ Creates a test instance using the updated script
2. ✅ Runs `kustomize build` to generate final YAML
3. ✅ Verifies no unreplaced placeholders remain
4. ✅ Validates specific field replacements work correctly
5. ✅ Confirms proper cluster name, nodepool name, namespace, and domain values

## Benefits

1. **Correct Execution Order**: Replacements now run where final values are available
2. **Proper Field Paths**: Fixed syntax issues with complex nested structures
3. **Maintainable**: Clear separation between template and instance-specific configurations
4. **Testable**: Comprehensive validation ensures replacements work correctly
5. **GitOps Compatible**: Works with the existing ArgoCD ApplicationSet pattern

## Usage

The fix is transparent to users. The existing `create-hosted-cluster-instance.sh` script now automatically:

1. Creates the instance directory
2. Copies and customizes the template files
3. Inserts the replacements at the instance level
4. Replaces all placeholders with actual values

Users can validate their configurations with:
```bash
./scripts/test-kustomize-replacements.sh
```

This ensures that Kustomize replacements work correctly for complex HyperShift hosted cluster configurations in a GitOps environment.
