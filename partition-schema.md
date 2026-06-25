# Manual partitioning steps — Fedora installer (Anaconda)

Recreates this layout: root + home on a 2-disk btrfs pool spanning both NVMe
drives, `/boot` + `/boot/efi` on NVMe (not HDD), and a separate bulk-storage
btrfs pool spanning both HDDs mounted at `/mnt/data`.

Hardware assumed: 2x NVMe (~2TB each), 2x HDD (~4TB each).

## 1. Installation Destination screen

- Select all four disks (both NVMe, both HDD) as installation targets.
- Choose **"Storage Configuration: Custom"** (manual partitioning), click Done.

## 2. Manual partitioning screen — add each mountpoint

Don't use the "click here to create them automatically" link — add each
mountpoint by hand with the **+** button so they land on the right disks.

For each row below: click **+**, enter the mountpoint and desired capacity,
click "Add mount point", then select it in the list and use the **Device
Type** dropdown + **Modify...** button (next to "Device(s)") to pin it to the
correct disk(s) and set the filesystem.

| Mountpoint   | Size   | Device Type | File System | Disk(s) |
|--------------|--------|-------------|-------------|---------|
| `/boot/efi`  | 600 MiB | Standard Partition | EFI System Partition | NVMe #1 only |
| `/boot`      | 2 GiB   | Standard Partition | ext4 | NVMe #1 only (same disk as `/boot/efi`) |
| `/`          | remaining space | Btrfs | btrfs | both NVMe disks |
| `/home`      | (shares the `/` btrfs volume) | Btrfs | btrfs | same volume as `/` |
| `/mnt/data`  | remaining space | Btrfs | btrfs | both HDD disks |

Notes on each row:

- **`/boot/efi` and `/boot`**: must go on the same single NVMe drive (pick
  one and remember which — call it "NVMe #1"). Use Modify... → uncheck the
  other three disks so only NVMe #1 is selected.
- **`/`**: set Device Type to Btrfs first, then Modify... → select both NVMe
  disks, RAID Level "None" (single-disk-equivalent striping across the set —
  this is the closest GUI option to the `-d single` profile used originally).
  Anaconda will create one btrfs volume across both NVMe drives.
- **`/home`**: after creating `/`, add a second mountpoint `/home`. In its
  Device Type dropdown pick the **existing Btrfs volume** you just created
  for `/` (it'll appear as an option once a btrfs volume already exists)
  rather than creating a new one — this makes `/home` a subvolume of the same
  pool instead of a separate filesystem.
- **`/mnt/data`**: set Device Type to Btrfs, Modify... → select both HDDs,
  RAID Level "RAID1". The installer doesn't expose a mixed single-data/
  raid1-metadata profile — RAID1 here mirrors data across both disks (more
  redundant than the original setup, at half the usable capacity). If you
  want the original single-data/raid1-metadata profile instead (full combined
  capacity, metadata-only redundancy), pick RAID Level "None" here in the
  installer and run this once after first boot:
  ```
  sudo btrfs balance start -mconvert=raid1 /mnt/data
  ```

## 3. Finish

- Click "Done", accept the summary, let Anaconda write the partitions and
  proceed with install as normal.

## Result

- One btrfs volume across both NVMe drives, label `fedora`, containing the
  `root` and `home` subvolumes (mounted at `/` and `/home`).
- `/boot` (ext4) and `/boot/efi` (vfat/ESP) both on a single NVMe drive, never
  on a spinning disk — this is what keeps boot fast (no HDD spin-up wait
  before GRUB/kernel can load).
- One btrfs volume across both HDDs, label `bulkdata`, mounted at `/mnt/data`,
  fully decoupled from root/boot so it can never gate boot time.
- fstab entries will be UUID-based automatically; `/dev/nvme0n1` vs
  `/dev/nvme1n1` letters can flip between boots (PCIe enumeration order), so
  don't rely on those names later — use UUIDs or `/dev/disk/by-id/`.
