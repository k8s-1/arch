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


<!-- https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition_with_TPM2_and_Secure_Boot -->
# Configure initramfs image
`/etc/mkinitcpio.conf`
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)

<!-- Do not regenerate the initramfs yet, as the /boot/EFI/Linux directory needs to be created by the boot loader installer first. -->

# (!!!) CONFIGURE BOOTLOADER

# Generate initramfs
<!-- AFTER installing boot loader, create initramfs, there's a pacman hook that runs this on kernel update, but it doesn't when only config is updated: -->
mkinitcpio -P

# SECURE BOOT
# sign existing bootloader
sbctl status
sbctl create-keys
<!-- Enroll your keys to UEFI, along with Microsoft's and firmware vendor keys, to the UEFI: -->
sbctl enroll-keys -m -f
sbctl status
sbctl verify
# Use the output from sbctl verify to see what needs to be signed
# EXAMPLE
sbctl sign -s /boot/vmlinuz-linux
sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI


# REBOOT
exit
umount -R /mnt # helps notice any busy partition, troubleshoot with fuser
reboot

# Verify secure boot status:
bootctl

systemctl reboot --firmware-setup
<!-- # test boot with signed loader -->
# enable secure boot
- go to firmware (F2, DEL, ESC)
- leave it in user mode (vs setup, usually automatic)
- also set a firmware admin password


# ENABLE TPM
# recovery key --- write down the output, it's a LUKS key slot to decrypt the disk if TPM fails (though if it happens, ask why first), keep offline and safe
systemd-cryptenroll /dev/sda2 --recovery-key

systemd-cryptenroll /dev/sda2 --wipe-slot=empty --tpm2-device=auto --tpm2-pcrs=7+15:sha256=0000000000000000000000000000000000000000000000000000000000000000
# (optional) add --tpm2-with-pin=yes to require an additional PIN to unlock at boot time.

# IMPORTANT
!!!! The state of PCR 7 can change if firmware certificates change, which can risk locking the user out
!!!! This can be implicitly done by firmware update -> fwupd or explicitly by rotating Secure Boot keys



reboot




# CONFIGURE FIRMWARE UPDATES
pacman -S fwupd
sbctl sign -s -o /usr/lib/fwupd/efi/fwupdx64.efi.signed /usr/lib/fwupd/efi/fwupdx64.efi

Then after each update of fwupd, the UEFI executable will be automatically signed, thanks to the sbctl pacman hook (/usr/share/libalpm/hooks/zz-sbctl.hook).

Finally, configure /etc/fwupd/fwupd.conf

```
...

[uefi_capsule]
DisableShimForSecureBoot=true
```
sudo systemctl enable --now fwupd.service
# UPDATE FIRMWARE - DO THIS MANUALLY YEARLY ~ (!! can cause tpm lockout due to PC7 change)
fwupdmgr get-devices
fwupdmgr refresh
fwupdmgr get-updates
fwupdmgr update
# in case of lockout, rebind the tpm key ---> login with recovery key:
systemd-cryptenroll /dev/root_partition --wipe-slot=auto --tpm2-device=auto --tpm2-pcrs=7+15




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




# More security
ufw
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
