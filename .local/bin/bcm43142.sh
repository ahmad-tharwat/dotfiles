#!/bin/bash

### Enable Wi-Fi
apt update
apt install linux-image-$(uname -r|sed 's,[^-]*-[^-]*-,,') linux-headers-$(uname -r|sed 's,[^-]*-[^-]*-,,') broadcom-sta-dkms
modprobe -r b44 b43 b43legacy ssb brcmsmac bcma
modprobe wl

### Enable Bluetooth
curl -H 'Accept: application/vnd.github.v3.raw' --output-dir /lib/firmware/brcm -O -L "https://api.github.com/repos/winterheart/broadcom-bt-firmware/contents/brcm/BCM43142A0-0a5c-21d7.hcd"
systemctl enable bluetooth

echo "------------------------------------------------------"
echo "You need to restart the computer for bluetooth to work"
echo "------------------------------------------------------"

