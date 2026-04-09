# Redis on Kubernetes

This directory deploys Redis as a single-replica workload for caching and message queue.

## Files

```
redis/
├── deployment.yaml
├── kustomization.yaml
└── namespace.yaml
```

## What Gets Created

- **Namespace**: `redis`
- **Workload**: `Deployment/redis`
- **Image**: `redis:7-alpine`
- **Storage**: `redis-data` PVC (1Gi)
- **Access**: ClusterIP service on port 6379

## Deploy

From the repo root:

```bash
kubectl apply -k k3s/redis
```

## Verify

```bash
kubectl get pods -n redis
kubectl get svc -n redis
kubectl get pvc -n redis
```

## Usage

Redis is used by:
- **Paperless-ngx** - Celery task queue broker for background document processing (OCR, thumbnails, text extraction)

Service endpoint: `redis.redis.svc.cluster.local:6379`

## Troubleshooting

```bash
# Check connection from another pod
kubectl run test --image=busybox --rm -it -- sh
# wget redis.redis.svc.cluster.local:6379

# Check logs
kubectl logs -n redis deploy/redis

# Restart
kubectl rollout restart deployment/redis -n redis
```

## Backup

```bash
kubectl exec -n redis deploy/redis -- \
  tar -czf - /data > redis-backup.tar.gz
```

## Notes

- Storage class: `local-path`
- Persistence enabled for data durability
- No password required (internal network only)