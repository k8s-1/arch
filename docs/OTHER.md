Add a pacman hook to update the bootloader in /efi when there is an update:
/etc/pacman.d/hooks/95-systemd-boot.hook
```
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Upgrading systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service
```

sudo systemctl enable --now fwupd.service
# UPDATE FIRMWARE - DO THIS MANUALLY YEARLY
pacman -S fwupd
fwupdmgr get-devices
fwupdmgr refresh
fwupdmgr get-updates
fwupdmgr update

# UKI hash monitor
Compute a hash of UKI when it’s known-good:

mkdir -p /etc/ukisums
sha256sum esp/EFI/Linux/arch.uki > /etc/ukisums/arch.uki.sha256

Run integrity check before maintenance:
sha256sum -c /etc/ukisums/arch.uki.sha256
<system-update>
<update-hash>

