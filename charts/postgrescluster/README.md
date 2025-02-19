# Crunchy PostgreCluster Helm Chart Documentation

## Overview
This document provides an explanation of the available configuration options for the PostgreSQL Helm chart and instructions for installation.

## Installation Steps

### Prerequisites
Ensure you have the following:
- A running Kubernetes cluster
- Helm installed on your local machine
- PostgreSQL Operator installed ([PGO Installation Guide](https://access.crunchydata.com/documentation/postgres-operator/v5/))

## Installation

To install the chart from GitHub Pages:

```bash
helm repo add thecodingsheikh https://thecodingsheikh.github.io/helm-charts
helm install hippo thecodingsheikh/postgrescluster
```

## Configuration Options

### General Settings
| Parameter | Description | Default |
|-----------|-------------|---------|
| `name` | Name of the cluster | Helm release name |
| `postgresVersion` | PostgreSQL version to deploy | Required |
| `postGISVersion` | PostGIS version (if enabled) | None |

### pgBouncer Configuration
| Parameter | Description | Default |
|-----------|-------------|---------|
| `pgBouncerReplicas` | Number of pgBouncer instances | `0` |
| `pgBouncerConfig` | Custom configuration for pgBouncer | None |

### Monitoring
| Parameter | Description | Default |
|-----------|-------------|---------|
| `monitoring` | Enable monitoring | `false` |

### Image Overrides
| Parameter | Description | Default |
|-----------|-------------|---------|
| `imagePostgres` | Postgres image | `registry.developers.crunchydata.com/crunchydata/crunchy-postgres:ubi8-17.2-2` |
| `imagePgBackRest` | pgBackRest image | `registry.developers.crunchydata.com/crunchydata/crunchy-pgbackrest:ubi8-2.54.1-0` |
| `imagePgBouncer` | pgBouncer image | `registry.developers.crunchydata.com/crunchydata/crunchy-pgbouncer:ubi8-1.23-3` |
| `imageExporter` | Exporter image | `registry.developers.crunchydata.com/crunchydata/crunchy-postgres-exporter:ubi8-0.16.0-0` |

### PostgreSQL Settings
| Parameter | Description | Default |
|-----------|-------------|---------|
| `instanceName` | Name of PostgreSQL instance | `instance1` |
| `instanceSize` | Storage size | `1Gi` |
| `instanceStorageClassName` | Storage class | `hostpath` |
| `instanceMemory` | Memory limit | `2Gi` |
| `instanceCPU` | CPU limit | `1000m` |
| `instanceReplicas` | Number of replicas | `1` |

### Backup Configuration
| Parameter | Description | Default |
|-----------|-------------|---------|
| `backupsSize` | Backup storage size | `1Gi` |
| `backupsStorageClassName` | Backup storage class | `hostpath` |
| `s3.bucket` | S3 bucket for backups | None |
| `s3.endpoint` | S3 endpoint | None |
| `gcs.bucket` | Google Cloud Storage bucket | None |
| `azure.account` | Azure storage account | None |
| `azure.key` | Azure storage key | None |
| `multiBackupRepos` | Enable multiple backup repositories | None |

### Kubernetes Settings
| Parameter | Description | Default |
|-----------|-------------|---------|
| `metadata` | Metadata (labels, annotations) | None |
| `imagePullPolicy` | Image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Image pull secrets | `[]` |
| `disableDefaultPodScheduling` | Disable default pod scheduling | `false` |
| `openshift` | OpenShift cluster configuration | `false` |

For more details, refer to the official documentation: [PostgreSQL Operator Documentation](https://access.crunchydata.com/documentation/postgres-operator/v5/).

## Uninstallation
To uninstall the chart, run:
```sh
helm uninstall hippo
```
This will remove all associated resources.

