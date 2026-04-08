# Homelab Data Stack on k3s

This repo is the Kubernetes layer for a small homelab data stack: MinIO for S3-compatible object storage, PostgreSQL for app data and backups, Kavita for self-hosted digital library management, and n8n for workflow automation.

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
│   ├── namespace.yaml
│   ├── nodeport.yaml
│   └── service.yaml
├── minio/
│   ├── README.md
│   ├── deployment.yaml
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   └── nodeport.yaml
├── n8n/
│   ├── deployment.yaml
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── nodeport.yaml
│   ├── pvc.yaml
│   └── service.yaml
├── psql/
│   ├── README.md
│   ├── appdb_backup.sql
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── postgres-configmap.yaml
│   ├── postgres-pvc.yaml
│   ├── postgres-services.yaml
│   └── postgres-statefulset.yaml
└── qbittorrent/
    ├── README.md
    ├── deployment.yaml
    ├── kustomization.yaml
    ├── namespace.yaml
    ├── nodeport.yaml
    ├── pvc.yaml
    └── service.yaml
```

## Stack Overview

### MinIO

- Namespace: `minio`
- Workload: single-replica `StatefulSet`
- Image: `quay.io/minio/minio:RELEASE.2024-10-02T17-50-41Z`
- Storage: `25Gi` via `local-path`
- Access:
  - internal `ClusterIP` service: `minio`
  - external `NodePort` service: `minio-nodeport` (ports 30002/30003)
  - console port: `9001`
  - S3 API port: `9000`
- Secret required: `minio-env`

### Kavita

- Namespace: `kavita`
- Workload: single-replica `Deployment`
- Image: `jvmilazz0/kavita:latest`
- Storage:
  - `5Gi` via `local-path` for app state
  - host directory `/home/jimoney/library` for library files
- Access:
  - internal `ClusterIP` service: `kavita`
  - external `NodePort` service: `kavita-nodeport` (port 30001)
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

### n8n

- Namespace: `n8n`
- Workload: single-replica `Deployment`
- Image: `n8nio/n8n:latest`
- Storage: `1Gi` via `local-path`
- Access:
  - internal `ClusterIP` service: `n8n`
  - external `NodePort` service: `n8n-nodeport` (port 30004)
  - app port: `5678`

### qbittorrent

- Namespace: `qbittorrent`
- Workload: single-replica `Deployment`
- Image: `lscr.io/linuxserver/qbittorrent:latest`
- Storage:
  - `1Gi` via `local-path` for app config
  - host directory `/home/jimoney/downloads` for downloads
- Access:
  - internal `ClusterIP` service: `qbittorrent`
  - external `NodePort` service: `qbittorrent-nodeport` (port 30005)
  - app port: `30005`

## How The Pieces Fit Together

The root [kustomization.yaml](/home/jimoney/homelab/k3s/kustomization.yaml) composes five service-level kustomizations:

- [kavita/kustomization.yaml](/home/jimoney/homelab/k3s/kavita/kustomization.yaml)
- [minio/kustomization.yaml](/home/jimoney/homelab/k3s/minio/kustomization.yaml)
- [psql/kustomization.yaml](/home/jimoney/homelab/k3s/psql/kustomization.yaml)
- [n8n/kustomization.yaml](/home/jimoney/homelab/k3s/n8n/kustomization.yaml)
- [qbittorrent/kustomization.yaml](/home/jimoney/homelab/k3s/qbittorrent/kustomization.yaml)

That means you can:

- deploy everything with `kubectl apply -k .`
- deploy the library service only with `kubectl apply -k kavita`
- deploy storage only with `kubectl apply -k minio`
- deploy database only with `kubectl apply -k psql`
- deploy automation only with `kubectl apply -k n8n`
- deploy qbittorrent only with `kubectl apply -k qbittorrent`

Operationally, PostgreSQL is already wired to know about MinIO through [psql/postgres-configmap.yaml](/home/jimoney/homelab/k3s/psql/postgres-configmap.yaml), which includes the in-cluster MinIO endpoint and backup bucket name.

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

## Access Services

### NodePort (from any machine on network)

| Service | Port | URL |
|---------|------|-----|
| Kavita | 30001 | `http://<host-ip>:30001` |
| MinIO API | 30002 | `http://<host-ip>:30002` |
| MinIO Console | 30003 | `http://<host-ip>:30003` |
| n8n | 30004 | `http://<host-ip>:30004` |
| qbittorrent | 30005 | `http://<host-ip>:30005` |

Replace `<host-ip>` with your machine's IP (e.g., `192.168.100.11`).

### Port-forward (alternative)

```bash
kubectl port-forward svc/minio -n minio 9000:9000 9001:9001
kubectl port-forward svc/kavita -n kavita 5000:5000
kubectl port-forward svc/postgres -n postgres 5432:5432
kubectl port-forward svc/n8n -n n8n 5678:5678
kubectl port-forward svc/qbittorrent -n qbittorrent 30005:30005
```

## Check Status

Check pods and services:

```bash
kubectl get pods,svc -n kavita
kubectl get pods,svc -n minio
kubectl get pods,svc -n postgres
kubectl get pods,svc -n n8n
kubectl get pods,svc -n qbittorrent
```

Preview manifests:

```bash
kubectl kustomize .
kubectl kustomize kavita
kubectl kustomize minio
kubectl kustomize psql
kubectl kustomize n8n
kubectl kustomize qbittorrent
```

## Files Worth Knowing

- [kavita/deployment.yaml](/home/jimoney/homelab/k3s/kavita/deployment.yaml) defines the Kavita workload and its persistent mounts for config and library data
- [kavita/kavita-pvcs.yaml](/home/jimoney/homelab/k3s/kavita/kavita-pvcs.yaml) provisions the PVC for Kavita app state
- [minio/deployment.yaml](/home/jimoney/homelab/k3s/minio/deployment.yaml) defines the MinIO `StatefulSet` and its persistent volume claim template
- [minio/nodeport.yaml](/home/jimoney/homelab/k3s/minio/nodeport.yaml) exposes MinIO via NodePort for external access
- [psql/postgres-statefulset.yaml](/home/jimoney/homelab/k3s/psql/postgres-statefulset.yaml) defines the PostgreSQL pod, probes, resources, and mounted storage
- [psql/postgres-configmap.yaml](/home/jimoney/homelab/k3s/psql/postgres-configmap.yaml) contains the database defaults plus MinIO backup settings
- [psql/appdb_backup.sql](/home/jimoney/homelab/k3s/psql/appdb_backup.sql) is the SQL backup currently stored in the repo
- [n8n/deployment.yaml](/home/jimoney/homelab/k3s/n8n/deployment.yaml) defines the n8n workflow automation workload
- [n8n/pvc.yaml](/home/jimoney/homelab/k3s/n8n/pvc.yaml) provisions the PVC for n8n workflow data
- [qbittorrent/deployment.yaml](/home/jimoney/homelab/k3s/qbittorrent/deployment.yaml) defines the qbittorrent workload with init container for WebUI port config

## Service Docs

The deeper operational notes still live in the service-specific docs:

- [kavita/README.md](/home/jimoney/homelab/k3s/kavita/README.md)
- [minio/README.md](/home/jimoney/homelab/k3s/minio/README.md)
- [psql/README.md](/home/jimoney/homelab/k3s/psql/README.md)
- [qbittorrent/README.md](/home/jimoney/homelab/k3s/qbittorrent/README.md)
