
function wifi_Usage()
{
cat << EOF
Usage: $0 -a <Wifi_Access_point_name> -p <passphrase_in_human_readable_format> -i <interface_name>
Options:
	-a      Wifi Access Point Name
	-p      Wifi Access Point in Human readable format, NOT in Encrypted format
	-i      wifi interface name
	-d      turn off wifi, safely, including driver rmmod
	-h      To print this usage format
	-u      To print this usage format
	-s      To see the source code
Examples:
	$0 -a nvmobile -p 123456 -i wlan0
EOF
	return 0
}

function wifi_config_table()
{
	if [ -z $MODULE ]; then
		[ `head -1 /etc/nv_tegra_release | grep -c R17` -gt 0 ] && RELEASE=R17
		[ $RELEASE == R16 ] && MODULE=bcm4329 
		[ $RELEASE == R17 ] && [ `lsmod | grep ^bcm -c` -gt 0 ] && MODULE=bcmdhd || MODULE=brcmfmac
		[ $RELEASE == "R17.1" ] && [ `lsmod | grep ^bcm -c` -gt 0 ] && MODULE=bcmdhd || MODULE=brcmfmac
		[ $RELEASE == main ] && MODULE=brcmfmac 
	fi
	IFACE=`iwconfig 2>&1 | grep EEE | grep -v p2p | cut -d ' ' -f1`
}

function wifi_down ()
{
	wifi_config_table
	[ -z $MODULE ] && echo Wifi Module not found && return 1

	kill -9 `pidof wpa_supplicant` `pidof dhclient $IFACE` >/dev/null 2>&1 
	modprobe -r $MODULE && echo "Wifi Turned Down and the driver is removed" && return 0
	echo -e "$YELL_COLOR Failed to remove the $MODULE Driver, BUG $NORM_COLOR" && return 1
}

function wifi_generate_wpa_supplicant()
{
	echo WAP_NAME=$WAP_NAME 
	echo WAP_KEY =$WAP_KEY && [ `echo $WAP_KEY | wc -c` -lt 8 ] && echo "Passphrase must be 8..63 characters" && return 1

	ENCRYPTED_KEY=`wpa_passphrase $WAP_NAME $WAP_KEY | grep -e psk`
	WPA_SUPP_CONF_FILE="/etc/wpa_supplicant_WPA2.conf"
	echo "ap_scan=2" > $WPA_SUPP_CONF_FILE #Writes a fresh
	echo "ctrl_interface=DIR=/var/run/wpa_supplicant" >> $WPA_SUPP_CONF_FILE
	echo "network={" >> $WPA_SUPP_CONF_FILE
	echo "  ssid=\"$WAP_NAME\"" >> $WPA_SUPP_CONF_FILE
	echo "$ENCRYPTED_KEY" >> $WPA_SUPP_CONF_FILE
	echo "  proto=RSN WPA" >> $WPA_SUPP_CONF_FILE
	echo "  pairwise=CCMP TKIP" >> $WPA_SUPP_CONF_FILE
	echo "  key_mgmt=WPA-PSK" >> $WPA_SUPP_CONF_FILE
	echo "}" >> $WPA_SUPP_CONF_FILE
}

function acquire_ip()
{
	[ -z $IFACE ] && echo Wifi Interface not found && return 1
	dhclient $IFACE && ADDR=`ifconfig | grep "^$IFACE " -A1 |grep inet |grep -v inet6 |cut -d ':' -f2 | cut -d ' ' -f1`     
	echo -e "$FINE_COLOR Acquired IP Address:$ADDR $NORM_COLOR"
	[ `echo $ADDR | wc -c` -ge 7 ] && echo WIFI: SUCCESS && return 0
	return 1
}

function wifi_parse_args ()
{
	while getopts "hsuda:p:i:" opt; do
   		case "$opt" in
			a) WAP_NAME=$OPTARG;;
			p) WAP_KEY=$OPTARG;;
			i) IFACE=$OPTARG;;
			s) less $0;;
			d) TURN_DOWN=1; break;;
			h|u|*) wifi_Usage;;
		esac
	done
}


local OPTIND=$OPTIND
wifi_parse_args $@
wifi_config_table
[ $TURN_DOWN ] && wifi_down && return 0 
[ `lsmod | grep -c $MODULE` -eq 0 ] && echo "inserting the driver $MODULE" && modprobe $MODULE && sleep 1
wifi_generate_wpa_supplicant
wpa_supplicant -i $IFACE -c $WPA_SUPP_CONF_FILE -B && sleep 2
acquire_ip



