# Kubeflow Helm Chart

This Helm chart generates an `AppProject` and multiple `Application` resources for ArgoCD, one for each component defined under `resources:` in `values.yaml`.

> **Note:** This chart assumes that **ArgoCD is already installed** in your cluster.

Each resource corresponds to a kubeflow resource and is preconfigured with paths and overlays matching those used in `examples/kustomization.yaml` from the [Kubeflow manifests upstream repository](https://github.com/kubeflow/manifests).

---

## Usage

### Installation

```bash
helm repo add thecodingsheikh https://thecodingsheikh.github.io/helm-charts
helm install kubeflow thecodingsheikh/kubeflow
```

this will install a working kubeflow exactly like [example](https://github.com/kubeflow/manifests/blob/master/example/kustomization.yaml)
---

### Values Reference

```yaml
# Name of the ArgoCD AppProject
argoProjectName: kubeflow

# Namespace where ArgoCD is installed
argoNamespace: argocd

# Common annotations for all argo apps
commonAppAnnotations: {}

# Destination Kubernetes cluster ArgoCD will deploy to
destinationServer: https://kubernetes.default.svc

# Kubeflow manifests Git repo
kubeflowManifestsRepo: https://github.com/kubeflow/manifests

# Git branch to use
kubeflowManifestsRepoBranch: HEAD

# All resources you want to deploy
resources:
  <componentName>: < this will be the argo app name converted to [kebabcase](https://helm.sh/docs/chart_template_guide/function_list/#kebabcase)
    enabled: true | false (required)
    path: <path/in/repo> (required)
    appNameOverride: custom argo app name (optional)
    repoOverride: custom repo source (optional - defaults to `kubeflowManifestsRepo`)
    repoBranchOverride: custom repo branch (optional - defaults to `kubeflowManifestsRepoBranch`)
    labels: argo app labels (optional)
    annotations: argo app annotations (optional)
    kustomize: [kustomize config for argo app](https://argo-cd.readthedocs.io/en/latest/user-guide/kustomize/#patches) (optional)

raw:
  resources: {} # extra resources
```

---

## Configuration

### Default `values.yaml`

```yaml
argoProjectName: kubeflow
argoNamespace: argocd
destinationServer: https://kubernetes.default.svc
kubeflowManifestsRepo: https://github.com/kubeflow/manifests
kubeflowManifestsRepoBranch: HEAD

resources:
  certManagerBase:
    enabled: true
    path: common/cert-manager/base

  certManagerKubeflowIssuer:
    enabled: true
    path: common/cert-manager/kubeflow-issuer/base

  istioCrds:
    enabled: true
    path: common/istio-1-24/istio-crds/base

  istioNamespace:
    enabled: true
    path: common/istio-1-24/istio-namespace/base

  istioInstall:
    enabled: true
    path: common/istio-1-24/istio-install/overlays/oauth2-proxy

  oauth2Proxy:
    enabled: true
    path: common/oauth2-proxy/overlays/m2m-dex-only

  dex:
    enabled: true
    path: common/dex/overlays/oauth2-proxy

  knativeServing:
    enabled: true
    path: common/knative/knative-serving/overlays/gateways

  clusterLocalGateway:
    enabled: true
    path: common/istio-1-24/cluster-local-gateway/base

  kubeflowNamespace:
    enabled: true
    path: common/kubeflow-namespace/base

  networkPolicies:
    enabled: true
    path: common/networkpolicies/base

  kubeflowRoles:
    enabled: true
    path: common/kubeflow-roles/base

  kubeflowIstioResources:
    enabled: true
    path: common/istio-1-24/kubeflow-istio-resources/base

  pipelines:
    enabled: true
    path: apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user

  katib:
    enabled: true
    path: apps/katib/upstream/installs/katib-with-kubeflow

  centralDashboard:
    enabled: true
    path: apps/centraldashboard/overlays/oauth2-proxy

  admissionWebhook:
    enabled: true
    path: apps/admission-webhook/upstream/overlays/cert-manager

  jupyterWebApp:
    enabled: true
    path: apps/jupyter/jupyter-web-app/upstream/overlays/istio

  notebookController:
    enabled: true
    path: apps/jupyter/notebook-controller/upstream/overlays/kubeflow

  profiles:
    enabled: true
    path: apps/profiles/upstream/overlays/kubeflow

  pvcViewer:
    enabled: true
    path: apps/pvcviewer-controller/upstream/base

  volumesWebApp:
    enabled: true
    path: apps/volumes-web-app/upstream/overlays/istio

  tensorboardController:
    enabled: true
    path: apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow

  tensorboardsWebApp:
    enabled: true
    path: apps/tensorboard/tensorboards-web-app/upstream/overlays/istio

  trainingOperator:
    enabled: true
    path: apps/training-operator/upstream/overlays/kubeflow

  userNamespace:
    enabled: true
    path: common/user-namespace/base

  kserve:
    enabled: true
    path: apps/kserve/kserve

  kserveModelsWebApp:
    enabled: true
    path: apps/kserve/models-web-app/overlays/kubeflow
```
### Sample `values.yaml` Override

```yaml
kubeflowManifestsRepoBranch: v1.10.0-branch

resources:
  istioCrds:
    enabled: false

  myCustomRepo: # app name will be my-custom-repo
    enabled: true
    repoOverride: <my repo url>
    repoBranchOverride: HEAD
    path: extras
    
  centralDashboard:
    kustomize:
      patches:
      - target:
          kind: ConfigMap
          name: centraldashboard-config
        patch: |-
          - op: replace
            path: /data/links
            value: |
              {
                "menuLinks": [
                  {
                    "type": "item",
                    "link": "/jupyter/",
                    "text": "Notebooks",
                    "icon": "book"
                  },
                  {
                    "type": "item",
                    "link": "/volumes/",
                    "text": "Volumes",
                    "icon": "device:storage"
                  }
                ],
                "externalLinks": [ ],
                  "quickLinks": [
                    {
                      "text": "Create a new Notebook server",
                      "desc": "Notebook Servers",
                      "link": "/jupyter/new?namespace=kubeflow"
                    }
                  ],
                  "documentationItems": [
                    {
                      "text": "Getting Started with Kubeflow",
                      "desc": "Get your machine-learning workflow up and running on Kubeflow",
                      "link": "https://www.kubeflow.org/docs/started/getting-started/"
                    }
                  ]
              }
```

### Extra Raw Manifests
this chart have the [Raw](https://github.com/TheCodingSheikh/helm-charts/tree/main/charts/raw) chart as dependency, so you can define extra resources directly in `values.yaml`

#### Example Adding Extra Ingress

```yaml
raw:
  resources:
    istio-ingress:
      apiVersion: networking.k8s.io/v1
      kind: Ingress
      annotations:
        nginx.ingress.kubernetes.io/ssl-redirect: "true"
      namespace: istio-system
      spec:
        spec:
          ingressClassName: nginx
          rules:
          - host: kubeflow.local.domain
            http:
              paths:
              - backend:
                  service:
                    name: istio-ingressgateway
                    port:
                      number: 80
                path: /
                pathType: Prefix
          tls:
          - hosts:
            - kubeflow.local.domain
            secretName: kubeflow-ingressgateway-tls
```

### Example `values.yaml` Override To Integrate Keycloak [Ref](https://github.com/kubeflow/manifests/tree/master/common/dex#kubeflow-dex--keycloak-integration-guide)
```yaml
resources:
  dex:
    kustomize:
      patches:
      - target:
          kind: ConfigMap
          name: dex
        patch: |-
          - op: replace
            path: /data/config.yaml
            value: |
              issuer: $DEX_ISSUER
              storage:
                type: kubernetes
                config:
                  inCluster: true
              web:
                http: 0.0.0.0:5556
              logger:
                level: "debug"
                format: text
              oauth2:
                skipApprovalScreen: true
              enablePasswordDB: false
              # staticPasswords:
              # - email: user@example.com
              #   hashFromEnv: DEX_USER_PASSWORD
              #   username: user
              #   userID: "15841185641784"
              staticClients:
              - idEnv: OIDC_CLIENT_ID
                redirectURIs: ["/oauth2/callback"]
                name: 'Dex Login Application'
                secretEnv: OIDC_CLIENT_SECRET
              connectors:
              - type: oidc
                id: keycloak
                name: keycloak
                config:
                  issuer: $KEYCLOAK_ISSUER
                  clientID: $CLIENT_ID
                  clientSecret: $CLIENT_SECRET
                  redirectURI: $REDIRECT_URI
                  insecure: false
                  insecureSkipEmailVerified: true
                  userNameKey: email       
                  scopes:
                    - openid
                    - profile
                    - email
                    - offline_access
  oauth2Proxy:
    kustomize:
      patches:
      - target:
          kind: RequestAuthentication
          name: dex-jwt
        patch: |-
          - op: replace
            path: /spec/jwtRules/0/issuer
            value: $DEX_ISSUER

      - target:
          kind: ConfigMap
          name: oauth2-proxy
        patch: |-
          - op: replace
            path: /data/oauth2_proxy.cfg
            value: |
              provider = "oidc"
              oidc_issuer_url = "$DEX_ISSUER"
              scope = "profile email offline_access openid"
              email_domains = "*"
              insecure_oidc_allow_unverified_email = "true"

              upstreams = [ "static://200" ]

              skip_auth_routes = [
                "^/dex/",
              ]

              api_routes = [
                "/api/",
                "/apis/",
                "^/ml_metadata",
              ]

              skip_oidc_discovery = true
              login_url = "/dex/auth"
              redeem_url = "http://dex.auth.svc.cluster.local:5556/dex/token"
              oidc_jwks_url = "http://dex.auth.svc.cluster.local:5556/dex/keys"

              skip_provider_button = false

              provider_display_name = "Dex"
              custom_sign_in_logo = "/custom-theme/kubeflow-logo.svg"
              banner = "-"
              footer = "-"

              prompt = "none"

              set_authorization_header = true
              set_xauthrequest = true

              cookie_name = "oauth2_proxy_kubeflow"
              cookie_expire = "24h"
              cookie_refresh = 0

              code_challenge_method = "S256"

              redirect_url = "/oauth2/callback"
              relative_redirect_url = true
```

### Goals

- update cert-manager, istio-base, istiod, dex, oauth2-proxy to use their upstream official helm charts instead of manifets repo, with default values that match the kustomize patches in the manifets repo