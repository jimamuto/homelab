# MinIO AIStor Object Storage

## Overview

MinIO AIStor is an enterprise-grade object storage solution. This guide covers deployment and basic operations using Docker.

## Prerequisites

- Docker installed and running
- Valid MinIO license file (`minio.license`)

## Deployment

### 1. Pull Latest Image

```bash
docker pull quay.io/minio/aistor/minio
```

### 2. Create Directory Structure

Create directories for data and certificates:

```bash
mkdir -p $HOME/minio/data $HOME/minio/certs
```

Place your license file at `$HOME/minio/minio.license`.

### 3. Run Container

```bash
docker run -dt \
  -p 9000:9000 -p 9001:9001 \
  -v $HOME/minio/data:/mnt/data \
  -v $HOME/minio/minio.license:/minio.license \
  -v $HOME/minio/certs:/etc/minio/certs \
  --name "aistor-server" \
  quay.io/minio/aistor/minio:latest minio server /mnt/data \
  --license /minio.license
```

**Ports:**
- `9000` - S3 API
- `9001` - Web Console

### 4. Verify Deployment

Check container logs:

```bash
docker logs aistor-server
```

## Basic Operations with mc CLI

### Enter Container

```bash
docker exec -it aistor-server /bin/bash
```

### Configure mc Client

```bash
mc alias set local http://localhost:9000 minioadmin minioadmin
```

### Check Server Info

```bash
mc admin info local
```

### Create Bucket

```bash
mc mb local/new-bucket
```

### List Buckets

```bash
mc ls local
```

### Upload File to Bucket

```bash
mc cp <filename> local/<bucket-name>
```

Example:

```bash
mc cp minio.license local/new-bucket
```

### List Bucket Contents

```bash
mc ls local/new-bucket
```

## Troubleshooting

- If `mc cp` reports "path not found", verify the file exists in the container's filesystem (not the host)
- Use `ls -la` inside the container to confirm file paths
- The license file is mounted at `/minio.license` inside the container
