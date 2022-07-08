#!/bin/bash


if [ "$1" = "h" ] || [ "$1" = "-h" ] || [ "$1" = "--h" ] || [ "$1" = "help" ] || [ "$1" = "-help" ] || [ "$1" = "--help" ]; then
  echo " "
  echo "use predefined -> ./NtwMgr-wifi-shared.sh <iface> <ESSID> <PSK>"
  echo "use autorunner -> ./NtwMgr-wifi-shared.sh <ESSID> <PSK>"
  echo "use autorunner -> ./NtwMgr-wifi-shared.sh"
  echo " "
  exit
else
  echo -n ""
fi


if [ -n "$3" ]; then
echo "(3 values)"
echo " "
  ifacename=$1
  ESSIDname=$2
  PSKname=$3
else
  echo " "
  echo "Check interfaces:"
  echo "-----------------------------------"
  iw dev
  echo "-----------------------------------"
  echo " "
  sleep 1
  echo "Add interface name for create hotspot:"
  echo " " # echo igrored
  read -p "" ifacename
  echo " " # echo igrored
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Add ESSID name for create hotspot:"
    echo " " # echo igrored
    read -p "" ESSIDname
    echo " " # echo igrored
    echo "Add PSK for create hotspot:"
    echo " " # echo igrored
    read -p "" PSKname
    echo " " # echo igrored
  else
    echo "(2 values)"
    echo " "
    ESSIDname=$1
    PSKname=$2
  fi
fi

chekapmode1="$(nmcli -p -f general,wifi-properties device show $ifacename | sed '/WIFI.*.AP/!d;/yes/!d;/^[[:space:]]*$/d' | sort -u | wc -l)"
# chekapmode1="(iw $(iw dev | awk "/$ifacename/{print prev} {prev=\$0}" | sed 's/[[:punct:]]//g') info | sed '/* AP/!d;/\* AP.*.[[:digit:]]/d;/^[[:space:]]*$/d' | sort -u | wc -l)"
if [ "$chekapmode1" = "0" ]; then
  echo "ERROR! The specified interface not supported AP mode! ($ifacename)"
  echo "(using another interface, or virtualization one supported iface)"
  # echo "check iface command -> iw \$(iw dev | awk '/<iface>/{print prev} {prev=\$0}'"" | sed 's/[[:punct:]]//g') info | sed ""'"'/* AP/!d;/\* AP.*.[[:digit:]]/d'"'"
  echo "check iface command -> nmcli -p -f general,wifi-properties device show <iface> | sed '/WIFI."'*.AP/!d;s/  */ /g'"'"
  exit
else
  echo -n ""
fi


# not work long text -> '[ -f ...]'
# [ -f /etc/NetworkManager/system-connections/'Wi-Fi connection '[0-9]* ] && rm /etc/NetworkManager/system-connections/'Wi-Fi connection '[0-9]*
# [ -f /etc/NetworkManager/system-connections/Wi-Fi-shared*.nmconnection ] && rm /etc/NetworkManager/system-connections/Wi-Fi-shared*.nmconnection
checkdoc1="$(ls /etc/NetworkManager/system-connections | sed '/Wi-Fi connection [0-9]/!d' | sort -u | wc -l)"
if [ "$checkdoc1" = "0" ]; then
  echo -n ""
else
  rm /etc/NetworkManager/system-connections/'Wi-Fi connection '[0-9]*
fi

checkdoc2="$(ls /etc/NetworkManager/system-connections | sed '/Wi-Fi-shared/!d' | sort -u | wc -l)"
if [ "$checkdoc2" = "0" ]; then
  echo -n ""
else
  rm /etc/NetworkManager/system-connections/Wi-Fi-shared*.nmconnection
fi


checkdoc3="$(sed "/$ifacename/!d" /etc/NetworkManager/system-connections/*.nmconnection | sort -u | wc -l)"
if [ "$checkdoc3" = "1" ]; then
  echo " "
  echo "Warning! The specified interface included in several network settings! ($ifacename)"
  echo " "
  read -p "Continue process (y)? or Check NetworkManager and delete undesired settings? (y/n) " nmsetting1
  echo " "
  if [ "$nmsetting1" = "n" ]; then
    echo "(opened nm-connection-editor and exit)"
    nm-connection-editor
    exit
  else
    echo -n ""
else
  echo -n ""
  fi
fi


# permanent mac grabbing multiple method
macaddr1="$(ethtool -P $ifacename | sed 's/.*address: //g;s/.*/\U&/g;s/[ ]//g;/^.\{17\}$/!d' | sort -u | wc -l)"
if [ "$macaddr1" = "1" ]; then
  MACaddr="$(ethtool -P $ifacename | sed 's/.*address: //g;s/.*/\U&/g;s/[ ]//g;/^.\{17\}$/!d')"
else
  macaddr2="$(ip link show $ifacename | sed '/permaddr/!d' | sort -u | wc -l)"
  if [ "$macaddr2" = "1" ]; then
    MACaddr="$(ip link show $ifacename | sed "/permaddr/!d;s/.*permaddr //g;/$ifacename:/d;s/[ ]//g;s/.*/\U&/g")"
  else
    macaddr3="$(ip link show $ifacename | sed '/link\/ether/!d' | sort -u | wc -l)"
    if [ "$macaddr3" = "1" ]; then
      MACaddr="$(ip link show $ifacename | sed "/link\/ether/!d;s/.*link\/ether //g;s/ brd.*//g;/$ifacename:/d;s/[ ]//g;s/.*/\U&/g")"
    else
      MACaddr="$(macchanger $ifacename -s | sed '/Current/d;s/Permanent MAC: //g;s/ (.*//g;s/[ ]//g;s/.*/\U&/g')"
    fi
  fi
fi



read -p "Select Band: 2.4G, or 5G, or Auto? (2/5/a) " select1
echo " "
if [ "$select1" = "2" ]; then
  echo "chosen band -> B/G (2.4 GHz)"
  selectband='wifi.band bg'
else
  if [ "$select1" = "5" ]; then
    echo "chosen band -> A (5 GHz)"
    selectband='wifi.band a'
  else
    if [ "$select1" = "a" ]; then
      echo "chosen band -> Automatic"
      # unset selectband
    else
      echo "no correct select: band -> default Automatic"
      # unset selectband
    fi
  fi
fi


echo " "
read -p "Select wifi mac randomization? (recommended) (y/n) " select2
echo " "
if [ "$select2" = "n" ]; then
  echo "chosen -> default mac (no random)"
  # unset selectmacrandom
else
  echo "chosen -> wifi mac randomization"
  selectmacrandom='wifi.mac-address-randomization 2'
fi


echo " "
read -p "Select Hidden network? (y/n) " select3
echo " "
if [ "$select3" = "y" ]; then
  echo "chosen -> Hidden network"
  selecthidden='wifi.hidden true'
else
  echo "chosen -> smooth network (not hidden)"
  # unset selecthidden
fi

echo " "
# remommended -> 'wifi.mac-address-randomization 2' something problem deleted !

nmcli con add type wifi mode ap ifname $ifacename ipv4.method shared ipv6.method shared con-name Wi-Fi-shared ssid $ESSIDname $selectband wifi-sec.key-mgmt wpa-psk wifi-sec.psk $PSKname $selectmacrandom wifi.mac-address $MACaddr $selecthidden


echo " "
echo "create -> /etc/NetworkManager/system-connections/Wi-Fi-shared.nmconnection"

# # # # #
selectband1 () {
read -p "Select Band: 2.4G, or 5G, or Auto? (2/5/a) " select1
echo " "
if [ "$select1" = "2" ]; then
  echo "chosen band -> B/G (2.4 GHz)"
  sed 's/band=.*/band=bg/g' -i /etc/NetworkManager/system-connections/Wi-Fi-shared*.nmconnection
else
  if [ "$select1" = "5" ]; then
    echo "chosen band -> A (5 GHz)"
    sed 's/band=.*/band=a/g' -i /etc/NetworkManager/system-connections/Wi-Fi-shared*.nmconnection
  else
    if [ "$select1" = "a" ]; then
      echo "chosen band -> Automatic"
      sed '/band=.*/d' -i /etc/NetworkManager/system-connections/Wi-Fi-shared*.nmconnection
    else
      echo "no correct select: band -> default Automatic"
      sed '/band=.*/d' -i /etc/NetworkManager/system-connections/Wi-Fi-shared*.nmconnection
    fi
  fi
fi
}
# # # # #

echo " "
echo "Check nmconnection file:"
echo "-----------------------------------"
cat /etc/NetworkManager/system-connections/Wi-Fi-shared*.nmconnection
echo "-----------------------------------"

#echo " "
#echo "(restart NetworkManager...)"
#echo " "
#sleep 1
#systemctl restart NetworkManager
#systemctl restart NetworkManager && systemctl restart NetworkManager.service
#service NetworkManager stop && service NetworkManager start && service NetworkManager restart

echo " "
echo "hotspot stop command ->  nmcli con down Wi-Fi-shared"
echo " "
echo "hotspot start command -> nmcli con up Wi-Fi-shared"
echo " "
echo 'hotspot start with UUID command -> UUID=$(grep uuid /etc/NetworkManager/system-connections/Wi-Fi-shared* | cut -d= -f2)'
echo 'nmcli con up uuid $UUID'
echo " "
echo "delete config file -> /etc/NetworkManager/system-connections/Wi-Fi-shared*.nmconnection"
echo " "
echo "all NtwMgr process restart -> systemctl restart NetworkManager"
echo " "
echo "Check shared network!!! Something problem use command -> nm-connection-editor"
echo " "
