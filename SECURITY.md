# SECURITY
https://wiki.archlinux.org/title/Security



# ufw
ufw default deny incoming
ufw default deny routed
ufw default allow outgoing
ufw status verbose
systemctl enable ufw
systemctl start ufw



# dns
ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
resolvectl status

/etc/systemd/resolved.conf.d/dns_servers.conf
```
# Cloudflare DNS (malware + adult content blocking)
# https://developers.cloudflare.com/1.1.1.1/ip-addresses/

[Resolve]
DNS=1.1.1.3 2606:4700:4700::1113
FallbackDNS=1.0.0.3 2606:4700:4700::1003
DNSOverTLS=yes
DNSSEC=yes
Cache=yes
```


# usbguard blocks malicious HID
https://wiki.archlinux.org/title/USBGuard
```
sudo pacman -S usbguard
sudo usbguard generate-policy > /etc/usbguard/rules.conf
sudo systemctl enable usbguard.service
sudo systemctl start usbguard.service
```
This can block btusb controllers, allow bluetooth controllers if needed (see docs).

/etc/usbguard/rules.conf    block all HID human interface device e.g. kb, mice, etc...
```
block with-interface { 03:*:* }
```

/etc/usbguard/usbguard-daemon.conf
```
RuleFile=/etc/usbguard/rules.conf
ImplicitPolicyTarget=block
PresentDevicePolicy=apply-policy
PresentControllerPolicy=keep
```

To temporarily allow a device:
```
usbguard list-devices
lsusb
sudo dmesg | grep -i 'authorized'
sudo usbguard allow-device {device_ID} # add --permanent to write to /etc/usbguard/rules.conf
```

Allow all monitors:
```
allow with-interface equals { 09:*:* }
```



# IOMMU isolation blocks DMA attacks - Direct Memory Access
IOMMU maps each device to a limited “sandboxed” memory region.

Configured at bootloader options. First check the CPU vendor:
grep -i "vendor_id" /proc/cpuinfo

/boot/loader/entries/arch.conf
```
options root=UUID=xxxx rw intel_iommu=on iommu=pt       <--- for intel
options root=UUID=xxxx rw amd_iommu=on iommu=pt         <--- for amd
```
Reboot and verify:
dmesg | grep -e DMAR -e IOMMU

Caveats:
- compatability issues (rare, but possible)




# disable UEFI USB boot




# set UEFI admin password




# umask
Remove group + others permissions, use 0027 to keep group
~/.bashrc
```
umask 0077
```




# auditd
https://wiki.archlinux.org/title/Audit_framework
TODO



# lynis auditing
Repeat this audit regularly to check how the system can be improved.
Don't try to fix everything at once and test changes (especially kernel parameters).
Turn off unused services.
```
sudo pacman -S lynis
sudo lynis audit system
sudo lynis show report
```



# swaylock + swayidle
TODO - trigger via sway shortcut
TODO https://wiki.archlinux.org/title/Sway#Idle




# pam
TODO





# harden kernel (safe params only)
TODO






# browser security
TODO




# clamav + chkrootkit/rkhunter + system tray notify
TODO




# disable ssh
TODO



# apparmor (few select profiles for services, browser, pdf-reader, docker)
TODO




# harden systemd services (e.g. docker.d)
TODO




# disable root login
sudo passwd -l root

# configure sudo
%wheel ALL=(ALL) ALL

# lock other service accounts:
sudo passwd -l nobody ftp git mail systemd-network systemd-timesync systemd-journal dbus avahi lp pulse


