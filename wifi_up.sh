#!/bin/bash 
# No formalities, but for syntax coloring when using vim

readonly export YELL_COLOR='\E[7m\E[33m'	# Red BG
readonly export FINE_COLOR='\E[7m\E[32m'	# Green BG
readonly export NORM_COLOR='\E[0m'       	# Normalize BG

function red_flag 
{
	echo -e "$YELL_COLOR $@ $NORM_COLOR"
}
export -f red_flag

function green_flag 
{
	echo -e "$FINE_COLOR $@ $NORM_COLOR"
}
export -f green_flag


function wifi_Usage()
{
cat << EOF
Usage: MODULE=<module_name> IFACE=<interface_name> $0 -a <Wifi_Access_point_name> -p <passphrase_in_human_readable_format> -i <interface_name>
Options:
	-a	Wifi Access Point Name
	-p	Wifi Access Point in Human readable format, NOT in Encrypted format
	-i	wifi interface name
	-d	turn off wifi, safely, including driver rmmod
	-h	To print this usage format
	-u	To print this usage format
	-s	To see the source code
Examples:
	MODULE=bcm43241 IFACE=wlan0 $0 -a nvmobile -p 12345678 
	MODULE=bcmdhd IFACE=wlan0 $0 -a nvmobile -p 12345678 
EOF
	return 0
}

function wifi_down ()
{
	[ -z $MODULE ] && echo pls set wifi driver variable MODULE && return 1
	[ `lsmod | grep -c $MODULE` -eq 0 ] &&  echo "Wifi Driver is already removed" && return 1

	kill -9 `pidof wpa_supplicant` `pidof dhclient $IFACE` >/dev/null 2>&1 
	modprobe -r $MODULE && echo "Wifi Turned Down and the driver is removed" && return 0
	echo -e "$YELL_COLOR Failed to remove the $MODULE Driver, BUG $NORM_COLOR" && return 1
}

function wifi_generate_wpa_supplicant()
{
	[ $# -gt 0 ] && WAP_NAME=$1 && WAP_KEY=$2
	echo WAP_NAME=$WAP_NAME 
	echo WAP_KEY =$WAP_KEY && [ `echo $WAP_KEY | wc -c` -lt 8 ] && echo "Passphrase must be 8..63 characters" && return 1

	ENCRYPTED_KEY=`wpa_passphrase $WAP_NAME $WAP_KEY | grep -e psk`
	WPA_SUPP_CONF_FILE="/etc/wpa_supplicant_WPA2.conf"
	echo "ap_scan=2" > $WPA_SUPP_CONF_FILE #Writes a fresh
	echo "ctrl_interface=DIR=/var/run/wpa_supplicant" >> $WPA_SUPP_CONF_FILE
	echo "network={" >> $WPA_SUPP_CONF_FILE
	echo "	ssid=\"$WAP_NAME\"" >> $WPA_SUPP_CONF_FILE
	echo "$ENCRYPTED_KEY" >> $WPA_SUPP_CONF_FILE
	echo "	proto=RSN WPA" >> $WPA_SUPP_CONF_FILE
	echo "	pairwise=CCMP TKIP" >> $WPA_SUPP_CONF_FILE
	echo "	key_mgmt=WPA-PSK" >> $WPA_SUPP_CONF_FILE
	echo "}" >> $WPA_SUPP_CONF_FILE
}

function acquire_ip()
{
	[ -z $IFACE ] && echo Wifi Interface not found && return 1
	if [ `ps -ef | grep dhclient | grep -c $IFACE` -gt 0 ]; then 
		echo "dhclient already running on $IFACE"
	else
		dhclient $IFACE && export ADDR=`ifconfig | grep "^$IFACE " -A1 | grep inet | grep -v inet6 | cut -d ':' -f2 | cut -d ' ' -f1`	
	fi
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

wifi_parse_args $@
[ $TURN_DOWN ] && wifi_down && return 0	
[ -z $MODULE ] && echo "Module name not mentioned" && wifi_usage && return 1
[ -z $IFACE ] && echo "Interface name not mentioned" && wifi_usage && return 2
[ `lsmod | grep -c $MODULE` -eq 0 ] && echo "inserting the driver $MODULE" && modprobe $MODULE
wifi_generate_wpa_supplicant
[ `ps -ef | grep wpa | grep -c $IFACE` -eq 0 ] && wpa_supplicant -D nl80211 -i $IFACE -c $WPA_SUPP_CONF_FILE -B && sleep 1
acquire_ip

