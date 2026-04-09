# Homelab Kubernetes Cluster

## Overview

This homelab runs on a single-node K3s cluster with multiple services for document management, automation, storage, and media.

## Quick Start

```bash
# Apply all manifests
kubectl apply -k k3s/

# Check status of all pods
kubectl get pods -A
```

## Services

| Service | Namespace | Port | Description |
|---------|-----------|------|-------------|
| **Paperless** | paperless | 30008 | Document management (PDFs, documents) |
| **Kavita** | kavita | 30005 | Comics/Manga/Books reader |
| **n8n** | n8n | 30004 | Workflow automation |
| **qBittorrent** | qbittorrent | 30003 | Torrent client |
| **MinIO** | minio | 30002 | S3-compatible object storage |
| **PostgreSQL** | postgres | 5432 | Database |
| **Redis** | redis | 6379 | Cache/Message queue |

## Detailed Setup

### Paperless (Document Management)

Access: `http://<node-ip>:30008`

```bash
# Check status
kubectl get pods -n paperless
kubectl get svc -n paperless

# View logs
kubectl logs -n paperless deploy/paperless
```

**Files created:**
- `k3s/paperless/namespace.yaml`
- `k3s/paperless/deployment.yaml`
- `k3s/paperless/pvc.yaml` (10GB data, 20GB consume)
- `k3s/paperless/nodeport.yaml`
- `k3s/paperless/secret.yaml`
- `k3s/paperless/kustomization.yaml`

### Kavita (Media Server)

Access: `http://<node-ip>:30005`

```bash
# Check status
kubectl get pods -n kavita
kubectl get svc -n kavita

# View logs
kubectl logs -n kavita deploy/kavita
```

### n8n (Automation)

Access: `http://<node-ip>:30004` (HTTPS)

```bash
# Check status
kubectl get pods -n n8n

# Access n8n UI
# Default login info set via sealed-secrets
```

### qBittorrent

Access: `http://<node-ip>:30003`

```bash
# Check status
kubectl get pods -n qbittorrent

# Default credentials: admin/adminadmin
```

### MinIO (Storage)

Access: `http://<node-ip>:30002`

```bash
# Check status
kubectl get pods -n minio

# Access MinIO console
# Credentials set in secrets
```

### PostgreSQL

```bash
# Connect to postgres
kubectl exec -n postgres postgres-0 -- psql -U appuser -d appdb

# Check status
kubectl get pods -n postgres
```

### Redis

```bash
# Check status
kubectl get pods -n redis
```

## Managing the Cluster

### Common Commands

```bash
# Apply all services
kubectl apply -k k3s/

# Restart a service
kubectl rollout restart deployment/<service> -n <namespace>

# View logs
kubectl logs -n <namespace> deploy/<service>

# Scale a service
kubectl scale deployment/<service> -n <namespace> --replicas=2

# Delete a service
kubectl delete -k k3s/<service>

# Check resource usage
kubectl top nodes
kubectl top pods -A

# Port forward for debugging
kubectl port-forward -n <namespace> deploy/<service> 8080:8000
```

### Backup & Restore

#### PostgreSQL Backup
```bash
kubectl exec -n postgres postgres-0 -- pg_dump -U appuser appdb > backup.sql
```

#### PostgreSQL Restore
```bash
kubectl exec -n postgres postgres-0 -- psql -U appuser appdb < backup.sql
```

#### PVC Backup (using rsync)
```bash
kubectl debug -n <namespace> pod/<pod> -- \
  chroot /host tar -czf - /path/to/volume > backup.tar.gz
```

## Project Structure

```
k3s/
├── kustomization.yaml          # Main entry point
├── kavita/                     # Comics/Books server
│   ├── deployment.yaml
│   ├── pvc.yaml
│   ├── nodeport.yaml
│   └── kustomization.yaml
├── minio/                      # S3 storage
│   ├── deployment.yaml
│   ├── secrets.yaml
│   ├── nodeport.yaml
│   └── kustomization.yaml
├── n8n/                        # Automation
│   ├── deployment.yaml
│   ├── sealed-secrets.yaml
│   ├── nodeport.yaml
│   └── kustomization.yaml
├── paperless/                  # Document management
│   ├── deployment.yaml
│   ├── pvc.yaml
│   ├── nodeport.yaml
│   ├── secret.yaml
│   └── kustomization.yaml
├── psql/                       # PostgreSQL
│   ├── postgres-statefulset.yaml
│   ├── postgres-configmap.yaml
│   ├── postgres-pvc.yaml
│   ├── postgres-services.yaml
│   └── kustomization.yaml
├── qbittorrent/                # Torrent client
│   ├── deployment.yaml
│   ├── pvc.yaml
│   ├── nodeport.yaml
│   └── kustomization.yaml
└── redis/                      # Cache
    ├── deployment.yaml
    └── kustomization.yaml
```

## Troubleshooting

### Pod stuck in Pending
```bash
kubectl describe pod <pod-name> -n <namespace>
# Check for PVC binding issues or resource constraints
```

### Pod in CrashLoopBackOff
```bash
kubectl logs <pod-name> -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

### Service not accessible
```bash
# Check endpoints
kubectl get endpoints -n <namespace>

# Check service selector
kubectl get svc <service> -n <namespace> -o jsonpath='{.spec.selector}'

# Verify pod labels match
kubectl get pods -n <namespace> --show-labels
```

### Database connection issues
```bash
# Test connectivity from a pod
kubectl run debug --image=busybox --rm -it -- sh
# wget postgres.postgres.svc.cluster.local:5432

# Check database credentials
kubectl get secrets -n <namespace>
```

## Resource Limits

| Service | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|-------------|-----------|-----------------|--------------|
| paperless | 500m | 2 | 1Gi | 2Gi |
| kavita | 250m | 1 | 512Mi | 1Gi |
| n8n | 250m | 1 | 512Mi | 1Gi |
| qbittorrent | 250m | 1 | 256Mi | 512Mi |
| minio | 250m | 1 | 512Mi | 1Gi |
| postgres | 250m | 1 | 512Mi | 1Gi |
| redis | 100m | 500m | 256Mi | 512Mi |

## Networking

- All services use ClusterIP for internal communication
- NodePort used for external access (30000-32767 range)
- Service discovery via DNS: `<service>.<namespace>.svc.cluster.local`

## Adding New Services

1. Create directory: `k3s/<service>/`
2. Create `namespace.yaml`
3. Create `deployment.yaml` with resources
4. Create `service.yaml` or `nodeport.yaml`
5. Create `kustomization.yaml`
6. Add to main `k3s/kustomization.yaml`

Example:
```bash
mkdir -p k3s/myservice
# Create manifests
echo "- myservice" >> k3s/kustomization.yaml
kubectl apply -k k3s/
```

## Security Notes

- Secrets are stored as Kubernetes Secrets (base64 encoded)
- For production, use SealedSecrets or external secret management
- TLS termination handled by individual services or ingress
- Network policies can be added to restrict inter-service communication