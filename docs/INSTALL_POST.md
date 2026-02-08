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

