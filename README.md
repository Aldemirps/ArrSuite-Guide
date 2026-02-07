# Arr Stack Configuration Files

This directory contains helper scripts and configuration examples for setting up your Arr Stack on Proxmox VE.

## 📁 Files in This Repository

### Main Documentation
- **[ARR_STACK_SETUP.md](ARR_STACK_SETUP.md)** - Complete setup guide with step-by-step instructions

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

- How to set up NFS storage for Proxmox
- How to install and configure Prowlarr, Sonarr, Radarr, qBittorrent, Jellyfin, and Jellyseerr
- How to connect all services together
- How to troubleshoot common issues
- Best practices for media automation

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

- [TRaSH Guides](https://trash-guides.info/) - Detailed configuration guides
- [Servarr Wiki](https://wiki.servarr.com/) - Official documentation
- [Proxmox Community Scripts](https://github.com/community-scripts/ProxmoxVE) - Container installation scripts

---

**Disclaimer:** This setup is for educational purposes. Only download content you have the legal right to access.
