# Homelab Data Stack on Kubernetes

This repo is the Kubernetes layer for a small homelab data stack: MinIO for S3-compatible object storage, PostgreSQL for app data and backups, and Kavita for self-hosted digital library management.

It is intentionally simple:

- plain manifests
- Kustomize at the root
- no operators
- one directory per service

If you want the whole stack:

```bash
kubectl apply -k .
```

If you want one service only:

```bash
kubectl apply -k kavita
kubectl apply -k minio
kubectl apply -k psql
```

## What Is In This Repo

```text
.
├── README.md
├── kustomization.yaml
├── kavita/
│   ├── README.md
│   ├── deployment.yaml
│   ├── kavita-pvcs.yaml
│   ├── kustomization.yaml
│   ├── loadbalancer.yaml
│   ├── namespace.yaml
│   └── service.yaml
├── minio/
│   ├── README.md
│   ├── deployment.yaml
│   ├── kustomization.yaml
│   ├── loadbalancer.yaml
│   └── namespace.yaml
└── psql/
    ├── README.md
    ├── appdb_backup.sql
    ├── kustomization.yaml
    ├── namespace.yaml
    ├── postgres-configmap.yaml
    ├── postgres-pvc.yaml
    ├── postgres-services.yaml
    └── postgres-statefulset.yaml
```

## Stack Overview

### MinIO

- Namespace: `minio`
- Workload: single-replica `StatefulSet`
- Image: `quay.io/minio/minio:RELEASE.2024-10-02T17-50-41Z`
- Storage: `25Gi` via `local-path`
- Access:
  - internal `ClusterIP` service: `minio`
  - external `LoadBalancer` service: `minio-loadbalancer`
  - console port: `9001`
  - S3 API port: `9000`
- Secret required: `minio-env`

### Kavita

- Namespace: `kavita`
- Workload: single-replica `Deployment`
- Image: `jvmilazz0/kavita:latest`
- Storage:
  - `5Gi` via `local-path` for app state
- Access:
  - internal `ClusterIP` service: `kavita`
  - external `LoadBalancer` service: `kavita-loadbalancer`
  - app port: `5000`

### PostgreSQL

- Namespace: `postgres`
- Workload: single-replica `StatefulSet`
- Image: `postgres:16`
- Storage: `20Gi` via `local-path`
- Access:
  - internal headless service: `postgres-headless`
  - internal client service: `postgres`
  - database port: `5432`
- Secret required: `postgres-auth`
- Default config from ConfigMap:
  - database: `appdb`
  - user: `appuser`
  - backup bucket: `postgres-backups`
  - MinIO endpoint: `http://minio.minio.svc.cluster.local:9000`

## How The Pieces Fit Together

The root [kustomization.yaml](/home/jimoney/homelab/k8s/kustomization.yaml) composes three service-level kustomizations:

- [kavita/kustomization.yaml](/home/jimoney/homelab/k8s/kavita/kustomization.yaml)
- [minio/kustomization.yaml](/home/jimoney/homelab/k8s/minio/kustomization.yaml)
- [psql/kustomization.yaml](/home/jimoney/homelab/k8s/psql/kustomization.yaml)

That means you can:

- deploy everything with `kubectl apply -k .`
- deploy the library service only with `kubectl apply -k kavita`
- deploy storage only with `kubectl apply -k minio`
- deploy database only with `kubectl apply -k psql`

Operationally, PostgreSQL is already wired to know about MinIO through [psql/postgres-configmap.yaml](/home/jimoney/homelab/k8s/psql/postgres-configmap.yaml), which includes the in-cluster MinIO endpoint and backup bucket name.

## Prerequisites

- a working Kubernetes cluster
- `kubectl` pointing at that cluster
- Kustomize support via `kubectl apply -k`
- a `local-path` StorageClass, or updated storage settings in the manifests

## Secrets You Need First

This repo does not commit runtime credentials, so create the required secrets before deployment.

### MinIO

Create `minio-env` in the `minio` namespace with at least:

- `MINIO_ROOT_USER`
- `MINIO_ROOT_PASSWORD`

Example:

```bash
kubectl create secret generic minio-env \
  -n minio \
  --from-literal=MINIO_ROOT_USER='<user>' \
  --from-literal=MINIO_ROOT_PASSWORD='<password>'
```

### PostgreSQL

Create `postgres-auth` in the `postgres` namespace with:

- `POSTGRES_PASSWORD`

Example:

```bash
kubectl create secret generic postgres-auth \
  -n postgres \
  --from-literal=POSTGRES_PASSWORD='<strong-password>'
```

## Common Commands

Preview manifests:

```bash
kubectl kustomize .
kubectl kustomize kavita
kubectl kustomize minio
kubectl kustomize psql
```

Check rollout state:

```bash
kubectl get pods -n kavita
kubectl get svc -n kavita
kubectl get pvc -n kavita
kubectl get pods -n minio
kubectl get svc -n minio
kubectl get pods -n postgres
kubectl get svc -n postgres
kubectl get pvc -n postgres
```

Access MinIO locally:

```bash
kubectl port-forward svc/minio-loadbalancer -n minio 9000:9000 9001:9001
```

Then open:

- `http://localhost:9000` for the S3 API
- `http://localhost:9001` for the console

Access Kavita locally:

```bash
kubectl port-forward svc/kavita -n kavita 5000:5000
```

Then open:

- `http://localhost:5000`

Connect to PostgreSQL from inside the cluster or by port-forwarding:

```bash
kubectl port-forward svc/postgres -n postgres 5432:5432
```

## Files Worth Knowing

- [kavita/deployment.yaml](/home/jimoney/homelab/k8s/kavita/deployment.yaml) defines the Kavita workload and its persistent mounts for config and library data
- [kavita/kavita-pvcs.yaml](/home/jimoney/homelab/k8s/kavita/kavita-pvcs.yaml) provisions the PVC for Kavita app state
- [minio/deployment.yaml](/home/jimoney/homelab/k8s/minio/deployment.yaml) defines the MinIO `StatefulSet` and its persistent volume claim template
- [minio/loadbalancer.yaml](/home/jimoney/homelab/k8s/minio/loadbalancer.yaml) exposes MinIO internally and through a `LoadBalancer`
- [psql/postgres-statefulset.yaml](/home/jimoney/homelab/k8s/psql/postgres-statefulset.yaml) defines the PostgreSQL pod, probes, resources, and mounted storage
- [psql/postgres-configmap.yaml](/home/jimoney/homelab/k8s/psql/postgres-configmap.yaml) contains the database defaults plus MinIO backup settings
- [psql/appdb_backup.sql](/home/jimoney/homelab/k8s/psql/appdb_backup.sql) is the SQL backup currently stored in the repo

## Service Docs

The deeper operational notes still live in the service-specific docs:

- [kavita/README.md](/home/jimoney/homelab/k8s/kavita/README.md)
- [minio/README.md](/home/jimoney/homelab/k8s/minio/README.md)
- [psql/README.md](/home/jimoney/homelab/k8s/psql/README.md)
