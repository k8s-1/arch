Basic LUKS + password, no TPM crap

# TODO (still configure UEFI password + disable USB)

✔ LUKS root
✔ UKI generated from encrypted /boot
✔ Minimal ESP
✔ Optional post‑login hash checks

- encrypt swap
- encrypt root
- UKI https://wiki.archlinux.org/title/Unified_kernel_image






# TODO implement some post-login hash monitor
You compute a hash of your UKI (or kernel + initramfs) when it’s known-good:
sha256sum /efi/EFI/Linux/arch-linux.efi > /efi/EFI/Linux/arch-linux.efi.sha256
Later, before booting, you or a script can verify:
sha256sum -c /efi/EFI/Linux/arch-linux.efi.sha256









1. Partition Layout (example)

Suppose a single NVMe disk (/dev/nvme0n1):

Partition	Type	Size	Notes
/dev/nvme0n1p1	EFI System Partition	300–500 MB	FAT32, mounted at /efi
/dev/nvme0n1p2	LUKS container	rest of disk	Contains root (/), including /boot as a directory

Important: /boot is not a separate partition, it’s just /boot inside root.



ESP (unlocked by firmware)
├── EFI
│   └── systemd-bootx64.efi
│   └── loader
│       ├── loader.conf
│       └── entries
│           └── arch.conf
│
Encrypted root (unlocked via LUKS)
├── /boot
│   ├── vmlinuz-linux
│   └── initramfs-linux.img


2. 
Encrypt root partition:
cryptsetup luksFormat /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 cryptroot

Then create root FS:
mkfs.ext4 /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt

3.
Create EFI partition:
mkfs.fat -F32 /dev/nvme0n1p1
mkdir /mnt/efi
mount /dev/nvme0n1p1 /mnt/efi

4.
Install base arch:
pacstrap /mnt base linux linux-firmware systemd
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

5.
Prepare UKI:
Ensure mkinitcpio has encrypt hook

Edit /etc/mkinitcpio.conf:
HOOKS=(base udev autodetect modconf block keyboard encrypt filesystems)


mkinitcpio -P


Install systemd-boot:
bootctl --path=/efi install


Create loader config /efi/loader/loader.conf:
default arch.conf
timeout 3
editor  no

6
Create loader entry /efi/loader/entries/arch.conf:

title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options cryptdevice=UUID=$(blkid -s UUID -o value /dev/nvme0n1p2):cryptroot root=/dev/mapper/cryptroot rw
