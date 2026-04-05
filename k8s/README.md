# Homelab Kubernetes Manifests

This repo contains Kubernetes manifests for the homelab services in this directory and uses Kustomize to group them into deployable units.

## Kustomization Layout

### Root kustomization

File: `kustomization.yaml`

Purpose:
- Acts as the entry point for the full stack in this repo.
- Composes the service-level kustomizations under `minio/` and `psql/`.
- Lets you deploy everything with a single command.

Apply it with:

```bash
kubectl apply -k .
```

### MinIO kustomization

File: `minio/kustomization.yaml`

Purpose:
- Groups all MinIO resources into one reusable package.
- Creates the `minio` namespace.
- Deploys the MinIO `StatefulSet`.
- Exposes MinIO internally with a `ClusterIP` service and externally with a `LoadBalancer` service.

Resources included:
- `namespace.yaml`
- `deployment.yaml`
- `loadbalancer.yaml`

Apply it with:

```bash
kubectl apply -k minio
```

### PostgreSQL kustomization

File: `psql/kustomization.yaml`

Purpose:
- Groups all PostgreSQL resources into one reusable package.
- Creates the `postgres` namespace.
- Defines PostgreSQL configuration with a `ConfigMap`.
- Provisions persistent storage with a `PersistentVolumeClaim`.
- Creates the internal services PostgreSQL depends on.
- Deploys PostgreSQL as a `StatefulSet`.

Resources included:
- `namespace.yaml`
- `postgres-configmap.yaml`
- `postgres-pvc.yaml`
- `postgres-services.yaml`
- `postgres-statefulset.yaml`

Apply it with:

```bash
kubectl apply -k psql
```

## Repo Purpose

The repo is structured so each service can be managed independently, while the root kustomization provides a single place to deploy the complete local data stack.

- `minio/` provides S3-compatible object storage.
- `psql/` provides PostgreSQL with persistent storage.
- `kustomization.yaml` at the repo root ties both services together.

## Typical Workflow

Preview rendered manifests:

```bash
kubectl kustomize .
kubectl kustomize minio
kubectl kustomize psql
```

Deploy everything:

```bash
kubectl apply -k .
```

Deploy one service only:

```bash
kubectl apply -k minio
kubectl apply -k psql
```

## Notes

- PostgreSQL expects a secret named `postgres-auth` in the `postgres` namespace.
- MinIO expects a secret named `minio-env` in the `minio` namespace.
- Service-specific operational details remain in [minio/README.md](/home/jimoney/homelab/k8s/minio/README.md) and [psql/README.md](/home/jimoney/homelab/k8s/psql/README.md).
