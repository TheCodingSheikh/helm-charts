# Crossplane-HRD (Helm Resource Definition)

This Helm chart provides an alternative to Crossplane's Compositions and CompositeResourceDefinitions (XRD). It simplifies the process of creating hierarchical resources by using Helm templates, reducing the complexity and repetitive tasks involved in managing Crossplane resources.

## Installation

To install the chart from GitHub Pages:

```bash
helm repo add thecodingsheikh https://thecodingsheikh.github.io/helm-charts
helm install crossplane-hrd thecodingsheikh/crossplane-hrd
```

## Quick Start

```yaml
global:
  providerConfigRef:
    name: aws-prod

components:
  VPC:
    apiVersion: ec2.aws.upbound.io/v1beta1
    list:
      main:
        forProvider:
          region: us-east-1
          cidrBlock: 10.0.0.0/16
        dependants:
          Subnet:
            list:
              web:
                forProvider:
                  region: us-east-1
                  availabilityZone: us-east-1b
                  cidrBlock: 10.0.1.0/24
```

**Renders:**
```yaml
---
apiVersion: ec2.aws.upbound.io/v1beta1
kind: VPC
metadata:
  name: main-vpc
spec:
  providerConfigRef:
    name: aws-prod
  forProvider:
    cidrBlock: 10.0.0.0/16
    region: us-east-1
---
apiVersion: ec2.aws.upbound.io/v1beta1
kind: Subnet
metadata:
  name: main-web-subnet
spec:
  providerConfigRef:
    name: aws-prod
  forProvider:
    availabilityZone: us-east-1b
    cidrBlock: 10.0.1.0/24
    region: us-east-1
    vpcIdRef:
      name: main-vpc
```

## Values Reference

The values have three levels:

```yaml
global:                # settings for every resource
  ...
components:
  <Kind>:              # a component: one resource kind
    ...
    list:
      <name>:          # a resource
        ...
        dependants:
          <Kind>:      # a component again, nested under the resource
            ...
```

### `global`

Settings applied to every resource. Any resource can override them (see [Settings: Overrides and Inheritance](#settings-overrides-and-inheritance)).

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `providerConfigRef` | map | `{}` | Rendered as `spec.providerConfigRef`, same fields as Crossplane: `name`, and `kind` (`ProviderConfig` or `ClusterProviderConfig`) for namespaced resources. Empty renders no `providerConfigRef`. |
| `namespace` | string | `""` | Rendered as `metadata.namespace`. Only for namespaced managed resources (Crossplane v2, e.g. `*.m.upbound.io`). Empty renders no namespace, as cluster scoped resources need. |
| `labels` | map | `{}` | Rendered as `metadata.labels`. Values are converted to strings. |
| `annotations` | map | `{}` | Rendered as `metadata.annotations`. Values are converted to strings. |
| `spec` | map | `{}` | Any other field rendered under `spec`, e.g. `deletionPolicy`, `managementPolicies`, `initProvider`, `writeConnectionSecretToRef`, or provider specific fields. `forProvider` and `providerConfigRef` are not allowed here, set them with their own fields. |

### `components`

A map of resource kinds. The key is rendered as `kind`; the same fields apply to the kinds under a resource's `dependants`.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `apiVersion` | string | parent's `apiVersion` | API version of the resources. Required at the top level; a dependant uses its parent's unless set, and passes it on to its own dependants. |
| `refKey` | string | `<kind>IdRef` | Field name that dependants use in `forProvider` to reference resources of this kind, e.g. `vpcIdRef` for `VPC`. |
| `appendName` | bool | `false` | Sets `forProvider.name` to the resource name. |
| `list` | map or list | | The resources of this kind: a map of resource name to [resource fields](#resources), or a list of names for resources that need no fields. |

### Resources

The fields of each entry in `list`.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `forProvider` | map | `{}` | Rendered as `spec.forProvider`. References to the parent resources are added to it. |
| `dependants` | map | `{}` | Resources that depend on this one, same format as `components`. Each dependant references this resource and all of its ancestors. |
| `inherit` | bool | `false` | When `true`, this resource's settings (below) are passed down to all of its dependants, at every depth. |
| `providerConfigRef` | map | inherited | Overrides `global.providerConfigRef` for this resource. |
| `namespace` | string | inherited | Overrides `global.namespace` for this resource. |
| `labels` | map | inherited | Overrides `global.labels` for this resource. |
| `annotations` | map | inherited | Overrides `global.annotations` for this resource. |
| `spec` | map | inherited | Overrides `global.spec` for this resource. |

## Settings: Overrides and Inheritance

The settings are `providerConfigRef`, `namespace`, `labels`, `annotations` and `spec`. A resource starts from the settings it inherits (`global` by default) and applies its own on top:

- Maps are merged, and the resource's value wins for keys set on both. This includes `providerConfigRef`, so `providerConfigRef: {name: other}` keeps an inherited `kind`.
- Any other value (string, number, boolean, list) replaces the inherited one.
- `null` removes an inherited value: `labels: {team: null}` removes one label, `labels: null` removes all of them.
- `namespace: ""` renders the resource without a namespace.

A resource's own settings apply only to that resource. Set `inherit: true` to also pass them down to all of its dependants:

```
global: namespace infra
├── VPC main          inherit: true, namespace: network   -> network
│   ├── Subnet web                                        -> network  (from main)
│   │   └── RouteTable a                                  -> network  (from main)
│   └── Subnet db     namespace: db                       -> db
│       └── RouteTable b                                  -> network  (db does not inherit, main does)
└── VPC other                                             -> infra
```

### Example

```yaml
global:
  providerConfigRef:
    name: default
    kind: ClusterProviderConfig
  namespace: infra
  labels:
    team: platform
  annotations:
    owner: sre
  spec:
    managementPolicies: ["*"]

components:
  VPC:
    apiVersion: ec2.aws.m.upbound.io/v1beta1
    list:
      main:
        inherit: true               # main's settings also apply to its subnets
        providerConfigRef:
          name: network             # merged: kind ClusterProviderConfig is kept
        namespace: network
        labels:
          tier: network
        forProvider:
          region: us-east-1
          cidrBlock: 10.0.0.0/16
        dependants:
          Subnet:
            list:
              web:
                spec:
                  managementPolicies: ["Observe"]
                forProvider:
                  region: us-east-1
                  cidrBlock: 10.0.1.0/24
      sandbox:
        labels:
          team: null                # removes the global label
        forProvider:
          region: eu-west-1
          cidrBlock: 10.1.0.0/16
```

**Renders:**
```yaml
---
apiVersion: ec2.aws.m.upbound.io/v1beta1
kind: VPC
metadata:
  name: main-vpc
  namespace: network
  labels:
    team: platform
    tier: network
  annotations:
    owner: sre
spec:
  managementPolicies:
  - '*'
  providerConfigRef:
    kind: ClusterProviderConfig
    name: network
  forProvider:
    cidrBlock: 10.0.0.0/16
    region: us-east-1
---
apiVersion: ec2.aws.m.upbound.io/v1beta1
kind: Subnet
metadata:
  name: main-web-subnet
  namespace: network
  labels:
    team: platform
    tier: network
  annotations:
    owner: sre
spec:
  managementPolicies:
  - Observe
  providerConfigRef:
    kind: ClusterProviderConfig
    name: network
  forProvider:
    cidrBlock: 10.0.1.0/24
    region: us-east-1
    vpcIdRef:
      name: main-vpc
---
apiVersion: ec2.aws.m.upbound.io/v1beta1
kind: VPC
metadata:
  name: sandbox-vpc
  namespace: infra
  annotations:
    owner: sre
spec:
  managementPolicies:
  - '*'
  providerConfigRef:
    kind: ClusterProviderConfig
    name: default
  forProvider:
    cidrBlock: 10.1.0.0/16
    region: eu-west-1
```

Without `inherit: true` on `main`, `main-web-subnet` would get the global settings: namespace `infra`, provider config `default`, no `tier` label.

### Things to keep in mind

- Namespaced managed resources can only reference resources in their own namespace, so when a resource with dependants overrides `namespace`, set `inherit: true`.
- Connection secret names must be unique, so set `spec.writeConnectionSecretToRef` on the resource itself, not in `global` or on a resource with `inherit: true`.

## Names and References

### Names
- A top level resource is named `<name>-<kind>`, e.g. `main-vpc`.
- A dependant is prefixed with the names of its ancestors, e.g. `main-web-subnet`.
- The kind is lowercased and the resource name is converted to kebab case, so use lowercase, dash separated names.

### References
Every dependant gets a reference to each of its ancestors in `forProvider`, named after the ancestor's `refKey`:

```yaml
components:
  VPC:
    apiVersion: ec2.aws.upbound.io/v1beta1
    list:
      main:
        forProvider:
          region: us-east-1
          cidrBlock: 10.0.0.0/16
        dependants:
          Subnet:
            list:
              web:
                forProvider:
                  region: us-east-1
                  cidrBlock: 10.0.1.0/24
                dependants:
                  RouteTable:
                    list:
                      public:
                        forProvider:
                          region: us-east-1
```

**Renders** (the RouteTable):
```yaml
apiVersion: ec2.aws.upbound.io/v1beta1
kind: RouteTable
metadata:
  name: main-web-public-routetable
spec:
  forProvider:
    region: us-east-1
    subnetIdRef:
      name: main-web-subnet
    vpcIdRef:
      name: main-vpc
```

### Custom Reference Key
Set `refKey` on a component to change the field its dependants use:

```yaml
components:
  VPC:
    apiVersion: ec2.aws.upbound.io/v1beta1
    refKey: networkIdentifier
    list:
      main:
        dependants:
          Subnet:
            list: [web]
```

**Renders** (the Subnet):
```yaml
apiVersion: ec2.aws.upbound.io/v1beta1
kind: Subnet
metadata:
  name: main-web-subnet
spec:
  forProvider:
    networkIdentifier:
      name: main-vpc
```

### API Version Override
Dependants use their parent's `apiVersion` unless they set their own, which is then used by their dependants too:

```yaml
dependants:
  Subnet:
    apiVersion: ec2.aws.upbound.io/v1beta1
    list: {...}
```

### Name Appending and Lists
Some resources have a `name` field under `forProvider`; `appendName: true` fills it with the resource name. Resources that need no other fields can be written as a list of names:

```yaml
components:
  Bucket:
    apiVersion: s3.aws.upbound.io/v1beta1
    appendName: true
    list:
      - logs
      - assets
```

**Renders:**
```yaml
---
apiVersion: s3.aws.upbound.io/v1beta1
kind: Bucket
metadata:
  name: logs-bucket
spec:
  forProvider:
    name: logs
---
apiVersion: s3.aws.upbound.io/v1beta1
kind: Bucket
metadata:
  name: assets-bucket
spec:
  forProvider:
    name: assets
```

## Upgrading from 0.4.x

Replace the top-level `providerConfig`:

```yaml
# before
providerConfig: aws-prod

# after
global:
  providerConfigRef:
    name: aws-prod
```

The old `providerConfig` still works for now; if both are set, `global.providerConfigRef` wins.

## Why Choose Crossplane-HRD?

- **Ease of Use**: No need to learn the intricacies of XRD or Composition files.
- **Flexibility**: Supports hierarchical resource creation with minimal configuration.
- **Dynamic References**: Automatically handles resource dependencies and references.

## Testing

The render tests need `helm` and `yq` (v4):

```bash
python3 charts/crossplane-hrd/tests/test_chart.py -v
```

## Uninstall

```bash
helm uninstall crossplane-hrd
```
