# SECURITY



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



# IOMMU isolation blocks DMA attacks
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
apparmor (few select profiles for browser, pdf-reader, docker)
harden systemd services (e.g. docker.d)

# disable root login
sudo passwd -l root

# configure sudo
%wheel ALL=(ALL) ALL

# lock other service accounts:
sudo passwd -l nobody ftp git mail systemd-network systemd-timesync systemd-journal dbus avahi lp pulse


