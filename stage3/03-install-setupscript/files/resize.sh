#!/bin/bash

###########################################################################
##
##
## V3 Resize mit Prozentangabe
## automatisches Update des Displays
## WLAN starten
## 23.3.2017
##
## V2 Passwoerter von pi, root und web aus setup.txt setzen
## WLAN einstellen
##
## Resize root partition
###########################################################################

if [ -e /proc/device-tree/aliases/serial0 ]; then
   SERIAL=/dev/serial0
else
   SERIAL=/dev/ttyAMA0
fi


function init_display {
  pkill -f wlt_2_nextion.py
  sleep 10
  pkill -9 -f wlt_2_nextion.py
  stty -F $SERIAL 115200
  echo -en "\xff\xff\xff" > $SERIAL
  echo -en sleep=0"\xff\xff\xff" > $SERIAL
  echo -en thsp=0"\xff\xff\xff" > $SERIAL
  echo -en nextion_down.val=0"\xff\xff\xff" > $SERIAL
  echo -en page boot"\xff\xff\xff" > $SERIAL
  echo -en tm0.en=0"\xff\xff\xff" > $SERIAL
  echo -en t0.txt=\"\""\xff\xff\xff" > $SERIAL

}

function display_message {
  echo -en t0.txt=\"$1\""\xff\xff\xff" > $SERIAL
  echo $1
}

function enable_ssh {
  systemctl enable ssh.service
  systemctl start ssh.service
  ssh_enabled=1
}

#crontab richtigstellen
sed -n '/reboot/!p' /etc/crontab >/etc/crontabtemp ; mv -f /etc/crontabtemp /etc/crontab
echo
echo "------------------------------------------------------"
echo "Config Start"
echo "------------------------------------------------------"
echo "Waiting 60s for boot to complete, in particular for the Nextion script to set the update flag"
sleep 60
init_display

if [ -e /boot/setup.txt ]; then

  display_message "Setup startet..."
  sleep 1

  eval $(grep -i "^piname=" /boot/setup.txt| tr -d "\n\r")
  eval $(grep -i "^pipass=" /boot/setup.txt| tr -d "\n\r")
  eval $(grep -i "^rootpass=" /boot/setup.txt| tr -d "\n\r")
  eval $(grep -i "^webguipw=" /boot/setup.txt| tr -d "\n\r")
  eval $(grep -i "^wlanssid=" /boot/setup.txt| tr -d "\n\r")
  eval $(grep -i "^wlankey=" /boot/setup.txt| tr -d "\n\r")
  eval $(grep -i "^keepconf=" /boot/setup.txt| tr -d "\n\r")
  eval $(grep -i "^partsize=" /boot/setup.txt| tr -d "\n\r")
  eval $(grep -i "^reboot=" /boot/setup.txt| tr -d "\n\r")
  eval $(grep -i "^hwversion=" /boot/setup.txt| tr -d "\n\r")
  eval $(grep -i "^force_update=" /boot/setup.txt| tr -d "\n\r")
  eval $(grep -i "^language=" /boot/setup.txt| tr -d "\n\r")
  eval $(grep -i "^keyboard=" /boot/setup.txt| tr -d "\n\r")
  eval $(grep -i "^timezone=" /boot/setup.txt| tr -d "\n\r")

  echo "Variablen"
  echo "Hostname:"
  echo $piname
  #echo $pipass
  #echo $rootpass
  #echo $webguipw
  echo "WLAN SSID:"
  echo $wlanssid
  #echo $wlankey
  echo "Config behalten:"
  echo $keepconf
  echo "Partitionsgroesse:"
  echo $partsize
  echo "Hardware Version:"
  echo $hwversion
  echo "Force update:"
  echo $force_update
  echo "Language:"
  echo $language
  echo "Keyboard:"
  echo $keyboard
  echo "Zeitzone:"
  echo $timezone
  
  echo
  echo "------------------------------------------------------"
  echo "Update display"
  echo "------------------------------------------------------"

  # Rotate display by 180 degree on miniV2
  if [ "$hwversion" == "miniV2" ]; then
     echo "Display orientation 180°"
     orientation=180
  else
     echo "Display orientation 0°"
     orientation=0
  fi

  # Display Update Check
  if [ -e /var/www/tmp/nextionupdate ] || [ -n "$force_update" ]; then
    echo "Display update starting $(date +"%R %x")"
    /usr/sbin/wlt_2_updatenextion.sh /usr/share/WLANThermo/nextion/ $orientation > /var/www/tmp/error.txt
    echo "Display update finished $(date +"%R %x")"
  fi

  # Set language
  case "$language" in
    "en")
      if [ "$keyboard" = "gb" ]; then
        DEBLANGUAGE="" # UK english is the default, so ignore
      else
        DEBLANGUAGE="en_US.UTF-8"
      fi
      ;;
    "de")
      DEBLANGUAGE="de_DE.UTF-8"
      ;;
    "fr")
      DEBLANGUAGE="fr_FR.UTF-8"
      ;;
    *)
      display_message "Language $language unknown"
      sleep 1
      ;;
  esac
  
  if [ -n "$DEBLANGUAGE" ]; then
    display_message "Setting language to $DEBLANGUAGE"
    update-locale LANG="$DEBLANGUAGE"
    sleep 0.5
  fi
  
  # Set timezone
  if [ -n "$timezone" ]; then
    display_message "Setting Timezone $timezone"
    if [ -f "/usr/share/zoneinfo/$timezone" ]; then
      cp "/usr/share/zoneinfo/$timezone" /etc/localtime
      echo "$timezone" > /etc/timezone
      dpkg-reconfigure -f noninteractive tzdata
      sleep 0.5
    else
      display_message "Timezone not found!"
      sleep 1
    fi
  fi
  
  # Set keyboard
  if [ -n "$keyboard" -a "$keyboard" != "gb" ]; then
    display_message "Setting keyboard to $keyboard"
    sed -i /etc/default/keyboard -e "s/^XKBLAYOUT.*/XKBLAYOUT=\"$keyboard\"/"
    dpkg-reconfigure -f noninteractive keyboard-configuration
    invoke-rc.d keyboard-setup start
    sleep 0.5
  fi
  
  # pi Rechnername setzen
  if [ -n "$piname" ]; then           #wenn nicht ""
    display_message "Hostname: $piname"
    sleep 1
    CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
    echo -n $piname > /etc/hostname
    sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$piname/g" /etc/hosts
    echo "Hostname gesetzt"
  fi

  # pi pass setzen
  if [ -n "$pipass" ]; then           #wenn nicht ""
    display_message "pi Passwort setzen"
    enable_ssh
    sleep 0.5
    echo "pi:$pipass" | chpasswd
    echo "Passwort pi gesetzt"
  fi

  # authorized_keys kopieren
  if [ -e /boot/authorized_keys ]; then
    display_message "Copying authorized_keys (pi)"
    sleep 0.5
    mkdir -p /home/pi/.ssh/
    mv /boot/authorized_keys /home/pi/.ssh/
    chown pi:pi /home/pi/.ssh/authorized_keys
    chmod 0600 /home/pi/.ssh/authorized_keys
    enable_ssh
    echo "authorized_keys (pi) copied..."
  fi

  # authorized_keys kopieren
  if [ -e /boot/authorized_keys.root ]; then
    display_message "Copying authorized_keys (root)"
    sleep 0.5
    mkdir -p /root/.ssh/
    mv /boot/authorized_keys.root /root/.ssh/authorized_keys
    chown root:root /root/.ssh/authorized_keys
    chmod 0600 /root/.ssh/authorized_keys
    enable_ssh
    echo "authorized_keys (root) copied..."
  fi
  
  #root pass setzen
  if [ -n "$rootpass" ]; then         #wenn nicht ""
    display_message "Setting root password"
    enable_ssh
    sleep 0.5
    echo "root:$rootpass" | chpasswd
    echo "Passwort root gesetzt"
  elif [ -n "$ssh_enabled" ]; then
    rootpass=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c10)
    display_message "Setting random root password"
    sleep 0.5
    echo "root:$rootpass" | chpasswd
    echo "Passwort root gesetzt: $rootpass"
  fi
  
  # pi pass setzen
  if [ -n "$pipass" ]; then           #wenn nicht ""
    display_message "pi Passwort setzen"
    enable_ssh
    sleep 0.5
    echo "pi:$pipass" | chpasswd
    echo "Passwort pi gesetzt"
  elif [ -n "$ssh_enabled" ]; then
    pipass=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c10)
    display_message "Setting random pi password"
    sleep 0.5
    echo "pi:$pipass" | chpasswd
    echo "Passwort pi gesetzt: $pipass"
  fi

  # wlanthermo pass setzen
  if [ -n "$webguipw" ]; then         #wenn nicht ""
    display_message "Setting web password"
    sleep 0.5
    htpasswd -b /etc/lighttpd/htpasswd wlanthermo $webguipw
    echo "Passwort webgui gesetzt"
  fi

  # wlan Netz und Key eintragen
  if [ -n "$wlanssid" ]; then         #wenn nicht ""
    if [  ${#wlankey} -ge 8 ]; then   # 8 Zeichen oder mehr
      display_message "Setting up WLAN"
      sleep 0.5
      echo "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev" > /etc/wpa_supplicant/wpa_supplicant.conf
      echo "update_config=1" >> /etc/wpa_supplicant/wpa_supplicant.conf

      wpa_passphrase $wlanssid $wlankey >> /etc/wpa_supplicant/wpa_supplicant.conf
      ifdown wlan0
      echo "WLAN SSID and passphrase set"

    fi
  fi

  # Configfile löschen
  if [ -z "$keepconf" ]; then         #wenn ""

    display_message "Deleting config"
    sleep 1

    rm /boot/setup.txt

    echo "Config deleted"
  fi
fi

display_message "Partition resize."
ROOT_PART=$(mount | sed -n 's|^/dev/\(.*\) on / .*|\1|p')
PART_NUM=${ROOT_PART#mmcblk0p}
PART_START=$(parted /dev/mmcblk0 -ms unit s p | egrep "^${PART_NUM}" | cut -f 2 -d: | sed 's/[^0-9]//g')
#PART_END=$(parted /dev/mmcblk0 -ms unit s p | egrep "^${PART_NUM}" | cut -d: -f3| sed 's/[^0-9]//g') # aktuelles Partiton Ende

CARD_END=$(parted /dev/mmcblk0 -ms unit s p | egrep "/dev/mmcblk0" | cut -d: -f2| sed 's/[^0-9]//g')  # Anzahl der Sektoren gesamt
PART_END=$(expr $CARD_END - 1)        # Ende der Karte setzen, Sektor 0 entfernen

if [ -n "$partsize"  ]; then         #wenn nicht ""
  if [ "$partsize" != *[!0-9]* ]; then         # und eine Zahl
    display_message "Partition resize $partsize%"
    sleep 1
    PARTTEMP=$(expr $PART_END \* 100)          # Shift für Ganzzahlen
    PARTTEMP=$(expr $PARTTEMP \* $partsize)    # Prozent der Größe angeben
    PART_END=$(expr $PARTTEMP / 10000)         # Auf den richtigen Wert
echo Debug PART_END $PART_END
echo Debug partsize $partsize
echo Debug PARTTEMP $PARTTEMP
  fi
fi

#[ "${PART_START}" ] || exit 1
#[ "${PART_END}" ] || exit 1

#if [ $(echo ${PART_END} | sed 's/s//g') -eq 3788799 -o \
#     $(echo ${PART_END} | sed 's/s//g') -eq 5785599 -o \
#     $(echo ${PART_END} | sed 's/s//g') -eq 6399999 \
#   ]; then
  echo
  echo "------------------------------------------------------"
  echo "Resize root partition"
  echo "------------------------------------------------------"

  fdisk /dev/mmcblk0 <<EOF
p
d
$PART_NUM
n
p
$PART_NUM
$PART_START
$PART_END
p
w
EOF
display_message "Partition resize.."
service WLANThermoNEXTION start

  echo
  echo "Done"
#fi

if [ ! -f /etc/init.d/resize2fs_once ]; then
  echo
  echo "------------------------------------------------------"
  echo "Create init script for filesystem resize"
  echo "------------------------------------------------------"

  cat <<EOF > /etc/init.d/resize2fs_once &&
#!/bin/sh
### BEGIN INIT INFO
# Provides:          resize2fs_once
# Required-Start:
# Required-Stop:
# Default-Start: 3
# Default-Stop:
# Short-Description: Resize the root filesystem to fill partition
# Description:
### END INIT INFO

. /lib/lsb/init-functions

case "\$1" in
  start)
    log_daemon_msg "Starting resize2fs_once" &&
    resize2fs /dev/$ROOT_PART &&
    systemctl disable resize2fs_once.service &&
    /sbin/dphys-swapfile setup &&
    rm /etc/init.d/resize2fs_once &&
    rm /root/resize.sh &&
    log_end_msg \$?
    ;;
  *)
    echo "Usage: \$0 start" >&2
    exit 3
    ;;
esac
EOF
service WLANThermoNEXTION stop
display_message "Partition resize..."

  chmod +x /etc/init.d/resize2fs_once&&
  systemctl daemon-reload 
  systemctl enable resize2fs_once.service &&

  echo
  echo "Done"
fi
ifup wlan0

if [ -n "$hwversion" ]; then
  display_message "Setting hardware version"
  sed -i /var/www/conf/WLANThermo.conf -e "s/^version = .*/version = $hwversion/"
  sleep 0.5
fi

# reboot wenn
if [ -z "$reboot" ]; then
  shutdown -r now
  display_message "Reboot....."
fi
