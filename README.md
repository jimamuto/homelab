# Homelab

Personal infrastructure for self-hosted services, automation, and media management.

## What's Running

| Service | Purpose | Port |
|---------|---------|------|
| Kavita | Digital library for manga/comics | 5000 |
| MinIO | S3-compatible object storage | 9000/9001 |
| PostgreSQL | Database for apps | 5432 |
| n8n | Workflow automation | 5678 |

## Quick Start

Deploy everything:
```bash
kubectl apply -k k8s
```

Deploy one service:
```bash
kubectl apply -k k8s/kavita
kubectl apply -k k8n/n8n
```

## Access Services

```bash
kubectl port-forward svc/kavita -n kavita 5000:5000     # http://localhost:5000
kubectl port-forward svc/minio-loadbalancer -n minio 9000:9000 9001:9001  # API:9000, Console:9001
kubectl port-forward svc/postgres -n postgres 5432:5432
kubectl port-forward svc/n8n -n n8n 5678:5678          # http://localhost:5678
```

## What's Next

- Add qBittorrent for automated downloads
- Connect RSS feeds → n8n → qBittorrent → Kavita workflow
- Set up automated library scanning

See [k8s/README.md](k8s/README.md) for full details.