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
kubeseal --cert ~/backup/sealed-secrets/sealed-secrets-cert.pem -n myns -o yaml < temp-secret.yaml > k8s/myns/sealed-secrets.yaml

# 3. Add to kustomization.yaml
echo "  - sealed-secrets.yaml" >> k8s/myns/kustomization.yaml

# 4. Apply
kubectl apply -k k8s/myns
```

### Restoring After Cluster Rebuild

1. Install sealed secrets controller
2. Apply the sealing certificate
3. Deploy sealed secrets files with `kubectl apply -f`