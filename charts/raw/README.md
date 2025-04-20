# Generic Recurring Resources Helm Chart

This Helm chart provides a flexible mechanism to dynamically generate multiple Kubernetes manifests using a single generic configuration. It supports both inline templating and declarative resource definitions, allowing for reusable, composable infrastructure.

## Features

- **Generic Templating:**  
  Use a `template` string to generate Kubernetes resources (e.g., ConfigMaps, Deployments).

- **Declarative Resources:**  
  Define full resources directly in values without writing a template.

- **Type Auto-Detection:**  
  Automatically detects whether the source data is a map or array and iterates accordingly.

- **Deep Nested Values:**  
  Support dot‑separated `rangeKey` paths to reach deeply nested values.

- **Conditionally Enabled:**  
  Each resource can be toggled on or off with an `enabled` flag (defaults to true).

- **Flexible Iteration:**  
  If `rangeKey` is omitted, the template is rendered only once.

## Installation

To install the chart from GitHub Pages:

```bash
helm repo add thecodingsheikh https://thecodingsheikh.github.io/helm-charts
helm install raw thecodingsheikh/raw -f values.yaml
```

This chart is best used as a **dependency chart**.

---

## Values Configuration

Each resource definition under `resources` can be defined in one of two modes:

### 1. Template Mode
Use a `template` string to render a YAML manifest dynamically. You can iterate over a list or map using `rangeKey`.

#### Fields:
- `enabled` (optional): Boolean (default `true`). Set to `false` to disable rendering.
- `rangeKey` (optional): Dot-separated path to the data to iterate over. If omitted, the template is rendered once.
- `template` (required): A YAML string templated using Helm's `tpl` function.

### 2. Declarative Mode
Use full `apiVersion`, `kind`, and `spec` to define a resource directly. Useful for static resources.

#### Fields:
- `enabled` (optional): Boolean (default `true`).
- `apiVersion`, `kind`, `spec` (required): Kubernetes resource definition.
- `nameOverride` (optional): Override the default name.
- `namespace`, `labels`, `annotations` (optional): Metadata.

---

## Examples

### Example 1: Using an Array

```yaml
services:
  - name: service1
    port: 8080
    protocol: TCP
  - name: service2
    port: 9090
    protocol: TCP

resources:
  service-configmap:
    enabled: true
    rangeKey: services
    template: |-
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: configmap-{{ .name }}
      data:
        SERVICE_NAME: "{{ .name }}"
        SERVICE_PORT: "{{ .port }}"
        SERVICE_PROTOCOL: "{{ .protocol }}"
```

### Example 2: Using a Map

```yaml
applications:
  list:
    app-a:
      image: nginx:1.19
      replicas: 2
    app-b:
      image: redis:6.0
      replicas: 1

resources:
  application-deployment:
    enabled: true
    rangeKey: applications.list
    template: |-
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: deployment-{{ .key }}
      spec:
        replicas: {{ .value.replicas }}
        selector:
          matchLabels:
            app: {{ .key }}
        template:
          metadata:
            labels:
              app: {{ .key }}
          spec:
            containers:
              - name: {{ .key }}
                image: {{ .value.image }}
```
### Example 3: Normal Template

```yaml
testKey: test-value

resources:
  service-configmap:
    enabled: true
    template: |-
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: {{ .Values.testKey }}
      data:
        TEST_KEY: {{ .Values.testKey }}
```

### Example 4: Static Resource (Declarative)

```yaml
resources:
  app-parameters:
    enabled: true
    apiVersion: v1
    kind: ConfigMap
    nameOverride: configmap-app-parameters
    namespace: app
    labels:
      app: app
    annotations:
      configmap.oauth2-proxy.io/parameters: "true"
    spec:
      data:
        SAMPLE_KEY: value
```

This will render a static ConfigMap with metadata and data.

---

## Tips
- You can use `{{ .Values }}` inside your templates to access global values.
- When using `rangeKey`, the system will handle both maps and arrays.
- `rangeKey` is optional. If omitted, the template is rendered once with `.Values` context.

---

Enjoy flexible, reusable Helm manifests with just a few lines!

