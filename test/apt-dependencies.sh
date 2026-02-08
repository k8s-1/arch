#!/usr/bin/env bash

set -euo pipefail

sudo apt update
sudo apt install -y \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-clients \
  bridge-utils \
  virtinst \
  virt-manager \
  expect

sudo adduser "$USER" kvm
sudo adduser "$USER" libvirt

sudo systemctl enable --now libvirtd

virsh list --all
