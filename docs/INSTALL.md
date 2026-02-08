https://wiki.archlinux.org/title/Installation_guide

# Disk Layout
/boot   - 1GB   efi
/swap   - 16GB  encrypted linux-swap
/       -       encrypted ext4

# Pre-install
- Prepare boot medium
- Disable UEFI secure boot
- Launch iso from usb
- Connect to WiFi with `iwctl` if needed:

iwctl
[iwd]# device list
[iwd]# station name scan
[iwd]# station name get-networks
[iwd]# station name connect SSID
