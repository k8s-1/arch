#!/bin/bash

set -e

# Update mirror list
if [ -z "$(find /etc/pacman.d/mirrorlist -mtime -7)" ]; then
    sudo reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
fi

# Update system and refresh keys if needed
if sudo pacman -Syu --noconfirm; then
    :
else
    sudo pacman-key --refresh-keys
    sudo pacman -Syu --noconfirm
fi

# Prune cache
sudo paccache -rk2 -u

# Remove orphans
orphaned=$(pacman -Qdtq)
if [ -n "$orphaned" ]; then
    sudo pacman -Rns "$orphaned" --noconfirm
else
    echo "No orphaned packages to remove."
fi

# Clean cache directory
rm -rf ~/.cache/* && sudo rm -rf /tmp/*

# Cleanup docker objects
docker system prune -af

# Update rust
rustup update


CHECK="\xE2\x9C\x85"   # ✅
echo -e "\n${CHECK} Maintance complete."


