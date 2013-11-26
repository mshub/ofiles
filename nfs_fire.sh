#!/bin/bash

function Usage ()
{
cat << EOF
Usage: $0 -p <platform_name> -f <rootfs_path> 
	-p: platform name <harmony/ventana/cardhu>
	-d: primary display pick up option for hdmi, default being lcd
	-f: filesystem_path (absolute, NOT relative)
	-b: bootloader to use <u for u-boot, f for fastboot>
	-h: <display this message>
	-u: <same as -h>
	-s: <display the source code>
EOF
exit 1
}

[ `pwd | grep -ie cardhu -c` -gt 0 ] && PLATFORM=cardhu
[ `pwd | grep -ie beaver -c` -gt 0 ] && PLATFORM=beaver
[ `pwd | grep -ie ventana -c` -gt 0 ] && PLATFORM=ventana
[ `pwd | grep -ie dalmore -c` -gt 0 ] && PLATFORM=dalmore
[ `pwd | grep -ie laguna -c` -gt 0 ] && PLATFORM=laguna

function die_with_message()
{
	echo -e "\nERROR/ALERT:$@\n" && Usage
}

function info_message()
{
	echo -e "$@" 
}

uboot_setup ()
{
	[ ! -d /tftpboot/ ] && echo check for tfptboot server installation and /tftpboot presence
	cp -aprf $FSPATH/boot/vmlinux.uimg /tftpboot && \
	[ $BOOTLOADER == u ] && EXTRA_ARGS="$EXTRA_ARGS -L ./bootloader/$PLATFORM/u-boot.bin" # For u-boot
}

function optparser()
{
	BOOTLOADER_FLAG=0

	while getopts "p:df:x:b:hus" opt; do
		case $opt in 
			p) PLATFORM=$OPTARG
				;;
			d) DISP=1 # For HDMI
				 EXTRA_ARGS="$EXTRA_ARGS -C \"fbcon=map:1\""
				;;
			f) FSPATH=$OPTARG
				;;
			b) BOOTLOADER=$OPTARG
				BOOTLOADER_FLAG=1
				;;
			s) more $0 && exit 1
				;;
			x)
				EXTRA_ARGS+="$OPTARG"
				;;
			h|u|?)
				Usage
				;;
		esac
	done
	[ -z $PLATFORM ] && die_with_message "Board name is not mentioned"
	[ -z $FSPATH ] && FSPATH=$PWD/rootfs/ && info_message  "selected Rootfs as $FSPATH by default"
	[ $BOOTLOADER_FLAG -eq 1 ] && uboot_setup
	[ -z $BOOTLOADER ] && BOOTLOADER="f" && info_message "selected bootloader as fastboot by default"
}

optparser $@

THIS_IP=`ifconfig |grep "addr:10.24." | cut -d ':' -f2 | cut -d ' ' -f1`
IFACE=eth0

[ `echo $FSPATH | cut -d '' -c1` != "/" ] && die_with_message "Absolute path needed, relative path won't work"

# To avoid duplicate entries in /etc/exports file
[ `cat /etc/exports | grep -c $FSPATH` -eq 0 ] && echo "$FSPATH  *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports

/etc/init.d/nfs-kernel-server restart && \
echo -e "\n\n./flash.sh $EXTRA_ARGS -N $THIS_IP:$FSPATH $PLATFORM $IFACE\n\n" && \
./flash.sh $EXTRA_ARGS -N $THIS_IP:$FSPATH $PLATFORM $IFACE


