#!/bin/bash

#################################################
# WireGuard VPN Container Setup Script
# For routing specific services through Surfshark
#################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if running on Proxmox host
if [ ! -f /etc/pve/.version ]; then
    print_error "This script must be run on the Proxmox VE host!"
    exit 1
fi

print_header "WireGuard VPN Container Setup"

# Get configuration from user
print_info "This script will:"
echo "  1. Create a privileged LXC container for WireGuard"
echo "  2. Install and configure WireGuard"
echo "  3. Set up Surfshark VPN"
echo "  4. Configure routing for your services"
echo ""

read -p "Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Get container ID
print_header "Step 1: Container Configuration"
read -p "Enter Container ID for VPN (default: 200): " VPN_CTID
VPN_CTID=${VPN_CTID:-200}

# Check if container already exists
if pct status $VPN_CTID &>/dev/null; then
    print_error "Container $VPN_CTID already exists!"
    read -p "Delete and recreate? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pct stop $VPN_CTID 2>/dev/null || true
        pct destroy $VPN_CTID
        print_success "Existing container destroyed"
    else
        exit 1
    fi
fi

# Get network configuration
read -p "Enter static IP for VPN container (e.g., 192.168.1.200): " VPN_IP
read -p "Enter subnet mask in CIDR (e.g., 24): " VPN_MASK
read -p "Enter gateway IP (e.g., 192.168.1.1): " VPN_GW

# Verify Alpine template exists
print_header "Step 2: Checking for Alpine Linux Template"
if ! pveam list local | grep -q alpine; then
    print_warning "Alpine template not found. Downloading..."
    pveam update
    ALPINE_TEMPLATE=$(pveam available | grep alpine | head -n1 | awk '{print $2}')
    pveam download local $ALPINE_TEMPLATE
    print_success "Alpine template downloaded"
else
    ALPINE_TEMPLATE=$(pveam list local | grep alpine | head -n1 | awk '{print $2}')
    print_success "Alpine template found: $ALPINE_TEMPLATE"
fi

# Create container
print_header "Step 3: Creating VPN Container"
print_info "Creating container $VPN_CTID..."

pct create $VPN_CTID local:vztmpl/$ALPINE_TEMPLATE \
    --hostname wireguard-vpn \
    --memory 512 \
    --swap 512 \
    --cores 1 \
    --storage local-lvm \
    --rootfs local-lvm:8 \
    --net0 name=eth0,bridge=vmbr0,ip=${VPN_IP}/${VPN_MASK},gw=${VPN_GW} \
    --unprivileged 0 \
    --features nesting=1 \
    --onboot 1

print_success "Container created successfully"

# Start container
print_info "Starting container..."
pct start $VPN_CTID
sleep 5
print_success "Container started"

# Install packages
print_header "Step 4: Installing WireGuard and Dependencies"
pct exec $VPN_CTID -- sh -c "apk update && apk upgrade"
pct exec $VPN_CTID -- apk add wireguard-tools iptables ip6tables curl bash nano openrc

print_success "Packages installed"

# Enable IP forwarding
print_header "Step 5: Configuring IP Forwarding"
pct exec $VPN_CTID -- sh -c "echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf"
pct exec $VPN_CTID -- sh -c "echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf"
pct exec $VPN_CTID -- sysctl -p

print_success "IP forwarding enabled"

# Configure WireGuard
print_header "Step 6: WireGuard Configuration"
print_warning "You need your Surfshark WireGuard configuration!"
print_info "Get it from: https://my.surfshark.com/ → VPN → Manual Setup → WireGuard"
echo ""
read -p "Press Enter when you have downloaded your config file..."

read -p "Enter path to your Surfshark WireGuard config file: " WG_CONFIG

if [ ! -f "$WG_CONFIG" ]; then
    print_error "Config file not found: $WG_CONFIG"
    exit 1
fi

# Copy config to container
pct exec $VPN_CTID -- mkdir -p /etc/wireguard
pct push $VPN_CTID "$WG_CONFIG" /etc/wireguard/wg0.conf
pct exec $VPN_CTID -- chmod 600 /etc/wireguard/wg0.conf

print_success "WireGuard configuration uploaded"

# Create startup script
print_header "Step 7: Creating Startup Scripts"

pct exec $VPN_CTID -- sh -c 'cat > /etc/local.d/wireguard.start << "EOF"
#!/bin/sh
sleep 5
wg-quick up wg0
iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o wg0 -j ACCEPT
iptables -A FORWARD -i wg0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
EOF'

pct exec $VPN_CTID -- chmod +x /etc/local.d/wireguard.start
pct exec $VPN_CTID -- rc-update add local default

# Create OpenRC service
pct exec $VPN_CTID -- sh -c 'cat > /etc/init.d/wg-quick << "EOF"
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

restart() {
    stop
    sleep 2
    start
}
EOF'

pct exec $VPN_CTID -- chmod +x /etc/init.d/wg-quick
pct exec $VPN_CTID -- rc-update add wg-quick default

print_success "Startup scripts created"

# Start WireGuard
print_header "Step 8: Starting WireGuard VPN"
pct exec $VPN_CTID -- wg-quick up wg0
sleep 3

# Test VPN
print_info "Testing VPN connection..."
VPN_PUBLIC_IP=$(pct exec $VPN_CTID -- curl -s ifconfig.me)

if [ -n "$VPN_PUBLIC_IP" ]; then
    print_success "VPN connected! Public IP: $VPN_PUBLIC_IP"
else
    print_error "VPN connection failed!"
    exit 1
fi

# Configure watchdog
print_header "Step 9: Setting Up VPN Watchdog"

pct exec $VPN_CTID -- sh -c 'cat > /usr/local/bin/vpn-watchdog.sh << "EOF"
#!/bin/bash

if ! wg show wg0 &>/dev/null; then
    echo "$(date): WireGuard down, restarting..."
    wg-quick down wg0 2>/dev/null
    wg-quick up wg0
fi

if ! ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
    echo "$(date): No internet through VPN, restarting..."
    wg-quick down wg0
    wg-quick up wg0
fi
EOF'

pct exec $VPN_CTID -- chmod +x /usr/local/bin/vpn-watchdog.sh

# Add cron job
pct exec $VPN_CTID -- sh -c 'echo "*/5 * * * * /usr/local/bin/vpn-watchdog.sh >> /var/log/vpn-watchdog.log 2>&1" | crontab -'
pct exec $VPN_CTID -- rc-update add crond default
pct exec $VPN_CTID -- rc-service crond start

print_success "Watchdog configured"

# Configure routing for services
print_header "Step 10: Configure Service Routing"
print_info "Now let's route your services through the VPN"
echo ""

while true; do
    read -p "Enter container ID to route through VPN (e.g., Whisparr CT ID) or 'done': " SERVICE_CTID
    
    if [ "$SERVICE_CTID" = "done" ]; then
        break
    fi
    
    if ! pct status $SERVICE_CTID &>/dev/null; then
        print_error "Container $SERVICE_CTID doesn't exist!"
        continue
    fi
    
    print_info "Routing container $SERVICE_CTID through VPN..."
    
    # Remove existing default route and add new one
    pct exec $SERVICE_CTID -- ip route del default 2>/dev/null || true
    pct exec $SERVICE_CTID -- ip route add default via $VPN_IP
    
    # Test routing
    SERVICE_IP=$(pct exec $SERVICE_CTID -- curl -s ifconfig.me 2>/dev/null || echo "Failed")
    
    if [ "$SERVICE_IP" = "$VPN_PUBLIC_IP" ]; then
        print_success "Container $SERVICE_CTID now routes through VPN (IP: $SERVICE_IP)"
    else
        print_warning "Container $SERVICE_CTID routing may not be working (IP: $SERVICE_IP)"
    fi
done

# Summary
print_header "Setup Complete!"
echo ""
print_success "VPN Container Information:"
echo "  Container ID: $VPN_CTID"
echo "  IP Address: $VPN_IP"
echo "  Public IP (VPN): $VPN_PUBLIC_IP"
echo ""
print_info "Useful Commands:"
echo "  Check VPN status: pct exec $VPN_CTID -- wg show"
echo "  Check VPN IP: pct exec $VPN_CTID -- curl ifconfig.me"
echo "  Restart VPN: pct exec $VPN_CTID -- rc-service wg-quick restart"
echo "  View logs: pct exec $VPN_CTID -- tail -f /var/log/vpn-watchdog.log"
echo ""
print_warning "Remember to test that Cloudflared and other services still work!"
echo ""
print_info "Full documentation: VPN_SPLIT_TUNNEL_SETUP.md"
echo ""

# Create quick reference script
cat > /usr/local/bin/vpn-status << EOF
#!/bin/bash
echo "=== VPN Container Status ==="
echo "Container: $VPN_CTID"
pct status $VPN_CTID
echo ""
echo "VPN Connection:"
pct exec $VPN_CTID -- wg show
echo ""
echo "Public IP:"
pct exec $VPN_CTID -- curl -s ifconfig.me
EOF

chmod +x /usr/local/bin/vpn-status
print_success "Created 'vpn-status' command for quick checking"

print_header "All Done! 🎉"
