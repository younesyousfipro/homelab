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

### Key Takeaways
- Avoid DHCP dependency
- Use static IPs
- Separate LAN from internet
