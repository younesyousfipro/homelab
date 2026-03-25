# Networking Design

## Overview

This homelab is designed to run as a simple and resilient local network.

It can:
- operate without internet
- avoid dependency on DHCP
- maintain stable connectivity between nodes

Internet access is considered optional and external to the core design.

---

## Topology

- Freebox (internet router)
- 2 Ethernet switches (cascaded)
- MacBook Pro (admin node)
- 3 nodes:
  - opti1 (Proxmox)
  - wyse1 (worker)
  - wyse2 (worker)

All devices are on the same LAN (Layer 2 network).

---

## IP Addressing

Static IPs are manually configured on each machine:

| Host     | IP Address     |
|----------|----------------|
| MacBook  | 192.168.1.10   |
| opti1    | 192.168.1.11   |
| wyse1    | 192.168.1.12   |
| wyse2    | 192.168.1.13   |

Subnet:
192.168.1.0/24

---

## Gateway

### Normal mode
- Default gateway: Freebox (192.168.1.1)
- Used for internet access (updates, downloads)

### Offline mode
- No default gateway configured
- LAN remains fully operational
- Nodes communicate directly (SSH, cluster, etc.)

---

## Design Choices

- Static IPs instead of DHCP (predictability, independence)
- LAN must function without any router
- Internet access is optional and external
- Avoid reliance on non-deterministic NAT behavior (macOS Internet Sharing)

---

## Current State

- LAN is stable and fully operational
- All nodes are reachable via static IPs
- Network works independently from internet availability

