#!/bin/bash
#set -e # Fire/Shout on Failures/Errors
#set -x # Replace Values, helps in debugging

#Author: Sundeep Borra <sborra@nvidia.com>
#Revision History: <10th Dec 2012>: created Initial version of script
#		 : 

function Usage()
{
cat << EOF
Usage: $0 -a <Wifi_Access_point_name> -p <passphrase_in_human_readable_format> -i <interface_name>
Options:
	-a	Wifi Access Point Name
	-p	Wifi Access Point in Human readable format, NOT in Encrypted format
	-i	wifi interface name
	-h	To print this usage format
	-u	To print this usage format
	-s	To see the source code
Examples:
	$0 -a nvmobile -p 123456 -i wlan0
EOF
	return 0
}

function wifi_config_table()
{
	[ `head -1 /etc/nv_tegra_release | grep -c R17` -gt 0 ] && RELEASE=R17
	[ $RELEASE == R16 ] && MODULE=bcm4329 && IFACE=`iwconfig 2>&1 | grep EEE | cut -d ' ' -f1`
	[ $RELEASE == R17 ] && MODULE=brcmfmac && IFACE=`iwconfig 2>&1 | grep EEE | cut -d ' ' -f1`
	[ $RELEASE == main ] && MODULE=brcmfmac && IFACE=`iwconfig 2>&1 | grep EEE | cut -d ' ' -f1`
}

function turn_down_wifi ()
{
	[ -z $MODULE ] && echo Wifi Module not found && return 1

	pkill -9 `pidof wpa_supplicant` `pidof dhclient $IFACE` >/dev/null 2>&1 
	modprobe -r $MODULE && echo "Wifi Turned Down and the driver is removed" && return 0
	echo "Failed to remove the $MODULE Driver, BUG" && return 1
}

function parse_args ()
{
	while getopts "hsuda:p:i:" opt; do
		case "$opt" in
			a) WAP_NAME=$OPTARG;;
			p) WAP_KEY=$OPTARG;;
			i) IFACE=$OPTARG;;
			s) less $0;;
			d) TURN_DOWN=1; break;;
			h|u|*) Usage;;
		esac
	done
}	

function generate_wpa_supplicant()
{
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
	dhclient $IFACE && ADDR=`ifconfig | grep "^$IFACE " -A1 |grep inet |grep -v inet6 |cut -d ':' -f2 | cut -d ' ' -f1`	
	echo "Acquired IP Address:$ADDR"
	[ `echo $ADDR | wc -c` -ge 7 ] && echo WIFI: SUCCESS && return 0
	return 1
}

function main()
{
	parse_args $@
	wifi_config_table
	[ $TURN_DOWN ] && turn_down_wifi && return 0	
	generate_wpa_supplicant
	wpa_supplicant -i $IFACE -c $WPA_SUPP_CONF_FILE -B && sleep 2
	acquire_ip
}

main $@
