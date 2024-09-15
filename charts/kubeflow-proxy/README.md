# Kubeflow Proxy

This Helm chart sets up a proxy for the Kubeflow Istio ingress gateway. It forwards traffic to the Istio ingress service using `kubectl port-forward` and exposes it via an NGINX proxy.

## Installation

To install the chart from GitHub Pages:

```bash
helm repo add my-charts https://<your-github-pages-url>/helm-charts
helm install kubeflow-proxy my-charts/kubeflow-proxy
```

## Assumptions

- **Kubeflow** is assumed to be installed using the official manifests from the Kubeflow manifest repository.

## Configuration

### Ingress Configuration

Ingress is enabled by default, you can customize the host and enable TLS settings:

```yaml
ingress:
  className: nginx
  annotations:
     cert-manager.io/cluster-issuer: nameOfClusterIssuer
  host: kubeflow.example.com
  tls: true
```

Example:

```bash
helm upgrade kubeflow-proxy my-charts/kubeflow-proxy \
  --set ingress.className=nginx \
  --set ingress.annotations.cert-manager.io/cluster-issuer=nameOfClusterIssuer \
  --set ingress.host=kubeflow.example.com \
  --set ingress.tls=true
```

### Istio Ingress Configuration

- **Istio** is assumed to be installed in the `istio-system` namespace with the default ingress gateway service named `istio-ingressgateway` and running on port `80`.

If your Istio installation differs from the assumptions above (e.g., installed in a different namespace, with a different service name or port), you can update the following values in `values.yaml`:

```yaml
istioIngressGatewaySvcName: my-istio-ingressgateway
istioIngressGatewaySvcPort: 8084
istioIngressGatewayNamespace: my-namespace
```

Example:

```bash
helm upgrade kubeflow-proxy my-charts/kubeflow-proxy \
  --set istioIngressGatewaySvcName=my-istio-ingressgateway \
  --set istioIngressGatewaySvcPort=8084 \
  --set istioIngressGatewayNamespace=my-namespace
```

## Uninstall

To uninstall the chart:

```bash
helm uninstall kubeflow-proxy
```
