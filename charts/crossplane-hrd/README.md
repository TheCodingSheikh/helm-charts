# Crossplane-HRD (Helm Resource Definition)
ps: if you have a better name, i'd be glad to change it.

This Helm chart provides an alternative to Crossplane's Compositions and CompositeResourceDefinitions (XRD). It simplifies the process of creating hierarchical resources by using Helm templates, reducing the complexity and repetitive tasks involved in managing Crossplane resources.

## Installation

To install the chart from GitHub Pages:

```bash
helm repo add thecodingsheikh https://thecodingsheikh.github.io/helm-charts
helm install crossplane-hrd thecodingsheikh/crossplane-hrd
```

Here's the updated documentation reflecting the latest implementation:

# Crossplane Helm Chart Documentation

## Configuration

### Global Configuration
```yaml
providerConfig: aws-prod  # Global provider config for all resources
```

### Components Configuration

#### Basic Example
```yaml
components:
  Bucket:
    apiVersion: s3.aws.crossplane.io/v1beta1
    list:
      test:
        forProvider:
          objectOwnership: BucketOwnerEnforced
          locationConstraint: us-east-1
```

**Renders:**
```yaml
---
apiVersion: s3.aws.crossplane.io/v1beta1
kind: Bucket
metadata:
  name: test-bucket
spec:
  providerConfigRef:
    name: aws-prod
  forProvider: 
    locationConstraint: us-east-1
    objectOwnership: BucketOwnerEnforced
```

### Nested Dependencies
```yaml
components:
  VPC:
    apiVersion: ec2.aws.crossplane.io/v1beta1
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
                  availabilityZone: us-east-1b
                  cidrBlock: 10.0.1.0/24
              db:
                forProvider:
                  availabilityZone: us-east-1c
                  cidrBlock: 10.0.2.0/24
```

**Rendered Output:**
```yaml
---
apiVersion: ec2.aws.crossplane.io/v1beta1
kind: VPC
metadata:
  name: main-vpc
spec:
  providerConfigRef:
    name: aws-prod
  forProvider:
    region: us-east-1
    cidrBlock: 10.0.0.0/16
---
apiVersion: ec2.aws.crossplane.io/v1beta1
kind: Subnet
metadata:
  name: main-db-subnet
spec:
  providerConfigRef:
    name: aws-prod
  forProvider:
    availabilityZone: us-east-1c
    cidrBlock: 10.0.2.0/24
    vpcIdRef:
      name: main-vpc
---
apiVersion: ec2.aws.crossplane.io/v1beta1
kind: Subnet
metadata:
  name: main-web-subnet
spec:
  providerConfigRef:
    name: aws-prod
  forProvider:
    availabilityZone: us-east-1b
    cidrBlock: 10.0.1.0/24
    vpcIdRef:
      name: main-vpc
```

### Multi-Level Dependencies
```yaml
components:
  VPC:
    apiVersion: ec2.aws.crossplane.io/v1beta1
    list:
      main-vpc:
        forProvider:
          region: us-east-1
          cidrBlock: 10.0.0.0/16
        dependants:
          Subnet:
            list:
              web-subnet:
                forProvider:
                  cidrBlock: 10.0.1.0/24
                dependants:
                  RouteTable:
                    list:
                      public-rt:
                        forProvider:
                          routes: [...]
```

**Rendered Output:**
```yaml
---
apiVersion: ec2.aws.crossplane.io/v1beta1
kind: RouteTable
metadata:
  name: main-web-public-routetable
spec:
  providerConfigRef:
    name: aws-prod
  forProvider:
    routes:
    - '...'
    vpcIdRef:
      name: main-vpc
    subnetIdRef:
      name: main-web-subnet
```

### Customization Options

#### 1. Reference Key Customization
```yaml
components:
  VPC:
    refKey: networkIdentifier  # Custom reference key
    apiVersion: ec2.aws.crossplane.io/v1beta1
    list:
      main: {...}
```

**Results in:**
```yaml
networkIdentifier: # Instead of vpcIdRef
  name: main-vpc  
```

#### 2. API Version Override
every dependant takes the parent apiVersion by default, you can override it like:
```yaml
dependants:
  Subnet:
    apiVersion: ec2.aws.upbound.io/v1beta1  # Override parent's API version
    list: {...}
```
now all dependants of Subnet will take its apiVersion by default, unless overriden

#### 3. Name Appending
some resources have the field `name` under `forProvider`, if you want to automatically append this field with the value of the resouce key name u can use `appenName: true`:

```yaml
components:
  VPC:
    apiVersion: ec2.aws.crossplane.io/v1beta1
    appenName: true
    list:
      main: {...}
```

**Results in:**
```yaml
apiVersion: ec2.aws.crossplane.io/v1beta1
kind: VPC
metadata:
  name: main-vpc
spec:
  providerConfigRef:
    name: aws-prod
  forProvider:
    name: main # Here
    ...
```

#### 4. Array Instead of Dict
This chart allows to list resources as dict, like

```yaml
components:
  Bucket:
    apiVersion: s3.aws.crossplane.io/v1beta1
    list:
      test:
        forProvider: {}
      test2:
        forProvider: {}
      test3:
        forProvider: {}
```
you can leave the forProvider empty, as some resources allows this, but this becomes noisy, this can be written as array.

```yaml
components:
  Bucket:
    apiVersion: s3.aws.crossplane.io/v1beta1
    list:
      - test
      - test2
      - test3
```

both will render same manifests, u can also use array in nested dependency the chart will append the reference keys automatically, u can combine this with `appendName: true` if name field is needed which will result in clean values structure

for example,

```yaml
components:
  Bucket:
    apiVersion: s3.aws.crossplane.io/v1beta1
    appendName: true
    list:
      - bucket1
      - bucket2
      - bucket3
```

**Renders:**
```yaml
---
apiVersion: s3.aws.crossplane.io/v1beta1
kind: Bucket
metadata:
  name: bucket1-bucket
spec:
  forProvider: 
    name: bucket1
---
apiVersion: s3.aws.crossplane.io/v1beta1
kind: Bucket
metadata:
  name: bucket2-bucket
spec:
  forProvider: 
    name: bucket2
---
apiVersion: s3.aws.crossplane.io/v1beta1
kind: Bucket
metadata:
  name: bucket3-bucket
spec:
  forProvider: 
    name: bucket3
```

### Name Generation
each manifest is generated in the format `{name}-{kind}`
the dependant manifests are generated in the format `{parent-names..}-{name}-{kind}`

### Provider Configuration
Set globally for all resources:
```yaml
providerConfig: aws-production
```

All resources will include:
```yaml
spec:
  providerConfigRef:
    name: aws-production
```

## Features

### Simplified Resource Creation

Unlike Crossplane's Compositions and XRD, this chart eliminates the need for complex YAML structures. Define resources hierarchically, and the chart will render the necessary templates with references automatically.

### Dynamic Reference Management

The chart dynamically calculates and injects reference keys into child resources, ensuring proper parent-child relationships without manual effort.

---

## Uninstall

To uninstall the chart:

```bash
helm uninstall crossplane-hrd
```

---

## Why Choose Crossplane-HRD?

- **Ease of Use**: No need to learn the intricacies of XRD or Composition files.
- **Flexibility**: Supports hierarchical resource creation with minimal configuration.
- **Dynamic References**: Automatically handles resource dependencies and references.

Say goodbye to the headache of managing Crossplane Compositions and XRD—start using Crossplane-HRD for a smoother experience!
