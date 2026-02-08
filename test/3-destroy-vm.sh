#!/usr/bin/env bash

set -euo pipefail

NAME="ArchLinux"

VBoxManage controlvm $NAME poweroff || true
sleep 3
VBoxManage unregistervm ArchLinux --delete
