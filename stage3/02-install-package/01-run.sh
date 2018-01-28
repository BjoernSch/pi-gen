#!/bin/bash -e

install -m 755 files/WLANThermo_install.run             ${ROOTFS_DIR}/tmp/

on_chroot << EOF
/tmp/WLANThermo_install.run
EOF

rm -f ${ROOTFS_DIR}/tmp/WLANThermo_install.run

