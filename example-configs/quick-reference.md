# Arr Stack Quick Reference Sheet

Print this page or keep it handy during setup!

## 📊 Default Ports

| Service | Port | URL |
|---------|------|-----|
| Prowlarr | 9696 | http://proxmox-ip:9696 |
| Sonarr | 8989 | http://proxmox-ip:8989 |
| Radarr | 7878 | http://proxmox-ip:7878 |
| Whisparr | 6969 | http://proxmox-ip:6969 |
| qBittorrent | 8080 | http://proxmox-ip:8080 |
| Jellyfin | 8096 | http://proxmox-ip:8096 |
| Jellyseerr | 5055 | http://proxmox-ip:5055 |
| Tdarr | 8265 | http://proxmox-ip:8265 |

**Default qBittorrent credentials:** `admin` / `adminadmin` (CHANGE IMMEDIATELY!)

---

## 📁 Standard Folder Paths

Use these exact paths in ALL services:

```
/mnt/cold-storage/downloads/complete/movies   ← qBittorrent category: movies
/mnt/cold-storage/downloads/complete/tv       ← qBittorrent category: tv
/mnt/cold-storage/downloads/incomplete        ← qBittorrent temp downloads
/mnt/cold-storage/ready/movies                ← Radarr root folder
/mnt/cold-storage/ready/tv                    ← Sonarr root folder  
/mnt/cold-storage/ready/adult                 ← Whisparr root folder
```

---

## 🚀 Installation One-Liner Commands

```bash
# 1. Prowlarr (Indexer Manager)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/prowlarr.sh)"

# 2. qBittorrent (Download Client)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/qbittorrent.sh)"

# 3. Sonarr (TV Shows)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/sonarr.sh)"

# 4. Radarr (Movies)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/radarr.sh)"

# 5. Jellyfin (Media Server)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/jellyfin.sh)"

# 6. Jellyseerr (Request System)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/jellyseerr.sh)"
```

---

## 🔧 Essential Commands

### Container Management
```bash
pct list                    # List all containers
pct status <CTID>          # Check if container is running
pct start <CTID>           # Start container
pct stop <CTID>            # Stop container
pct reboot <CTID>          # Restart container
pct enter <CTID>           # Enter container shell
```

### Add Storage to Container
```bash
ct-add-storage <CTID>
pct reboot <CTID>
```

### Check Container IP
```bash
pct exec <CTID> -- hostname -I
```

### View Logs
```bash
pct enter <CTID>
journalctl -u sonarr -f    # Replace 'sonarr' with service name
```

---

## 🔗 Connection Settings Quick Reference

### Prowlarr → Sonarr
```
Settings → Apps → Add Sonarr
Prowlarr Server: http://localhost:9696
Sonarr Server: http://<sonarr-ip>:8989
API Key: [from Sonarr Settings → General]
```

### Prowlarr → Radarr
```
Settings → Apps → Add Radarr
Radarr Server: http://<radarr-ip>:7878
API Key: [from Radarr Settings → General]
```

### Sonarr → qBittorrent
```
Settings → Download Clients → Add qBittorrent
Host: <qbittorrent-ip>
Port: 8080
Username: admin
Password: [your new password]
Category: tv
```

### Radarr → qBittorrent
```
Settings → Download Clients → Add qBittorrent
Host: <qbittorrent-ip>
Port: 8080
Category: movies
```

### Jellyseerr → Jellyfin
```
Jellyfin URL: http://<jellyfin-ip>:8096
Sign in with Jellyfin account
```

### Jellyseerr → Sonarr/Radarr
```
Settings → Services → Add Sonarr/Radarr
Hostname: <service-ip>
Port: 8989 (Sonarr) or 7878 (Radarr)
API Key: [from service]
Root Folder: /mnt/cold-storage/ready/tv (or movies)
```

---

## 🎯 Configuration Checklist

### qBittorrent
- [ ] Change password
- [ ] Default Save Path: `/mnt/cold-storage/downloads/complete`
- [ ] Temp Path: `/mnt/cold-storage/downloads/incomplete`
- [ ] Category `movies`: `/mnt/cold-storage/downloads/complete/movies`
- [ ] Category `tv`: `/mnt/cold-storage/downloads/complete/tv`

### Sonarr
- [ ] Root Folder: `/mnt/cold-storage/ready/tv`
- [ ] Download Client: qBittorrent (category: `tv`)
- [ ] Indexers synced from Prowlarr

### Radarr
- [ ] Root Folder: `/mnt/cold-storage/ready/movies`
- [ ] Download Client: qBittorrent (category: `movies`)
- [ ] Indexers synced from Prowlarr

### Jellyfin
- [ ] Movies Library: `/mnt/cold-storage/ready/movies`
- [ ] TV Shows Library: `/mnt/cold-storage/ready/tv`

---

## 🔍 Troubleshooting Quick Fixes

### Can't access web UI
```bash
pct status <CTID>          # Check if running
pct start <CTID>           # Start if stopped
curl http://localhost:PORT # Test from host
```

### Permission errors
```bash
chmod -R 777 /mnt/cold-storage    # Fix permissions
pct enter <CTID>
ls -la /mnt/cold-storage          # Verify from container
```

### Download not importing
- Check paths match EXACTLY in all apps
- Verify qBittorrent category is set correctly
- Check Activity → Queue in Sonarr/Radarr for errors

### NFS not mounting
```bash
mount | grep cold-storage         # Check if mounted
mount -a                          # Mount from fstab
# Add _netdev to fstab if boots before NFS ready
```

---

## 📊 Typical Container IDs (adjust for your setup)

| CTID | Service | IP | Status |
|------|---------|----|----|
| 101  | Radarr     | ___.___.___.___  | [ ] |
| 102  | Sonarr     | ___.___.___.___  | [ ] |
| 104  | Prowlarr   | ___.___.___.___  | [ ] |
| 105  | Jellyfin   | ___.___.___.___  | [ ] |
| 106  | qBittorrent| ___.___.___.___  | [ ] |
| 103  | Jellyseerr | ___.___.___.___  | [ ] |

---

## 🔑 API Keys Reference

Write down your API keys here:

| Service | API Key | Location |
|---------|---------|----------|
| Prowlarr  | _____________________ | Settings → General |
| Sonarr    | _____________________ | Settings → General |
| Radarr    | _____________________ | Settings → General |
| Jellyseerr| _____________________ | Settings → General |

---

## 📞 Support Resources

- **TRaSH Guides:** https://trash-guides.info/
- **Servarr Wiki:** https://wiki.servarr.com/
- **Reddit r/sonarr:** https://reddit.com/r/sonarr
- **Reddit r/radarr:** https://reddit.com/r/radarr
- **Discord:** https://discord.gg/servarr

---

## 📝 Notes Section

Use this space for your custom settings:

```
My NFS Server IP: ___________________
My Proxmox Host IP: _________________
My Network Gateway: _________________

Custom paths or notes:








```

---

**Print this page and keep it next to your keyboard during setup!**
