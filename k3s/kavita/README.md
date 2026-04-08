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
  - host directory `/home/jimoney/library` for books and comics
- Access:
  - internal `ClusterIP` service: `kavita`
  - external `LoadBalancer` service: `kavita-loadbalancer`
  - app port: `5000`

## Storage Layout

Kavita is not stateless. The manifests mount:

- `/kavita/config` for config, metadata, users, reading progress, and internal database state
- `/books` for the library files Kavita scans, backed by `/home/jimoney/library`

Create library directories on the host:

```bash
mkdir -p /home/jimoney/library/{manga,programming,manuals}
```

Then place files under paths like:

- `/home/jimoney/library/manga`
- `/home/jimoney/library/programming`
- `/home/jimoney/library/manuals`

In Kavita, add library paths such as:

- `/books/manga`
- `/books/programming`
- `/books/manuals`

Important: point Kavita at the parent library folder, not a book-specific folder.

Good examples:

- `/books/programming`
- `/books/manga`

Bad examples:

- `/books/programming/rust`
- `/books/programming/The Rust Programming Language`

Kavita expects the library root to contain folders, not files directly at the root.

For programming books, use a structure like:

```text
/home/jimoney/library/programming/rust/The Rust Programming Language.pdf
```

That maps to:

```text
/books/programming/rust/The Rust Programming Language.pdf
```

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

Verify the mounted library is visible inside the container:

```bash
kubectl exec -n kavita deployment/kavita -- ls -la /books
kubectl exec -n kavita deployment/kavita -- ls -la /books/programming
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
- The library mount uses `hostPath` at `/home/jimoney/library`
- If Kavita warns that a library has files at the root, move those files into a subfolder and keep the library path pointed at the parent directory
