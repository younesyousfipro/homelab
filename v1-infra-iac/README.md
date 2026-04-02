# Proxmox Terraform Module – k3s VMs

## Overview

This module provisions two virtual machines on Proxmox:

- one control plane node (`k3s-cp`)
- one worker node (`k3s-worker-1`)

Both VMs are cloned from an existing template and initialized using cloud-init.

---

## What it does

- Connects to Proxmox API
- Clones a template VM
- Configures:
  - CPU and memory
  - disk size
  - static IP
  - gateway and DNS
  - user and SSH access

---

## Requirements

- Proxmox VE
- A prepared VM template with:
  - cloud-init enabled
  - qemu-guest-agent installed
- Terraform
- Proxmox provider (`bpg/proxmox`)

---

## Usage

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply