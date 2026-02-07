# WireGuard VPN Split Tunnel Setup for Proxmox

**Purpose:** Route specific services (like Whisparr) through Surfshark VPN while keeping other services (Cloudflared, etc.) on normal network.

---

## 📋 Overview

This guide sets up a dedicated LXC container running WireGuard with Surfshark VPN. Services that need VPN access will route their traffic through this container using routing rules and iptables, while all other traffic remains unaffected.

**Architecture:**
```
Internet
   ↑
   ├─→ Cloudflared (Direct) ──────→ Services needing direct access
   │
   └─→ WireGuard VPN Container ───→ Whisparr, ThePornDB access, etc.
         (Surfshark)
```

## ✅ Prerequisites

- Proxmox VE with root access
- Active Surfshark VPN subscription
- Understanding of your network configuration
- Services already running in LXC containers

---

## 🚀 Part 1: Create WireGuard LXC Container

### Step 1: Create Privileged Container

WireGuard needs kernel access, so we'll use a privileged container:

```bash
# On Proxmox host, download Alpine Linux template (lightweight)
pveam update
pveam available | grep alpine
pveam download local alpine-3.19-default_20240207_amd64.tar.xz

# Create container (adjust CTID 200 to your preference)
pct create 200 local:vztmpl/alpine-3.19-default_20240207_amd64.tar.xz \
  --hostname wireguard-vpn \
  --memory 512 \
  --swap 512 \
  --cores 1 \
  --storage local-lvm \
  --rootfs local-lvm:8 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --unprivileged 0 \
  --features nesting=1

# Start the container
pct start 200

# Enter the container
pct enter 200
```

### Step 2: Install Required Packages

```bash
# Update system
apk update && apk upgrade

# Install WireGuard and tools
apk add wireguard-tools iptables ip6tables curl bash nano

# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding = 1" >> /etc/sysctl.conf
sysctl -p
```

---

## 🔐 Part 2: Configure Surfshark VPN

### Step 1: Get Surfshark WireGuard Configuration

1. **Login to Surfshark:**
   - Go to: https://my.surfshark.com/
   - Navigate to: VPN → Manual Setup → WireGuard

2. **Generate Credentials:**
   - Click "Generate new credentials"
   - Note down your credentials (you'll need them)

3. **Download Config:**
   - Choose a server location (e.g., US, UK, Netherlands)
   - Download the WireGuard config file
   - Keep this file safe!

### Step 2: Create WireGuard Configuration

**Inside the WireGuard container:**

```bash
# Create WireGuard directory
mkdir -p /etc/wireguard
cd /etc/wireguard

# Create configuration file
nano /etc/wireguard/wg0.conf
```

**Paste your Surfshark config (example structure):**

```ini
[Interface]
PrivateKey = YOUR_PRIVATE_KEY_FROM_SURFSHARK
Address = 10.14.0.2/16
DNS = 162.252.172.57

[Peer]
PublicKey = SURFSHARK_SERVER_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = SURFSHARK_SERVER_IP:51820
PersistentKeepalive = 25
```

**Set proper permissions:**

```bash
chmod 600 /etc/wireguard/wg0.conf
```

### Step 3: Create Startup Script

```bash
nano /etc/local.d/wireguard.start
```

**Add the following:**

```bash
#!/bin/bash

# Start WireGuard
wg-quick up wg0

# Enable NAT for incoming traffic
iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE

# Allow forwarding
iptables -A FORWARD -i eth0 -o wg0 -j ACCEPT
iptables -A FORWARD -i wg0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Save iptables rules
rc-service iptables save
```

**Make it executable:**

```bash
chmod +x /etc/local.d/wireguard.start
rc-update add local default
```

### Step 4: Test VPN Connection

```bash
# Start WireGuard manually
wg-quick up wg0

# Check connection status
wg show

# Test if VPN is working - check your IP
curl ifconfig.me

# Should show Surfshark server IP, not your real IP
```

**If successful, enable on boot:**

```bash
# Create OpenRC service
cat > /etc/init.d/wg-quick <<'EOF'
#!/sbin/openrc-run

name="wg-quick"
description="WireGuard VPN"

depend() {
    need net
    after firewall
}

start() {
    ebegin "Starting WireGuard VPN"
    /usr/bin/wg-quick up wg0
    eend $?
}

stop() {
    ebegin "Stopping WireGuard VPN"
    /usr/bin/wg-quick down wg0
    eend $?
}
EOF

chmod +x /etc/init.d/wg-quick
rc-update add wg-quick default
```

---

## 🔀 Part 3: Configure Split Tunneling

Now we route specific services through the VPN container.

### Method A: Route Entire Container Through VPN

**Best for:** Whisparr, Prowlarr, or any container needing full VPN access

**On Proxmox Host:**

```bash
# Get the WireGuard container's IP
VPN_IP=$(pct exec 200 -- ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo "VPN Container IP: $VPN_IP"

# Get the service container ID you want to route (e.g., Whisparr - CT 106)
SERVICE_CTID=106  # Change this to your Whisparr container ID

# Enter the service container
pct enter $SERVICE_CTID

# Add route for all traffic through VPN
ip route add default via $VPN_IP

# Or to be safe, delete old default and add new one
ip route del default
ip route add default via $VPN_IP

# Make it permanent - add to container's network config
exit  # Exit the service container

# On Proxmox host - edit container config
nano /etc/pve/lxc/${SERVICE_CTID}.conf

# Add this line under the net0 configuration:
# lxc.net.0.ipv4.gateway = VPN_CONTAINER_IP
```

### Method B: Route Specific Domains Through VPN

**Best for:** Selective traffic routing (e.g., only ThePornDB)

**In the service container (e.g., Whisparr):**

```bash
# Install routing tools
apt update && apt install iproute2 iptables -y

# Create custom routing table
echo "200 vpn" >> /etc/iproute2/rt_tables

# Route specific destination through VPN
# Example: Route all traffic to theporndb.net through VPN
VPN_GW="10.0.0.200"  # Your VPN container IP

# Add rule for specific domain
iptables -t nat -A OUTPUT -d theporndb.net -j MARK --set-mark 200
ip rule add fwmark 200 table vpn
ip route add default via $VPN_GW table vpn
```

### Method C: Use WireGuard Container as Proxy (Advanced)

**Setup SOCKS5 proxy in VPN container:**

```bash
# In WireGuard container
apk add dante-server

# Configure dante
nano /etc/sockd.conf
```

**Add:**

```
logoutput: syslog
internal: eth0 port = 1080
external: wg0

clientmethod: none
socksmethod: none

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}
```

**Start proxy:**

```bash
rc-service sockd start
rc-update add sockd default
```

**Configure Whisparr to use proxy:**
- In Whisparr UI: Settings → General → Proxy
- Type: SOCKS5
- Hostname: VPN container IP
- Port: 1080

---

## 🧪 Part 4: Testing Split Tunnel

### Test 1: Verify VPN Container

```bash
# In VPN container
curl ifconfig.me
# Should show Surfshark IP

wg show
# Should show active connection
```

### Test 2: Verify Service Routing

```bash
# In Whisparr container (or service using VPN)
curl ifconfig.me
# Should show Surfshark IP if routing through VPN

# Test specific domain
curl -I https://theporndb.net
# Should work now
```

### Test 3: Verify Other Services Not Affected

```bash
# In other containers (Sonarr, Radarr, etc.)
curl ifconfig.me
# Should show your REAL IP, not VPN IP

# Test Cloudflared
pct enter CLOUDFLARED_CTID
systemctl status cloudflared
# Should show running and connected
```

---

## 🔧 Part 5: Troubleshooting

### Issue: VPN won't connect

```bash
# Check WireGuard status
wg show

# Check logs
dmesg | grep wireguard

# Test connectivity
ping 1.1.1.1  # If this fails, problem is with WireGuard config
ping google.com  # If this fails, DNS issue
```

### Issue: Service can't route through VPN

```bash
# In service container, check routes
ip route show

# Check if VPN container is reachable
ping VPN_CONTAINER_IP

# Check iptables in VPN container
iptables -t nat -L -n -v
```

### Issue: Cloudflared stops working

This shouldn't happen with split tunneling, but if it does:

```bash
# Remove VPN routing from Cloudflared container
pct enter CLOUDFLARED_CTID
ip route del default via VPN_IP
ip route add default via YOUR_NORMAL_GATEWAY
```

### Issue: VPN disconnects randomly

**Add watchdog script in VPN container:**

```bash
nano /usr/local/bin/vpn-watchdog.sh
```

**Add:**

```bash
#!/bin/bash

# Check if WireGuard is up
if ! wg show wg0 &>/dev/null; then
    echo "$(date): WireGuard down, restarting..."
    wg-quick down wg0 2>/dev/null
    wg-quick up wg0
fi

# Check if we can reach internet through VPN
if ! ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
    echo "$(date): No internet through VPN, restarting..."
    wg-quick down wg0
    wg-quick up wg0
fi
```

**Make executable and add to cron:**

```bash
chmod +x /usr/local/bin/vpn-watchdog.sh

# Add to crontab (every 5 minutes)
crontab -e
# Add: */5 * * * * /usr/local/bin/vpn-watchdog.sh >> /var/log/vpn-watchdog.log 2>&1
```

---

## 📊 Part 6: Recommended Setup for Your Use Case

Based on your needs (Whisparr + ThePornDB), here's the recommended configuration:

### Container Setup

1. **WireGuard VPN Container (CT 200)**
   - Running Surfshark WireGuard
   - IP: Static (e.g., 10.0.0.200)
   - Purpose: VPN gateway

2. **Whisparr Container**
   - Route ALL traffic through VPN
   - Use Method A (Full Container Routing)

### Quick Setup Commands

```bash
# 1. Create VPN container (on Proxmox host)
pct create 200 local:vztmpl/alpine-3.19-default_20240207_amd64.tar.xz \
  --hostname wireguard-vpn \
  --memory 512 --cores 1 \
  --net0 name=eth0,bridge=vmbr0,ip=10.0.0.200/24,gw=10.0.0.1 \
  --unprivileged 0 --features nesting=1

# 2. Setup WireGuard (follow Part 2)

# 3. Route Whisparr through VPN
WHISPARR_CTID=106  # Your Whisparr container ID
pct exec $WHISPARR_CTID -- ip route add default via 10.0.0.200

# 4. Test
pct exec $WHISPARR_CTID -- curl ifconfig.me
# Should show Surfshark IP
```

---

## 🔒 Security Best Practices

1. **Kill Switch:** Prevent traffic if VPN drops

```bash
# In VPN container
iptables -A OUTPUT -o eth0 ! -d 10.0.0.0/24 -j DROP
iptables -A OUTPUT -o wg0 -j ACCEPT
```

2. **DNS Leak Prevention:**

```bash
# In service containers using VPN
echo "nameserver 162.252.172.57" > /etc/resolv.conf
chattr +i /etc/resolv.conf  # Make immutable
```

3. **Regular IP Checks:**

```bash
# Add to cron in service container
*/30 * * * * curl -s ifconfig.me | grep -q "YOUR_REAL_IP" && echo "VPN LEAK!" | mail -s "VPN Alert" admin@example.com
```

---

## 📝 Complete Configuration Checklist

- [ ] VPN container created and WireGuard installed
- [ ] Surfshark WireGuard config obtained and configured
- [ ] VPN connection tested (curl ifconfig.me shows VPN IP)
- [ ] IP forwarding enabled in VPN container
- [ ] iptables NAT rules configured
- [ ] Service container routed through VPN
- [ ] Service container shows VPN IP when testing
- [ ] ThePornDB accessible from Whisparr
- [ ] Cloudflared still works (not routed through VPN)
- [ ] Other Arr services work normally
- [ ] VPN auto-starts on boot
- [ ] Watchdog script configured
- [ ] Kill switch enabled
- [ ] DNS leak prevention configured

---

## 🆘 Quick Reference Commands

```bash
# Check VPN status
pct exec 200 -- wg show

# Check service routing
pct exec WHISPARR_CTID -- curl ifconfig.me

# Restart VPN
pct exec 200 -- wg-quick down wg0 && pct exec 200 -- wg-quick up wg0

# View VPN container logs
pct enter 200
tail -f /var/log/messages

# Emergency: Remove VPN routing
pct exec WHISPARR_CTID -- ip route del default via 10.0.0.200
pct exec WHISPARR_CTID -- ip route add default via NORMAL_GATEWAY
```

---

## 🔗 Additional Resources

- [Surfshark Manual Setup Guide](https://support.surfshark.com/hc/en-us/articles/360011051133-How-to-set-up-manual-WireGuard-connection-)
- [WireGuard Quick Start](https://www.wireguard.com/quickstart/)
- [Proxmox LXC Documentation](https://pve.proxmox.com/wiki/Linux_Container)

---

**Note:** Replace IP addresses, container IDs, and paths with your actual values. Always test in a non-production environment first!

**Questions or issues?** Check the troubleshooting section or review your firewall rules on the Proxmox host.
