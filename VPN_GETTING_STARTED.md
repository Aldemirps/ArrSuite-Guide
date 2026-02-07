# 🚀 Getting Started with VPN Split Tunnel

**Problem Solved:** Access ThePornDB and other restricted services through Surfshark VPN while keeping Cloudflared and other services on your normal network.

---

## ⚡ Quick Start (5 Minutes)

### Prerequisites Checklist

Before running the setup:

- [ ] Proxmox VE host with root access
- [ ] Active Surfshark VPN subscription
- [ ] Surfshark account credentials ready
- [ ] Know your network configuration (gateway IP, available IP for VPN container)
- [ ] Know which services need VPN (e.g., Whisparr container ID)

### Step 1: Get Surfshark WireGuard Config

1. **Login to Surfshark:**
   ```
   https://my.surfshark.com/
   ```

2. **Navigate to Manual Setup:**
   ```
   VPN → Manual Setup → WireGuard
   ```

3. **Generate Credentials:**
   - Click "Generate new credentials"
   - Save the credentials shown (you won't see them again!)

4. **Download Config:**
   - Choose a server location:
     - **US** - Good for US content
     - **Netherlands** - Good for EU content, adult content
     - **UK** - Good for UK content
   - Click "Download" to get the `.conf` file
   - Save it somewhere accessible (e.g., `/root/surfshark-us.conf`)

### Step 2: Run Automated Setup

```bash
# On your Proxmox host
cd /root

# Run the setup script
./vpn-setup.sh
```

The script will ask you for:
- VPN container ID (default: 200)
- Static IP for VPN container (e.g., 192.168.1.200)
- Network subnet mask (usually: 24)
- Gateway IP (e.g., 192.168.1.1)
- Path to Surfshark config file
- Service container IDs to route through VPN

### Step 3: Verify It Works

```bash
# Check VPN is running
vpn-status

# Check Whisparr uses VPN (replace 106 with your CT ID)
pct exec 106 -- curl ifconfig.me
# Should show VPN IP, not your real IP

# Test ThePornDB access
pct exec 106 -- curl -I https://theporndb.net
# Should return HTTP 200 OK

# Verify Cloudflared still works
pct exec CLOUDFLARED_CT -- systemctl status cloudflared
# Should show active and running
```

✅ **Done!** Your split tunnel is configured.

---

## 🎯 What Just Happened?

The setup script:
1. ✅ Created a new privileged LXC container for VPN
2. ✅ Installed WireGuard and dependencies
3. ✅ Configured Surfshark VPN connection
4. ✅ Set up IP forwarding and NAT
5. ✅ Configured routing for your services
6. ✅ Set up automatic restart watchdog
7. ✅ Created management commands

**Result:** Whisparr (and other selected services) now route through VPN, while everything else works normally.

---

## 📋 Manual Setup (If You Prefer)

If you want to do it manually or the script fails, follow the detailed guide:

**Read:** [VPN_SPLIT_TUNNEL_SETUP.md](VPN_SPLIT_TUNNEL_SETUP.md)

---

## 🔧 Day-to-Day Management

### Common Commands

```bash
# Check VPN status
vpn-status

# Check VPN public IP
pct exec 200 -- curl ifconfig.me

# Restart VPN
pct exec 200 -- rc-service wg-quick restart

# Check if Whisparr uses VPN
pct exec 106 -- curl ifconfig.me

# View VPN logs
pct exec 200 -- tail -f /var/log/vpn-watchdog.log
```

**Full reference:** [vpn-quick-reference.md](example-configs/vpn-quick-reference.md)

---

## 🎬 Configuring Whisparr

After VPN is set up:

1. **Access Whisparr UI:**
   ```
   http://WHISPARR_IP:9708
   ```

2. **Add ThePornDB Integration:**
   ```
   Settings → Metadata → Add → ThePornDB
   - Get API key from: https://theporndb.net/
   - Add the API key
   - Test connection (should work now!)
   ```

3. **Add Indexers:**
   ```
   Settings → Indexers → Add
   - Add your preferred adult content indexers
   - They should all work through VPN now
   ```

4. **Verify in Logs:**
   ```
   System → Logs → Files
   - Should show successful connections
   - No more geo-blocking errors
   ```

---

## ⚠️ Troubleshooting Quick Fixes

### Whisparr Can't Access Internet

```bash
# Check VPN is running
pct exec 200 -- wg show

# Check Whisparr routing
pct exec 106 -- ip route show
# Should show: default via 192.168.1.200 (VPN IP)

# Fix routing
pct exec 106 -- ip route del default
pct exec 106 -- ip route add default via 192.168.1.200
```

### VPN Disconnected

```bash
# Restart VPN
pct exec 200 -- wg-quick down wg0
pct exec 200 -- wg-quick up wg0

# Check connection
pct exec 200 -- curl ifconfig.me
```

### Cloudflared Stopped Working

```bash
# Check it's NOT routed through VPN
pct exec CLOUDFLARED_CT -- ip route show
# Should NOT have VPN IP as gateway

# Fix if needed
pct exec CLOUDFLARED_CT -- ip route del default via 192.168.1.200
pct exec CLOUDFLARED_CT -- ip route add default via 192.168.1.1

# Restart
pct exec CLOUDFLARED_CT -- systemctl restart cloudflared
```

**More troubleshooting:** [VPN_SPLIT_TUNNEL_SETUP.md#troubleshooting](VPN_SPLIT_TUNNEL_SETUP.md#-part-5-troubleshooting)

---

## 🔐 Security Features Included

- ✅ **Kill Switch:** Blocks traffic if VPN drops
- ✅ **DNS Leak Prevention:** Uses Surfshark DNS
- ✅ **Auto-Reconnect:** Watchdog restarts VPN if it fails
- ✅ **Traffic Isolation:** Only selected services use VPN
- ✅ **Encrypted Tunnel:** All VPN traffic is WireGuard encrypted

---

## 📊 Architecture Overview

```
Internet
   ↑
   ├─→ Cloudflared (Direct) ────→ Normal network access
   │
   └─→ WireGuard VPN ───→ Whisparr → ThePornDB
         (Surfshark)        (Routed through VPN)
```

**Visual Diagram:** Scroll up to see the full architecture diagram created above!

---

## 📖 Additional Documentation

- **[VPN_SPLIT_TUNNEL_SETUP.md](VPN_SPLIT_TUNNEL_SETUP.md)** - Complete detailed guide
- **[vpn-quick-reference.md](example-configs/vpn-quick-reference.md)** - Command reference
- **[ARR_STACK_SETUP.md](ARR_STACK_SETUP.md)** - Main Arr stack guide

---

## 🎓 How It Works (Simple Explanation)

Think of it like this:

1. **Normal Setup:** All your containers talk directly to the internet through your router
   ```
   Whisparr → Router → Internet → ThePornDB (BLOCKED!)
   ```

2. **With Split Tunnel:** Whisparr's traffic goes through VPN, others go direct
   ```
   Whisparr → VPN Container → Surfshark → Internet → ThePornDB (✓ Works!)
   Sonarr → Router → Internet → TMDB (✓ Still works!)
   ```

3. **How:** We changed Whisparr's default route to point to the VPN container instead of the router

---

## 💡 Pro Tips

1. **Choose Server Location Wisely:**
   - US servers for US content
   - Netherlands for most permissive access
   - Closer = faster speeds

2. **Monitor Regularly:**
   ```bash
   # Add to cron
   0 */6 * * * /usr/local/bin/vpn-monitor >> /var/log/vpn-monitor.log
   ```

3. **Test Before Relying:**
   ```bash
   # Always verify IP
   pct exec 106 -- curl ifconfig.me
   
   # Test DNS leaks
   pct exec 106 -- curl https://dnsleaktest.com/
   ```

4. **Keep Backup Config:**
   ```bash
   # Backup WireGuard config
   pct pull 200 /etc/wireguard/wg0.conf ./wg0-backup.conf
   ```

5. **Use Static IPs:** Makes debugging easier

---

## 🆘 Need Help?

1. **Check VPN status:** `vpn-status`
2. **Check logs:** `pct exec 200 -- tail -f /var/log/vpn-watchdog.log`
3. **Review routing:** `pct exec 106 -- ip route show`
4. **Test connectivity:** `pct exec 200 -- ping -c 3 1.1.1.1`
5. **Read full docs:** [VPN_SPLIT_TUNNEL_SETUP.md](VPN_SPLIT_TUNNEL_SETUP.md)

---

## ✅ Success Checklist

After setup, verify:

- [ ] VPN container shows VPN IP: `pct exec 200 -- curl ifconfig.me`
- [ ] Whisparr shows VPN IP: `pct exec 106 -- curl ifconfig.me`
- [ ] ThePornDB accessible: `pct exec 106 -- curl -I https://theporndb.net`
- [ ] Sonarr shows REAL IP: `pct exec 103 -- curl ifconfig.me`
- [ ] Radarr shows REAL IP: `pct exec 104 -- curl ifconfig.me`
- [ ] Cloudflared still connected: `pct exec CF_CT -- systemctl status cloudflared`
- [ ] VPN starts on boot: Reboot VPN container and check
- [ ] Watchdog is active: `pct exec 200 -- crontab -l`

---

## 🎉 You're All Set!

Your split tunnel is configured and working. Whisparr can now access ThePornDB and other services through Surfshark VPN, while all your other services continue working normally on your regular network.

**Enjoy your automated media stack! 🍿**

---

*Questions or issues? Check the troubleshooting sections in the detailed guides or review system logs.*
