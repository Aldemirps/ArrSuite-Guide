# VPN Split Tunnel Setup Checklist

**Date Started:** _______________  
**Completed:** ☐ Yes ☐ No

---

## Pre-Setup Phase

### Gather Information
- [ ] Surfshark VPN subscription active
- [ ] Surfshark account credentials ready (username/password)
- [ ] Know network gateway IP: _______________
- [ ] Know network subnet (usually /24): _______________
- [ ] Chosen IP for VPN container: _______________
- [ ] Know Whisparr container ID: _______________
- [ ] Know other container IDs that need VPN: _______________

### Download Surfshark Config
- [ ] Logged into https://my.surfshark.com/
- [ ] Navigated to: VPN → Manual Setup → WireGuard
- [ ] Generated new credentials
- [ ] Saved credentials securely
- [ ] Downloaded WireGuard config file
- [ ] Config file location: _______________
- [ ] Chosen server location: _______________

---

## Installation Phase

### Run Setup Script
- [ ] SSH'd into Proxmox host as root
- [ ] Script exists: `/root/vpn-setup.sh`
- [ ] Made script executable: `chmod +x vpn-setup.sh`
- [ ] Ran script: `./vpn-setup.sh`

### Setup Script Completed
- [ ] Chose VPN Container ID (default: 200)
- [ ] Provided network configuration
- [ ] Alpine template downloaded/found
- [ ] Container created successfully
- [ ] WireGuard installed
- [ ] Surfshark config uploaded
- [ ] IP forwarding enabled
- [ ] Startup scripts created
- [ ] WireGuard started successfully
- [ ] VPN connection established
- [ ] Watchdog configured
- [ ] Services routed through VPN

---

## Verification Phase

### VPN Container Tests
- [ ] Container is running: `pct status 200`
  - Status: _______________
- [ ] WireGuard interface active: `pct exec 200 -- wg show`
  - Output shows interface: ☐ Yes ☐ No
- [ ] VPN IP check: `pct exec 200 -- curl ifconfig.me`
  - Shows VPN IP (not real IP): ☐ Yes ☐ No
  - VPN IP: _______________
- [ ] Internet connectivity: `pct exec 200 -- ping -c 3 1.1.1.1`
  - Successful: ☐ Yes ☐ No
- [ ] DNS working: `pct exec 200 -- nslookup google.com`
  - Successful: ☐ Yes ☐ No

### Service Routing Tests (Whisparr)
- [ ] Whisparr container running
- [ ] Check routing: `pct exec 106 -- ip route show`
  - Default route points to VPN IP: ☐ Yes ☐ No
- [ ] IP check: `pct exec 106 -- curl ifconfig.me`
  - Shows VPN IP: ☐ Yes ☐ No
  - IP matches VPN container: ☐ Yes ☐ No
- [ ] ThePornDB access: `pct exec 106 -- curl -I https://theporndb.net`
  - HTTP 200 OK: ☐ Yes ☐ No
- [ ] Whisparr web UI accessible on LAN: `http://IP:9708`
  - Accessible: ☐ Yes ☐ No

### Other Services NOT Affected
- [ ] Sonarr IP check: `pct exec 103 -- curl ifconfig.me`
  - Shows REAL IP (not VPN): ☐ Yes ☐ No
- [ ] Radarr IP check: `pct exec 104 -- curl ifconfig.me`
  - Shows REAL IP (not VPN): ☐ Yes ☐ No
- [ ] Prowlarr accessible: `http://IP:9696`
  - Accessible: ☐ Yes ☐ No
- [ ] Cloudflared status: Check if tunnel is active
  - Active and connected: ☐ Yes ☐ No

---

## Configuration Phase

### Whisparr Configuration
- [ ] Accessed Whisparr web UI
- [ ] Navigated to: Settings → Metadata
- [ ] Added ThePornDB integration
- [ ] Obtained API key from https://theporndb.net/
  - API key: _______________
- [ ] Added API key to Whisparr
- [ ] Tested connection: ☐ Success ☐ Failed
- [ ] Configured indexers: Settings → Indexers
- [ ] Added preferred indexers
- [ ] Tested indexer connections: ☐ All passed

### Security Configuration
- [ ] DNS leak prevention verified
  - Test: `pct exec 106 -- dig +short myip.opendns.com @resolver1.opendns.com`
  - Shows VPN IP: ☐ Yes ☐ No
- [ ] Kill switch functional
  - Stopped VPN: `pct exec 200 -- wg-quick down wg0`
  - Service can't reach internet: ☐ Correct (no access)
  - Restarted VPN: `pct exec 200 -- wg-quick up wg0`
  - Service works again: ☐ Yes ☐ No

---

## Automation & Monitoring

### Auto-Start Configuration
- [ ] VPN container set to start on boot: `onboot=1` in config
- [ ] Tested by rebooting VPN container
  - VPN auto-started: ☐ Yes ☐ No
- [ ] Service routing persists after reboot: ☐ Yes ☐ No

### Watchdog Configuration
- [ ] Watchdog script exists: `/usr/local/bin/vpn-watchdog.sh`
- [ ] Cron job configured: `pct exec 200 -- crontab -l`
  - Shows watchdog entry: ☐ Yes ☐ No
- [ ] Crond service enabled: `pct exec 200 -- rc-status`
  - Crond running: ☐ Yes ☐ No
- [ ] Watchdog log exists: `pct exec 200 -- cat /var/log/vpn-watchdog.log`

### Monitoring Setup
- [ ] Created monitoring script: `/usr/local/bin/vpn-monitor`
- [ ] Can run: `vpn-monitor`
  - Works: ☐ Yes ☐ No
- [ ] Added monitoring to cron (optional)
  - Scheduled: ☐ Yes ☐ No ☐ Skipped
  - Frequency: _______________

---

## Documentation & Backup

### Configuration Backup
- [ ] Backed up WireGuard config
  - Command: `pct pull 200 /etc/wireguard/wg0.conf ./wg0-backup.conf`
  - Backup location: _______________
- [ ] Backed up VPN container
  - Command: `vzdump 200 --storage local --compress gzip`
  - Backup location: _______________
- [ ] Documented custom settings
  - VPN Container ID: _______________
  - VPN IP: _______________
  - Services using VPN: _______________

### Reference Documents
- [ ] Read: VPN_SPLIT_TUNNEL_SETUP.md
- [ ] Read: VPN_GETTING_STARTED.md
- [ ] Bookmarked: vpn-quick-reference.md
- [ ] Saved Surfshark credentials securely
- [ ] Stored this checklist for future reference

---

## Final Validation

### 24-Hour Stability Test
- [ ] VPN running continuously for 24 hours
- [ ] No disconnections in watchdog log
- [ ] Services remained connected
- [ ] No errors in system logs: `pct exec 200 -- tail -100 /var/log/messages`

### Performance Test
- [ ] Whisparr download speed acceptable
  - Speed: _______________
- [ ] Whisparr API responses fast
- [ ] No timeouts in Whisparr logs
- [ ] VPN container CPU usage reasonable
  - Usage: _______________
- [ ] VPN container memory usage reasonable
  - Usage: _______________

### Functionality Test
- [ ] Requested content in Whisparr
- [ ] Indexers searched successfully
- [ ] Downloads initiated
- [ ] Content downloaded successfully
- [ ] Movies/shows properly cataloged
- [ ] No errors in Whisparr logs

---

## Troubleshooting (If Needed)

### Issues Encountered
☐ No issues  
☐ Had issues (document below)

**Issue #1:**
- Problem: _______________________________________________
- When occurred: _________________________________________
- Solution: ______________________________________________
- Reference: _____________________________________________

**Issue #2:**
- Problem: _______________________________________________
- When occurred: _________________________________________
- Solution: ______________________________________________
- Reference: _____________________________________________

**Issue #3:**
- Problem: _______________________________________________
- When occurred: _________________________________________
- Solution: ______________________________________________
- Reference: _____________________________________________

---

## Maintenance Schedule

### Weekly
- [ ] Check VPN status: `vpn-status`
- [ ] Review watchdog logs
- [ ] Verify services still route correctly

### Monthly
- [ ] Test VPN connection speed
- [ ] Review Whisparr logs for errors
- [ ] Check for WireGuard updates: `pct exec 200 -- apk update && apk list -u`
- [ ] Verify backup exists and is recent

### As Needed
- [ ] Change VPN server location
- [ ] Add/remove services from VPN routing
- [ ] Update Surfshark credentials (if changed)
- [ ] Adjust VPN container resources

---

## Quick Reference

### Important IPs & IDs
```
VPN Container ID:       _______________
VPN Container IP:       _______________
VPN Public IP:          _______________
Network Gateway:        _______________
Whisparr CT ID:         _______________
Sonarr CT ID:           _______________
Radarr CT ID:           _______________
Cloudflared CT ID:      _______________
```

### Essential Commands
```bash
# Check VPN
vpn-status
pct exec 200 -- wg show
pct exec 200 -- curl ifconfig.me

# Check service
pct exec 106 -- curl ifconfig.me

# Restart VPN
pct exec 200 -- rc-service wg-quick restart

# View logs
pct exec 200 -- tail -f /var/log/vpn-watchdog.log
```

### Emergency Contacts/Resources
```
Surfshark Support:      https://support.surfshark.com/
Documentation:          VPN_SPLIT_TUNNEL_SETUP.md
Quick Reference:        vpn-quick-reference.md
Community Forums:       _______________
Your Notes:             _______________
```

---

## Completion

### Final Sign-Off
- [ ] All tests passed
- [ ] Documentation reviewed
- [ ] Backups created
- [ ] Monitoring configured
- [ ] Team/self trained on management
- [ ] Emergency procedures documented
- [ ] Success! ✅

**Completed By:** _______________  
**Date Completed:** _______________  
**Time Spent:** _______________  
**Overall Experience:** ☐ Easy ☐ Medium ☐ Difficult

### Notes for Future Reference
```
________________________________________________________________________
________________________________________________________________________
________________________________________________________________________
________________________________________________________________________
```

---

**This setup is complete and working! 🎉**

*Save this checklist for troubleshooting and future reference.*
