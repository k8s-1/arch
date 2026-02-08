https://wiki.archlinux.org/title/Installation_guide

# Disk Layout
/boot   - 1GB   efi
/swap   - 16GB  encrypted linux-swap
/       -       encrypted ext4

# Pre-install
- Prepare live usb
- Disable UEFI secure boot
- Launch live usb
- Connect to wifi if wireless:

iwctl
[iwd]# device list
[iwd]# station name scan
[iwd]# station name get-networks
[iwd]# station name connect SSID

# Recover broken system
- boot from live usb
```
cryptsetup luksOpen /dev/sdXn root
mount /dev/mapper/root /mnt
```
