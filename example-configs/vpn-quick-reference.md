# VPN Split Tunnel Quick Reference

## 📋 Quick Setup (TL;DR)

```bash
# 1. Make script executable
chmod +x vpn-setup.sh

# 2. Run setup script
./vpn-setup.sh

# 3. Follow prompts and provide:
#    - Surfshark WireGuard config file
#    - VPN container IP address
#    - Service container IDs to route through VPN
```

---

## 🚀 Common Commands

### Check VPN Status
```bash
# Check if VPN is running
pct exec 200 -- wg show

# Check public IP (should show VPN IP)
pct exec 200 -- curl ifconfig.me

# Quick status command
vpn-status
```

### Restart VPN
```bash
# Restart WireGuard
pct exec 200 -- rc-service wg-quick restart

# Or manually
pct exec 200 -- wg-quick down wg0
pct exec 200 -- wg-quick up wg0
```

### Check Service Routing
```bash
# Check if Whisparr uses VPN (replace 106 with your CT ID)
pct exec 106 -- curl ifconfig.me

# Should match VPN IP, not your real IP
```

### View Logs
```bash
# VPN watchdog logs
pct exec 200 -- tail -f /var/log/vpn-watchdog.log

# System logs
pct exec 200 -- tail -f /var/log/messages
```

---

## 🔧 Management Tasks

### Add Another Service to VPN
```bash
# Get service container ID
pct list | grep whisparr  # Example

# Route through VPN (replace IPs and CT IDs)
pct exec 106 -- ip route del default
pct exec 106 -- ip route add default via 192.168.1.200

# Test
pct exec 106 -- curl ifconfig.me
```

### Remove Service from VPN
```bash
# Restore normal routing (replace with your gateway)
pct exec 106 -- ip route del default
pct exec 106 -- ip route add default via 192.168.1.1

# Test
pct exec 106 -- curl ifconfig.me  # Should show real IP
```

### Change VPN Server Location
```bash
# 1. Login to Surfshark and download new config for different location
# 2. Upload new config
pct push 200 /path/to/new-config.conf /etc/wireguard/wg0.conf

# 3. Restart VPN
pct exec 200 -- wg-quick down wg0
pct exec 200 -- wg-quick up wg0

# 4. Verify new IP
pct exec 200 -- curl ifconfig.me
```

---

## 🧪 Testing & Verification

### Test VPN Works
```bash
# 1. Check WireGuard interface is up
pct exec 200 -- wg show wg0

# 2. Check IP (should be VPN server IP)
pct exec 200 -- curl ifconfig.me

# 3. Test DNS
pct exec 200 -- nslookup google.com

# 4. Test connectivity
pct exec 200 -- ping -c 3 1.1.1.1
```

### Test Service Routing
```bash
# In Whisparr container (example)
WHISPARR_CT=106

# Should show VPN IP
pct exec $WHISPARR_CT -- curl ifconfig.me

# Test ThePornDB access
pct exec $WHISPARR_CT -- curl -I https://theporndb.net

# Check routes
pct exec $WHISPARR_CT -- ip route show
```

### Test Other Services NOT Affected
```bash
# Check Sonarr (example) - should show real IP
pct exec 103 -- curl ifconfig.me

# Check Cloudflared status
pct exec CLOUDFLARED_CT -- systemctl status cloudflared
```

---

## ⚠️ Troubleshooting

### VPN Won't Connect
```bash
# Check config file
pct exec 200 -- cat /etc/wireguard/wg0.conf

# Check WireGuard kernel module
pct exec 200 -- modprobe wireguard

# Check firewall
pct exec 200 -- iptables -L -n -v

# Restart everything
pct reboot 200
```

### Service Can't Reach Internet
```bash
# Check if VPN container is reachable
pct exec SERVICE_CT -- ping -c 3 VPN_IP

# Check routes
pct exec SERVICE_CT -- ip route show

# Check if VPN has internet
pct exec 200 -- ping -c 3 1.1.1.1

# Check NAT rules in VPN container
pct exec 200 -- iptables -t nat -L -n -v
```

### DNS Not Working
```bash
# Set DNS manually in service container
pct exec SERVICE_CT -- sh -c 'echo "nameserver 1.1.1.1" > /etc/resolv.conf'

# Or use Surfshark DNS
pct exec SERVICE_CT -- sh -c 'echo "nameserver 162.252.172.57" > /etc/resolv.conf'

# Make it permanent
pct exec SERVICE_CT -- chattr +i /etc/resolv.conf
```

### VPN Disconnects Randomly
```bash
# Check watchdog is running
pct exec 200 -- crontab -l

# View watchdog logs
pct exec 200 -- tail -100 /var/log/vpn-watchdog.log

# Manually run watchdog
pct exec 200 -- /usr/local/bin/vpn-watchdog.sh

# Check for network issues
pct exec 200 -- ping -c 10 SURFSHARK_SERVER_IP
```

### Cloudflared Stopped Working
```bash
# This shouldn't happen, but if it does:

# 1. Check Cloudflared container routes
pct exec CF_CT -- ip route show

# 2. Make sure it's NOT routed through VPN
# It should use normal gateway, not VPN IP

# 3. Fix routing if needed
pct exec CF_CT -- ip route del default via VPN_IP
pct exec CF_CT -- ip route add default via NORMAL_GATEWAY

# 4. Restart Cloudflared
pct exec CF_CT -- systemctl restart cloudflared
```

---

## 📊 Monitoring

### Create Monitoring Script
```bash
cat > /usr/local/bin/vpn-monitor << 'EOF'
#!/bin/bash

echo "=== VPN Health Check ==="
echo "Time: $(date)"
echo ""

# VPN Container Status
echo "VPN Container: $(pct status 200)"

# WireGuard Status
echo "WireGuard:"
pct exec 200 -- wg show | head -n 3

# Public IP
VPN_IP=$(pct exec 200 -- curl -s ifconfig.me)
echo "VPN Public IP: $VPN_IP"

# Services Check
echo ""
echo "Services Routing:"
for CT in 106; do  # Add your service CT IDs here
    SERVICE_IP=$(pct exec $CT -- curl -s ifconfig.me 2>/dev/null || echo "Error")
    if [ "$SERVICE_IP" = "$VPN_IP" ]; then
        echo "  CT $CT: ✓ Using VPN ($SERVICE_IP)"
    else
        echo "  CT $CT: ✗ NOT using VPN ($SERVICE_IP)"
    fi
done

echo ""
echo "Last 5 VPN events:"
pct exec 200 -- tail -5 /var/log/vpn-watchdog.log
EOF

chmod +x /usr/local/bin/vpn-monitor

# Add to cron for alerts
# crontab -e
# 0 */6 * * * /usr/local/bin/vpn-monitor >> /var/log/vpn-monitor.log
```

---

## 🔐 Security Checks

### Verify No DNS Leaks
```bash
# From service container
pct exec 106 -- curl https://dnsleaktest.com/

# Or use command line
pct exec 106 -- dig +short myip.opendns.com @resolver1.opendns.com
# Should show VPN IP
```

### Verify Kill Switch Works
```bash
# Stop VPN
pct exec 200 -- wg-quick down wg0

# Try to access internet from service
pct exec 106 -- curl ifconfig.me
# Should FAIL or timeout

# Restart VPN
pct exec 200 -- wg-quick up wg0
```

### Check for IP Leaks
```bash
# Should only show VPN IP, not real IP
pct exec 106 -- curl https://ipinfo.io
pct exec 106 -- curl https://api.ipify.org
pct exec 106 -- curl https://icanhazip.com
```

---

## 🔄 Maintenance

### Update WireGuard
```bash
pct exec 200 -- apk update
pct exec 200 -- apk upgrade wireguard-tools
pct reboot 200
```

### Backup Configuration
```bash
# Backup WireGuard config
pct pull 200 /etc/wireguard/wg0.conf ./wg0-backup.conf

# Backup entire VPN container
vzdump 200 --storage local --compress gzip
```

### Restore Configuration
```bash
# Restore WireGuard config
pct push 200 ./wg0-backup.conf /etc/wireguard/wg0.conf
pct exec 200 -- chmod 600 /etc/wireguard/wg0.conf
pct exec 200 -- wg-quick down wg0
pct exec 200 -- wg-quick up wg0
```

---

## 📱 Whisparr-Specific Configuration

### Configure Whisparr for VPN Use

1. **Web UI Access** (Whisparr should still be accessible on LAN)
   - Access: `http://WHISPARR_IP:9708`
   - This works because VPN only affects outbound traffic

2. **Indexers Configuration**
   ```
   Settings → Indexers → Add
   - ThePornDB should now work
   - Test connection after adding
   ```

3. **Proxy Settings** (if Method C used)
   ```
   Settings → General → Proxy
   - Type: SOCKS5
   - Hostname: VPN_IP (e.g., 192.168.1.200)
   - Port: 1080
   ```

4. **Test Connection**
   ```bash
   # From Proxmox host
   pct exec 106 -- curl ifconfig.me
   # Should show VPN IP
   
   # Test ThePornDB
   pct exec 106 -- curl -I https://theporndb.net
   # Should return HTTP 200
   ```

---

## 🎯 Performance Optimization

### Reduce VPN Latency
```bash
# In VPN container, edit WireGuard config
pct exec 200 -- nano /etc/wireguard/wg0.conf

# Optimize PersistentKeepalive
# Change: PersistentKeepalive = 25
# To: PersistentKeepalive = 15

# Restart VPN
pct exec 200 -- wg-quick down wg0 && pct exec 200 -- wg-quick up wg0
```

### Increase Container Resources
```bash
# Stop container
pct stop 200

# Increase memory
pct set 200 --memory 1024

# Increase CPU cores
pct set 200 --cores 2

# Start container
pct start 200
```

---

## 📋 Container IDs Reference

Keep track of your container IDs:

```
VPN Container:     200  (wireguard-vpn)
Whisparr:          106
Prowlarr:          101
Sonarr:            103
Radarr:            104
qBittorrent:       105
Cloudflared:       ???
```

---

## 🆘 Emergency Commands

### Something Broke - Quick Reset

```bash
# 1. Stop all affected services
pct stop 106

# 2. Stop VPN
pct exec 200 -- wg-quick down wg0

# 3. Fix routing on services
pct start 106
pct exec 106 -- ip route del default
pct exec 106 -- ip route add default via NORMAL_GATEWAY

# 4. Restart VPN
pct exec 200 -- wg-quick up wg0

# 5. Re-route services
pct exec 106 -- ip route del default
pct exec 106 -- ip route add default via VPN_IP

# 6. Test
pct exec 106 -- curl ifconfig.me
```

### Complete VPN Restart
```bash
pct stop 200
sleep 5
pct start 200
sleep 10
pct exec 200 -- wg-quick up wg0
sleep 5
pct exec 200 -- curl ifconfig.me
```

### Remove VPN Completely
```bash
# 1. Remove routing from all services
for CT in 106; do  # Add all service CTs here
    pct exec $CT -- ip route del default via VPN_IP
    pct exec $CT -- ip route add default via NORMAL_GATEWAY
done

# 2. Stop and destroy VPN container
pct stop 200
pct destroy 200

# 3. Verify services work normally
pct exec 106 -- curl ifconfig.me  # Should show real IP
```

---

## 📞 Getting Help

If you're stuck:

1. Check [VPN_SPLIT_TUNNEL_SETUP.md](VPN_SPLIT_TUNNEL_SETUP.md) for detailed explanations
2. Run diagnostics:
   ```bash
   vpn-status
   vpn-monitor
   ```
3. Check logs:
   ```bash
   pct exec 200 -- tail -100 /var/log/messages
   pct exec 200 -- dmesg | tail -50
   ```
4. Test each component individually (VPN → Routing → Service)

---

**Remember:** Always test in a safe environment first. Keep backups of your container configurations!
