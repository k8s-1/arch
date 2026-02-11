https://wiki.archlinux.org/title/Installation_guide

# Disk Layout
```
/boot   - 1GB   efi
/swap   - 16GB  encrypted linux-swap
/       -       encrypted ext4
```

# Pre-install
- Prepare live usb
- Disable UEFI secure boot
- Launch live usb
- Connect to wifi if wireless:

```
iwctl
[iwd]# device list
[iwd]# station name scan
[iwd]# station name get-networks
[iwd]# station name connect SSID
```

# Install
```
wget https://raw.githubusercontent.com/k8s-1/arch/main/install.sh
chmod +x install.sh
./install.sh | tee log
reboot

cd arch
git clone https://github.com/k8s-1/arch.git
git remote set-url origin git@github.com:k8s-1/arch.git
ansible-playbook -K main.yaml

cd
git clone git@github.com:k8s-1/dotfiles.git
cd dotfiles
make arch
```

# Recovery
- boot from live usb
```
lsblk
cryptsetup luksOpen /dev/sdXn root
mount /dev/mapper/root /mnt
```
- apply fixes
