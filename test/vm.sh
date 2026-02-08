#!/bin/bash

set -euo pipefail

sudo virsh net-define network.xml
sudo virsh net-destroy default || true
sudo virsh net-start default
sudo virsh net-autostart default

# sudo mv /tmp/archlinux-x86_64.iso /var/lib/libvirt/images/
# sudo chown root:kvm /var/lib/libvirt/images/archlinux-x86_64.iso
# sudo chmod 644 /var/lib/libvirt/images/archlinux-x86_64.iso

virt-install \
  --name arch \
  --memory 4096 \
  --vcpus 2 \
  --disk size=20,format=qcow2,bus=virtio \
  --cdrom /tmp/archlinux-x86_64.iso \
  --cdrom /var/lib/libvirt/images/archlinux-x86_64.iso \
  --boot uefi,cdrom,hd \
  --os-variant archlinux \
  --network network=default,model=virtio \
  --graphics spice \
  --video virtio \
  --console pty,target_type=serial

virsh net-dumpxml default | grep ip

# virt-viewer arch
# virsh list --all
# virsh shutdown arch
# virsh undefine arch --nvram
# virsh destroy arch
