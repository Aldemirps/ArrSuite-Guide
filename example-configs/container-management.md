# Container Management Commands

Quick reference for managing your Arr Stack containers in Proxmox.

## 📋 Container Information

### List All Containers
```bash
pct list
```

### Get Detailed Container Info
```bash
pct config <CTID>
```

### Find Container IP Address
```bash
# Method 1: From host
pct exec <CTID> -- ip addr show | grep inet

# Method 2: Using pct list with awk
pct list | awk '{print $1, $3}'

# Method 3: Enter container and check
pct enter <CTID>
hostname -I
exit
```

## 🔄 Container Control

### Start Container
```bash
pct start <CTID>
```

### Stop Container (graceful)
```bash
pct stop <CTID>
```

### Force Stop Container
```bash
pct stop <CTID> --force
```

### Restart Container
```bash
pct reboot <CTID>
```

### Check Container Status
```bash
pct status <CTID>
```

## 🖥️ Accessing Containers

### Enter Container Shell
```bash
pct enter <CTID>
```

### Execute Single Command
```bash
pct exec <CTID> -- <command>

# Examples:
pct exec 106 -- ls -la /mnt/cold-storage
pct exec 102 -- journalctl -u sonarr -n 50
pct exec 104 -- systemctl status prowlarr
```

### Push File to Container
```bash
pct push <CTID> <local-file> <container-path>

# Example:
pct push 106 /root/custom-config.conf /config/custom-config.conf
```

### Pull File from Container
```bash
pct pull <CTID> <container-path> <local-file>

# Example:
pct pull 102 /config/config.xml /root/backup/sonarr-config.xml
```

## 💾 Storage Management

### Add Mount Point
```bash
pct set <CTID> -mp0 /mnt/cold-storage,mp=/mnt/cold-storage
```

### Remove Mount Point
```bash
pct set <CTID> --delete mp0
```

### Check Container Storage Usage
```bash
pct exec <CTID> -- df -h
```

## ⚙️ Resource Configuration

### Set CPU Cores
```bash
pct set <CTID> -cores 2
```

### Set Memory (MB)
```bash
pct set <CTID> -memory 2048
```

### Set Swap (MB)
```bash
pct set <CTID> -swap 512
```

### View Current Resources
```bash
pct config <CTID> | grep -E "cores|memory|swap"
```

## 🔧 Service Management (Inside Container)

### Check Service Status
```bash
pct enter <CTID>
systemctl status <service-name>

# Examples:
systemctl status sonarr
systemctl status radarr
systemctl status prowlarr
systemctl status qbittorrent
```

### Restart Service
```bash
pct enter <CTID>
systemctl restart <service-name>
```

### View Service Logs
```bash
pct enter <CTID>
journalctl -u <service-name> -f

# Show last 100 lines:
journalctl -u <service-name> -n 100
```

### Enable Service on Boot
```bash
pct enter <CTID>
systemctl enable <service-name>
```

## 🔍 Troubleshooting Commands

### Check Container Logs
```bash
pct enter <CTID>
journalctl -xe
```

### Monitor Container Resources
```bash
# From host
pct exec <CTID> -- top -b -n 1

# Or enter and monitor
pct enter <CTID>
htop
```

### Test Network Connectivity
```bash
pct exec <CTID> -- ping -c 4 8.8.8.8
pct exec <CTID> -- curl -I https://google.com
```

### Check Storage Mounts
```bash
pct exec <CTID> -- mount | grep cold-storage
pct exec <CTID> -- ls -la /mnt/cold-storage
```

## 📦 Backup & Restore

### Backup Container
```bash
vzdump <CTID> --storage local --compress zstd --mode snapshot

# Specify backup location
vzdump <CTID> --storage local --dumpdir /var/lib/vz/dump
```

### Restore Container
```bash
pct restore <NEW-CTID> /var/lib/vz/dump/vzdump-lxc-<CTID>-*.tar.zst
```

### Backup Config Files Only
```bash
# From host
pct exec <CTID> tar czf - /config > /root/backups/ct<CTID>-config-$(date +%F).tar.gz

# Or enter container
pct enter <CTID>
tar czf /tmp/config-backup.tar.gz /config
exit
pct pull <CTID> /tmp/config-backup.tar.gz /root/backups/
```

## 🔄 Bulk Operations

### Start All Containers
```bash
for ctid in $(pct list | awk 'NR>1 {print $1}'); do
    pct start $ctid
    echo "Started CT $ctid"
done
```

### Stop All Containers
```bash
for ctid in $(pct list | awk 'NR>1 {print $1}'); do
    pct stop $ctid
    echo "Stopped CT $ctid"
done
```

### Restart Specific Services
```bash
# Restart all *arr services
for ctid in 101 102 104; do
    echo "Restarting services in CT $ctid..."
    pct enter $ctid -c "systemctl restart *arr"
done
```

### Update All Containers
```bash
for ctid in $(pct list | awk 'NR>1 {print $1}'); do
    echo "Updating CT $ctid..."
    pct exec $ctid -- bash -c "apt update && apt upgrade -y"
done
```

## 🗑️ Container Removal

### Stop and Destroy Container
```bash
pct stop <CTID>
pct destroy <CTID>

# Force destroy if needed
pct destroy <CTID> --force --purge
```

**Warning:** This permanently deletes the container!

## 🎯 Common Task Examples

### Check All Container IPs
```bash
echo "Container IPs:"
echo "=============="
pct list | awk 'NR>1 {print $1, $3}' | while read ctid name; do
    ip=$(pct exec $ctid -- hostname -I 2>/dev/null | awk '{print $1}')
    printf "%-4s %-20s %s\n" "$ctid" "$name" "$ip"
done
```

### Monitor All Container Resources
```bash
watch -n 2 'pct list | awk "NR>1 {print \$1}" | while read ctid; do
    echo "CT $ctid:"
    pct exec $ctid -- df -h / | grep -v Filesystem
    pct exec $ctid -- free -h | grep Mem
    echo ""
done'
```

### Find Which Container is Using Most Storage
```bash
for ctid in $(pct list | awk 'NR>1 {print $1}'); do
    usage=$(pct exec $ctid -- df / | awk 'NR==2 {print $3}')
    echo "CT $ctid: $usage KB"
done | sort -k3 -n -r
```

## 📝 Useful Aliases

Add these to `/root/.bashrc` for quick access:

```bash
# Container shortcuts
alias ctlist='pct list'
alias ctenter='pct enter'
alias ctstatus='pct status'
alias ctstart='pct start'
alias ctstop='pct stop'
alias ctreboot='pct reboot'

# Arr stack specific
alias sonarr-logs='pct exec 102 -- journalctl -u sonarr -f'
alias radarr-logs='pct exec 101 -- journalctl -u radarr -f'
alias prowlarr-logs='pct exec 104 -- journalctl -u prowlarr -f'
alias qbt-logs='pct exec 106 -- journalctl -u qbittorrent -f'

# Quick IP check
alias arr-ips='for ctid in 101 102 104 105 106; do echo -n "CT $ctid: "; pct exec $ctid -- hostname -I; done'

# Restart all arr services
alias arr-restart='for ctid in 101 102 104; do echo "Restarting CT $ctid"; pct reboot $ctid; done'
```

Then reload:
```bash
source ~/.bashrc
```

---

## 🎓 Pro Tips

1. **Always check container status** before troubleshooting: `pct status <CTID>`
2. **Use `pct exec` for quick commands** instead of entering the container
3. **Create backups before major changes**: `vzdump <CTID>`
4. **Monitor logs in real-time** with `-f` flag: `journalctl -u sonarr -f`
5. **Set up automatic backups** in Proxmox: Datacenter → Backup → Add job

---

**Need more help?** Check the main [ARR_STACK_SETUP.md](ARR_STACK_SETUP.md) guide!
