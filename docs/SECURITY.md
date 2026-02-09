# SECURITY
https://wiki.archlinux.org/title/Security


# configure sudo
https://wiki.archlinux.org/title/Sudo
visudo
sudo -ll

/etc/sudoers.d/10-wheel
%wheel      ALL=(ALL:ALL) ALL

/etc/sudoers.d/90-username_commands
username ALL=(ALL) NOPASSWD: /usr/bin/halt, /usr/bin/poweroff, /usr/bin/reboot, /usr/bin/pacman -Syu


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

add kernel param:
audit=1

Start/enable auditd.service

WARNING: Before adding rules, you must know that the audit framework can be very verbose and that each rule must be carefully tested before being effectively deployed. Indeed, just one rule can flood all your logs within a few minutes.

List active rules:
auditctl -l

Validate rules:
auditctl -a always,exit -F arch=b64 -F path=/etc/passwd -F perm=rwxa
auditctl -a always,exit -F arch=b32 -F path=/etc/passwd -F perm=rwxa
auditctl -a always,exit -F arch=b64 -F dir=/etc/security
auditctl -a always,exit -F arch=b32 -F dir=/etc/security

Then add them to /etc/audit/rules.d/example.rules:
```
# Audit changes to users
-a always,exit -F arch=b64 -F path=/etc/passwd -F perm=rwxa

# Audit changes to security settings
-a always,exit -F arch=b64 -F dir=/etc/security

# Monitor changes to /etc/sudoers (used for sudo privileges)
-a always,exit -F arch=b64 -F path=/etc/sudoers -F perm=rwxa

# Monitor changes in /etc/sudoers.d/ (additional sudo configurations)
-a always,exit -F arch=b64 -F dir=/etc/sudoers.d

# Audit changes to /etc/hostname (hostname can affect network identity)
-a always,exit -F arch=b64 -F path=/etc/hostname -F perm=rwxa

# Audit changes to /etc/hosts (important for network resolution)
-a always,exit -F arch=b64 -F path=/etc/hosts -F perm=rwxa

# Audit changes to cron configuration (cron.d, cron.daily, etc.)
-a always,exit -F arch=b64 -F dir=/etc/cron.d
-a always,exit -F arch=b64 -F dir=/etc/cron.daily

# Audit changes to systemd service configurations
-a always,exit -F arch=b64 -F dir=/etc/systemd/system

# Audit changes to init scripts or systemd services
-a always,exit -F arch=b64 -F dir=/etc/init.d/

# Audit login attempts (successful and failed) via PAM (Pluggable Authentication Modules)
-a always,exit -F arch=b64 -S execve -F exe=/usr/bin/login

# Audit use of sudo (successful and failed)
-a always,exit -F arch=b64 -S execve -F exe=/usr/bin/sudo
-a always,exit -F arch=b32 -S execve -F exe=/usr/bin/sudo
```

Audit ownership changes:
auditctl -a exit,always -S chmod

/etc/audit/rules.d/quiet.rules
```
-a exclude,always -F msgtype=SERVICE_START
-a exclude,always -F msgtype=SERVICE_STOP
-a exclude,always -F msgtype=BPF
-a exclude,always -F exe=/usr/bin/sudo
```


Remember to verify changes (fix as necessary) and regenerate /etc/audit/audit.rules as follows:
augenrules --check
augenrules --load


Check anomalies:
aureport -n


also nice to have (according to chatgpt):
auditctl -a always,exit -F arch=b64 \
  -S chmod,fchmod,fchmodat \
  -S chown,fchown,fchownat,lchown \
  -k perm_changes
auditctl -w /etc -p wa -k etc_changes
auditctl -w /home -p wa -k home_changes
auditctl -w /usr/bin -p wa -k bin_changes
auditctl -w /usr/sbin -p wa -k sbin_changes

Also lock the rules:
sudo auditctl -R /etc/audit/rules.d/*.rules
sudo auditctl -l          # verify rules
sudo auditctl -e 2        # lock

Make it persistent:
echo "-e 2" | sudo tee /etc/audit/rules.d/99-lockdown.rules






# lynis audit
Repeat this audit regularly to check how the system can be improved.
Don't try to fix everything at once and test changes (especially kernel parameters).
Turn off unused services.
```
sudo pacman -S lynis
sudo lynis audit system
sudo lynis show report
```




# swaylock
pacman -S swaylock

https://wiki.archlinux.org/title/Sway#Custom_keybindings

~/.config/sway/config - configure shortcut
```
bindsym $mod+l exec swaylock --show-failed-attempts --no-unlock-indicator --color 000000 --disable-caps-lock-text
```



# touchpad
Input devices
It is possible to tweak specific input device configurations. For example, to enable tap-to-click and natural scrolling for all touchpads:

~/.config/sway/config
input type:touchpad {
    tap enabled
    natural_scroll enabled
}



# swayidle
pacman -S swayidle

https://wiki.archlinux.org/title/Sway#Idle
The following instructs swayidle to lock the screen after 30 minutes and turn it off five seconds after:

~/.config/sway/config
exec swayidle -w \
	timeout 1800 'swaylock -f' \
	timeout 1805 'swaymsg "output * power off"' \
		resume 'swaymsg "output * power on"'




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




# check system package integrity [add to maintenance.sh]
sudo pacman -Qk



# other checks [add to maintenance.sh]
systemctl --failed



# rkhunter
Prior to running for the first time, update file properties db:
rkhunter --propupd

Running:
rkhunter --update
rkhunter --check --sk
rkhunter --config-check

Out of the box, Rootkit Hunter will throw up some false warnings during the file properties check. This occurs because a few of the core utilities have been replaced by scripts. These warnings can be muted through white-listing:
/etc/rkhunter.conf
```
SCRIPTWHITELIST=/usr/bin/egrep
SCRIPTWHITELIST=/usr/bin/fgrep
SCRIPTWHITELIST=/usr/bin/ldd
SCRIPTWHITELIST=/usr/bin/vendor_perl/GET
```








# apparmor (few select profiles for services, browser, pdf-reader, docker) = MAC mandatory access control (even applies to root user)
https://wiki.archlinux.org/title/AppArmor

pacman -S apparmor
systemctl start apparmor.service
systemctl enable apparmor.service

set kernel parameter via systemd-boot:
lsm=landlock,lockdown,yama,integrity,apparmor,bpf

test if enabled:
aa-enabled

if you need to disable apparmor:
aa-teardown

next, ensure `audit` is set up + running for log-based profile building.

profiles are stored in /etc/apparmor.d/<path>.<to>.<binary>

to generate a profile:
aa-genprof <path to executable>
aa-enforce <path to executable>

NOTE: Currently the tools do not properly utilize variables such as @{PROC},
and @{HOME}, so you may want to adjust the profile after to use
abstractions that the tools could not discover.

modify profile from logs:
aa-logprof

or set it back with:
aa-complain <path to executable>

profiles to configure:
- systemd
- dbus
- firefox
- file manager
- docker
- pdfreader


# firejail
https://wiki.archlinux.org/title/Firejail#Enable_AppArmor_support
firejail --apparmor firefox
firejail --list

The security risk of Firejail being a SUID executable can be mitigated by adding the line
`force-nonewprivs yes`
to /etc/firejail/firejail.config

Use firejail by default for all apps for which it has profiles:
firecfg             # set default, creates symlinks
firecfg --clean     # undo set default, removes symlinks



## to configure notifications on apparmor deny:
groupadd -r audit
gpasswd -a user audit

/etc/audit/auditd.conf
log_group = audit


/etc/tmpfiles.d/audit.conf
z /var/log/audit 750 root audit - -


pacman -S python-notify2 python-psutil

Create a desktop launcher with the following content:
~/.config/autostart/apparmor-notify.desktop

[Desktop Entry]
Type=Application
Name=AppArmor Notify
Comment=Receive on-screen notifications of AppArmor denials
TryExec=aa-notify
Exec=aa-notify -p -s 1 -w 60 -f /var/log/audit/audit.log
StartupNotify=false
NoDisplay=true

Reboot and check if the aa-notify process is running:
$ pgrep -ax aa-notify


## speed up apparmor boot
systemd-analyze blame | grep apparmor

To enable caching AppArmor profiles, uncomment:
/etc/apparmor/parser.conf
## Turn creating/updating of the cache on by default
write-cache





# disable root login
check if you can sudo su, then
sudo passwd --lock root

# lock other service accounts:
sudo passwd -l nobody ftp git mail systemd-network systemd-timesync systemd-journal dbus avahi lp pulse








