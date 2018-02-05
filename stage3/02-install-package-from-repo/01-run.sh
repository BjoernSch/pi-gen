#!/bin/bash -e

on_chroot << EOF
wget -O - https://packages.wlanthermo.net/wlanthermo.gpg.key | sudo apt-key add -
wget -O /etc/apt/sources.list.d/wlanthermo-stretch-dev.list https://packages.wlanthermo.net/wlanthermo-stretch-dev.list
apt update
apt -y install wlanthermo
EOF
