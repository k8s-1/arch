#!/usr/bin/env bash

set -euo pipefail

NAME="ArchLinux"

VBoxManage controlvm $NAME shutdown

VBoxManage modifyvm $NAME --boot1 disk --boot2 none

VBoxManage startvm $NAME
