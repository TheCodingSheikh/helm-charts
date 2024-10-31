# Deepeval Api

This Helm chart deploys the Deepeval API, which enables evaluating LLM and conversational test cases via FastAPI. The deployment can be configured to use either the default OpenAI configuration or a local model.

## Installation

To install the chart from GitHub Pages:

```bash
helm repo add my-charts https://thecodingsheikh.github.io/helm-charts
helm install deepeval-api my-charts/deepeval-api
```


## Configuration

```yaml
openaiApiKey: ""          # API key for OpenAI (if useLocalModel is false)
useLocalModel: false      # Set to true to use a local model configuration
modelName: ""             # The name of the model to use
baseUrl: ""               # The base URL for the local model server
apiKey: ""                # API key for local model authentication
```

Example:

```bash
helm upgrade deepeval-api my-charts/deepeval-api \
  --set useLocalModel=true \
  --set modelName="model-name" \
  --set baseUrl="http://your-model-base-url" \
  --set apiKey="your-local-api-key"
```

## Uninstall

To uninstall the chart:

```bash
helm uninstall deepeval-api
```
