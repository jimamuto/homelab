# qbittorrent

A Kubernetes deployment for qbittorrent using the linuxserver.io image.

- Namespace: `qbittorrent`
- Workload: single-replica `Deployment`
- Image: `lscr.io/linuxserver/qbittorrent:latest`
- Storage:
  - `1Gi` via `local-path` for app config
  - host directory `/home/jimoney/downloads` for downloads
- Access:
  - internal `ClusterIP` service: `qbittorrent`
  - external `NodePort` service: `qbittorrent-nodeport` (port 30005)
  - app port: `30005`

## Deployment

```bash
kubectl apply -k qbittorrent
```

## Access

From any machine on the network:

```
http://<host-ip>:30005
```

Default credentials are set on first login through the web UI.

## Notes

- The deployment includes an init container that configures the WebUI port to `30005` in the qBittorrent config file
- Downloads are stored on the host at `/home/jimoney/downloads`
- PUID/PGID are set to `1000` for ownership compatibility