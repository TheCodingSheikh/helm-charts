# Generic Recurring Resources Helm Chart

This Helm chart provides a flexible mechanism to generate multiple Kubernetes manifests dynamically from a single recurring template definition. By configuring a data source in your values file (which can be either an array or a map) and a corresponding YAML template, the chart will iterate over your data to render individual manifests.

The chart automatically detects the type of the supplied data using Helm’s built-in type functions, eliminating the need to specify whether the data is a map or an array.

## Features

- **Generic Templating:**  
  Create any type of Kubernetes manifest (e.g. ConfigMaps, Deployments, etc.) with a single recurring definition.
  
- **Type Auto-Detection:**  
  The chart auto-detects if your data is an array or a map and iterates accordingly. In the case of maps, the current key and its value are passed to the template context.

- **Deep Nested Values:**  
  Use dot‑separated paths to specify nested data in your values.

## Installation

To install the chart from GitHub Pages:

```bash
helm repo add thecodingsheikh https://thecodingsheikh.github.io/helm-charts
helm install recurring-resources thecodingsheikh/recurring-resources -f values.yaml
```

This chart is best used as a dependency chart

## Values Configuration
There are two primary keys:

- **Data Source:**  
  This is where you define your data for iteration (either an array or a map).

- **`recurringResources`:**  
  Under this key, you define one or more recurring resource entries. Each entry must specify:
  
  - **`rangeKey`:** A dot‑separated string pointing to the data source (e.g., `services` or `applications`).
  - **`template`:** A multi-line YAML snippet that uses templating syntax (via `tpl`) to render the manifest for each item.

## Example: Using an Array

The following example uses an array to generate a ConfigMap for each service defined. The array is defined under the key `services`.

### values.yaml

```yaml
# Define an array of service items.
services:
  - name: service1
    port: 8080
    protocol: TCP
  - name: service2
    port: 9090
    protocol: TCP

# Recurring resource that generates a ConfigMap for each service.
recurringResources:
  service-configmap:
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

### Expected Rendered Output

When you run the chart, you should see something similar to:

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-service1
data:
  SERVICE_NAME: "service1"
  SERVICE_PORT: "8080"
  SERVICE_PROTOCOL: "TCP"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-service2
data:
  SERVICE_NAME: "service2"
  SERVICE_PORT: "9090"
  SERVICE_PROTOCOL: "TCP"
```

## Example: Using a Map

The next example uses a map to generate a Deployment for each application. In this case, the key of the map becomes part of the resource name.

### values.yaml

```yaml
# Define a map of applications.
applications:
  app-a:
    image: nginx:1.19
    replicas: 2
  app-b:
    image: redis:6.0
    replicas: 1

# Recurring resource that generates a Deployment for each application.
recurringResources:
  application-deployment:
    rangeKey: applications
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

### Expected Rendered Output

The rendered output should look similar to:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-app-a
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app-a
  template:
    metadata:
      labels:
        app: app-a
    spec:
      containers:
        - name: app-a
          image: nginx:1.19
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-app-b
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-b
  template:
    metadata:
      labels:
        app: app-b
    spec:
      containers:
        - name: app-b
          image: redis:6.0
```