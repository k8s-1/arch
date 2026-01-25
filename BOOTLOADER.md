# Bootloader + Secure Boot
https://wiki.archlinux.org/title/Systemd-boot

# The Golden Rule
1. Never enable Secure Boot until you have successfully booted a signed loader using your own keys.
2. You can brick a system beyond recovery when:
    - Factory PKs are removed from UEFI (!)
3. Set a UEFI admin password
4. Also configure TPM to ensure tamper-resistance

# first, disable "Secure Boot"

Use bootctl to install systemd-boot to the <esp>: 
```
arch-chroot -S /mnt     # systemd chroot
bootctl install
```

- The UEFI boot entry will be called "Linux Boot Manager" and will point to \EFI\systemd\systemd-bootx64.efi
- When running bootctl install, systemd-boot will try to locate the <esp> at /efi, /boot, and /boot/efi

Configure automatic update of systemd boot EFI executable:

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

Configure automatic resigning of boot entries:

/etc/pacman.d/hooks/80-secureboot.hook
```
[Trigger]
Operation = Install
Operation = Upgrade
Type = Path
Target = usr/lib/systemd/boot/efi/systemd-boot*.efi

[Action]
Description = Signing systemd-boot EFI binary for Secure Boot
When = PostTransaction
Exec = /bin/sh -c 'while read -r f; do sbctl sign -s -o "${f}.signed" "$f"; done'
Depends = sh
NeedsTargets
```


# configure the loader
`<esp>/loader/loader.conf` ---> see basic config file at /usr/share/systemd/bootctl/loader.conf
default  arch.conf
timeout  4
console-mode max
editor   no



# adding loader
Automatic when mkinitcpio generates UKI (unified kernel image)


# generate keys
pacman -S sbctl efibootmgr
sbctl create-keys

# sign existing bootloader
sbctl status
sbctl sign /boot/efi/EFI/arch/grubx64.efi
sbctl verify

# test boot with signed loader
---> Reboot without enabling Secure Boot.

# enroll keys
sbctl enroll-keys

# sign everything
sbctl sign-all
sbctl verify

# enable Secure Boot
---> go to firmware (F2, DEL, ESC)
---> leave it in user mode (vs setup, usually automatic)
