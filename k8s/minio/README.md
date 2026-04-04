# MinIO on Kubernetes

Deploy MinIO object storage on a Kubernetes cluster using the MinIO Operator.

## Prerequisites

- A running Kubernetes cluster (k3s, kind, minikube, etc.)
- `kubectl` configured and connected to your cluster
- A `local-path` StorageClass (or update `storageClassName` in `deployment.yaml`)

## File Structure

```
minio/
├── deployment.yaml      # Namespace + MinIO Tenant
├── loadbalancer.yaml    # LoadBalancer service for external access
├── secrets.yaml         # Credentials (gitignored - DO NOT commit)
├── .gitignore
└── README.md
```

## Setup

### 1. Create the secrets file

Copy `secrets.yaml.example` to `secrets.yaml` and update with your credentials:

```bash
cp secrets.yaml.example secrets.yaml
```

Edit `secrets.yaml` and set your values:

- `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` — MinIO admin credentials
- `CONSOLE_ACCESS_KEY` / `CONSOLE_SECRET_KEY` — base64-encoded console login

To encode values:

```bash
echo -n 'your-username' | base64
echo -n 'your-password' | base64
```

### 2. Install the MinIO Operator

```bash
kubectl apply -k "github.com/minio/operator?ref=v7.0.1"
```

Wait for the operator to be ready:

```bash
kubectl get pods -n minio-operator
```

### 3. Deploy MinIO

Apply secrets first, then the namespace and tenant:

```bash
kubectl apply -f secrets.yaml
kubectl apply -f deployment.yaml
kubectl apply -f loadbalancer.yaml
```

### 4. Verify deployment

```bash
kubectl get pods -n minio-tenant
kubectl get svc -n minio-tenant
```

Wait until the pod shows `2/2 Ready` and the LoadBalancer has an external IP.

## Accessing MinIO

### Via LoadBalancer (if your cluster supports it)

Get the external IP:

```bash
kubectl get svc minio-loadbalancer -n minio-tenant
```

- **Console**: `https://<EXTERNAL-IP>:9443`
- **API (S3)**: `https://<EXTERNAL-IP>:9000`

### Via NodePort (works on all clusters)

Use the node's IP with the NodePort:

- **Console**: `https://<NODE-IP>:30775`
- **API (S3)**: `https://<NODE-IP>:32333`

### Via Port Forward (local dev)

```bash
kubectl port-forward svc/minio-loadbalancer -n minio-tenant 9000:9000 9443:9443
```

- **Console**: `https://localhost:9443`
- **API (S3)**: `https://localhost:9000`

> **Note**: You will see a certificate warning in your browser. This is expected — MinIO uses self-signed certificates. Click "Advanced" → "Proceed anyway".

## Using the MinIO Client (mc)

### Install mc

```bash
# Linux
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc
chmod +x /usr/local/bin/mc

# macOS
brew install minio/stable/mc
```

### Configure alias

```bash
mc alias set myminio https://localhost:9000 jimoney kayole12A --insecure
```

Replace `localhost:9000` with your actual endpoint if not using port forwarding. The `--insecure` flag is needed for self-signed certs.

### Common commands

```bash
mc ls myminio                       # List buckets
mc mb myminio/mybucket              # Create a bucket
mc cp file.txt myminio/mybucket     # Upload a file
mc cp myminio/mybucket/file.txt .   # Download a file
mc rm myminio/mybucket/file.txt     # Delete a file
mc admin info myminio               # Server info
mc admin user list myminio          # List users
mc policy set download myminio/mybucket  # Make bucket publicly readable
```

## Troubleshooting

### Pod not ready

```bash
kubectl describe pod -n minio-tenant -l v1.min.io/tenant=minio
kubectl logs -n minio-tenant -l v1.min.io/tenant=minio -c minio
```

### No external IP on LoadBalancer

Some clusters (kind, minikube, bare-metal) don't support LoadBalancer out of the box. Use port forwarding or NodePort instead.

### Certificate errors with mc

Always use `--insecure` when connecting to a MinIO instance with self-signed certs:

```bash
mc alias set myminio https://localhost:9000 <user> <pass> --insecure
```

### Reset deployment

```bash
kubectl delete -f loadbalancer.yaml
kubectl delete -f deployment.yaml
kubectl delete -f secrets.yaml
kubectl delete namespace minio-tenant
```

Then re-apply from step 3.
