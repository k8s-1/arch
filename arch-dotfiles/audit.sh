#!/usr/bin/bash

sudo lynis audit system

sudo arch-audit

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
