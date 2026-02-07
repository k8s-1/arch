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

# Configure disk
fdisk -l
fdisk /dev/sda
    g
    n +1G t 1
    n +4G t 19
    n <enter>
    w

# Configure mounts
https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition

cryptsetup -v luksFormat /dev/sda3
cryptsetup open /dev/sda3 root

mkfs.ext4 /dev/mapper/root
mount /dev/mapper/root /mnt

mkfs.fat -F32 /dev/sda1
mount --mkdir /dev/sda1 /mnt/boot

mkswap /dev/sda2
swapon /dev/sda2

# Install base packages
pacstrap -K /mnt base linux linux-firmware vim networkmanager

# Configure system
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
ln -sf /usr/share/zoneinfo/Area/Location /etc/localtime
hwclock --systohc
vim /etc/locale.gen # uncomment en_US.UTF-8
locale-gen

/etc/locale.conf
```
LANG=en_US.UTF-8
```

/etc/hostname
```
example1
car2
panda3
```

# Initramfs
/etc/mkinitcpio.conf, add sd-encrypt, remove sd-vconsole
```
HOOKS=(base systemd autodetect microcode modconf kms keyboard block sd-encrypt filesystems fsck)
```

mkinitcpio -P

# Set secure root password
passwd

# Bootloader
bootctl install

add bootloader kernel parameters, device-UUID refers to the UUID of the LUKS superblock:

esp/loader/entries/arch.conf
```
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options rd.luks.name=device-UUID=root root=/dev/mapper/root
```

esp/loader/loader.conf
```
default  arch.conf
timeout  4
console-mode max
editor   no
```

# REBOOT
umount -R /mnt
reboot

