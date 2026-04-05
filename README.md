# Homelab

This repo is the working notes and infrastructure for a small homelab environment.

Right now it has two main tracks:

- base server setup and tooling notes in `docs/`
- Kubernetes manifests for the data stack in `k8s/`

## Repo Layout

```text
.
├── README.md
├── docs/
│   ├── minio-aistor.md
│   └── setup.md
└── k8s/
    ├── README.md
    ├── kustomization.yaml
    ├── minio/
    └── psql/
```

## What Is Here

### Docs

- [docs/setup.md](/home/jimoney/homelab/docs/setup.md) covers the Ubuntu server bootstrap, SSH setup, Docker installation, GitHub CLI auth, and a few common issues
- [docs/minio-aistor.md](/home/jimoney/homelab/docs/minio-aistor.md) documents a Docker-based MinIO AIStor deployment

### Kubernetes

- [k8s/README.md](/home/jimoney/homelab/k8s/README.md) is the entry point for the Kubernetes side of the repo
- [k8s/minio/README.md](/home/jimoney/homelab/k8s/minio/README.md) documents the MinIO manifests
- [k8s/psql/README.md](/home/jimoney/homelab/k8s/psql/README.md) documents the PostgreSQL manifests

The current Kubernetes stack is centered on:

- MinIO for S3-compatible object storage
- PostgreSQL for application data and backups
- Kustomize to deploy either service independently or the full stack together

## Common Entry Points

Read the server setup notes:

```bash
sed -n '1,200p' docs/setup.md
```

Preview the Kubernetes stack:

```bash
kubectl kustomize k8s
```

Deploy the full Kubernetes stack:

```bash
kubectl apply -k k8s
```

Deploy one service only:

```bash
kubectl apply -k k8s/minio
kubectl apply -k k8s/psql
```

## Current Focus

This repo is no longer just a generic homelab scratchpad. The concrete infrastructure checked in today is:

- host setup documentation under `docs/`
- MinIO and PostgreSQL Kubernetes manifests under `k8s/`
- a Docker-based MinIO AIStor reference doc under `docs/`

If you are looking for the actively maintained manifests, start with [k8s/README.md](/home/jimoney/homelab/k8s/README.md).
