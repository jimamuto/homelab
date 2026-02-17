# Homelab Setup Guide

## Overview
Ubuntu 24.04 server used as a devops playground for learning and experimentation.

## Initial Setup

### SSH Access
1. Generate SSH key on local machine: `ssh-keygen -t ed25519`
2. Copy public key to server: `ssh-copy-id user@server-ip`
3. Verify passwordless login works

### Base Software
```bash
sudo apt update
sudo apt install git docker.io
```

### Docker Permissions
```bash
sudo usermod -aG docker $USER
newgrp docker
```

## GitHub CLI

Authenticate using SSH protocol (avoids browser OAuth issues on headless server):

1. Generate SSH key: `ssh-keygen -t ed25519 -C "email@example.com"`
2. Add public key to GitHub (Settings → SSH and GPG keys)
3. Run `gh auth login` and select SSH option

## Projects

### Octavia
Load balancer project running in Docker Compose:
```bash
cd ~/octavia/octavia
docker-compose -f docker-compose.prod.yml up --build
```

## Common Issues

| Issue | Solution |
|-------|----------|
| Docker permission denied | Run `sudo usermod -aG docker $USER` and `newgrp docker` |
| gh auth login fails to open browser | Use SSH authentication instead of web flow |

## Server Details
- OS: Ubuntu 24.04.4 LTS
- Location: Local network
- Purpose: Devops learning and experimentation
