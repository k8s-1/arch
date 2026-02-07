# Encrypted swap
swapoff /dev/sda2
mkfs.ext2 -L cryptswap /dev/sda2 1M

vim /etc/crypttab -> uncomment + adjust swap line

/etc/crypttab
```
# <name> <device>         <password>    <options>
swap      LABEL=cryptswap    /dev/urandom   swap,cipher=aes-xts-plain64,size=512,sector-size=4096
```

/etc/fstab
```
# <filesystem>    <dir>  <type>  <options>  <dump>  <pass>
/dev/mapper/swap  none   swap    defaults   0       0
```

disable sleep/hibernate:
/etc/systemd/sleep.conf.d/disable-sleep.conf
[Sleep]
AllowSuspend=no
AllowHibernation=no
AllowHybridSleep=no
AllowSuspendThenHibernate=no

# Bootloader automatic update
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

# Power management
pacman -S tlp
systemctl enable tlp.service

/etc/tlp.conf
```
DEVICES_TO_ENABLE_ON_STARTUP="wifi"
RUNTIME_PM_ON_AC=auto
USB_AUTOSUSPEND=0
```

# Configure non-root user
useradd -mG wheel user
passwd user
EDITOR=vim visudo
+ %wheel ALL=(ALL) ALL
passwd --lock root

# Other packages
CPU microcode updates—amd-ucode or intel-ucode—for hardware bug and security fixes

packages for accessing documentation in man pages:
man-db
man-pages

neovim

sway

reflector # update pacman mirrors to latest/fast mirrors



# sway
~/.bashrc
```
if [ -z "$WAYLAND_DISPLAY" ] && [ -n "$XDG_VTNR" ] && [ "$XDG_VTNR" -eq 1 ] ; then
    exec sway
fi
...
```

It is possible to tweak specific input device configurations. For example, to enable tap-to-click and natural scrolling for all touchpads:
~/.config/sway/config
input type:touchpad {
    tap enabled
    natural_scroll enabled
}

