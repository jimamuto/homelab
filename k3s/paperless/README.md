# Paperless-ngx on Kubernetes

This directory deploys Paperless-ngx as a single-replica workload for document management.

## Files

```
paperless/
├── deployment.yaml
├── kustomization.yaml
├── namespace.yaml
├── nodeport.yaml
├── pvc.yaml
└── secret.yaml
```

## What Gets Created

- **Namespace**: `paperless`
- **Workload**: `Deployment/paperless`
- **Image**: `ghcr.io/paperless-ngx/paperless-ngx:latest`
- **Storage**:
  - `paperless-data` PVC (10Gi) - database and app data
  - `paperless-consume` PVC (20Gi) - document intake folder
- **Access**: NodePort on port 30008
- **Dependencies**:
  - Redis for task queue (`redis.redis.svc.cluster.local:6379`) - handles background document processing (OCR, thumbnails, text extraction)
  - SQLite for database (simplified, no PostgreSQL required)

## Deploy

From the repo root:

```bash
kubectl apply -k k3s/paperless
```

Or from this directory:

```bash
kubectl apply -k .
```

## Verify

```bash
kubectl get pods -n paperless
kubectl get svc -n paperless
kubectl get pvc -n paperless
```

Check logs:

```bash
kubectl logs -n paperless deploy/paperless
```

## Access

- **NodePort**: `http://<node-ip>:30008`
- **Port-forward**: `kubectl port-forward -n paperless svc/paperless-nodeport 8000:8000`

## First-Time Setup

1. Access the UI at `http://<node-ip>:30008`
2. Create admin user account
3. Configure consumption folder (automatic document import)
4. Add correspondents, tags, and document types

## Configuration

Key environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `PAPERLESS_DBENGINE` | Database engine | `sqlite` |
| `PAPERLESS_REDIS` | Redis connection (required for background task processing) | `redis://redis.redis.svc.cluster.local:6379` |
| `PAPERLESS_TIME_ZONE` | Timezone | `America/New_York` |
| `PAPERLESS_SECRET_KEY` | Security key | From secret |

## Storage

The consume folder is where you drop documents for automatic processing:

```bash
# List files in consume folder
kubectl exec -n paperless deploy/paperless -- ls -la /usr/src/paperless/consume

# View media files
kubectl exec -n paperless deploy/paperless -- ls -la /usr/src/paperless/media/documents
```

## Troubleshooting

### Pod won't start
```bash
kubectl describe pod -n paperless -l app=paperless
kubectl logs -n paperless -l app=paperless
```

### Database migration issues
```bash
# Delete PVCs to start fresh (will lose data)
kubectl delete pvc -n paperless --all
kubectl rollout restart deployment/paperless -n paperless
```

### Redis connection issues
```bash
# Check Redis is running
kubectl get pods -n redis

# Check connection
kubectl exec -n paperless deploy/paperless -- ping redis.redis.svc.cluster.local
```

### Migration lock file
If migrations fail with "Resource busy" error:
```bash
# Scale to 0
kubectl scale deployment paperless -n paperless --replicas=0

# Delete PVCs
kubectl delete pvc -n paperless --all

# Scale back up
kubectl scale deployment paperless -n paperless --replicas=1
```

## Backup

### Backup data PVC
```bash
kubectl exec -n paperless deploy/paperless -- \
  tar -czf - /usr/src/paperless/data > paperless-data-backup.tar.gz

kubectl exec -n paperless deploy/paperless -- \
  tar -czf - /usr/src/paperless/consume > paperless-consume-backup.tar.gz
```

### Restore
```bash
kubectl exec -n paperless deploy/paperless -- \
  tar -xzf - /usr/src/paperless/data < paperless-data-backup.tar.gz
```

## Upgrading

```bash
kubectl rollout restart deployment/paperless -n paperless
```

Watch for migration issues in logs.

## Notes

- Uses SQLite for simplicity (no PostgreSQL authentication issues)
- **Redis is required** - serves as the message broker for Celery (task queue). When you upload documents through the GUI, Redis queues tasks for background processing (OCR, thumbnail generation, text extraction). Without Redis, documents won't be processed.
- Single instance (not HA)
- Storage class: `local-path`