# how do you arch-chroot into encrypted disk?
boot from live USB
cryptsetup luksOpen /dev/sdXn root
mount /dev/mapper/root /mnt

