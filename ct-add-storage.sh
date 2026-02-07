#!/bin/bash
# Add storage mounts to a container
# Usage: ct-add-storage <vmid>
# 
# This script shares the Proxmox host's storage with LXC containers
# so all services can access the same media files.
#
# Installation:
#   1. cp ct-add-storage.sh /usr/local/bin/ct-add-storage
#   2. chmod +x /usr/local/bin/ct-add-storage
#   3. ct-add-storage 106

if [ -z "$1" ]; then
    echo "Usage: ct-add-storage <vmid>"
    echo "Example: ct-add-storage 106"
    exit 1
fi

VMID=$1

# Check if container exists
if ! pct status "$VMID" >/dev/null 2>&1; then
    echo "Error: Container $VMID does not exist"
    exit 1
fi

echo "Adding storage mounts to CT $VMID..."

# Add cold-storage NFS mount
# This makes /mnt/cold-storage on the host appear inside the container
if pct set "$VMID" -mp0 /mnt/cold-storage,mp=/mnt/cold-storage 2>/dev/null; then
    echo "✓ Added /mnt/cold-storage (22TB NFS)"
else
    echo "✓ /mnt/cold-storage already configured or failed"
fi

# Optional: Add additional local storage mount
# Uncomment if you have additional storage
# if pct set "$VMID" -mp1 /mnt/storage,mp=/mnt/storage 2>/dev/null; then
#     echo "✓ Added /mnt/storage (local)"
# else
#     echo "✓ /mnt/storage already configured or failed"
# fi

echo ""
echo "Storage mounts configured for CT $VMID"
echo "Note: You may need to reboot the container for changes to take effect:"
echo "  pct reboot $VMID"
