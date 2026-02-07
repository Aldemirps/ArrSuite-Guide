# Quick Setup Checklist for Arr Stack

Use this checklist to ensure you don't miss any steps during setup.

## Pre-Installation

- [ ] Proxmox VE installed and accessible
- [ ] SSH access to Proxmox host
- [ ] Network configured (containers will get IPs via DHCP)
- [ ] Storage available (NAS with NFS or local large disk)

## Storage Setup

- [ ] NFS client installed: `apt install nfs-common -y`
- [ ] Mount point created: `mkdir -p /mnt/cold-storage`
- [ ] NFS mounted and tested: `mount -t nfs <NAS-IP>:<PATH> /mnt/cold-storage`
- [ ] Added to `/etc/fstab` with `_netdev` option
- [ ] Folder structure created:
  - [ ] `/mnt/cold-storage/downloads/complete`
  - [ ] `/mnt/cold-storage/downloads/incomplete`
  - [ ] `/mnt/cold-storage/ready/movies`
  - [ ] `/mnt/cold-storage/ready/tv`
  - [ ] `/mnt/cold-storage/ready/adult` (optional)
- [ ] Permissions set: `chmod -R 777 /mnt/cold-storage`
- [ ] ct-add-storage script installed and executable

## Container Installation

- [ ] Prowlarr installed (note CTID: ____)
- [ ] qBittorrent installed (note CTID: ____)
  - [ ] Storage added: `ct-add-storage <CTID>`
  - [ ] Container rebooted
- [ ] Sonarr installed (note CTID: ____)
  - [ ] Storage added: `ct-add-storage <CTID>`
  - [ ] Container rebooted
- [ ] Radarr installed (note CTID: ____)
  - [ ] Storage added: `ct-add-storage <CTID>`
  - [ ] Container rebooted
- [ ] Jellyfin installed (note CTID: ____)
  - [ ] Storage added: `ct-add-storage <CTID>`
  - [ ] Container rebooted
- [ ] Jellyseerr installed (note CTID: ____)

## Get Container IPs

Run `pct list` and note IPs:

```
Prowlarr IP:     192.168.1.___
qBittorrent IP:  192.168.1.___
Sonarr IP:       192.168.1.___
Radarr IP:       192.168.1.___
Jellyfin IP:     192.168.1.___
Jellyseerr IP:   192.168.1.___
```

## Prowlarr Configuration

- [ ] Accessed web UI: `http://<IP>:9696`
- [ ] Noted API key from Settings → General
- [ ] Added 3-5 indexers
- [ ] Tested indexers (click test button)

## qBittorrent Configuration

- [ ] Accessed web UI: `http://<IP>:8080`
- [ ] Changed default password (admin/adminadmin)
- [ ] Set download paths:
  - [ ] Default Save Path: `/mnt/cold-storage/downloads/complete`
  - [ ] Temp Path: `/mnt/cold-storage/downloads/incomplete`
  - [ ] Enabled "Keep incomplete torrents in"
- [ ] Created category `movies` → `/mnt/cold-storage/downloads/complete/movies`
- [ ] Created category `tv` → `/mnt/cold-storage/downloads/complete/tv`
- [ ] Noted username and password for *arr apps

## Sonarr Configuration

- [ ] Accessed web UI: `http://<IP>:8989`
- [ ] Noted API key from Settings → General
- [ ] Added root folder: `/mnt/cold-storage/ready/tv`
- [ ] Added download client (qBittorrent):
  - [ ] Host: `<qbittorrent-ip>`
  - [ ] Port: `8080`
  - [ ] Username: `admin`
  - [ ] Password: `<your-new-password>`
  - [ ] Category: `tv`
  - [ ] Tested successfully
- [ ] Verified indexers appeared (from Prowlarr)
- [ ] Configured Media Management:
  - [ ] Advanced Settings ON
  - [ ] Use hard links: ✓
  - [ ] Episode folder format configured

## Radarr Configuration

- [ ] Accessed web UI: `http://<IP>:7878`
- [ ] Noted API key from Settings → General
- [ ] Added root folder: `/mnt/cold-storage/ready/movies`
- [ ] Added download client (qBittorrent):
  - [ ] Host: `<qbittorrent-ip>`
  - [ ] Port: `8080`
  - [ ] Category: `movies`
  - [ ] Tested successfully
- [ ] Verified indexers appeared (from Prowlarr)
- [ ] Configured Media Management:
  - [ ] Advanced Settings ON
  - [ ] Use hard links: ✓
  - [ ] Movie folder format configured

## Prowlarr → *arr App Connection

- [ ] In Prowlarr: Settings → Apps → Add Sonarr
  - [ ] Prowlarr Server: `http://localhost:9696`
  - [ ] Sonarr Server: `http://<sonarr-ip>:8989`
  - [ ] API Key: `<sonarr-api-key>`
  - [ ] Tested successfully
- [ ] In Prowlarr: Settings → Apps → Add Radarr
  - [ ] Prowlarr Server: `http://localhost:9696`
  - [ ] Radarr Server: `http://<radarr-ip>:7878`
  - [ ] API Key: `<radarr-api-key>`
  - [ ] Tested successfully
- [ ] Synced indexers (should happen automatically)

## Jellyfin Configuration

- [ ] Accessed web UI: `http://<IP>:8096`
- [ ] Completed initial setup wizard
- [ ] Created admin account
- [ ] Added Movies library:
  - [ ] Content type: Movies
  - [ ] Display name: Movies
  - [ ] Folder: `/mnt/cold-storage/ready/movies`
- [ ] Added TV Shows library:
  - [ ] Content type: Shows
  - [ ] Display name: TV Shows
  - [ ] Folder: `/mnt/cold-storage/ready/tv`
- [ ] Scanned all libraries
- [ ] Tested playback from web browser

## Jellyseerr Configuration

- [ ] Accessed web UI: `http://<IP>:5055`
- [ ] Connected to Jellyfin:
  - [ ] Jellyfin URL: `http://<jellyfin-ip>:8096`
  - [ ] Signed in with Jellyfin admin account
- [ ] Added Sonarr server:
  - [ ] Hostname: `<sonarr-ip>`
  - [ ] Port: `8989`
  - [ ] API Key: `<sonarr-api-key>`
  - [ ] Root folder: `/mnt/cold-storage/ready/tv`
  - [ ] Quality profile: HD-1080p
  - [ ] Tested successfully
- [ ] Added Radarr server:
  - [ ] Hostname: `<radarr-ip>`
  - [ ] Port: `7878`
  - [ ] API Key: `<radarr-api-key>`
  - [ ] Root folder: `/mnt/cold-storage/ready/movies`
  - [ ] Quality profile: HD-1080p
  - [ ] Tested successfully

## End-to-End Testing

### Test TV Show Download

- [ ] In Sonarr: Added a single-episode show
- [ ] Clicked manual search, selected a release
- [ ] Verified appeared in qBittorrent with category `tv`
- [ ] Download completed
- [ ] Sonarr imported and renamed file
- [ ] File exists in `/mnt/cold-storage/ready/tv/<show-name>/`
- [ ] Show appears in Jellyfin after library scan

### Test Movie Download

- [ ] In Radarr: Added a short movie
- [ ] Clicked search
- [ ] Verified appeared in qBittorrent with category `movies`
- [ ] Download completed
- [ ] Radarr imported and renamed file
- [ ] File exists in `/mnt/cold-storage/ready/movies/<movie-name>/`
- [ ] Movie appears in Jellyfin after library scan

### Test User Request

- [ ] In Jellyseerr: Searched for a movie/show
- [ ] Requested it
- [ ] Verified appeared in Radarr/Sonarr
- [ ] Download started automatically
- [ ] Completed and appeared in Jellyfin

## Post-Setup Optimization

- [ ] Set static IPs for containers (optional but recommended)
- [ ] Configure Proxmox automatic backups
- [ ] Set up Notifiarr for notifications (optional)
- [ ] Review TRaSH Guides for quality profiles
- [ ] Configure custom formats (advanced)
- [ ] Set up VPN for qBittorrent (if desired)

## Troubleshooting If Things Don't Work

If a step fails, check:

1. [ ] All containers are running: `pct list`
2. [ ] Storage is mounted: `df -h | grep cold-storage`
3. [ ] Paths are accessible from containers:
   ```bash
   pct enter <CTID>
   ls -la /mnt/cold-storage/downloads
   ```
4. [ ] Paths match exactly across all services
5. [ ] API keys are correct
6. [ ] qBittorrent credentials are correct in *arr apps
7. [ ] Check logs in each service: System → Logs

---

✅ **Setup Complete!** Enjoy your automated media system!
