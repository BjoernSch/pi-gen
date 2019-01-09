#!/bin/bash -e

install -m 644 files/wlanthermo-*.deb             ${ROOTFS_DIR}/tmp/

on_chroot << EOF
wget -O - https://packages.wlanthermo.com/wlanthermo.gpg.key | sudo apt-key add -
wget -O /etc/apt/sources.list.d/wlanthermo-stretch.list https://packages.wlanthermo.com/wlanthermo-stretch-dev.list

apt update

dpkg -i /tmp/wlanthermo-*.deb
rm -f /tmp/wlanthermo-*.deb
apt -yf install

EOF
