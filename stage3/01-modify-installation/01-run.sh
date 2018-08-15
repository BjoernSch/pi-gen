#!/bin/bash -e

install -m 644 files/hostname             ${ROOTFS_DIR}/etc/
install -m 644 files/8192cu.conf          ${ROOTFS_DIR}/etc/modprobe.d/

on_chroot << EOF
systemctl disable resize2fs_once
systemctl disable apply_noobs_os_config
rm -f /etc/systemd/system/dhcpcd.service.d/wait.conf
EOF

rm -f ${ROOTFS_DIR}/etc/init.d/resize2fs_once
rm -f ${ROOTFS_DIR}/etc/init.d/apply_noobs_os_config
