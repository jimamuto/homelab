# PostgreSQL on Kubernetes

This directory deploys PostgreSQL as a single-replica `StatefulSet` with persistent storage and internal services for stable discovery inside the cluster.

The manifests also include backup-related environment values pointing at the MinIO service in this repo, so this is not just a generic database deployment. It is wired for the homelab stack here.

## Files

```text
psql/
├── README.md
├── appdb_backup.sql
├── kustomization.yaml
├── namespace.yaml
├── postgres-configmap.yaml
├── postgres-pvc.yaml
├── postgres-services.yaml
└── postgres-statefulset.yaml
```

## What Gets Created

- Namespace: `postgres`
- Workload: `StatefulSet/postgres`
- Image: `postgres:16`
- Storage: `20Gi` PVC named `postgres-pvc`
- Services:
  - `postgres-headless` for stable identity
  - `postgres` as the internal client service
- Secret dependency: `postgres-auth`
- ConfigMap: `postgres-config`

Current config values from [postgres-configmap.yaml](/home/jimoney/homelab/k8s/psql/postgres-configmap.yaml):

- `POSTGRES_DB=appdb`
- `POSTGRES_USER=appuser`
- `AWS_ENDPOINT=http://minio.minio.svc.cluster.local:9000`
- `AWS_REGION=us-east-1`
- `BACKUP_BUCKET=postgres-backups`

## Required Secret

Create the `postgres-auth` secret in the `postgres` namespace before deployment.

Required key:

- `POSTGRES_PASSWORD`

Example:

```bash
kubectl create namespace postgres --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic postgres-auth \
  -n postgres \
  --from-literal=POSTGRES_PASSWORD='<strong-password>'
```

## Deploy

From the repo root:

```bash
kubectl apply -k psql
```

Or from this directory:

```bash
kubectl apply -k .
```

## Verify

```bash
kubectl get pods -n postgres
kubectl get svc -n postgres
kubectl get pvc -n postgres
kubectl get statefulset -n postgres
```

Inspect the pod if needed:

```bash
kubectl describe pod -n postgres -l app=postgres
kubectl logs -n postgres -l app=postgres
```

## Connect

Port-forward the service:

```bash
kubectl port-forward svc/postgres -n postgres 5432:5432
```

Then connect locally with your normal PostgreSQL client using:

- host: `localhost`
- port: `5432`
- database: `appdb`
- user: `appuser`

Or open a shell in the running pod:

```bash
kubectl exec -it -n postgres statefulset/postgres -- psql -U appuser -d appdb
```

## Persistence Check

A quick persistence test:

```bash
kubectl exec -it -n postgres statefulset/postgres -- psql -U appuser -d appdb
```

Then run:

```sql
CREATE TABLE IF NOT EXISTS healthcheck (
  id serial PRIMARY KEY,
  status text NOT NULL
);
INSERT INTO healthcheck (status) VALUES ('ok');
SELECT count(*) FROM healthcheck;
```

Delete the pod:

```bash
kubectl delete pod -n postgres -l app=postgres
kubectl get pods -n postgres -w
```

Reconnect and verify the row count is still there.

## Kustomize Contents

[kustomization.yaml](/home/jimoney/homelab/k8s/psql/kustomization.yaml) includes:

- [namespace.yaml](/home/jimoney/homelab/k8s/psql/namespace.yaml)
- [postgres-configmap.yaml](/home/jimoney/homelab/k8s/psql/postgres-configmap.yaml)
- [postgres-pvc.yaml](/home/jimoney/homelab/k8s/psql/postgres-pvc.yaml)
- [postgres-services.yaml](/home/jimoney/homelab/k8s/psql/postgres-services.yaml)
- [postgres-statefulset.yaml](/home/jimoney/homelab/k8s/psql/postgres-statefulset.yaml)

## Notes

- Storage class is `local-path`
- Resource requests are `250m` CPU and `512Mi` memory
- Resource limits are `1` CPU and `1Gi` memory
- Readiness and liveness probes both use `pg_isready`
- The checked-in [appdb_backup.sql](/home/jimoney/homelab/k8s/psql/appdb_backup.sql) is the SQL backup artifact currently stored in this directory

## Troubleshooting

Secret missing:

```bash
kubectl get secret postgres-auth -n postgres
```

PVC not binding:

```bash
kubectl describe pvc postgres-pvc -n postgres
```

Pod not ready:

```bash
kubectl describe pod -n postgres -l app=postgres
kubectl logs -n postgres -l app=postgres
```

Service discovery test from another pod:

```bash
kubectl run psql-debug --rm -it --restart=Never \
  --image=postgres:16 \
  -n postgres \
  -- psql -h postgres -U appuser -d appdb
```
