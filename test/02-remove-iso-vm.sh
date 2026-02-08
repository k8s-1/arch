#!/usr/bin/env bash

set -euo pipefail

NAME="ArchLinux"

VBoxManage modifyvm $NAME --boot1 disk --boot2 none
