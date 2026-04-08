# MinIO on Kubernetes

This directory deploys MinIO as a plain single-node `StatefulSet` with persistent storage and two services:

- `minio` as the internal `ClusterIP` service
- `minio-loadbalancer` as the external `LoadBalancer` service

It is a small, direct setup for homelab use. No operator, no extra control plane components, just the manifests needed to run MinIO.

## Files

```text
minio/
├── README.md
├── deployment.yaml
├── kustomization.yaml
├── loadbalancer.yaml
└── namespace.yaml
```

## What Gets Created

- Namespace: `minio`
- Workload: `StatefulSet/minio`
- Image: `quay.io/minio/minio:RELEASE.2024-10-02T17-50-41Z`
- Storage: `25Gi` PVC from `volumeClaimTemplates`
- Ports:
  - `9000` for the S3 API
  - `9001` for the web console
- Secret dependency: `minio-env`

The main container is configured with:

```text
minio server /data --console-address :9001
```

## Required Secret

Create the `minio-env` secret in the `minio` namespace before applying the manifests.

Required keys:

- `MINIO_ROOT_USER`
- `MINIO_ROOT_PASSWORD`

Example:

```bash
kubectl create namespace minio --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic minio-env \
  -n minio \
  --from-literal=MINIO_ROOT_USER='<user>' \
  --from-literal=MINIO_ROOT_PASSWORD='<password>'
```

## Deploy

From the repo root:

```bash
kubectl apply -k minio
```

Or from this directory:

```bash
kubectl apply -k .
```

## Verify

```bash
kubectl get pods -n minio
kubectl get svc -n minio
kubectl get statefulset -n minio
```

Inspect the pod if it is not ready:

```bash
kubectl describe pod -n minio -l app=minio
kubectl logs -n minio -l app=minio
```

## Access

For local admin access, port-forwarding is the safest default:

```bash
kubectl port-forward svc/minio-loadbalancer -n minio 9000:9000 9001:9001
```

Endpoints:

- Console: `http://localhost:9001`
- API: `http://localhost:9000`

If your cluster exposes `LoadBalancer` services cleanly on your network, you can also use:

```bash
kubectl get svc minio-loadbalancer -n minio
```

Then connect to:

- `http://<external-ip>:9001`
- `http://<external-ip>:9000`

Whether the external IP is reachable depends on the cluster and host networking. If it is not, use port-forwarding.

## Kustomize Contents

[kustomization.yaml](/home/jimoney/homelab/k3s/minio/kustomization.yaml) includes:

- [namespace.yaml](/home/jimoney/homelab/k3s/minio/namespace.yaml)
- [deployment.yaml](/home/jimoney/homelab/k3s/minio/deployment.yaml)
- [loadbalancer.yaml](/home/jimoney/homelab/k3s/minio/loadbalancer.yaml)

## Notes

- Storage class is set to `local-path`
- The workload uses a single replica, which fits homelab and local persistence use
- Readiness and liveness probes hit MinIO health endpoints on port `9000`
- The internal service name other workloads can use is `minio.minio.svc.cluster.local:9000`

## Troubleshooting

No pod:

```bash
kubectl get events -n minio --sort-by=.lastTimestamp
```

Secret missing:

```bash
kubectl get secret minio-env -n minio
```

PVC not binding:

```bash
kubectl get pvc -n minio
kubectl describe pvc -n minio
```

Service reachable in cluster but not from your machine:

- check the `EXTERNAL-IP` on `minio-loadbalancer`
- confirm your cluster supports `LoadBalancer`
- fall back to `kubectl port-forward`
