#!/bin/bash -e

install -m 755 files/resize.sh             ${ROOTFS_DIR}/root/
install -m 644 files/setup.txt             ${ROOTFS_DIR}/boot/

on_chroot << EOF
WLANThermoVersion=$(grep -e '^$_SESSION\["webGUIversion"\]' /var/www/header.php | cut -d'"' -f4)
sed -i -e "s/XXX_VERSION_XXX/${WLANThermoVersion}/" /boot/setup.txt
sed -i -e "s/XXX_DATE_XXX/$(date +%Y-%m-%d)/" /boot/setup.txt
echo "@reboot         root    /bin/bash -x /root/resize.sh 2>&1 > /boot/setup.log" >> /etc/crontab
EOF
