# Arr Stack Setup - Proxmox VE

LXC-based media automation stack using Proxmox Community Scripts. Isolated containers for Prowlarr, Sonarr, Radarr, qBittorrent, and Jellyfin.

## Overview

Deployment model: One service per LXC container. Shared storage via NFS or bind mount. Setup relies on hardlinks/atomic moves for efficient media handling. Ensure download path and library path share the same filesystem to avoid I/O penalty during import.

Reference scripts and configs:
- [ct-add-storage.sh](ct-add-storage.sh) - Bind mount automation
- [nfs-setup.sh](nfs-setup.sh) - NFS client setup
- [example-configs/](example-configs/) - Path mappings and checklists

## Prerequisites

- Proxmox VE 7.x+ with root shell access
- Network connectivity (DHCP or static IPs)
- Shared storage: NFS export or local mount (recommend 10TB+)
- Basic Linux proficiency

## Storage Layout

Standard directory structure. Critical: `/mnt/media/torrents` and `/mnt/media/library` must be on same mount for hardlink support (atomic moves, no copy overhead).

```
/mnt/media/
├── torrents/
│   ├── incomplete/          # qBittorrent temp downloads
│   ├── complete/            # Finished downloads before import
│   │   ├── movies/
│   │   ├── tv/
│   │   └── anime/
│   └── watch/               # .torrent drop folder
└── library/                 # Final organized media
    ├── movies/              # Radarr root folder
    ├── tv/                  # Sonarr root folder
    └── anime/               # Sonarr-anime instance
```

Create structure:

```bash
mkdir -p /mnt/media/{torrents/{incomplete,complete/{movies,tv,anime},watch},library/{movies,tv,anime}}
```

Permissions for LXC access:

```bash
# For unprivileged containers (PUID 1000 maps to host 101000)
chown -R 101000:101000 /mnt/media

# For privileged containers
chown -R 1000:1000 /mnt/media
```

## NFS Setup

On Proxmox host:

```bash
apt update && apt install -y nfs-common

mkdir -p /mnt/media

# Test mount
mount -t nfs 192.168.1.100:/export/media /mnt/media

# Persistent mount (add to /etc/fstab)
echo "192.168.1.100:/export/media /mnt/media nfs defaults,_netdev,noatime 0 0" >> /etc/fstab

# Verify
df -h | grep media
mount -a
```

For local storage (skip if using NFS):

```bash
# ⚠️ WARNING: This erases all data on the device
mkfs.ext4 /dev/sdb1

mkdir -p /mnt/media
mount /dev/sdb1 /mnt/media
echo "/dev/sdb1 /mnt/media ext4 defaults 0 0" >> /etc/fstab
```

## ct-add-storage Helper

Automates bind mounting host storage into LXC containers.

Create `/usr/local/bin/ct-add-storage`:

```bash
#!/bin/bash
# Bind mount /mnt/media into specified container
# Usage: ct-add-storage <vmid>

if [ -z "$1" ]; then
    echo "Usage: ct-add-storage <vmid>"
    exit 1
fi

VMID=$1

if ! pct status "$VMID" >/dev/null 2>&1; then
    echo "Error: Container $VMID does not exist"
    exit 1
fi

pct set "$VMID" -mp0 /mnt/media,mp=/mnt/media
echo "Storage mounted. Reboot: pct reboot $VMID"
```

Make executable:

```bash
chmod +x /usr/local/bin/ct-add-storage
```

## Installation

Deploy using Proxmox Community Scripts. Each command spawns interactive installer. Note assigned VMID.

### Core Services

**Prowlarr** (Indexer aggregator):
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/prowlarr.sh)"
# Port: 9696, no storage mount needed
```

**qBittorrent** (Download client):
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/qbittorrent.sh)"
# Port: 8080, default: admin/adminadmin
ct-add-storage <VMID>
pct reboot <VMID>
```

**Sonarr** (Series automation):
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/sonarr.sh)"
# Port: 8989
ct-add-storage <VMID>
pct reboot <VMID>
```

**Radarr** (Movie automation):
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/radarr.sh)"
# Port: 7878
ct-add-storage <VMID>
pct reboot <VMID>
```

**Jellyfin** (Media server):
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/jellyfin.sh)"
# Port: 8096
ct-add-storage <VMID>
pct reboot <VMID>
```

**Jellyseerr** (Request interface):
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/jellyseerr.sh)"
# Port: 5055, no storage mount needed
```

### Optional Services

**Whisparr** (Adult content - same as Sonarr):
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/whisparr.sh)"
# Port: 6969
ct-add-storage <VMID>
pct reboot <VMID>
```

**Tdarr** (Transcoding):
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/tdarr.sh)"
# Port: 8265
ct-add-storage <VMID>
pct reboot <VMID>
```

**Configarr** (Auto-config using TRaSH guides):
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/configarr.sh)"
```

**Notifiarr** (Centralized notifications):
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/notifiarr.sh)"
```

## Configuration

###  Path Mapping (Critical)

All services must use identical paths. No remote path mapping needed if paths match exactly.

**qBittorrent paths** (Tools → Options → Downloads):
- Default Save Path: `/mnt/media/torrents/complete`
- Temp Path: `/mnt/media/torrents/incomplete`
- Categories:
  - `movies` → `/mnt/media/torrents/complete/movies`
  - `tv` → `/mnt/media/torrents/complete/tv`

Config file: `/config/qBittorrent/config/qBittorrent.conf` (inside container)

```ini
[Preferences]
Downloads\SavePath=/mnt/media/torrents/complete
Downloads\TempPath=/mnt/media/torrents/incomplete
Downloads\TempPathEnabled=true

[BitTorrent]
Session\Port=6881
```

**Sonarr/Radarr paths**:

Settings → Media Management:
- Root Folder: `/mnt/media/library/tv` (Sonarr) or `/mnt/media/library/movies` (Radarr)
- Use Hardlinks: **Enable** (critical for performance - no copy overhead)
- File Management: Rename Files (recommended)

Settings → Download Clients → Add qBittorrent:
- Host: `<qbittorrent-container-ip>` (get via `pct exec <VMID> hostname -I`)
- Port: `8080`
- Category: `tv` or `movies` (must match qBit category)

**Path verification**:

Paths in download client and arr apps must be identical. Example:
- qBittorrent saves to: `/mnt/media/torrents/complete/tv/Show.S01E01.mkv`
- Sonarr sees same path: `/mnt/media/torrents/complete/tv/Show.S01E01.mkv`
- Sonarr hardlinks to: `/mnt/media/library/tv/Show/Season 01/Show.S01E01.mkv`

Verify same filesystem (must show same device):
```bash
df /mnt/media/torrents /mnt/media/library
```

**Jellyfin libraries**:

Dashboard → Libraries → Add Library:
- Movies: `/mnt/media/library/movies`
- Shows: `/mnt/media/library/tv`

**Jellyseerr integration**:

Initial setup: Connect to Jellyfin (`http://<jellyfin-ip>:8096`)

Settings → Services:
- Add Sonarr: URL `http://<sonarr-ip>:8989`, API key from Sonarr Settings → General
- Add Radarr: URL `http://<radarr-ip>:7878`, API key from Radarr Settings → General

### Prowlarr Integration

Settings → Apps → Add Application:
- Sonarr: URL `http://<sonarr-ip>:8989`, API ID from Sonarr
- Radarr: URL `http://<radarr-ip>:7878`, API key from Radarr
- Prowlarr URL: `http://localhost:9696`

Add indexers in Prowlarr (Indexers → Add Indexer), sync propagates to connected apps.

### Download Flow

```
User adds series in Sonarr
↓
Sonarr → Prowlarr queries indexers
↓
Sonarr sends torrent to qBittorrent (category "tv")
↓
qBittorrent downloads to /mnt/media/torrents/complete/tv/
↓
Sonarr detects completion, hardlinks to /mnt/media/library/tv/SeriesName/
↓
Jellyfin library scan picks up new file
```

Import time: Seconds to minutes (hardlink is atomic).

## Network Configuration

Containers get DHCP by default. Recommendation: Static IPs for stability.

Static IP assignment (edit container config):
```bash
nano /etc/pve/lxc/<VMID>.conf
```

Add/modify:
```
net0: name=eth0,bridge=vmbr0,hwaddr=XX:XX:XX:XX:XX:XX,ip=192.168.1.50/24,gw=192.168.1.1,type=veth
```

Or via pct:
```bash
pct set <VMID> -net0 name=eth0,bridge=vmbr0,ip=192.168.1.50/24,gw=192.168.1.1
pct reboot <VMID>
```

Find container IPs:
```bash
pct list
pct exec <VMID> hostname -I
```

## Service Ports

| Service | Port | Purpose |
|---------|------|---------|
| Prowlarr | 9696 | Indexer management |
| qBittorrent | 8080 | Download client |
| Sonarr | 8989 | Series automation |
| Radarr | 7878 | Movie automation |
| Whisparr | 6969 | Adult content |
| Jellyfin | 8096 | Media server |
| Jellyseerr | 5055 | Request interface |
| Tdarr | 8265 | Transcoding |

Access: `http://<host-ip>:<port>` or `http://<container-ip>:<port>`

## Common Operations

Container management:
```bash
pct list                    # List all containers
pct start <VMID>           # Start container
pct stop <VMID>            # Stop container
pct reboot <VMID>          # Reboot container
pct enter <VMID>           # Enter container shell
pct exec <VMID> <cmd>      # Execute command
```

Config file locations (inside containers):
- Prowlarr/Sonarr/Radarr/Whisparr: `/config/config.xml`
- qBittorrent: `/config/qBittorrent/config/qBittorrent.conf`
- Jellyfin: `/config/`

Backup configs:
```bash
mkdir -p /mnt/media/backups
pct exec <VMID> tar czf /mnt/media/backups/ct<VMID>-config.tar.gz /config/
```

Update container OS:
```bash
pct exec <VMID> -- bash -c "apt update && apt upgrade -y"
```

## Troubleshooting

**Import failures** ("No files found"):
- Verify paths match exactly in qBittorrent and arr apps
- Check filesystem: `df /mnt/media/torrents /mnt/media/library` must show same device
- Confirm hardlinks enabled: Settings → Media Management → Use Hardlinks
- Check permissions: `ls -la /mnt/media/torrents/complete/`

**Container can't access storage**:
```bash
# Verify mount inside container
pct exec <VMID> ls -la /mnt/media

# Check host mount
df -h | grep media

# Re-apply bind mount
pct set <VMID> -mp0 /mnt/media,mp=/mnt/media
pct reboot <VMID>
```

**Services unreachable**:
```bash
# Check container running
pct status <VMID>

# Check service status inside container
pct enter <VMID>
systemctl status sonarr  # or prowlarr, radarr, etc.
journalctl -xe
```

**High I/O on imports** (copying instead of hardlinking):
- Verify `/mnt/media/torrents` and `/mnt/media/library` on same mount
- Settings → Media Management → Use Hardlinks **must be enabled**
- Check with: `ls -li` on source and destination - inode numbers should match

**Prowlarr indexers not syncing**:
- Verify Prowlarr → Settings → Apps shows apps configured
- Check API keys correct
- Test connectivity: `pct exec <SONARR_VMID> curl http://<prowlarr-ip>:9696`

**NFS mount fails on boot**:
- Add `_netdev` option in `/etc/fstab`:
```bash
192.168.1.100:/export/media /mnt/media nfs defaults,_netdev,noatime 0 0
```
- Verify NFS server is accessible: `showmount -e 192.168.1.100`

**Permission denied errors**:
```bash
# Check ownership on host
ls -lan /mnt/media

# For unprivileged containers, set owner to 101000:
chown -R 101000:101000 /mnt/media

# For privileged containers:
chown -R 1000:1000 /mnt/media
```

## Reference

- [Proxmox Community Scripts](https://github.com/community-scripts/ProxmoxVE) - Installation scripts
- [TRaSH Guides](https://trash-guides.info/) - Quality profiles, best practices
- [Servarr Wiki](https://wiki.servarr.com/) - Official documentation
- [example-configs/sonarr-radarr-paths.md](example-configs/sonarr-radarr-paths.md) - Path examples
- [example-configs/quick-reference.md](example-configs/quick-reference.md) - Quick reference sheet
