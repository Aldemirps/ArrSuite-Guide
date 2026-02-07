# Arr Stack Setup Guide for Proxmox VE

A minimal, developer-friendly guide to setting up a complete media automation stack on Proxmox using LXC containers.

## 📋 Overview

This guide uses [Proxmox VE Community Scripts](https://github.com/community-scripts/ProxmoxVE) to deploy each service as a lightweight LXC container. Each container is isolated, resource-efficient, and easy to manage.

## ✅ Prerequisites

- Proxmox VE host with root access
- Network connectivity (containers will auto-configure networking)
- Shared storage for media files (optional but recommended)

## 🎯 Core Stack Components

### 1. Indexer Management
**Prowlarr** - Centralized indexer management for all *arr apps

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/prowlarr.sh)"
```

> 💡 **Start here** - Prowlarr manages indexers for all other services

### 2. Download Client
**qBittorrent** - Torrent client

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/qbittorrent.sh)"
```

### 3. Content Management
**Sonarr** - TV show automation

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/sonarr.sh)"
```

**Radarr** - Movie automation

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/radarr.sh)"
```

**Whisparr** - Adult content automation (optional)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/whisparr.sh)"
```

### 4. Media Server
**Jellyfin** - Open-source media server

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/jellyfin.sh)"
```

### 5. Request Management
**Jellyseerr** - User request interface for Jellyfin

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/jellyseerr.sh)"
```

## 🔧 Optional Utilities

### Automation & Monitoring

**Configarr** - Auto-configuration tool for *arr apps

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/configarr.sh)"
```

**Notifiarr** - Unified notification system

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/notifiarr.sh)"
```

**Cleanuparr** - Automated cleanup utility

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/cleanuparr.sh)"
```

**Huntarr** - Content discovery and automation

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/huntarr.sh)"
```

### Transcoding

**Tdarr** - Distributed transcoding system

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/tdarr.sh)"
```

## 🚀 Installation Flow

### Step 1: Run Installation Scripts

SSH into your Proxmox host and run each command. The scripts will:
- ✅ Create a new LXC container
- ✅ Install the service
- ✅ Configure basic settings
- ✅ Start the service

### Step 2: Add Shared Storage

After creating containers, add shared storage (NFS/CIFS/local bind mount) for media files:

```bash
# Add storage to a container (replace 108 with your container ID)
ct-add-storage 108
pct reboot 108
```

Repeat for each container that needs access to media files (typically Sonarr, Radarr, qBittorrent, Jellyfin).

### Step 3: Configure Services

Access each service via web UI (default ports):

1. **Prowlarr** (`:9696`) - Add indexers first
2. **qBittorrent** (`:8080`) - Configure download directories
3. **Sonarr** (`:8989`) & **Radarr** (`:7878`) - Connect to Prowlarr & qBittorrent
4. **Jellyfin** (`:8096`) - Add media libraries
5. **Jellyseerr** (`:5055`) - Connect to Jellyfin and *arr apps

### Step 4: Connect Services

- In Prowlarr: Add Sonarr and Radarr as apps
- In Sonarr/Radarr: Add qBittorrent as download client
- Set matching paths across all services (e.g., `/media/tv`, `/media/movies`)

## 🔍 Finding Container IPs

From Proxmox host:

```bash
# List all containers with IPs
pct list

# Get specific container IP
pct exec <CTID> -- ip addr show
```

## 📊 Quick Reference

| Service | Default Port | Purpose |
|---------|--------------|---------|
| Prowlarr | 9696 | Indexer management |
| Sonarr | 8989 | TV automation |
| Radarr | 7878 | Movie automation |
| Whisparr | 6969 | Adult content |
| qBittorrent | 8080 | Download client |
| Jellyfin | 8096 | Media server |
| Jellyseerr | 5055 | Request management |
| Tdarr | 8265 | Transcoding |

## ⚡ Common Commands

```bash
# Enter container shell
pct enter <CTID>

# Restart container
pct reboot <CTID>

# Stop/Start container
pct stop <CTID>
pct start <CTID>

# Update Proxmox host
apt update && apt dist-upgrade -y
```

## 🎬 Bare Minimum Setup

For a functional basic stack, install in this order:

1. **Prowlarr** - Indexer management
2. **qBittorrent** - Downloads
3. **Radarr** OR **Sonarr** - Content management
4. **Jellyfin** - Media playback

That's **4 containers** for a working media automation setup.

## 💡 Tips

- **Storage Paths**: Use consistent paths across all containers (e.g., `/media/downloads`, `/media/movies`, `/media/tv`)
- **Resource Allocation**: LXC containers are lightweight - 1GB RAM per container is usually sufficient
- **Networking**: Containers get DHCP by default; set static IPs in Proxmox for stability
- **Backups**: Use Proxmox built-in backup for easy restoration
- **Updates**: Services auto-update or can be updated via their web UI

## 🐛 Troubleshooting

- **Can't access web UI**: Check container is running (`pct status <CTID>`) and firewall rules
- **Services can't communicate**: Ensure all containers are on the same network bridge
- **Permission errors**: Container users may need matching UIDs/GIDs for shared storage

## 📚 Resources

- [Proxmox VE Community Scripts](https://github.com/community-scripts/ProxmoxVE)
- [TRaSH Guides](https://trash-guides.info/) - Detailed *arr configuration guides
- [Servarr Wiki](https://wiki.servarr.com/) - Official documentation

---

<div align="center">

**This setup runs each service in isolated LXC containers for maximum efficiency and security on Proxmox VE.**

*Last updated: February 2026*

</div>
