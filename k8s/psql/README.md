# PostgreSQL on Kubernetes Deployment Guide

This guide documents the steps to deploy PostgreSQL on Kubernetes using StatefulSet for persistence.

## Prerequisites
- Kubernetes cluster - kubectl configured to access the cluster

## Deployment Steps

### 1. Create Namespace
Create a dedicated namespace for PostgreSQL resources:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: postgres
```

Apply:
```bash
kubectl apply -f namespace.yaml
```

### 2. Create Secret and ConfigMap
Create a Secret for passwords and a ConfigMap for non-sensitive settings:

```bash
kubectl create secret generic postgres-auth \
  --namespace postgres \
  --from-literal=POSTGRES_PASSWORD='ReplaceWithStrongPassword'
```

ConfigMap (postgres-configmap.yaml):
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: postgres
data:
  POSTGRES_DB: appdb
  POSTGRES_USER: appuser
```

Apply:
```bash
kubectl apply -f postgres-configmap.yaml
```

### 3. Create Persistent Storage
Create a PersistentVolumeClaim for storage:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: postgres
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 20Gi
```

Apply and verify:
```bash
kubectl apply -f postgres-pvc.yaml
kubectl get pvc -n postgres
```

### 4. Create Services
Create a headless service for stable network identity and a ClusterIP service for client access:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
  namespace: postgres
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
    - name: postgres
      port: 5432
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: postgres
spec:
  type: ClusterIP
  selector:
    app: postgres
  ports:
    - name: postgres
      port: 5432
      targetPort: 5432
```

Apply:
```bash
kubectl apply -f postgres-services.yaml
```

### 5. Deploy PostgreSQL with StatefulSet
Deploy PostgreSQL using a StatefulSet:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: postgres
spec:
  serviceName: postgres-headless
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:16
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_DB
              valueFrom:
                configMapKeyRef:
                  name: postgres-config
                  key: POSTGRES_DB
            - name: POSTGRES_USER
              valueFrom:
                configMapKeyRef:
                  name: postgres-config
                  key: POSTGRES_USER
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-auth
                  key: POSTGRES_PASSWORD
          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
          readinessProbe:
            exec:
              command:
                - /bin/sh
                - -c
                - pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"
            initialDelaySeconds: 10
            periodSeconds: 5
          livenessProbe:
            exec:
              command:
                - /bin/sh
                - -c
                - pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"
            initialDelaySeconds: 30
            periodSeconds: 10
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: postgres-storage
          persistentVolumeClaim:
            claimName: postgres-pvc
```

Apply and verify:
```bash
kubectl apply -f postgres-statefulset.yaml
kubectl get pods -n postgres -l app=postgres
kubectl get statefulset -n postgres
```

### 6. Verify Persistence
Test connectivity and verify data persistence:

```bash
# Get pod name
POD_NAME=$(kubectl get pods -n postgres -l app=postgres \
  -o jsonpath='{.items[0].metadata.name}')
echo "$POD_NAME"

# Connect to PostgreSQL
kubectl exec -it -n postgres "$POD_NAME" -- \
  psql -U appuser -d appdb

# Inside psql, run:
CREATE TABLE IF NOT EXISTS healthcheck (
  id serial PRIMARY KEY,
  status text NOT NULL
);
INSERT INTO healthcheck (status) VALUES ('ok');
SELECT count(*) FROM healthcheck;

# Exit psql, then delete pod
kubectl delete pod -n postgres "$POD_NAME"
kubectl get pods -n postgres -l app=postgres -w

# After pod recreates, reconnect and verify
NEW_POD_NAME=$(kubectl get pods -n postgres -l app=postgres \
  -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n postgres "$NEW_POD_NAME" -- \
  psql -U appuser -d appdb -c "SELECT count(*) FROM healthcheck;"
```

If the row count persists, your storage is correctly configured.

## Notes
- Storage class used: `local-path` (adjust based on your cluster's available storage classes)
- Resource requests/limits can be adjusted based on workload requirements
