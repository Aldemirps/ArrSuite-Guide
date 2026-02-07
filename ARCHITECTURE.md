# Proxmox Arr Stack Architecture Guide

A deep dive into the design decisions, infrastructure setup, and architectural philosophy behind this media automation stack.

---

## 📖 Table of Contents

- [Phase 1: Project Overview & Philosophy](#phase-1-project-overview--philosophy)
- [Phase 2: Infrastructure & Installation](#phase-2-infrastructure--installation)
- [Phase 3: The "Hard Part" - Storage & Permissions](#phase-3-the-hard-part---storage--permissions)
- [Phase 4: Hardware & Transcoding](#phase-4-hardware--transcoding)
- [Phase 5: Networking & Access](#phase-5-networking--access)
- [Phase 6: The Application Stack (The Arrs)](#phase-6-the-application-stack-the-arrs)
- [Phase 7: Maintenance & Backups](#phase-7-maintenance--backups)

---

## Phase 1: Project Overview & Philosophy

### What is this project?

The **Proxmox Arr Stack** is a complete media automation system running on Proxmox VE, where each service (Sonarr, Radarr, Prowlarr, qBittorrent, Jellyfin, etc.) runs in its own dedicated LXC container. This creates a highly modular, efficient, and maintainable media server infrastructure.

**The Flow:**
```
User requests content → Jellyseerr
                         ↓
Sonarr/Radarr monitors and searches (via Prowlarr)
                         ↓
Download client (qBittorrent) downloads
                         ↓
*arr apps organize and rename
                         ↓
Jellyfin/Plex serves content to devices
```

### Why choose LXC Containers over a single Docker VM?

This is the most common question, and the answer comes down to **efficiency and architecture**:

#### 1. **Resource Isolation with Lower Overhead**

**LXC Containers:**
- Share the host kernel (system-level virtualization)
- Near-native performance
- Minimal RAM overhead (~50-100MB per container)
- Each container feels like a mini Linux system

**Docker in a VM:**
- VM needs its own kernel (hardware virtualization)
- VM overhead: ~512MB-1GB RAM just for the VM itself
- Then Docker adds another layer
- More resource usage for the same workload

**Real-world comparison:**
```
LXC Approach (8 containers):
├── Sonarr LXC:     ~200MB RAM
├── Radarr LXC:     ~200MB RAM
├── Prowlarr LXC:   ~150MB RAM
├── qBittorrent:    ~400MB RAM
├── Jellyfin:       ~800MB RAM
├── Jellyseerr:     ~200MB RAM
├── Tdarr:          ~300MB RAM
└── Notifiarr:      ~100MB RAM
Total: ~2.35GB RAM

Docker-in-VM Approach:
├── Ubuntu VM:      ~1GB RAM (base)
├── Docker daemon:  ~200MB RAM
└── All containers: ~2.5GB RAM
Total: ~3.7GB RAM (55% more!)
```

#### 2. **True "Microservices" Architecture**

Each LXC container is:
- **Independently managed** - Update Sonarr without touching Radarr
- **Individually backed up** - Snapshot just the container that changed
- **Isolated failure domain** - If Sonarr crashes, Radarr keeps running
- **Resource-limited** - Can set CPU/RAM limits per service

With Docker-in-VM:
- Everything shares the VM's resources
- Can't easily backup just one service
- VM failure = entire stack is down
- Harder to monitor individual service resources

#### 3. **Granular Backups & Rollbacks**

**LXC Snapshots:**
```bash
# Snapshot before Sonarr update
vzdump 102 --mode snapshot --storage local

# Update breaks something? Rollback in seconds:
pct restore 102 /var/lib/vz/dump/vzdump-lxc-102-*.tar.zst

# Rest of the stack unaffected
```

**Docker-in-VM:**
- Must backup entire VM (10-50GB+)
- Rollback affects ALL services
- Longer backup/restore times

#### 4. **Separate Kernel Processes**

Each LXC container has its own:
- Process namespace (isolated processes)
- Network namespace (own IP address)
- IPC namespace (inter-process communication)
- Mount namespace (own filesystem view)

This means:
- `systemctl restart sonarr` only affects that container
- Network issues in one container don't affect others
- Each service sees only its own processes (`ps aux` shows only that container)

**Why this matters:**
```bash
# LXC: Check Sonarr's CPU usage
pct exec 102 -- top

# Docker-in-VM: Must enter VM, then check all Docker containers
# Harder to isolate resource usage per service
```

#### 5. **Native Proxmox Integration**

LXC containers are **first-class citizens** in Proxmox:
- Built-in backup scheduler
- Easy migration between hosts
- Native resource monitoring
- Web UI management
- No extra layers (no Docker daemon to maintain)

### Why use Proxmox Helper Scripts?

The **[Community-Scripts](https://github.com/community-scripts/ProxmoxVE)** (formerly tteck's scripts) are the gold standard for LXC deployment:

**Benefits:**
1. **One-line installation** - No manual CT creation, downloads, or configuration
2. **Optimized settings** - Pre-configured with correct memory, CPU, and features
3. **Best practices** - Unprivileged by default, nesting enabled where needed
4. **Maintained** - Community updates for security and compatibility
5. **Consistent** - Every container built the same way

**Example:**
```bash
# Creates container, installs Sonarr, configures service, starts it
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/sonarr.sh)"

# What it does automatically:
# 1. Downloads Alpine/Debian template
# 2. Creates unprivileged LXC
# 3. Sets memory (2GB) and CPU (2 cores)
# 4. Enables nesting and keyctl features
# 5. Installs Sonarr and dependencies
# 6. Configures systemd service
# 7. Starts the service
# 8. Shows you the IP and port
```

**Without the script, you'd need:**
```bash
# Manual steps (30+ commands):
pct create 102 local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst
pct set 102 -hostname sonarr -memory 2048 -cores 2
pct set 102 -features nesting=1,keyctl=1
pct start 102
pct enter 102
curl -o- https://raw.githubusercontent.com/Sonarr/Sonarr/develop/distribution/debian/install.sh | bash
# ... plus systemd configuration, user creation, etc.
```

---

## Phase 2: Infrastructure & Installation

### How do you install the applications?

**One-line installation commands:**

```bash
# Core Stack (in recommended order)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/prowlarr.sh)"    # Indexer manager
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/qbittorrent.sh)" # Download client
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/sonarr.sh)"      # TV shows
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/radarr.sh)"      # Movies
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/jellyfin.sh)"    # Media server
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/jellyseerr.sh)"  # Request system

# Optional Services
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/whisparr.sh)"    # Adult content
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/tdarr.sh)"       # Transcoding
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/notifiarr.sh)"   # Notifications
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/huntarr.sh)"     # Auto-add content
```

**What happens during installation:**

1. **Interactive prompts:**
   - Container ID (auto-suggests next available)
   - Privileged or Unprivileged (recommends unprivileged)
   - Disk size (default 8GB for most apps)
   - CPU cores (default 2)
   - RAM (default 2048MB)
   - Network bridge (default vmbr0)
   - IP address (DHCP or static)

2. **Automatic setup:**
   - Downloads container template
   - Creates container with optimized settings
   - Installs application and dependencies
   - Configures systemd service
   - Enables autostart
   - Starts the service

3. **Output shows:**
   ```
   ✓ Successfully created Sonarr LXC Container
   
   Container ID: 102
   IP Address: 192.168.1.155
   Port: 8989
   Access: http://192.168.1.155:8989
   ```

### How are the containers configured?

**Unprivileged vs Privileged:**

The scripts default to **Unprivileged** containers, which is the safer choice:

**Unprivileged Container (Recommended):**
```bash
# UIDs inside container are mapped to high UIDs on host
Container UID 0 (root) → Host UID 100000
Container UID 1000 → Host UID 101000

# Security benefits:
# - Root inside container ≠ root on host
# - Can't escape to compromise host
# - Limited kernel capabilities
```

**View the mapping:**
```bash
cat /etc/pve/lxc/102.conf
# Output:
lxc.idmap: u 0 100000 65536
lxc.idmap: g 0 100000 65536
```

**Privileged Container (Rare cases):**
```bash
# Container UID = Host UID (1:1 mapping)
# Needed for:
# - Docker-in-LXC
# - Advanced GPU passthrough
# - Some kernel module access

# Security risk:
# - Root inside = root on host
# - Can potentially escape container
```

**Best practice:** Start with unprivileged. Only use privileged if you hit a specific limitation.

**Container features enabled:**
```bash
features: nesting=1,keyctl=1

# nesting=1: Allows nested containers (Docker-in-LXC if needed)
# keyctl=1: Allows keyring operations (needed by some apps)
```

### How do you handle updates?

**LXC Container updates:**

Each container is updated **independently**:

```bash
# Update Sonarr container OS packages
pct enter 102
apt update && apt upgrade -y
exit

# Update Sonarr application
# Most *arr apps auto-update via their web UI
# Or manually: Dashboard → System → Updates → Install
```

**Advantages over Docker stack updates:**

| LXC Approach | Docker-in-VM Approach |
|--------------|----------------------|
| Update one app without affecting others | Docker-compose pull updates all |
| Test updates individually | All-or-nothing update |
| Easy rollback per container | Must rollback entire VM |
| No need to manage Docker versions | Docker daemon updates needed |

**Bulk updates (all containers):**
```bash
# Update all container OS packages
for ctid in $(pct list | awk 'NR>1 {print $1}'); do
    echo "Updating CT $ctid..."
    pct exec $ctid -- bash -c "apt update && apt upgrade -y"
done
```

**Update strategy:**
1. **OS-level updates:** Monthly via SSH/cron
2. **Application updates:** Automatic (enabled in web UI) or manual
3. **Proxmox host updates:** Quarterly with backups before
4. **Snapshot before major updates:** Always snapshot critical containers

---

## Phase 3: The "Hard Part" - Storage & Permissions

This is where most people struggle. Let's break it down step-by-step.

### How is the storage architecture set up?

**The flow:**

```
┌─────────────────────────────────────────────────────────────┐
│                        NAS (TrueNAS/Synology)               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  /tank/media                                         │   │
│  │  ├── downloads/                                      │   │
│  │  └── ready/                                          │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │ NFS Export: 192.168.1.200:/tank/media
                         │ Options: rw,all_squash,anonuid=1000,anongid=1000
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Proxmox Host (PVE)                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  /mnt/cold-storage/  (NFS mount)                     │   │
│  │  ├── downloads/                                      │   │
│  │  └── ready/                                          │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────┬────────────────────────┬─────────────────────────┘
           │ Bind Mount             │ Bind Mount
           │ mp0: /mnt/cold-storage │ mp0: /mnt/cold-storage
           ▼                        ▼
┌──────────────────────┐   ┌──────────────────────┐
│   Sonarr LXC (102)   │   │   Radarr LXC (101)   │
│ /mnt/cold-storage/   │   │ /mnt/cold-storage/   │
│ ├── downloads/       │   │ ├── downloads/       │
│ └── ready/           │   │ └── ready/           │
└──────────────────────┘   └──────────────────────┘
```

**Key principle:** **Same path everywhere**
- NAS exports: `/tank/media`
- Host mounts: `/mnt/cold-storage`
- Containers see: `/mnt/cold-storage`

### How do you mount the NAS to the Proxmox Host?

**Method 1: Using Proxmox Web UI (Datacenter → Storage)**

Not recommended for bind mounts. Proxmox storage is meant for VM/CT disks, not media shares.

**Method 2: Direct NFS mount (Recommended)**

```bash
# On Proxmox host

# Step 1: Install NFS client tools
apt update && apt install nfs-common -y

# Step 2: Create mount point
mkdir -p /mnt/cold-storage

# Step 3: Test the mount
mount -t nfs 192.168.1.200:/tank/media /mnt/cold-storage

# Verify
df -h | grep cold-storage
ls -la /mnt/cold-storage

# Step 4: Make it permanent
nano /etc/fstab

# Add this line:
192.168.1.200:/tank/media /mnt/cold-storage nfs defaults,_netdev,vers=3 0 0

# _netdev: Wait for network before mounting
# vers=3: NFS version (or vers=4 for NFSv4)

# Step 5: Test fstab mount
umount /mnt/cold-storage
mount -a
df -h | grep cold-storage
```

**NFS export configuration on NAS:**

```bash
# TrueNAS/FreeNAS: GUI → Sharing → NFS
# Export: /tank/media
# Network: 192.168.1.0/24
# Mapall User: media (UID 1000)
# Mapall Group: media (GID 1000)

# Or manually in /etc/exports:
/tank/media 192.168.1.0/24(rw,all_squash,anonuid=1000,anongid=1000,no_subtree_check)

# Explanation:
# rw: Read-write access
# all_squash: Map all UIDs to anonymous UID
# anonuid=1000: Map to UID 1000 on NAS
# anongid=1000: Map to GID 1000 on NAS
# no_subtree_check: Improve performance, slight security trade-off
```

### How do you pass the storage to the LXC?

**Using Bind Mounts:**

A bind mount makes a host directory appear inside the container.

**Method 1: Manual configuration**

```bash
# Stop the container first
pct stop 102

# Add bind mount
pct set 102 -mp0 /mnt/cold-storage,mp=/mnt/cold-storage

# Restart container
pct start 102

# Verify inside container
pct enter 102
ls -la /mnt/cold-storage
df -h | grep cold-storage
exit
```

**What this command does:**
```
-mp0                          # Mount point 0 (can use mp0, mp1, mp2, etc.)
/mnt/cold-storage            # Path on Proxmox HOST
,mp=/mnt/cold-storage        # Path inside the CONTAINER
```

**In the container config file:**
```bash
# View config
cat /etc/pve/lxc/102.conf

# You'll see:
mp0: /mnt/cold-storage,mp=/mnt/cold-storage

# Full line might look like:
mp0: /mnt/cold-storage,mp=/mnt/cold-storage,shared=1
```

**Method 2: Using the helper script**

```bash
# Use our ct-add-storage script
ct-add-storage 102
pct reboot 102
```

**Add to multiple containers:**
```bash
# Add storage to all media-related containers
for ctid in 101 102 104 105 106; do
    echo "Adding storage to CT $ctid..."
    ct-add-storage $ctid
    pct reboot $ctid
done
```

### How do you fix Permission/UID issues?

**The Problem:**

LXC containers use UID/GID mapping. If the NAS has files owned by UID 1000, but the container maps UID 1000 to UID 101000, permission denied!

**Solution 1: Use `all_squash` on NFS export (Easiest)**

This is the recommended approach and what we use:

```bash
# On NAS /etc/exports:
/tank/media 192.168.1.0/24(rw,all_squash,anonuid=1000,anongid=1000)

# What this does:
# - All requests are mapped to UID/GID 1000 on the NAS
# - Doesn't matter what UID the container uses
# - Files appear as accessible to everyone in containers
```

**Verification:**
```bash
# Inside Sonarr container
pct enter 102
touch /mnt/cold-storage/test.txt
ls -l /mnt/cold-storage/test.txt
# Shows ownership, might appear as "nobody" but it's writable
rm /mnt/cold-storage/test.txt
exit
```

**Solution 2: UID/GID Mapping (Advanced)**

For unprivileged containers that need specific UIDs:

```bash
# Find the UID used by the app
pct enter 102
ps aux | grep sonarr
# Shows: sonarr user (UID might be 999 or 1000)

# On Proxmox host, edit container config
nano /etc/pve/lxc/102.conf

# Add UID mapping:
lxc.idmap: u 0 100000 999         # Map UIDs 0-998
lxc.idmap: g 0 100000 999         # Map GIDs 0-998
lxc.idmap: u 999 1000 1           # Map container UID 999 to host UID 1000
lxc.idmap: g 999 1000 1           # Map container GID 999 to host GID 1000
lxc.idmap: u 1000 101000 64536    # Map remaining UIDs
lxc.idmap: g 1000 101000 64536    # Map remaining GIDs

# Restart container
pct stop 102 && pct start 102
```

**Solution 3: Privileged container (Not recommended)**

```bash
# Convert to privileged (WARNING: Security implications)
# Only do this if other solutions fail
pct set 102 -unprivileged 0
pct reboot 102
```

**Best practice:** Start with `all_squash` on NFS. 99% of permission issues disappear.

---

## Phase 4: Hardware & Transcoding

See the dedicated [GPU Hardware Acceleration section](ARR_STACK_SETUP.md#-gpu-hardware-acceleration-jellyfin-transcoding) in the main setup guide for complete details.

### Summary: How do you handle Transcoding in an LXC?

**Key insight:** You don't need full PCI passthrough like a VM!

**LXC advantages:**
- **Device node passthrough** - Pass `/dev/dri/*` or `/dev/nvidia0` directly
- **No VFIO** required - No kernel modules, no IOMMU complexity
- **Shared GPU** - Multiple containers can use the same GPU
- **Simpler** - Just bind mount device nodes

### What drivers need to be installed on the Host?

**Install on Proxmox HOST, not in containers:**

**For Nvidia:**
```bash
apt install nvidia-driver firmware-misc-nonfree -y
reboot
nvidia-smi  # Verify
```

**For Intel QuickSync:**
```bash
apt install intel-media-va-driver-non-free -y
# No reboot needed
ls -l /dev/dri/renderD128  # Verify
```

### How do you pass the GPU to the Container?

**For Nvidia GPU:**
```bash
# Edit Jellyfin container config
nano /etc/pve/lxc/105.conf

# Add these lines:
lxc.cgroup2.devices.allow: c 195:* rwm
lxc.cgroup2.devices.allow: c 509:* rwm
lxc.mount.entry: /dev/nvidia0 dev/nvidia0 none bind,optional,create=file
lxc.mount.entry: /dev/nvidiactl dev/nvidiactl none bind,optional,create=file
lxc.mount.entry: /dev/nvidia-uvm dev/nvidia-uvm none bind,optional,create=file

# Restart
pct stop 105 && pct start 105
```

**For Intel QuickSync:**
```bash
nano /etc/pve/lxc/105.conf

# Add:
lxc.cgroup2.devices.allow: c 226:* rwm
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir

# Restart
pct stop 105 && pct start 105
```

### Why use a dedicated GPU vs. iGPU?

**Intel QuickSync (iGPU) - Recommended for most:**
- ✅ Built into CPU (no extra power, no PCIe slot)
- ✅ Excellent HEVC/H.265 support
- ✅ Low power consumption (~15W during transcode)
- ✅ Supports tone mapping for HDR
- ❌ Limited simultaneous streams (~10-15)

**Nvidia Dedicated GPU (e.g., NVS 510, P400, P2000):**
- ✅ More simultaneous transcodes (15-30+)
- ✅ Better for 4K content
- ✅ Professional cards are quiet
- ❌ Requires PCIe slot
- ❌ Extra power consumption (25-75W)
- ❌ Nvidia driver license may limit consumer cards to 2 streams (unlocked with kernel patch)

**Recommendation:**
- **Home use (1-5 users):** Intel QuickSync is perfect
- **Power users (10+ users, lots of 4K):** Nvidia P400 or P2000
- **Budget/existing hardware:** Use what you have!

---

## Phase 5: Networking & Access

### How do you access the services remotely?

**Option 1: VPN (Recommended) - Tailscale or WireGuard**

**Why VPN?**
- ✅ Secure, encrypted tunnel to home network
- ✅ Appears as if you're local (low latency)
- ✅ Access ALL services, not just web apps
- ✅ No port forwarding vulnerabilities

**Tailscale setup (Easiest):**
```bash
# On Proxmox host
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up

# On your phone/laptop
# Install Tailscale app
# Login with same account

# Access services via Tailscale IP:
http://100.64.x.x:8096  # Jellyfin
http://100.64.x.x:8989  # Sonarr
```

**WireGuard setup (More control):**
```bash
# Install WireGuard LXC
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/wireguard.sh)"

# Configure peers for your devices
# Access home network from anywhere
```

**Option 2: Reverse Proxy with SSL**

For exposing specific services externally:

```bash
# Install Nginx Proxy Manager LXC
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/nginx-proxy-manager.sh)"

# Configure:
# 1. Point domain to your IP (CloudFlare DNS)
# 2. Add proxy hosts in NPM
# 3. Get free SSL certificates (Let's Encrypt)
# 4. Access: https://jellyfin.yourdomain.com
```

**Option 3: Cloudflare Tunnel**

Good for web UIs, **but:**

### Why not use Cloudflare Tunnels for video?

**Cloudflare Terms of Service explicitly prohibit:**

From Cloudflare ToS Section 2.8:
> "Use of the Services for serving video or a disproportionate percentage of pictures, audio files, or other non-HTML content is prohibited"

**Translation:** Streaming video through Cloudflare tunnels for media servers violates ToS.

**What can happen:**
- Account suspension
- Service termination
- Potential legal issues

**Safe uses of Cloudflare Tunnel:**
- Overseerr/Jellyseerr (request UI)
- Sonarr/Radarr web interfaces
- Proxmox web UI
- Any HTML/CSS/JS content

**Not safe:**
- Jellyfin/Plex streaming
- Direct video playback
- Large media downloads

**Recommendation:** Use Tailscale/WireGuard for media streaming, Cloudflare Tunnel for management UIs.

### How do you handle DNS/Ad-blocking?

**Pi-hole in LXC:**

```bash
# Install Pi-hole
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/pi-hole.sh)"

# Configure:
# 1. Set as DNS server on router (192.168.1.x)
# 2. Or per-device DNS
# 3. Add custom DNS records for services:
#    jellyfin.local → 192.168.1.105
#    sonarr.local → 192.168.1.102
```

**Benefits:**
- Network-wide ad blocking
- Custom local DNS (pretty URLs)
- DNS-level tracker blocking
- Query logging and statistics

---

## Phase 6: The Application Stack (The Arrs)

### Which specific applications are included?

**Core Stack:**

| Application | Purpose | Port | Default Login |
|-------------|---------|------|---------------|
| **Prowlarr** | Indexer management | 9696 | Set on first run |
| **Sonarr** | TV show automation | 8989 | Set on first run |
| **Radarr** | Movie automation | 7878 | Set on first run |
| **qBittorrent** | Torrent download client | 8080 | admin / adminadmin |
| **Jellyfin** | Media server | 8096 | Set on first run |
| **Jellyseerr** | Request management | 5055 | Sign in with Jellyfin |

**Optional Services:**

| Application | Purpose | Port |
|-------------|---------|------|
| **Whisparr** | Adult content automation | 6969 |
| **Lidarr** | Music automation | 8686 |
| **Readarr** | eBook automation | 8787 |
| **Bazarr** | Subtitle automation | 6767 |
| **Tdarr** | Transcoding/optimization | 8265 |
| **Notifiarr** | Unified notifications | 5454 |
| **Huntarr** | Auto-add trending content | 7879 |
| **Configarr** | Auto-configuration via TRaSH Guides | 5055 |

### How does Prowlarr fit in?

**Prowlarr is the central indexer manager:**

**Without Prowlarr:**
```
You add indexers manually to:
├── Sonarr (10 indexers)
├── Radarr (10 indexers)
├── Lidarr (10 indexers)
└── Readarr (10 indexers)
Total: 40 manual configurations
```

**With Prowlarr:**
```
You add indexers once to Prowlarr (10 indexers)
                ↓
Prowlarr syncs automatically to:
├── Sonarr
├── Radarr
├── Lidarr
└── Readarr
Total: 10 configurations, synced to all
```

**Setup flow:**
1. **Add indexers to Prowlarr:** TorrentLeech, NZBGeek, etc.
2. **Connect apps to Prowlarr:** Add Sonarr, Radarr as "Applications"
3. **Automatic sync:** Indexers appear in all apps
4. **Updates propagate:** Change an indexer in Prowlarr, it updates everywhere

**Why this is huge:**
- Change API key once, updates all apps
- Add new indexer, instantly available in all apps
- Test indexers centrally
- Unified search across all indexers

### How do you handle "Requests"?

**Jellyseerr (or Overseerr for Plex):**

**The problem it solves:**
- Users want to request content
- Don't want to give them access to Sonarr/Radarr (too much power!)
- Need to track what's requested vs. available

**Jellyseerr features:**
- **User-friendly interface** - Clean, simple request system
- **Jellyfin integration** - Sign in with Jellyfin account
- **Permission system** - Set quotas, approve/deny requests
- **Notifications** - Discord, Telegram, email on request status
- **Discover content** - Trending, popular, top-rated

**Setup:**
```bash
# 1. Install Jellyseerr
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/jellyseerr.sh)"

# 2. Connect to Jellyfin (sign in with admin account)
# 3. Add Sonarr server (Settings → Services)
# 4. Add Radarr server
# 5. Configure user permissions
# 6. Share Jellyseerr URL with family: http://your-ip:5055
```

**User workflow:**
1. User browses Jellyseerr, finds a movie
2. Clicks "Request"
3. Jellyseerr sends request to Radarr
4. Radarr searches, downloads, organizes
5. Jellyfin picks it up
6. User gets notification: "Your request is available!"

---

## Phase 7: Maintenance & Backups

### How do you back up the stack?

**Proxmox built-in backup (vzdump):**

**Manual backup:**
```bash
# Backup single container
vzdump 102 --storage local --compress zstd --mode snapshot

# Backup multiple containers
vzdump 101 102 104 105 106 --storage local --compress zstd
```

**Automated backup via Proxmox UI:**
```
1. Datacenter → Backup
2. Add → VZDump backup job
3. Select containers (101, 102, 104, 105, 106)
4. Schedule: Daily at 2:00 AM
5. Retention: Keep last 7 backups
6. Mode: Snapshot (fastest, no downtime)
7. Compression: ZSTD (best balance)
8. Storage: local or NFS share
```

**Backup modes:**

| Mode | Downtime | Speed | Use Case |
|------|----------|-------|----------|
| **Snapshot** | None | Fast | Preferred for LXC |
| **Suspend** | Brief pause | Fast | If snapshot fails |
| **Stop** | Full stop | Fastest | Maintenance windows |

**Backup structure:**
```
/var/lib/vz/dump/
├── vzdump-lxc-101-2026_02_08-02_00_00.tar.zst
├── vzdump-lxc-102-2026_02_08-02_00_00.tar.zst
├── vzdump-lxc-104-2026_02_08-02_00_00.tar.zst
└── ...
```

**Off-site backup:**
```bash
# Sync backups to remote NAS
rsync -avz --delete /var/lib/vz/dump/ user@backup-nas:/backups/proxmox/
```

**Config-only backups (faster):**
```bash
# Backup just config directories (much smaller)
for ctid in 101 102 104 105 106; do
    pct exec $ctid tar czf /tmp/config-backup.tar.gz /config 2>/dev/null
    pct pull $ctid /tmp/config-backup.tar.gz /root/backups/ct${ctid}-config-$(date +%F).tar.gz
done
```

### What happens if an update breaks an app?

**Rollback process:**

**Scenario:** Sonarr v4.0 update breaks your setup.

**Step 1: Stop the broken container**
```bash
pct stop 102
```

**Step 2: List available backups**
```bash
ls -lh /var/lib/vz/dump/ | grep 102
# Shows:
# vzdump-lxc-102-2026_02_07-02_00_00.tar.zst (yesterday, working)
# vzdump-lxc-102-2026_02_08-02_00_00.tar.zst (today, broken)
```

**Step 3: Restore from yesterday's backup**
```bash
# Method 1: Restore in place (overwrites current container)
pct restore 102 /var/lib/vz/dump/vzdump-lxc-102-2026_02_07-02_00_00.tar.zst --force

# Method 2: Restore to new CTID (keeps broken one for comparison)
pct restore 112 /var/lib/vz/dump/vzdump-lxc-102-2026_02_07-02_00_00.tar.zst
# Test CT 112, if working, delete 102 and rename 112 → 102
```

**Step 4: Verify and start**
```bash
pct start 102
# Access web UI and verify everything works
```

**Entire process: < 5 minutes!**

**Preventing update issues:**

1. **Enable test updates first:**
   - In Sonarr: Settings → General → Branch → "develop"
   - Test in a cloned container before updating production

2. **Snapshot before updates:**
   ```bash
   # Quick snapshot before major update
   vzdump 102 --mode snapshot --storage local
   # Update Sonarr
   # If breaks, restore in seconds
   ```

3. **Staged rollouts:**
   - Update Prowlarr first (least critical)
   - Wait 24 hours
   - Update Sonarr/Radarr next
   - Wait 24 hours
   - Update Jellyfin last (most critical)

4. **Monitor logs:**
   ```bash
   pct enter 102
   journalctl -u sonarr -f
   # Watch for errors during update
   ```

**The LXC advantage:**
- Each service backs up independently (~500MB-2GB each)
- Restore just what broke
- Other services keep running
- Faster than restoring entire Docker VM

---

## 🎯 Architecture Summary

**Why this approach works:**

1. **Efficiency:** LXC overhead is minimal (~100MB RAM per container)
2. **Isolation:** Each service is independent, failures don't cascade
3. **Maintainability:** Update, backup, restore services individually
4. **Scalability:** Add new services without affecting existing ones
5. **Native:** Uses Proxmox's native CT technology, not Docker layers
6. **Flexibility:** GPU sharing, storage bind mounts, granular resource control

**Trade-offs:**

❌ **More initial setup** than docker-compose (but Community-Scripts help!)
❌ **More containers to manage** (but Proxmox UI makes this easy)
❌ **Learning curve** for LXC vs Docker concepts

✅ **Lower resource usage** than VMs
✅ **Better isolation** than docker-in-VM
✅ **Easier to debug** per-service issues
✅ **Professional-grade** architecture

---

## 🔗 See Also

- **[ARR_STACK_SETUP.md](ARR_STACK_SETUP.md)** - Step-by-step installation guide
- **[README.md](README.md)** - Quick start and "Big 3" questions
- **[example-configs/](example-configs/)** - Configuration examples and checklists

**Questions?** Open an issue on [GitHub](https://github.com/AmmarTee/ArrSuite-Guide/issues)!
