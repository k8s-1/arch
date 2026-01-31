# SECURITY
https://wiki.archlinux.org/title/Security



# configure non-root user
useradd -m -G wheel -s /bin/bash username
passwd username
groups username



# configure sudo
https://wiki.archlinux.org/title/Sudo
visudo
sudo -ll

/etc/sudoers.d/10-wheel
%wheel      ALL=(ALL:ALL) ALL

/etc/sudoers.d/90-username_commands
username ALL=(ALL) NOPASSWD: /usr/bin/halt, /usr/bin/poweroff, /usr/bin/reboot, /usr/bin/pacman -Syu




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




# secure UEFI
- disable USB boot
- set admin password




# umask
Remove group + others permissions, use 0027 to keep group
~/.bashrc
```
umask 0077
```




# auditd
https://wiki.archlinux.org/title/Audit_framework
TODO



# lynis audit
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
The pam package is a dependency of the base meta package and, thereby, normally installed on an Arch system. The PAM modules are installed into /usr/lib/security exclusively. 

# pam lock on failed login attempts https://wiki.archlinux.org/title/Security#Lock_out_user_after_three_failed_login_attempts

to unlock after failed attempts:
```
faillock --user username --reset
```

configure: /etc/security/faillock.conf
```
deny=4                  # limited tries
unlock_time=3600        # 1h lock
even_deny_root=true     # root is already locked with passwd --lock root, extra measure
fail_interval=900       # only count failures within 15 min
dir=/var/lib/faillock   # persist reboots
```



# pam allow only certain users to login with su https://wiki.archlinux.org/title/Security#Allow_only_certain_users
Uncomment the appropriate line in /etc/pam.d/su and /etc/pam.d/su-l
```
auth required pam_wheel.so use_uid
```




# pam limits.conf
/etc/security/limits.conf
```
*           soft    priority   0           # Set the default priority to neutral niceness.

*           hard    nproc      4096        # Prevent fork-bombs from taking out the system.
root        hard    nproc      65536       # Prevent root from not being able to launch enough processes


*           hard    nofile     65535
*           soft    nofile      8192


*           soft    core       0           # Prevent corefiles from being generated.
*           hard    core       0

*           hard    nice       -19         # Prevent non-root users from running a process at minimal niceness.
root        hard    nice       -20         # Allows root to run a process at minimal niceness to fix the system when unresponsive.

```



# harden kernel (safe params only)
/etc/sysctl.d/99-hardening.conf:
```
# NOTE: Any settings here can break the system.

# Disable ICMP echo (aka ping) requests: 
net.ipv4.icmp_echo_ignore_all = 1
net.ipv6.icmp.echo_ignore_all = 1

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Reverse path filtering (1=strict, 2=loose), the kernel will do source validation of the packets received from all the interfaces on the machine
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Protect kernel pointers from unprivileged users
kernel.kptr_restrict = 1

# Restrict ptrace to own processes (prevents process snooping)
kernel.yama.ptrace_scope = 1

# Filesystem
fs.suid_dumpable = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2
```






# browser security
- noscript
- ublock origin
- config...



# clamav [add to maintenance.sh]
https://wiki.archlinux.org/title/ClamAV
pacman -S clamav
freshclam # update clamav db
Start/enable clamav-freshclam-once.timer (runs freshclam 1x / day)

Run a manual scan:
clamscan --recursive --infected --log=/var/log/clamav/home_scan.log /home/$USER

Run a system scan:
sudo clamscan --recursive --infected --log=/var/log/clamav/system_scan.log /usr /bin /etc /lib

Add this to maintenance script.




# remove unused packages [add to maintenance.sh]
orphaned=$(pacman -Qdtq)
if [ -n "$orphaned" ]; then
    sudo pacman -Rns $orphaned
else
    echo "No orphaned packages to remove."
fi




# check system package integrity [add to maintenance.sh]
sudo pacman -Qk





# chkrootkit/rkhunter + system tray notify
TODO




# lograte



# disable ssh
Disable the service:
```
sudo systemctl stop sshd.service
sudo systemctl disable sshd.service
sudo systemctl mask sshd.service
```

Additionally disable via config:
/etc/ssh/ssh_config
```
DenyUsers *
PasswordAuthentication no
PermitRootLogin no
```




# apparmor (few select profiles for services, browser, pdf-reader, docker)
TODO




# review systemd services (e.g. docker.d)
systemd-analzye security
https://wiki.archlinux.org/title/Systemd/Sandboxing





# disable root login
check if you can sudo su, then
sudo passwd --lock root

# lock other service accounts:
sudo passwd -l nobody ftp git mail systemd-network systemd-timesync systemd-journal dbus avahi lp pulse


