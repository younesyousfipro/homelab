# Setup External SSD as NAS-like Storage (Backup + NFS)

## Context

I do not have a dedicated NAS yet, but I still need shared storage and backup capabilities in my homelab.  
I use an external SSD connected to a Linux machine as a temporary NAS-like storage.

Goal:
- Local backup storage (VM backups)
- Shared storage (NFS) for other machines

---

## Key Concepts

- A **filesystem (ext4)** is how data is organized on a disk
- A **mount point** is a directory where a disk becomes accessible (e.g., `/mnt/data`)
- **NFS (Network File System)** allows a remote machine to access a folder as if it were local
- Storage is split into:
  - `/mnt/backup` → local only (safe for backups)
  - `/mnt/data` → shared over the network (used by other machines)

---

## 1. Identify disk

List all disks and find the external SSD (here `/dev/sdb`):

`lsblk`

---

## 2. Create partition table

Initialize the disk with a GPT layout:

`sudo parted /dev/sdb --script mklabel gpt`

---

## 3. Create partitions

Split the disk:
- 70% for backups
- 30% for shared data

`sudo parted /dev/sdb --script mkpart primary ext4 1MiB 70%`  
`sudo parted /dev/sdb --script mkpart primary ext4 70% 100%`

---

## 4. Format

Create a filesystem (ext4) on each partition:

`sudo mkfs.ext4 /dev/sdb1`  
`sudo mkfs.ext4 /dev/sdb2`

---

## 5. Create mount points

Create directories where disks will be accessible:

`sudo mkdir -p /mnt/backup`  
`sudo mkdir -p /mnt/data`

---

## 6. Mount

Attach partitions to the filesystem:

`sudo mount /dev/sdb1 /mnt/backup`  
`sudo mount /dev/sdb2 /mnt/data`

Now:
- `/mnt/backup` → first partition
- `/mnt/data` → second partition

---

## 7. Persist mounts

Without this step, mounts are lost after reboot.

Get UUIDs (unique disk identifiers):

`sudo blkid`

Edit fstab:

`sudo nano /etc/fstab`

Add:

`UUID=XXX /mnt/backup ext4 defaults,nofail 0 2`  
`UUID=YYY /mnt/data   ext4 defaults,nofail 0 2`

- `nofail` → system still boots if disk is missing

Apply:

`sudo mount -a`

---

## 8. Setup NFS server (on opti1)

Install NFS server:

`sudo apt install nfs-kernel-server -y`

Configure shared folder:

`sudo nano /etc/exports`

Add:

`/mnt/data 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)`

Meaning:
- `rw` → read/write
- `sync` → safer writes
- `no_root_squash` → allow root access (simplifies homelab)

Apply config:

`sudo exportfs -a`  
`sudo systemctl restart nfs-kernel-server`

---

## 9. Permissions

Allow write access to shared folder:

`sudo chmod 777 /mnt/data`

(OK for homelab, not for production)

---

## 10. Setup NFS client (on wyse)

Install NFS client:

`sudo apt install nfs-common -y`

Create mount point:

`sudo mkdir -p /mnt/data`

Mount remote storage:

`sudo mount 192.168.1.11:/mnt/data /mnt/data`

Now `/mnt/data` behaves like a local folder but is actually remote.

---

## 11. Persist NFS mount

Ensure mount survives reboot:

`sudo nano /etc/fstab`

Add:

`192.168.1.11:/mnt/data /mnt/data nfs defaults,nofail,_netdev 0 0`

- `_netdev` → wait for network before mounting

Apply:

`sudo mount -a`

---

## 12. Test

On client:

`touch /mnt/data/test.txt`  
`ls /mnt/data`

On server:

`ls /mnt/data`

If the file appears on both → setup is working.

---

## Result

- `/mnt/backup` → local backup storage (not shared)
- `/mnt/data` → shared storage over network (NFS)

---

## Important Notes

- If NFS is not mounted, writing to `/mnt/data` writes locally → dangerous
- Always verify mount with:

`findmnt /mnt/data`

- `lost+found` is a normal system directory → do not delete# Setup External SSD as NAS-like Storage (Backup + NFS)

## Context

I do not have a dedicated NAS yet, but I still need shared storage and backup capabilities in my homelab.  
I use an external SSD connected to a Linux machine as a temporary NAS-like storage.

Goal:
- Local backup storage (VM backups)
- Shared storage (NFS) for other machines

---

## Key Concepts

- A **filesystem (ext4)** is how data is organized on a disk
- A **mount point** is a directory where a disk becomes accessible (e.g., `/mnt/data`)
- **NFS (Network File System)** allows a remote machine to access a folder as if it were local
- Storage is split into:
  - `/mnt/backup` → local only (safe for backups)
  - `/mnt/data` → shared over the network (used by other machines)

---

## 1. Identify disk

List all disks and find the external SSD (here `/dev/sdb`):

`lsblk`

---

## 2. Create partition table

Initialize the disk with a GPT layout:

`sudo parted /dev/sdb --script mklabel gpt`

---

## 3. Create partitions

Split the disk:
- 70% for backups
- 30% for shared data

`sudo parted /dev/sdb --script mkpart primary ext4 1MiB 70%`  
`sudo parted /dev/sdb --script mkpart primary ext4 70% 100%`

---

## 4. Format

Create a filesystem (ext4) on each partition:

`sudo mkfs.ext4 /dev/sdb1`  
`sudo mkfs.ext4 /dev/sdb2`

---

## 5. Create mount points

Create directories where disks will be accessible:

`sudo mkdir -p /mnt/backup`  
`sudo mkdir -p /mnt/data`

---

## 6. Mount

Attach partitions to the filesystem:

`sudo mount /dev/sdb1 /mnt/backup`  
`sudo mount /dev/sdb2 /mnt/data`

Now:
- `/mnt/backup` → first partition
- `/mnt/data` → second partition

---

## 7. Persist mounts

Without this step, mounts are lost after reboot.

Get UUIDs (unique disk identifiers):

`sudo blkid`

Edit fstab:

`sudo nano /etc/fstab`

Add:

`UUID=XXX /mnt/backup ext4 defaults,nofail 0 2`  
`UUID=YYY /mnt/data   ext4 defaults,nofail 0 2`

- `nofail` → system still boots if disk is missing

Apply:

`sudo mount -a`

---

## 8. Setup NFS server (on opti1)

Install NFS server:

`sudo apt install nfs-kernel-server -y`

Configure shared folder:

`sudo nano /etc/exports`

Add:

`/mnt/data 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)`

Meaning:
- `rw` → read/write
- `sync` → safer writes
- `no_root_squash` → allow root access (simplifies homelab)

Apply config:

`sudo exportfs -a`  
`sudo systemctl restart nfs-kernel-server`

---

## 9. Permissions

Allow write access to shared folder:

`sudo chmod 777 /mnt/data`

(OK for homelab, not for production)

---

## 10. Setup NFS client (on wyse)

Install NFS client:

`sudo apt install nfs-common -y`

Create mount point:

`sudo mkdir -p /mnt/data`

Mount remote storage:

`sudo mount 192.168.1.11:/mnt/data /mnt/data`

Now `/mnt/data` behaves like a local folder but is actually remote.

---

## 11. Persist NFS mount

Ensure mount survives reboot:

`sudo nano /etc/fstab`

Add:

`192.168.1.11:/mnt/data /mnt/data nfs defaults,nofail,_netdev 0 0`

- `_netdev` → wait for network before mounting

Apply:

`sudo mount -a`

---

## 12. Test

On client:

`touch /mnt/data/test.txt`  
`ls /mnt/data`

On server:

`ls /mnt/data`

If the file appears on both → setup is working.

---

## Result

- `/mnt/backup` → local backup storage (not shared)
- `/mnt/data` → shared storage over network (NFS)

---

## Important Notes

- If NFS is not mounted, writing to `/mnt/data` writes locally → dangerous
- Always verify mount with:

`findmnt /mnt/data`
