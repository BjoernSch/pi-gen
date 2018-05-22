#!/bin/bash -e

on_chroot << EOF
wget -O - https://packages.wlanthermo.com/wlanthermo.gpg.key | sudo apt-key add -
wget -O /etc/apt/sources.list.d/wlanthermo-stretch.list https://packages.wlanthermo.com/wlanthermo-stretch-dev.list
apt update
apt -y install wlanthermo
EOF
