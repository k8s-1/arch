#!/usr/bin/env bash

set -euo pipefail


precheck () {
  # set up logging
  exec 1> >(tee "stdout.log")
  exec 2> >(tee "stderr.log")

  # ensure correct time during install
  timedatectl set-ntp true
}


setvars() {
  read -r -p "hostname: " hostname
  echo

  lsblk
  read -r -p "device NAME to partition .e.g. sda (WARNING: loses all data!): " device
  echo

  while true; do
    echo -n "LUKS encryption password: "
    read -r -s luks_pw
    echo
    echo -n "LUKS encryption password (repeat): "
    read -r -s luks_pw2
    echo

    [[ "$luks_pw" == "$luks_pw2" ]] && break
  done

  echo -n "root password: "
  read -r -s root_pw
  echo

  echo -n "user password: "
  read -r -s user_pw
  echo

  echo -n "dev user password: "
  read -r -s dev_pw
  echo

  read -r -p "username: " user
  echo

  # if device ends with a digit, add "p" before partition number
  suffix=""
  if [[ "$device" =~ [0-9]$ ]]; then
      suffix="p"
  fi
  part_boot="/dev/${device}${suffix}1"
  part_swap="/dev/${device}${suffix}2"
  part_root="/dev/${device}${suffix}3"
}


disk() {
  # allocate space
  sfdisk "/dev/$device" << EOF
label: gpt

# EFI
start=2048, size=+1G, type=uefi

# swap
size=+4G, type=linux-swap

# root
type=linux
EOF

  # wipe filesystem labels
  wipefs -a "$part_boot"
  wipefs -a "$part_swap"
  wipefs -a "$part_root"

  # encrypt disk
  printf '%s' "$luks_pw" | cryptsetup luksFormat "$part_root" --batch-mode -

  # open encrypted disk for further processing
  printf '%s' "$luks_pw" | cryptsetup open "$part_root" root --batch-mode -
}


mounts() {
  # make filesystem
  mkfs.vfat -F32 "${part_boot}"
  mkfs.ext4 /dev/mapper/root
  mkswap "${part_swap}"

  # mount filesystem
  mount /dev/mapper/root /mnt
  mount --mkdir "${part_boot}" /mnt/boot
  swapon "${part_swap}"
}


system () {
  # base packages
  pacstrap -K /mnt base linux linux-firmware networkmanager vim

  # fstab
  genfstab -U /mnt >> /mnt/etc/fstab

  # hostname
  echo "${hostname}" > /mnt/etc/hostname

  # time
  arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
  arch-chroot /mnt hwclock --systohc

  # localization
  arch-chroot /mnt sed -i 's/^#\(en_US.UTF-8\)/\1/' /etc/locale.gen
  arch-chroot /mnt locale-gen
  echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
}


bootloader() {
  # initramfs
  arch-chroot /mnt sed -i \
    "s|^HOOKS=.*|HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)|" \
    /etc/mkinitcpio.conf
  echo 'KEYMAP=us' > /mnt/etc/vconsole.conf
  arch-chroot /mnt mkinitcpio -P

  # bootloader install
  arch-chroot /mnt bootctl install

  # bootloader config
  cat <<EOF > /mnt/boot/loader/loader.conf
default arch
EOF

  cat <<EOF > /mnt/boot/loader/entries/arch.conf
title    Arch Linux
linux    /vmlinuz-linux
initrd   /initramfs-linux.img
options  rd.luks.name=$(blkid -s UUID -o value "$part_root")=root root=/dev/mapper/root
EOF
}


swap_encryption () {
  # ensure swap is turned off
  swapoff "$part_swap"

  # create disk label
  mkfs.ext2 -L cryptswap "$part_swap" 1M

  # add labelled disk to crypttab
  cat <<EOF> /etc/crypttab
# <name> <device>         <password>    <options>
swap     LABEL=cryptswap  /dev/urandom  swap,offset=2048,cipher=aes-xts-plain64,size=512,sector-size=4096
EOF

  # add virtual swap disk to fstab
  fstab_file="/mnt/etc/fstab"
  swap_line="/dev/mapper/swap  none   swap    defaults   0       0"
  echo "$swap_line" >> "$fstab_file"
}


users () {
  devuser="dev"
  arch-chroot /mnt useradd -mU -s /usr/bin/bash -G wheel,video,audio,storage "$user"
  arch-chroot /mnt useradd -mU -s /usr/bin/bash -G video,audio,storage "$devuser"

  echo "$user:$user_pw" | chpasswd --root /mnt
  echo "$devuser:$dev_pw" | chpasswd --root /mnt
  echo "root:$root_pw" | chpasswd --root /mnt
}


main () {
  precheck
  setvars
  disk
  mounts
  system
  bootloader
  swap_encryption
  users
}

main "$@"
