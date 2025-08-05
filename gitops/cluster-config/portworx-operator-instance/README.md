## Portworx StorageCluster Install

### Prerequisites

Before running this, we need a secret with the Pure FlashArray and FlashBlade credentials in the `portworx` namespace named `px-pure-secret` with the contents of a JSON file named `pure.json`. See [this document](https://docs.portworx.com/portworx-enterprise/platform/openshift/ocp-flasharray/install-flasharray/install-with-px-storev2#create-a-kubernetes-secret) for more information.