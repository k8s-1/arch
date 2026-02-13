#!/usr/bin/bash

sudo lynis audit system

sudo arch-audit -rcq

sudo systemd-analzye security


# rkhunter
# Prior to running for the first time, update file properties db:
rkhunter --propupd

# Running:
rkhunter --update
rkhunter --check --sk
rkhunter --config-check


# other checks [add to maintenance.sh]
systemctl --failed


# check system package integrity [add to maintenance.sh]
sudo pacman -Qk


# clamav homedir scan
freshclam
find "$HOME" -type f -print0 | xargs -0 -P "$(nproc)" clamscan
