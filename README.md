# Homelab

Personal infrastructure for self-hosted services, automation, and media management.

## What's Running

| Service | Purpose | Port |
|---------|---------|------|
| Kavita | Digital comics/manga library | 30005 |
| MinIO | S3-compatible object storage | 30002 |
| PostgreSQL | Database for apps | (internal) |
| n8n | Workflow automation | 30004 |
| qBittorrent | Torrent client | 30003 |
| **Paperless** | Document management (PDFs) | **30008** |
| **Redis** | Cache/Message queue | (internal) |

## Quick Start

Deploy everything:
```bash
kubectl apply -k k3s
```

Deploy one service:
```bash
kubectl apply -k k3s/kavita
kubectl apply -k k3s/n8n
kubectl apply -k k3s/paperless
```

## Access Services

| Service | URL |
|---------|-----|
| Kavita | http://localhost:30005 |
| MinIO | http://localhost:30002 |
| n8n | https://localhost:30004 |
| qBittorrent | http://localhost:30003 |
| **Paperless** | **http://localhost:30008** |

Port-forward examples:
```bash
kubectl port-forward svc/kavita -n kavita 5000:5000
kubectl port-forward svc/minio-loadbalancer -n minio 9000:9000
kubectl port-forward svc/paperless-nodeport -n paperless 8000:8000
```

## Services Overview

### Paperless (Document Management)
- **Port**: 30008
- **Purpose**: Scan, index, and archive documents
- **Storage**: 10GB data + 20GB consume folder
- **Docs**: [k3s/paperless/README.md](k3s/paperless/README.md)

### Kavita (Media Server)
- **Port**: 30005
- **Purpose**: Comics, manga, and ebook reader
- **Storage**: Host path at `/home/jimoney/library`

### n8n (Automation)
- **Port**: 30004 (HTTPS)
- **Purpose**: Workflow automation
- **Uses**: PostgreSQL, Redis

### qBittorrent
- **Port**: 30003
- **Purpose**: Torrent downloads

### MinIO
- **Port**: 30002
- **Purpose**: S3-compatible storage

### PostgreSQL
- **Internal**: postgres.postgres.svc.cluster.local:5432
- **Purpose**: Database for n8n and other apps

### Redis
- **Internal**: redis.redis.svc.cluster.local:6379
- **Purpose**: Task queue for Paperless

## Documentation

- [Homelab Overview](docs/homelab.md) - Full cluster documentation
- [Paperless Setup](k3s/paperless/README.md) - Document management guide
- [Kavita Setup](k3s/kavita/README.md) - Library configuration

## What's Next

- Connect RSS feeds → n8n → qBittorrent → Kavita workflow
- Set up automated library scanning
- Configure paperless email ingestion

See [docs/homelab.md](docs/homelab.md) for full details.

## Secrets Management

This repo uses **Sealed Secrets** to store secrets safely in git.

### How It Works

- Secrets are encrypted with a cluster-specific public key
- Only the cluster can decrypt them (via the private key)
- Sealed secrets are stored in `*-secrets.yaml` files alongside your deployments

### Backup the Sealing Key

**IMPORTANT:** Store this file somewhere safe (not in git):

```bash
~/backup/sealed-secrets/sealed-secrets-cert.pem
```

Without this key, sealed secrets become unrecoverable if the cluster is rebuilt.

### Adding New Secrets

```bash
# 1. Create the secret
kubectl create secret generic my-secret -n myns --from-literal=key=value -o yaml > temp-secret.yaml

# 2. Encrypt it (requires kubeseal installed)
kubeseal --cert ~/backup/sealed-secrets/sealed-secrets-cert.pem -n myns -o yaml < temp-secret.yaml > k3s/myns/sealed-secrets.yaml

# 3. Add to kustomization.yaml
echo "  - sealed-secrets.yaml" >> k3s/myns/kustomization.yaml

# 4. Apply
kubectl apply -k k3s/myns
```

### Restoring After Cluster Rebuild

1. Install sealed secrets controller
2. Apply the sealing certificate
3. Deploy sealed secrets files with `kubectl apply -f`