# n8n HTTPS Setup Documentation

## Overview
Configured n8n to use TLS certificates for HTTPS access via NodePort.

## Access URL
- **URL**: https://fedora.tailf20727.ts.net:30004

## Files Created/Modified

### 1. secret-tls.yaml (new)
- Created TLS secret with certificate and key from Tailscale
- Secret name: `n8n-tls`
- Namespace: `n8n`

### 2. deployment.yaml (modified)
- Added TLS volume mount at `/home/node/certs`
- Updated environment variables:
  - `N8N_PROTOCOL: https`
  - `N8N_HOST: n8n.fedora.tailf20727.ts.net`
  - `WEBHOOK_URL: https://n8n.fedora.tailf20727.ts.net`
  - `N8N_SSL_KEY: /home/node/certs/private.key`
  - `N8N_SSL_CERT: /home/node/certs/public.crt`
- Added `scheme: HTTPS` to liveness and readiness probes

### 3. kustomization.yaml (modified)
- Added `secret-tls.yaml` to resources

### 4. nodeport.yaml (existing)
- Port: 30004 (unchanged)

## TLS Certificate
- Source: Tailscale-generated certificate for `fedora.tailf20727.ts.net`
- Files: `~/fedora.tailf20727.ts.net.crt` and `~/fedora.tailf20727.ts.net.key`
- Note: Certificate valid for 3 months

## Troubleshooting

### Check pod status
```bash
kubectl get pods -n n8n
```

### View pod logs
```bash
kubectl logs -n n8n -l app=n8n
```

### Test HTTPS endpoint
```bash
curl -k https://fedora.tailf20727.ts.net:30004
```

### Check TLS secret
```bash
kubectl get secret n8n-tls -n n8n
```

### Restart deployment
```bash
kubectl rollout restart deployment/n8n -n n8n
```

## Common Issues
- **Unhealthy probe**: Ensure `scheme: HTTPS` is set in probes
- **HTTP response to HTTPS client**: Ensure `N8N_SSL_KEY` and `N8N_SSL_CERT` env vars are set
- **Pod not ready**: Check logs for startup errors