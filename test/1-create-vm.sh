#!/usr/bin/env bash

set -euo pipefail

NAME="ArchLinux"

VBoxManage createvm \
  --name $NAME \
  --ostype "${NAME}_64" \
  --register

VBoxManage modifyvm $NAME \
  --memory 4096 \
  --cpus 4 \
  --nic1 nat \
  --boot1 dvd \
  --boot2 disk \
  --vram 128 \
  --firmware efi

VBoxManage createhd \
  --filename ~/VirtualBox\ VMs/$NAME.vdi \
  --size 20000 \
  --variant Fixed

VBoxManage storagectl $NAME \
  --name "SATA Controller" \
  --add sata \
  --controller IntelAhci

VBoxManage storageattach $NAME \
  --storagectl "SATA Controller" \
  --port 0 \
  --device 0 \
  --type hdd \
  --medium ~/VirtualBox\ VMs/$NAME.vdi

VBoxManage storageattach $NAME \
  --storagectl "SATA Controller" \
  --port 1 \
  --device 0 \
  --type dvddrive \
  --medium ./archlinux.iso

# folder will be in /media
VBoxManage sharedfolder add $NAME \
  --name code \
  --hostpath ~/code/arch \
  --automount

VBoxManage startvm $NAME

