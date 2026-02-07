# Arr Stack Configuration Files

This directory contains helper scripts and configuration examples for setting up your Arr Stack on Proxmox VE.

## � The Big 3 Questions (From Reddit)

### 1️⃣ What Scripts Do You Use?

**[Community-Scripts (formerly tteck's scripts)]([https://github.com/community-scripts/ProxmoxVE](https://community-scripts.github.io/ProxmoxVE/))** - These create optimized LXC containers automatically.

Example installation:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/sonarr.sh)"
```

Each script creates a pre-configured container with the service already installed and running.

### 2️⃣ How Do You Share Storage with Containers?

**Using Bind Mounts** - This makes your Proxmox host storage appear inside containers.

**The specific command:**
```bash
pct set <CTID> -mp0 /mnt/cold-storage,mp=/mnt/cold-storage
```

**Real example from my setup:**
```bash
pct set 106 -mp0 /mnt/cold-storage,mp=/mnt/cold-storage
pct reboot 106
```

This mounts the host path `/mnt/cold-storage` into the container at the same path. All containers see the same files.

**Or use the helper script:**
```bash
ct-add-storage 106
```

### 3️⃣ How Do You Enable GPU for Jellyfin/Transcoding?

**Install Nvidia drivers on the Proxmox HOST first:**

```bash
# Check if you have an Nvidia GPU
lspci | grep -i nvidia

# Add non-free repositories
nano /etc/apt/sources.list
# Add "contrib non-free non-free-firmware" to each line

# Update and install drivers
apt update
apt install nvidia-driver firmware-misc-nonfree -y

# Reboot host
reboot

# Verify driver loaded
nvidia-smi
```

**Then pass GPU to container:**
```bash
# Find GPU device
ls -l /dev/dri/

# Add to container (example for container 105)
nano /etc/pve/lxc/105.conf

# Add these lines:
lxc.cgroup2.devices.allow: c 226:* rwm
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir

# Restart container
pct stop 105 && pct start 105

# Configure in Jellyfin: Dashboard → Playback → Hardware Acceleration → NVIDIA NVENC
```

---

## �📁 Files in This Repository

### Main Documentation
- **[ARR_STACK_SETUP.md](ARR_STACK_SETUP.md)** - Complete setup guide with step-by-step instructions- **[ARCHITECTURE.md](ARCHITECTURE.md)** - 🆕 Deep dive into design decisions, philosophy, and "why LXC over Docker"
### Helper Scripts
- **[ct-add-storage.sh](ct-add-storage.sh)** - Automatically share storage with containers
- **[nfs-setup.sh](nfs-setup.sh)** - Interactive NFS storage setup script

### Configuration Examples
- **[example-configs/sonarr-radarr-paths.md](example-configs/sonarr-radarr-paths.md)** - Path configuration reference
- **[example-configs/quick-setup-checklist.md](example-configs/quick-setup-checklist.md)** - Step-by-step checklist
- **[example-configs/container-management.md](example-configs/container-management.md)** - Container commands reference
- **[example-configs/quick-reference.md](example-configs/quick-reference.md)** - One-page cheat sheet (print this!)

## 🚀 Quick Start

1. **Read the main guide:** [ARR_STACK_SETUP.md](ARR_STACK_SETUP.md)

2. **Setup NFS storage:**
   ```bash
   wget https://raw.githubusercontent.com/AmmarTee/ArrSuite-Guide/main/nfs-setup.sh
   chmod +x nfs-setup.sh
   ./nfs-setup.sh
   ```

3. **Install ct-add-storage helper:**
   ```bash
   wget https://raw.githubusercontent.com/AmmarTee/ArrSuite-Guide/main/ct-add-storage.sh
   cp ct-add-storage.sh /usr/local/bin/ct-add-storage
   chmod +x /usr/local/bin/ct-add-storage
   ```

4. **Follow the checklist:** [quick-setup-checklist.md](example-configs/quick-setup-checklist.md)

## 📚 What You'll Learn

- **[Why LXC over Docker?](ARCHITECTURE.md#phase-1-project-overview--philosophy)** - Design philosophy and architecture decisions
- **[Storage setup explained](ARCHITECTURE.md#phase-3-the-hard-part---storage--permissions)** - The complete flow from NAS to containers
- How to set up NFS storage for Proxmox
- How to install and configure Prowlarr, Sonarr, Radarr, qBittorrent, Jellyfin, and Jellyseerr
- How to connect all services together
- How to troubleshoot common issues
- GPU hardware acceleration for transcoding
- Best practices for media automation
- Backup and rollback strategies

## 🎯 End Result

A fully automated media system where:
- Users request content via Jellyseerr
- Sonarr/Radarr automatically search and download
- qBittorrent handles downloads
- Content is automatically organized
- Jellyfin streams to any device

## 💡 Support

If you found this helpful:
- ⭐ Star the repository on [GitHub](https://github.com/AmmarTee/ArrSuite-Guide)
- 📢 Share with others
- 🐛 Open an issue for problems or improvements

## 📖 Additional Resources

- **[Proxmox Community Scripts](https://github.com/community-scripts/ProxmoxVE)** - The scripts used for all container installations (formerly tteck's scripts)
- [TRaSH Guides](https://trash-guides.info/) - Detailed configuration guides
- [Servarr Wiki](https://wiki.servarr.com/) - Official documentation
- [Jellyfin Hardware Acceleration](https://jellyfin.org/docs/general/administration/hardware-acceleration/) - GPU setup guide

---

**Disclaimer:** This setup is for educational purposes. Only download content you have the legal right to access.
