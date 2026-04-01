# Proxmox Golden VM Template Guide (Ubuntu Cloud Image)  
*A practical step-by-step guide to recreate the exact workflow used today, including the pitfalls I hit.*

---

## Goal

Build a **clean, reusable Proxmox golden template** for Linux VMs that will later be cloned and customized with:
- hostname
- static IP
- SSH key
- RAM / CPU / disk sizing
- application role (control plane, worker, etc.)

This guide is intentionally focused on the **template creation workflow**, not yet on Terraform or Ansible.

---

# 1. Target architecture and design principles

## What the template should be
A golden template must be:

- **generic**
- **clean**
- **cloud-init ready**
- **SSH ready**
- **role-neutral**

It should contain:
- Ubuntu Server
- cloud-init support
- SSH enabled
- optional `qemu-guest-agent`
- no app-specific tooling
- no fixed node role
- no fixed static IP

## What must NOT be baked into the template
Do **not** hardcode:
- Kubernetes
- control-plane / worker role
- final static IP
- MAC-specific netplan config
- temporary debug settings

---

# 2. Recommended target sizing (important lesson learned)

## Template base VM
The template itself can stay small-ish, but **clones must be resized** depending on role.

## Minimum practical sizing for clones

### Control plane VM
- **2 vCPU**
- **3 GB RAM**
- **30 GB disk**

### Worker VM
- **1 vCPU**
- **2 GB RAM**
- **30 GB disk**

## Important pitfall
I initially kept the imported cloud image disk around **3.5 GB** and the VM RAM at **1 GB**.

This caused:
- `k3s` startup failures
- `no space left on device`
- slow / stuck services
- Kubernetes components hanging or failing

### Rule
For real usage:
- **1 GB RAM is too small for k3s control plane**
- **3.5 GB disk is too small for k3s nodes**

---

# 3. Download the Ubuntu cloud image

Use the official Ubuntu cloud images.

Example source:
- Ubuntu Noble cloud image directory

Pick the correct file:
- `noble-server-cloudimg-amd64.img`

### Why this file
- `amd64` matches Intel/AMD x86_64 systems
- `cloudimg` is designed for cloud-init
- `.img` is a disk image ready to import into Proxmox

### Do NOT use
- `.tar.gz`
- `lxd` images
- Azure-specific VHD
- VMware-specific formats unless that is your target platform

---

# 4. Create an empty VM shell in Proxmox

Create a new VM in Proxmox UI with these settings.

## General
- Name: `ubuntu-cloud-template`
- VM ID: e.g. `100`

## OS
- **Do not use any media**

Reason:
- you are **not** installing from ISO
- you will import the Ubuntu cloud image as the VM disk

## System
- Machine: `q35`
- BIOS: `OVMF (UEFI)`
- Add EFI Disk: **enabled**
- SCSI Controller: `VirtIO SCSI single`

## Disks
- Delete the automatically proposed disk

Reason:
- you do not want an empty disk
- you will import your own `.img`

## CPU
- 1 core is fine for the template shell itself

## Memory
- 1 GB is acceptable for the template shell itself
- **but clones must later be resized**

## Network
- Bridge: `vmbr0`
- Model: `VirtIO`

Create the VM.

---

# 5. Transfer the cloud image to the Proxmox host

From your Mac/Linux client, copy the downloaded image to the Proxmox host.

Example:
```bash
scp ~/Downloads/noble-server-cloudimg-amd64.img root@192.168.1.11:/root/
```

Then SSH into the Proxmox host and verify:
```bash
ls -lh /root
```

You should see:
```text
noble-server-cloudimg-amd64.img
```

---

# 6. Import the disk into Proxmox

On the **Proxmox host**:

```bash
sudo qm importdisk 100 /root/noble-server-cloudimg-amd64.img local-lvm
```

## What this does
It imports the external disk image into Proxmox storage and associates it with VM `100`.

## Important note
Use an **absolute path** to the image file.

### Common mistake
Using the wrong filename or a relative path can produce:
```text
non-existent or non-regular file
```

---

# 7. Attach the imported disk and add cloud-init disk

After import, check VM config:

```bash
sudo qm config 100
```

You should see something like:
```text
unused0: local-lvm:vm-100-disk-1
```

Now attach it properly:

```bash
sudo qm set 100 --scsi0 local-lvm:vm-100-disk-1
sudo qm set 100 --ide2 local-lvm:cloudinit
sudo qm set 100 --boot order=scsi0
```

## Meaning
- `scsi0` = main OS disk
- `ide2` = cloud-init disk
- boot from `scsi0`

---

# 8. Optional but recommended: serial console

To make console access easier:

```bash
sudo qm set 100 --serial0 socket
sudo qm set 100 --vga serial0
```

This is useful for headless server-style operation.

---

# 9. Configure cloud-init for initial validation

At this stage, you need a **temporary** network / SSH config to validate the VM.

## Inject a user
```bash
sudo qm set 100 --ciuser younes
```

## Inject SSH public key
The file path used by `qm set --sshkey` must exist on the **Proxmox host**, not on your laptop.

Example if you copied your public key to Proxmox:
```bash
sudo qm set 100 --sshkey /home/younes/id_ed25519_homelab.pub
```

## Temporary static IP for testing
```bash
sudo qm set 100 --ipconfig0 ip=192.168.1.20/24,gw=192.168.1.254
```

### Important
This static IP is **temporary for validation only**.

It must **not remain in the final template**.

---

# 10. Start the VM and validate SSH

Start it:

```bash
sudo qm start 100
```

From your laptop:
```bash
ssh -i ~/.ssh/id_ed25519_homelab younes@192.168.1.20
```

If it works:
- cloud-init user injection works
- SSH key injection works
- static IP injection works

---

# 11. Clean SSH client warnings if reusing the same IP

If you reused the same IP as an older VM, SSH may warn:

```text
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!
```

This is normal if the machine identity changed.

Fix on your client:
```bash
ssh-keygen -R 192.168.1.20
```

Then reconnect and accept the new host key.

---

# 12. Install qemu-guest-agent (recommended)

Inside the VM:

```bash
sudo apt update
sudo apt install -y qemu-guest-agent
```

Then on Proxmox, enable the guest agent in the VM options (or CLI if needed).

After that, reboot the VM and check:

```bash
ls /dev/virtio-ports/
```

You want:
```text
org.qemu.guest_agent.0
```

Then:

```bash
sudo systemctl start qemu-guest-agent
sudo systemctl status qemu-guest-agent
```

## If it blocks
The usual reason is that the guest agent channel was not properly exposed by Proxmox.

### Fix checklist
- make sure QEMU Guest Agent is enabled in Proxmox
- fully reboot the VM
- recheck `/dev/virtio-ports/`

## Important note
`qemu-guest-agent` is **recommended** but **not mandatory** for the template to work.

It improves:
- IP visibility in Proxmox
- graceful shutdown
- VM introspection

---

# 13. Convert networking back to generic DHCP before templating

## Why
A template must not keep a static IP.

If you keep a fixed IP in the template, every clone will inherit it and you will get network conflicts.

## Check current netplan
Inside the VM:
```bash
cat /etc/netplan/*.yaml
```

If you see static IPs or MAC-based matching, replace with a minimal DHCP config.

### Recommended netplan for template
```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
```

## Important pitfall
Do **not** keep:
```yaml
match:
  macaddress: ...
```

Why:
- clones get different MAC addresses
- MAC-bound config will break networking in clones

Apply:
```bash
sudo netplan apply
```

### Expected effect
Your SSH session may drop because the static IP disappears and DHCP assigns a new one.

That is normal.

---

# 14. Verify the VM after switching to DHCP

Reconnect using the new DHCP IP (found via console or guest agent if available).

Check:
```bash
hostnamectl
ip a
cloud-init status --long
systemctl status ssh --no-pager
sudo apt update
```

You want:
- generic hostname (or acceptable template hostname)
- DHCP network working
- cloud-init status finished
- SSH working
- package management working

---

# 15. Clean the machine before converting to template

## Clean machine-id
Inside the VM:

```bash
sudo truncate -s 0 /etc/machine-id
sudo rm /var/lib/dbus/machine-id
```

### Why
Each clone must generate its own unique machine identity.

### Important
Do **not** reboot after this.

If you reboot before templating, the machine-id may be regenerated and all clones may inherit it.

---

## Clean cloud-init state
```bash
sudo cloud-init clean
```

### Why
You do not want the template to keep “already initialized” cloud-init state.

---

## Optional light cleanup
```bash
history -c
rm ~/.bash_history
```

You can also clear unnecessary logs if you want, but it is not always essential.

---

# 16. Shut down the VM cleanly

Inside the VM:
```bash
sudo shutdown -h now
```

or from Proxmox host:
```bash
sudo qm shutdown 100
```

Wait until the VM is fully stopped.

---

# 17. Convert to template

On the **Proxmox host**:

```bash
sudo qm template 100
```

If successful, Proxmox will rename disks from:
```text
vm-100-disk-X
```
to:
```text
base-100-disk-X
```

This means the VM is now a true Proxmox template.

---

# 18. Clone from the template

## Example: control plane
```bash
sudo qm clone 100 101 --name k3s-cp
```

Then customize:
```bash
sudo qm set 101 --ciuser younes
sudo qm set 101 --sshkey /home/younes/id_ed25519_homelab.pub
sudo qm set 101 --ipconfig0 ip=192.168.1.20/24,gw=192.168.1.254
sudo qm set 101 --memory 3072
sudo qm start 101
```

## Example: worker
```bash
sudo qm clone 100 102 --name k3s-worker-1
```

Then customize:
```bash
sudo qm set 102 --ciuser younes
sudo qm set 102 --sshkey /home/younes/id_ed25519_homelab.pub
sudo qm set 102 --ipconfig0 ip=192.168.1.21/24,gw=192.168.1.254
sudo qm set 102 --memory 2048
sudo qm start 102
```

---

# 19. Golden template checklist

Before declaring success, confirm the template is:

- [x] Ubuntu cloud image imported
- [x] boot disk attached on `scsi0`
- [x] cloud-init disk attached on `ide2`
- [x] boot order set to `scsi0`
- [x] SSH works during validation phase
- [x] cloud-init works
- [x] netplan reverted to DHCP
- [x] no MAC-bound config in netplan
- [x] machine-id cleaned
- [x] `cloud-init clean` executed
- [x] VM shut down cleanly
- [x] converted with `qm template`

Recommended bonus:
- [x] `qemu-guest-agent` installed and functional

---

# 20. Common mistakes and lessons learned

## Mistake: using the wrong machine for a command
Always ask:
```text
Which machine am I on right now?
```

- `qm ...` commands run on **Proxmox host**
- SSH config / private keys live on **your laptop**
- cloud-init executes in the **guest VM**

---

## Mistake: keeping static IP in the template
This creates IP conflicts in clones.

### Correct model
- template = DHCP / neutral
- clone = static IP via `qm set` / Terraform

---

## Mistake: keeping MAC matching in netplan
This breaks clones because cloned VMs have different MAC addresses.

---

## Mistake: not resizing clones
The Ubuntu cloud image root disk starts small.

### Symptom
`k3s` fails with:
```text
no space left on device
```

### Fix
Resize the clone disk:
```bash
sudo qm stop 101
sudo qm resize 101 scsi0 30G
sudo qm start 101
```

Then inside the VM verify:
```bash
df -h
```

---

## Mistake: too little RAM
1 GB may boot Ubuntu, but is too small for a realistic Kubernetes control plane.

### Recommended minimums
- CP: 3 GB
- Worker: 2 GB

---

## Mistake: assuming IP = machine identity
SSH host identity is tied to the **SSH host key**, not to the IP.

If a new VM gets the same IP, SSH may warn:
```text
REMOTE HOST IDENTIFICATION HAS CHANGED
```

This is expected when the machine changed.

Fix:
```bash
ssh-keygen -R <ip>
```

---

## Mistake: trying to use the Proxmox host's `authorized_keys` as a conceptual source of truth
For `qm set --sshkey`, use a clean `.pub` file copied to the Proxmox host.

Technically `authorized_keys` may work if it contains only the intended key, but a dedicated `.pub` file is cleaner.

---

# 21. Conceptual model to remember

## Template phase
Build a generic, clean base image.

## Clone phase
Inject:
- hostname
- static IP
- RAM / CPU
- role-specific settings

## Provisioning phase
Install:
- k3s
- apps
- monitoring
- whatever the VM is meant to run

### In one sentence
**Template = neutral OS image  
Clone = infrastructure identity  
Provisioning = workload and role**

---

# 22. Minimal command summary

## Import image
```bash
sudo qm importdisk 100 /root/noble-server-cloudimg-amd64.img local-lvm
```

## Attach disk and cloud-init
```bash
sudo qm set 100 --scsi0 local-lvm:vm-100-disk-1
sudo qm set 100 --ide2 local-lvm:cloudinit
sudo qm set 100 --boot order=scsi0
```

## Validation settings
```bash
sudo qm set 100 --ciuser younes
sudo qm set 100 --sshkey /home/younes/id_ed25519_homelab.pub
sudo qm set 100 --ipconfig0 ip=192.168.1.20/24,gw=192.168.1.254
```

## Template cleanup inside VM
```bash
sudo truncate -s 0 /etc/machine-id
sudo rm /var/lib/dbus/machine-id
sudo cloud-init clean
sudo shutdown -h now
```

## Convert to template
```bash
sudo qm template 100
```

## Clone and customize
```bash
sudo qm clone 100 101 --name k3s-cp
sudo qm set 101 --ciuser younes
sudo qm set 101 --sshkey /home/younes/id_ed25519_homelab.pub
sudo qm set 101 --ipconfig0 ip=192.168.1.20/24,gw=192.168.1.254
sudo qm set 101 --memory 3072
sudo qm start 101
```

---

# 23. Final takeaway

If you remember only one thing, remember this:

> **A good golden template is generic.  
> Identity, networking, and sizing belong to the clone stage, not to the template itself.**

That separation is what makes the workflow:
- reproducible
- scalable
- automatable
- ready for Terraform / Ansible later