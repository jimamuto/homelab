# Kavita on Kubernetes

This directory deploys Kavita as a single-replica workload with persistent storage for both application state and library files.

It follows the same pattern as the rest of this repo:

- plain manifests
- Kustomize-friendly layout
- one directory per service

## Files

```text
kavita/
├── README.md
├── deployment.yaml
├── kavita-pvcs.yaml
├── kustomization.yaml
├── loadbalancer.yaml
├── namespace.yaml
└── service.yaml
```

## What Gets Created

- Namespace: `kavita`
- Workload: `Deployment/kavita`
- Image: `jvmilazz0/kavita:latest`
- Storage:
  - `kavita-config` PVC for app state
- Access:
  - internal `ClusterIP` service: `kavita`
  - external `LoadBalancer` service: `kavita-loadbalancer`
  - app port: `5000`

## Storage Layout

Kavita is not stateless. The manifests mount:

- `/kavita/config` for config, metadata, users, reading progress, and internal database state

This setup does not mount a host or shared library directory. Add content through Kavita itself or update the manifests later if you want a filesystem-backed library source.

For now, this repo assumes the Kavita web UI is the content-management path.

Typical flow after deployment:

1. Open Kavita in the browser.
2. Complete initial admin setup if prompted.
3. Use the web UI to add and manage your content.
4. Revisit the manifests later if you want a mounted library path such as NFS or another shared storage source.

## Deploy

From the repo root:

```bash
kubectl apply -k kavita
```

Or from this directory:

```bash
kubectl apply -k .
```

## Verify

```bash
kubectl get pods -n kavita
kubectl get svc -n kavita
kubectl get deployment -n kavita
kubectl get pvc -n kavita
```

Inspect logs if the pod is not ready:

```bash
kubectl describe pod -n kavita -l app=kavita
kubectl logs -n kavita -l app=kavita
```

## Access

Port-forward for local access:

```bash
kubectl port-forward svc/kavita -n kavita 5000:5000
```

Then open:

- `http://localhost:5000`

If your cluster exposes `LoadBalancer` services on the local network, you can also use:

```bash
kubectl get svc kavita-loadbalancer -n kavita
```

Then connect to:

- `http://<external-ip>:5000`

## Notes

- Storage class is `local-path`
- This is a single-instance setup intended for homelab use
- The image is configured without external database dependencies
- MinIO is not used as Kavita's live runtime storage in this setup
- No host library path is configured in this version
