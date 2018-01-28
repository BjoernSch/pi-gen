#!/bin/bash -e

install -m 755 files/resize.sh             ${ROOTFS_DIR}/root/
install -m 644 files/setup.txt             ${ROOTFS_DIR}/boot/

on_chroot << EOF
echo "@reboot         root    /bin/bash -x /root/resize.sh 2>&1 > /boot/setup.log" >> /etc/crontab
EOF

