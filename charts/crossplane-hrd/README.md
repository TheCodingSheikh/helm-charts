# Crossplane-HRD (Helm Resource Definition)
ps: if you have a better name, i'd be glad to change it.

This Helm chart provides an alternative to Crossplane's Compositions and CompositeResourceDefinitions (XRD). It simplifies the process of creating hierarchical resources by using Helm templates, reducing the complexity and repetitive tasks involved in managing Crossplane resources.

## Installation

To install the chart from GitHub Pages:

```bash
helm repo add my-charts https://thecodingsheikh.github.io/helm-charts
helm install crossplane-hrd my-charts/crossplane-hrd
```

## Configuration

### Components Configuration

The `values.yaml` file allows you to define hierarchical resources using a structured `components` field. Each component can have:
- An `apiVersion`
- A `kind`
- A list of items, each with a `forProvider` field for its configuration
- Optional `dependants` for child resources
- Optional `refKey` for managing parent-child relationships dynamically

Example:

```yaml
components:
  Bucket:
    apiVersion: s3.aws.crossplane.io/v1beta1
    list:
      test-bucket:
        forProvider:
          objectOwnership: BucketOwnerEnforced
          locationConstraint: us-east-1
      repl-dest:
        forProvider:
          acl: private
          versioningConfiguration:
            status: Enabled
      bucket-3:
        forProvider:
          acl: private
          versioningConfiguration:
            status: Enabled
```

The above configuration will render

```yaml
apiVersion: s3.aws.crossplane.io/v1beta1
kind: Bucket
metadata:
  name: bucket-3-bucket
spec:
  forProvider: 
    acl: private
    versioningConfiguration:
      status: Enabled
---
apiVersion: s3.aws.crossplane.io/v1beta1
kind: Bucket
metadata:
  name: repl-dest-bucket
spec:
  forProvider: 
    acl: private
    versioningConfiguration:
      status: Enabled
---
apiVersion: s3.aws.crossplane.io/v1beta1
kind: Bucket
metadata:
  name: test-bucket-bucket
spec:
  forProvider: 
    locationConstraint: us-east-1
    objectOwnership: BucketOwnerEnforced

```

Another Example:

```yaml
components:
  VPC:
    apiVersion: ec2.aws.crossplane.io/v1beta1
    list:
      sample-vpc:
        forProvider:
          region: us-east-1
          cidrBlock: 10.0.0.0/16
        dependants:
          Subnet:
            list:
              sample-subnet1:
                forProvider:
                  region: us-east-1
                  availabilityZone: us-east-1b
                  cidrBlock: 10.0.1.0/24
                  mapPublicIPOnLaunch: true
              sample-subnet2:
                forProvider:
                  region: us-east-1
                  availabilityZone: us-east-1c
                  cidrBlock: 10.0.2.0/24
                  mapPublicIPOnLaunch: true
```

This configuration will render

```yaml
apiVersion: ec2.aws.crossplane.io/v1beta1
kind: Subnet
metadata:
  name: sample-vpc-sample-subnet1-subnet
spec:
  forProvider: 
    availabilityZone: us-east-1b
    cidrBlock: 10.0.1.0/24
    mapPublicIPOnLaunch: true
    region: us-east-1
    vpcIdRef: sample-vpc-vpc
---
apiVersion: ec2.aws.crossplane.io/v1beta1
kind: Subnet
metadata:
  name: sample-vpc-sample-subnet2-subnet
spec:
  forProvider: 
    availabilityZone: us-east-1c
    cidrBlock: 10.0.2.0/24
    mapPublicIPOnLaunch: true
    region: us-east-1
    vpcIdRef: sample-vpc-vpc
---
apiVersion: ec2.aws.crossplane.io/v1beta1
kind: VPC
metadata:
  name: sample-vpc-vpc
spec:
  forProvider: 
    cidrBlock: 10.0.0.0/16
    region: us-east-1
```

If you notice `vpcIdRef` is automatically appended in Subnets, since they are dependants,

### Customizing Resource Hierarchy

You can customize the reference keys used for parent-child relationships by setting `refKey` for each component. If no `refKey` is provided, a default key in the format `{parentKind}IdRef` will be used.

For example:
```yaml
VPC:
  refKey: vpnNameRef
```
it will render
```yaml
forProvider: 
  availabilityZone: us-east-1c
  cidrBlock: 10.0.2.0/24
  mapPublicIPOnLaunch: true
  region: us-east-1
  vpnNameRef: sample-vpc-vpc
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