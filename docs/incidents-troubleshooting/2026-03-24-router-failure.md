# 2026-03-24 Internet router (Freebox) KO

## Issue: No network connectivity

### Context
Freebox (internet router) was down → no DHCP, no gateway.

### Symptoms
- No SSH access
- Cannot ping nodes
- No IP on Mac Ethernet
- `.local` not resolving

### Root Cause
- DHCP unavailable
- No static IPs configured
- No fallback gateway

### Fix
- Set static IPs on all nodes
- Verify connectivity with ping (192.168.1.x)
- Restore SSH access (ssh younes@IP)

### Result
- LAN operational without router
- SSH restored

Update: Removed mDNS (.local)

Change
	•	Removed dependency on .local (Avahi / mDNS)
	•	Switched to static IP + SSH config (~/.ssh/config)

Reason
	•	.local is unreliable (mDNS, multicast, IPv6 issues)
	•	Not used in production environments
	•	Caused resolution inconsistencies during setup

Result
	•	Stable and deterministic access (ex: ssh opti1)
	•	No dependency on network discovery services

### Key Takeaways
- Avoid DHCP dependency
- Use static IPs
- Separate LAN from internet
