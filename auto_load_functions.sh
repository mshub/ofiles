#!/bin/bash
# Author: Mohit Sharma <mohits@nvidia.com>
# About	: List of autoload functions

export Cdir="/media/Linx1/cardhu/"
export Vdir="/media/Linx1/ventana/"
export Ddir="/media/Linx1/dalmore/"
export Ldir="/media/Linx1/laguna/"
export Mgit="/media/Linx2/mohits_git/"
export Mtest="/media/Linx2/mohits_exp/"
export PS1='\u@\W$ '

function mkcd () { mkdir -p $1 && cd $1; }
alias axel="axel -a"
alias doff="xset dpms force off"
alias dbuild="find ./debian -type d | xargs chmod 755 && dpkg-deb -b debian && lintian debian.deb"
alias minicom='minicom -w -c on -C /tmp/minicom.log'
alias snotify='sudo -u mohits notify-send -i /usr/share/pixmaps/mnotify.png'
alias gcc='gcc -Wall'
alias p4v='/home/mohits/Downloads/p4v-2013.1.611503/bin/p4v'

alias dconnected='dmesg | grep -ie "pl2303 converter now" | tail -2 && dmesg | grep -ie "FTDI USB Serial Device converter now" | tail -4'
alias sclean="echo -en '\nCleaning ...' && apt-get autoclean -y > /dev/null && apt-get autoremove -y > /dev/null && echo -e ' completed.'"
alias supdate="echo -en '\nUpdating system ...' && apt-get update > /dev/null && apt-get upgrade -y"
alias netappMount_mobile_content='smbmount //netapp-pu02/mobile_content/ /media/netapp-pu02/mobile_content -o,username=mohits'
alias netappMount_mobile_content2='smbmount //netapp-pu02/mobile_content2/ /media/netapp-pu02/mobile_content2 -o,username=mohits'

#MY_TFTPD_RUNNING=0

#echo list=$0
#[ $MY_TFTPD_RUNNING -eq 0 ] && /bin/tftpd -p /tftboot && sed -i $1 's/MY_TFTPD_RUNNING=0/MY_TFTPD_RUNNING=1/'

function rootFlash()
{
	MOUNT_POINT=$1
	[ ! -d $MOUNT_POINT ] && echo -e "Given path is not a directory, exiting ..." && return 1
	printf "\nDelete files in $MOUNT_POINT, continue[Y/n]? "; read response; [ `echo $response | grep -c "Y\|y\|Yes\|YES"` -gt 0 ] && echo "Deleting files ..." || return 1

	MOUNT_POINT_SIZE=`du -hs $MOUNT_POINT | awk '{print $1}'`
	ROOTFS_SIZE=`du -hs rootfs/ | awk '{print $1}'`

	#[ `echo $MOUNT_POINT | grep -o - | wc -l` -ne "4" ] && echo "Given path is not correct, exiting ..." && return 1
	cd $MOUNT_POINT
	[ `ls $MOUNT_POINT | wc -l` -gt 1 ] && START=$(date +%s) && rm -r `ls $MOUNT_POINT | grep -v "lost+found"`\
		&& sync && NOW=$(date +%s) && echo "Deleted $MOUNT_POINT_SIZE in $(( $NOW - $START )) secs ..."
	echo -e "Copying filesystem ...\n"
	cd - > /dev/null; START=$(date +%s) && cp -rpf rootfs/* $MOUNT_POINT && sync && NOW=$(date +%s); sync && umount $MOUNT_POINT;
	echo -e "Copied $ROOTFS_SIZE in $(( $NOW - $START )) secs ...\n"
	echo -e 'Done !\n'
}
export -f rootFlash

function TOTUsage()
{
cat << "TOTUsage"
        Usage: TOT [#platform_branch]
        platform_branch:
	d17/D17       for Dalmore rel17
	d171/D171     for Dalmore rel17.1
	dmain/Dmain   for Dalmore main
	c16/C16       for Cardhu rel16
	c17/C17       for Cardhu rel17
	cmain/Cmain   for Cardhu main
	lmain/Lmain   for Ardbeg/Laguna main

	Example:
		TOT lmain	# To download Laguna TOT on main
TOTUsage
	return 1
}

function TOT()
{
	TOT_ARG=$1

	DalmoreRel17="http://buildbrain/mobile/automatic/rel-17_linux-k340_dalmore-t114_dev_git-master_hardfp_release"
	Dalmore17r1="http://buildbrain/mobile/automatic/l4t-l4t-r17.1_linux-k340_dalmore-t114_dev_git-master_hardfp_release"
	DalmoreMain="http://buildbrain/mobile/automatic/main_linux-k310_dalmore-t114_dev_git-master_hardfp_release"
	CardhuRel16="http://buildbrain/mobile/automatic/l4t-l4t-r16_linux-k310_cardhu_dev_git-master_hardfp_release"
	CardhuRel17="http://buildbrain/mobile/automatic/rel-17_linux-k340_cardhu_dev_git-master_hardfp_release"
	Cardhu17r1="http://buildbrain/mobile/automatic/l4t-l4t-r17.1_linux-k340_cardhu_dev_git-master_hardfp_release"
	CardhuMain="http://buildbrain/mobile/automatic/main_linux-k380_cardhu_dev_git-master_hardfp_release"
	ArdbegMain="http://buildbrain/mobile/automatic/main_linux-k310_ardbeg_dev_git-master_hardfp_release"

        if [ `echo $TOT_ARG | grep -ie http://buildbrain/mobile/automatic/` ]; then
		BUILDNO=$(echo $TOT_ARG | egrep -o [0-9]\{7})
		BUILD_ADDR="$TOT_ARG/full_linux_for_tegra.tbz2"

	elif [ `echo $TOT_ARG | grep -c "d171\|D171"` -gt 0 ]; then
		BUILDNO=`curl -s $Dalmore17r1/ | grep href | tail -1 | egrep -o [0-9]\{7} | head -1` && URL=$Dalmore17r1; BUILD_ADDR="$URL/$BUILDNO/full_linux_for_tegra.tbz2"
	elif [ `echo $TOT_ARG | grep -c "d17\|D17"` -gt 0 ]; then
		BUILDNO=`curl -s $DalmoreRel17/ | grep href | tail -1 | egrep -o [0-9]\{7} | head -1` && URL=$DalmoreRel17; BUILD_ADDR="$URL/$BUILDNO/full_linux_for_tegra.tbz2"
	elif [ `echo $TOT_ARG | grep -c  "dmain\|Dmain"` -gt 0 ]; then
		BUILDNO=`curl -s $DalmoreMain/ | grep href | tail -1 | egrep -o [0-9]\{7} | head -1` && URL=$DalmoreMain; BUILD_ADDR="$URL/$BUILDNO/full_linux_for_tegra.tbz2"
	elif [ `echo $TOT_ARG | grep -c  "c16\|C16"` -gt 0 ]; then
		BUILDNO=`curl -s $CardhuRel16/ | grep href | tail -1 | egrep -o [0-9]\{7} | head -1` && URL=$CardhuRel16; BUILD_ADDR="$URL/$BUILDNO/full_linux_for_tegra.tbz2"
	elif [ `echo $TOT_ARG | grep -c  "c171\|C171"` -gt 0 ]; then
		BUILDNO=`curl -s $Cardhu17r1/ | grep href | tail -1 | egrep -o [0-9]\{7} | head -1` && URL=$Cardhu17r1; BUILD_ADDR="$URL/$BUILDNO/full_linux_for_tegra.tbz2"
	elif [ `echo $TOT_ARG | grep -c  "c17\|C17"` -gt 0 ]; then
		BUILDNO=`curl -s $CardhuRel17/ | grep href | tail -1 | egrep -o [0-9]\{7} | head -1` && URL=$CardhuRel17; BUILD_ADDR="$URL/$BUILDNO/full_linux_for_tegra.tbz2"
	elif [ `echo $TOT_ARG | grep -c  "cmain\|Cmain"` -gt 0 ]; then
		BUILDNO=`curl -s $CardhuMain/ | grep href | tail -1 | egrep -o [0-9]\{7} | head -1` && URL=$CardhuMain; BUILD_ADDR="$URL/$BUILDNO/full_linux_for_tegra.tbz2"
	elif [ `echo $TOT_ARG | grep -c  "lmain\|Lmain"` -gt 0 ]; then
		BUILDNO=`curl -s $ArdbegMain/ | grep href | tail -1 | egrep -o [0-9]\{7} | head -1` && URL=$ArdbegMain; BUILD_ADDR="$URL/$BUILDNO/full_linux_for_tegra.tbz2"
	else
		TOTUsage; return 1
	fi

	[ -d "$BUILDNO" ] && echo "TOT build directory $BUILDNO/ already exists ..." && return 1

	sudo mkdir ./$BUILDNO; cd $BUILDNO; sync;
	#echo -e "Downloading build ..."
	sudo axel -a -n 50 $BUILD_ADDR && l4t_ready.sh

        echo -e "Build Add:\n$BUILD_ADDR" >> full_linux_for_tegra/Linux_for_Tegra/rootfs/home/ubuntu/.build_info
	cd full_linux_for_tegra/Linux_for_Tegra > /dev/null
}
export -f TOT

