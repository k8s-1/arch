https://wiki.archlinux.org/title/Installation_guide

# Disk Layout
/boot   - 1GB   efi
/swap   - 16GB  encrypted linux-swap
/       -       encrypted ext4

# Login flow
LUKS password -> autologin + swaylock if needed

# First prepare boot medium
# Disable UEFI secure boot
# Launch instaler
# Connect to WiFi with `iwctl` if needed:
iwctl
[iwd]# device list
[iwd]# station name scan
[iwd]# station name get-networks
[iwd]# station name connect SSID OR [iwd]# station name connect-hidden SSID


# Partition
fdisk -l
## Delete existing partition tables and labels
cryptsetup erase /dev/sdX      # remove LUKS headers
wipefs -a /dev/sdX             # remove filesystem/partition metadata

lsblk
fdisk /dev/sdX

## Create GPT partition table
g
## /boot
n <enter> <enter> +1G
t 1 1
## /swap
n <enter> <enter> +16G
t 2 19
## /
n <enter> <enter> <enter>
w

fdisk -l

# Encrypt root
## https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition
cryptsetup -v luksFormat /dev/root_partition
cryptsetup open /dev/root_partition root

# Format partitions
mkfs.fat -F 32 /dev/efi_system_partition
mkfs.ext2 -L cryptswap /dev/swap_partition 1M
mkswap /dev/swap_partition
mkfs.ext4 /dev/mapper/root

# Mount FS
mount /dev/mapper/root /mnt
# (!) verify it works:
# umount /mnt
# cryptsetup close root
# cryptsetup open /dev/sdaX root
# mount /dev/mapper/root /mnt
mount --mkdir /dev/efi_system_partition /mnt/boot

# Encrypt swap with ephemeral key - (!) ensure hibernate is disabled -> this setup does not support hibernate
## https://wiki.archlinux.org/title/Dm-crypt/Swap_encryption#UUID_and_LABEL
We first create a small label to identify the swap partition:
blkid /dev/swap_partition

/etc/crypttab
# <name> <device>         <password>    <options>
swap     LABEL=cryptswap  /dev/urandom  swap,offset=2048,cipher=aes-xts-plain64,size=512,sector-size=4096
/etc/fstab
# <filesystem>    <dir>  <type>  <options>  <dump>  <pass>
/dev/mapper/swap  none   swap    defaults   0       0

# Turn on swap
swapon /dev/swap_partition

# Install base packages
pacstrap -K /mnt base linux linux-firmware

# Configure system
<!-- mkdir -p /mnt/etc -->
<!-- genfstab -U /mnt >> /mnt/etc/fstab -->
<!-- vim /mnt/etc/fstab      -> change swap entry UUID=..... to /dev/mapper/swap -->

arch-chroot /mnt

# Set the timezone, adjust as needed (!)
ln -sf /usr/share/zoneinfo/Area/Location /etc/localtime

# Set the Hardware Clock from the System Clock
hwclock --systohc

# To prevent clock drift and ensure accurate time, set up time synchronization using a Network Time Protocol (NTP) client such as systemd-timesyncd. 
timedatectl set-ntp true
timedatectl status

# Uncomment the UTF-8 locales you will be using.
vim /etc/locale.gen

# Generate the locales:
locale-gen

/etc/locale.conf
```
LANG=en_US.UTF-8
```

/etc/hostname
```
yourhostname # 1-64 chars, lowercase, allowed chars: a-z, 0-9, -
```
NOTE: good hostnames are generic, unrevealing, and short (RFC standard):
fox1
green2
chair3

# Set secure root password
passwd

<!-- https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition_with_TPM2_and_Secure_Boot -->
# Configure initramfs image
`/etc/mkinitcpio.conf`
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)

<!-- Do not regenerate the initramfs yet, as the /boot/EFI/Linux directory needs to be created by the boot loader installer first. -->
# Configure systemd-boot bootloader
Copy the systemd-boot UEFI boot manager to the ESP, create a UEFI boot entry for it and set it as the first in the UEFI boot order:
bootctl install
lsblk -f

Set kernel parameter:
cryptdevice=UUID=device-UUID:root root=/dev/mapper/root

Add a pacman hook to update the bootloader in /efi when there is an update:
/etc/pacman.d/hooks/95-systemd-boot.hook
```
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Upgrading systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service
```

Configure loader - a basic loader configuration file is located at /usr/share/systemd/bootctl/loader.conf:
esp/loader/loader.conf
```
default  arch.conf
timeout  4
console-mode max
editor   no
```

Add loaders; systemd-boot will search for .conf files in /loader/entries/ on the EFI system partition
```
esp/loader/entries/arch.conf

title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx rw
```

NOTE: Unified kernel images (UKIs) in esp/EFI/Linux/uki.efi are automatically sourced by systemd-boot, and do not need an entry in esp/loader/entries

# Generate initramfs
mkinitcpio -P

# REBOOT
exit
umount -R /mnt # helps notice any busy partition, troubleshoot with fuser
reboot

sudo systemctl enable --now fwupd.service
# UPDATE FIRMWARE - DO THIS MANUALLY YEARLY
pacman -S fwupd
fwupdmgr get-devices
fwupdmgr refresh
fwupdmgr get-updates
fwupdmgr update

# Disable hibernate
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

/etc/systemd/logind.conf
```
...
[Login] 
HandleLidSwitch=ignore 
HandleLidSwitchDocked=ignore
```
systemctl restart systemd-logind


# UKI hash monitor
Compute a hash of UKI when it’s known-good:

mkdir -p /etc/ukisums
sha256sum esp/EFI/Linux/arch.uki > /etc/ukisums/arch.uki.sha256

Run integrity check before maintenance:
sha256sum -c /etc/ukisums/arch.uki.sha256
<system-update>
<update-hash>

