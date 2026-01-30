Basic LUKS + password, no TPM crap

https://wiki.archlinux.org/title/Dm-crypt/Specialties#Securing_the_unencrypted_boot_partition



# wipe partition headers
cryptsetup erase /dev/sda      # remove LUKS headers
wipefs -a /dev/sda             # remove filesystem/partition metadata


# ROOT PARITION

# encrypt luks device
cryptsetup -v luksFormat /dev/sda2
cryptsetup open /dev/sda2 root

# create fs
mkfs.ext4 /dev/mapper/root

# mount
mount /dev/mapper/root /mnt

# verify
umount /mnt
cryptsetup close root
cryptsetup open /dev/sda2 root
mount /dev/mapper/root /mnt


# EFI PARTITION
mkfs.fat -F32 /dev/sda1
mount --mkdir /dev/sda1 /mnt/boot



# Configure mkinitcpio
If using the default systemd-based initramfs, add the keyboard and sd-encrypt hooks to mkinitcpio.conf. If you use a non-US console keymap or a non-default console font, additionally add the sd-vconsole hook.

HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)

Then follow https://wiki.archlinux.org/title/Installation_guide#Initramfs, re-create initramfs:
`mkinitcpio -P`



# Configure systemd-boot bootloader:
Copy the systemd-boot UEFI boot manager to the ESP, create a UEFI boot entry for it and set it as the first in the UEFI boot order:
bootctl install


lsblk -f

set kernel parameter:
cryptdevice=UUID=device-UUID:root root=/dev/mapper/root



Add a pacman hook to update the bootloader in /efi when there is an update:
/etc/pacman.d/hooks/95-systemd-boot.hook
```
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Gracefully upgrading systemd-boot...
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





# TODO (still configure UEFI password + disable USB)



# TODO implement some post-login hash monitor
You compute a hash of your UKI (or kernel + initramfs) when it’s known-good:
sha256sum /efi/EFI/Linux/arch-linux.efi > /efi/EFI/Linux/arch-linux.efi.sha256
Later, before booting, you or a script can verify:
sha256sum -c /efi/EFI/Linux/arch-linux.efi.sha256
