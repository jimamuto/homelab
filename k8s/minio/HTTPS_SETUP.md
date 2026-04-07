# MinIO HTTPS Setup Documentation

## Overview
Configured MinIO to use TLS certificates for HTTPS access instead of HTTP.

## Issues Encountered

### 1. TLS Secret Key Names
**Problem:** The Kubernetes TLS secret stores certificates with keys `tls.crt` and `tls.key`, but initially tried to reference them as `fedora.tailf20727.ts.net.crt`.

**Error:** `MountVolume.SetUp failed for volume "certs": references non-existent secret key: fedora.tailf20727.ts.net.crt`

**Fix:** Updated volume items to use correct keys:
```yaml
items:
  - key: tls.crt
    path: public.crt
  - key: tls.key
    path: private.key
```

### 2. Wrong Certificate Mount Path
**Problem:** Initially mounted certs to `/etc/minio/certs` which is not the default path MinIO expects.

**Fix:** Changed mount path to `/root/.minio/certs` (MinIO's default).

### 3. Probes Failing with HTTPS
**Problem:** Health probes were using HTTP scheme but MinIO was now serving HTTPS.

**Error:** ` Readiness probe failed: HTTP probe failed with statuscode: 400`

**Fix:** Added `scheme: HTTPS` to both liveness and readiness probes:
```yaml
readinessProbe:
  httpGet:
    scheme: HTTPS
    path: /minio/health/ready
    port: 9000
livenessProbe:
  httpGet:
    scheme: HTTPS
    path: /minio/health/live
    port: 9000
```

### 4. Certificate File Permissions
**Problem:** Key file owned by root with restrictive permissions.

**Fix:** 
```bash
sudo chown jimoney:jimoney ~/fedora.tailf20727.ts.net.key
chmod 600 ~/fedora.tailf20727.ts.net.key
```

## Final URLs
- **Console**: https://fedora.tailf20727.ts.net:30003
- **API**: https://fedora.tailf20727.ts.net:30002

## Files Modified
- `minio/deployment.yaml` - Added TLS volume mount and HTTPS probes
- `minio/secrets.yaml` - Created TLS secret (done separately via kubectl)

## Troubleshooting Tips

### Check pod status
```bash
kubectl get pods -n minio
```

### View pod logs
```bash
kubectl logs minio-0 -n minio
```

### Check why pod is restarting
```bash
kubectl describe pod minio-0 -n minio
```

### Verify TLS secret exists
```bash
kubectl get secret minio-tls -n minio
```

### Test MinIO directly (if port forwarding)
```bash
kubectl port-forward -n minio svc/minio 9000:9000 9001:9001
# Then access https://localhost:9000 or https://localhost:9001
```

### Common Issues
- **400 Bad Request on probes**: Usually means probes are using wrong scheme (HTTP vs HTTPS)
- **CrashLoopBackOff**: Check logs for startup errors - often incorrect args or missing mounts
- **Pod not starting**: Check events with `kubectl describe pod` - look for FailedMount errors
- **Secret not found**: Ensure secret is in same namespace as pod
