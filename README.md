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
# Connect to WiFi with `iwctl` if needed


# Partition
fdisk -l
## Overwrite existing data
pv /dev/zero -o /dev/sdX
## Delete partition tables and labels
wipefs -a /dev/sdX

lsblk
fdisk /dev/example

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

# Encrypt swap with ephemeral key - (!) ensure hibernate is disabled
## https://wiki.archlinux.org/title/Dm-crypt/Swap_encryption#UUID_and_LABEL
mkfs.ext2 -L cryptswap /dev/swap_partition 1M
blkid /dev/swap_partition

/etc/crypttab
# <name> <device>         <password>    <options>
swap     LABEL=cryptswap  /dev/urandom  swap,offset=2048,cipher=aes-xts-plain64,size=512,sector-size=4096

(we configure the fstab entry for this at a later point)

# Encrypt root
## https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition
cryptsetup -v luksFormat /dev/root_partition
cryptsetup open /dev/root_partition root

# Format partitions
mkfs.fat -F 32 /dev/efi_system_partition
mkswap /dev/swap_partition
mkfs.ext4 /dev/mapper/root


# Mount FS
mount /dev/mapper/root /mnt
# (!) verify it works:
# umount /mnt
# cryptsetup close root
# cryptsetup open /dev/sda2 root
# mount /dev/mapper/root /mnt
mount --mkdir /dev/efi_system_partition /mnt/boot






# Turn on swap
swapon /dev/swap_partition

# Install base packages
pacstrap -K /mnt base linux linux-firmware

# Configure system
<!-- mkdir -p /mnt/etc -->
<!-- genfstab -U /mnt >> /mnt/etc/fstab -->
<!-- vim /mnt/etc/fstab      -> change swap entry UUID=..... to /dev/mapper/swap -->

arch-chroot /mnt

ln -sf /usr/share/zoneinfo/Area/Location /etc/localtime

hwclock --systohc #TODO: To prevent clock drift and ensure accurate time, set up time synchronization using a Network Time Protocol (NTP) client such as systemd-timesyncd. 

edit /etc/locale.gen and uncomment the UTF-8 locales you will be using.
Generate the locales:
locale-gen

/etc/locale.conf
LANG=en_US.UTF-8

/etc/hostname
yourhostname # 1-64 chars, lowercase, allowed chars: a-z, 0-9, -
Good hostnames are generic, unrevealing, and short:
dev01
brown01
oak01

# Set secure root password
passwd



# (!!!) CONFIGURE BOOTLOADER



https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition_with_TPM2_and_Secure_Boot
# Configure initramfs image
`/etc/mkinitcpio.conf`
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)

Do not regenerate the initramfs yet, as the /boot/EFI/Linux directory needs to be created by the boot loader installer first.


AFTER installing boot loader, create initramfs, there's a pacman hook that runs this on kernel update, but it doesn't when only config is updated:
mkinitcpio -P






# REBOOT
exit
umount -R /mnt # helps notice any busy partition, troubleshoot with fuser
reboot

# TODO
Disable hibernate


# Security Setup
Layer	        Choice
Disk            encryption	LUKS (manual passphrase)
Swap	        Encrypted, random key
TPM	            ❌ Not used
Secure Boot 	✅ Enabled
Kernel signing	sbctl
BIOS password	Supervisor/Admin only
Bootloader      GRUB
Login	        LUKS password + autologin
Screen lock	    swaylock + password

This protects against:
Laptop theft
Evil-Maid attacks
Bootloader tampering


consider:
secure grub -> grub password + signed kernels https://www.gnu.org/software/grub/manual/grub/html_node/Using-GPG_002dstyle-digital-signatures.html
                                              https://www.gnu.org/software/grub/manual/grub/html_node/Using-appended-signatures.html
lynis (auditing)
https://wiki.archlinux.org/title/Security
swaylock
pam
harden kernel (safe params only)
umask
browser security
clamav + chkrootkit/rkhunter + system tray notify
restrict usb access
disable ssh
audit -> https://wiki.archlinux.org/title/Audit_framework
apparmor (few select profiles for browser, pdf-reader)
harden systemd services (e.g. docker.d)


https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition_with_TPM2_and_Secure_Boot
