# Generic Resources Helm Chart

This Helm chart lets you define Kubernetes resources (like ConfigMaps or Deployments) directly in your `values.yaml`. You can:

- Loop over arrays or maps
- Use templates or full objects
- Enable or disable resources

⚠️ Only the `resources:` key is rendered into manifests. Everything else (like `applications`, `services`, `testKey`) is just data used in your templates.

---

## ✅ Features

- Write full Kubernetes resources or just templates
- Loop over arrays or maps (auto-detects which)
- Supports nested keys with dot notation
- Render once or loop multiple times
- Toggle rendering with `enabled: true/false`
- When looping over a **map**, `.key` and `.value` will be available in the template

---

## 🚀 Quick Install

```bash
helm repo add thecodingsheikh https://thecodingsheikh.github.io/helm-charts
helm install raw thecodingsheikh/raw -f values.yaml
```

Use it as a **dependency chart** in your own Helm charts.

---

## 🛠 Basic Usage

### ✅ Define Your Data
You can define global values that will be used by this chart. This chart is designed to work great as a **dependency chart** inside your main Helm chart, so all values defined in the parent chart will be accessible here under `.Values`.
You can define arrays, maps, or values to use in templates:
```yaml
applications:
  list:
    app-a:
      image: nginx:1.19
      replicas: 2
    app-b:
      image: redis:6.0
      replicas: 1

services:
  - name: service1
    port: 8080
    protocol: TCP

  - name: service2
    port: 9090
    protocol: TCP

testKey: test-value
```

### ✅ Define Resources
```yaml
resources:
  # Loop over applications map
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

  # Loop over services array
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

  # Render once (no loop)
  single-config:
    enabled: true
    template: |-
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: configmap-{{ .Values.testKey }}
      data:
        TEST_KEY: {{ .Values.testKey }}

  # Declarative full resource
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

---

## 💡 Tips

- Use `.Values` inside templates to access global values.
- `rangeKey` is optional; omit it to render the template once.
- You can disable any resource by setting `enabled: false`.
- `resources:` is the only key that generates manifests.
- When iterating over a **map**, the template gets:
  - `.key`: the map key (e.g. `app-a`)
  - `.value`: the map value (e.g. `{ image: nginx, replicas: 2 }`)

---

With just a clean `values.yaml`, you can manage multiple resources with less YAML and full control. 💡

Happy templating! 🚀

