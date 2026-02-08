#!/usr/bin/env bash

set -euo pipefail

NAME="ArchLinux"

VBoxManage controlvm $NAME acpipowerbutton || true
sleep 5

VBoxManage storageattach "$NAME" \
  --storagectl "SATA Controller" \
  --port 1 \
  --device 0 \
  --type dvddrive \
  --medium none

VBoxManage modifyvm $NAME --boot1 disk --boot2 none

VBoxManage startvm $NAME
