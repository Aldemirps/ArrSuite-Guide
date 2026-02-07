# Example Path Configuration for Arr Stack

This document shows the exact paths to use in each service to ensure everything works together seamlessly.

## 🗂️ Folder Structure

```
/mnt/cold-storage/
├── downloads/
│   ├── complete/       ← qBittorrent saves completed downloads here
│   │   ├── movies/     ← Movie category in qBittorrent
│   │   └── tv/         ← TV category in qBittorrent
│   └── incomplete/     ← qBittorrent works on downloads here
├── ready/              ← Final organized media location
│   ├── movies/         ← Radarr moves movies here
│   ├── tv/             ← Sonarr moves TV shows here
│   └── adult/          ← Whisparr moves adult content here
└── torrents/           ← .torrent files and metadata
```

## 📺 Sonarr Configuration

### Root Folder
```
Path: /mnt/cold-storage/ready/tv
```
This is where Sonarr will move completed and renamed TV shows.

### Download Client (qBittorrent)
```
Host: <qbittorrent-container-ip>
Port: 8080
Category: tv
```

**Important:** The category `tv` must match exactly with the category created in qBittorrent.

### Expected Behavior
1. Sonarr sends download to qBittorrent with category `tv`
2. qBittorrent saves to: `/mnt/cold-storage/downloads/complete/tv/`
3. Sonarr detects completion
4. Sonarr moves and renames to: `/mnt/cold-storage/ready/tv/Show Name (Year)/Season 01/`

## 🎬 Radarr Configuration

### Root Folder
```
Path: /mnt/cold-storage/ready/movies
```

### Download Client (qBittorrent)
```
Host: <qbittorrent-container-ip>
Port: 8080
Category: movies
```

### Expected Behavior
1. Radarr sends download to qBittorrent with category `movies`
2. qBittorrent saves to: `/mnt/cold-storage/downloads/complete/movies/`
3. Radarr detects completion
4. Radarr moves and renames to: `/mnt/cold-storage/ready/movies/Movie Name (Year)/Movie Name (Year).mkv`

## ⬇️ qBittorrent Configuration

### Default Save Path
```
Tools → Options → Downloads
Default Save Path: /mnt/cold-storage/downloads/complete
```

### Incomplete Downloads
```
Keep incomplete torrents in: /mnt/cold-storage/downloads/incomplete
☑ Append .!qB extension to incomplete files
```

### Categories

**Movies Category:**
```
Name: movies
Save Path: /mnt/cold-storage/downloads/complete/movies
```

**TV Category:**
```
Name: tv
Save Path: /mnt/cold-storage/downloads/complete/tv
```

## 📺 Jellyfin Configuration

### Movie Library
```
Content Type: Movies
Display Name: Movies
Folder: /mnt/cold-storage/ready/movies
```

### TV Show Library
```
Content Type: Shows
Display Name: TV Shows
Folder: /mnt/cold-storage/ready/tv
```

## 🔗 Path Mapping (Usually NOT Needed)

**When paths match exactly across all containers, you DON'T need remote path mapping.**

If you do need it (rare cases where containers see different paths):

In Sonarr/Radarr → Settings → Download Clients → Advanced Settings:
```
Remote Path Mapping:
  Host: <qbittorrent-ip>
  Remote Path: /downloads/complete/
  Local Path: /mnt/cold-storage/downloads/complete/
```

But again, **if you followed this guide, you don't need this!**

## ✅ Verification Checklist

Run these commands inside each container to verify paths exist:

```bash
# In qBittorrent container (pct enter 106)
ls -la /mnt/cold-storage/downloads/

# In Sonarr container (pct enter 102)
ls -la /mnt/cold-storage/downloads/
ls -la /mnt/cold-storage/ready/tv/

# In Radarr container (pct enter 101)
ls -la /mnt/cold-storage/downloads/
ls -la /mnt/cold-storage/ready/movies/

# In Jellyfin container (pct enter 105)
ls -la /mnt/cold-storage/ready/movies/
ls -la /mnt/cold-storage/ready/tv/
```

All commands should show the same folders. If you get "Permission denied" or "No such file or directory", your storage mounts aren't configured correctly.

## 🎯 Quick Test

To test the complete flow:

1. **In Sonarr:** Add a single episode show
2. **Watch qBittorrent:** Download should start in category `tv`
3. **Check path in qBittorrent:** Right-click torrent → Show in folder → Should be `/mnt/cold-storage/downloads/complete/tv/`
4. **Wait for completion**
5. **Check Sonarr:** Activity → Queue → Should show "Importing"
6. **Check final location:** `/mnt/cold-storage/ready/tv/Show Name/Season 01/`
7. **Check Jellyfin:** Scan library → Show should appear

If any step fails, check your paths!
