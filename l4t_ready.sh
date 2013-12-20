
# AUTHOR: SUNDEEP BORRA <sborra@nvidia.com>
# FILE: 
# (C) NVIDIA Corp

set -e

[ $USER != root ] && echo Not a root user, Sorry && exit 1

L1_DIR=$PWD
L2_DIR="$L1_DIR/full_linux_for_tegra"
CLEAN_UP=0
REDO=0
SOURCE_CLEAN=0

function create_custom_tools ()
{
cat > $1/custom_functions << 'CUSTOM_EOF'
#!/bin/bash # No formalities, but for syntax coloring when using vim

#tee -a /etc/bash.bashrc <<EOF EOF
#ip link show, netstat -i

#Device out speaker volume controls

function hpvolume ()
{
	VOLNUMID=$(amixer controls | grep -ie "HP Playback Volume\|HP Volume" | cut -d "," -f1 | cut -d"=" -f2)
	amixer cset numid=$VOLNUMID $1
}
export -f hpvolume

function dvolume ()
{
	VOLNUMID=$(amixer controls | grep -ie "Speaker Volume\|Speaker Playback Volume" | cut -d "," -f1 | cut -d"=" -f2)
	amixer cset numid=$VOLNUMID $1
}
export -f dvolume

alias snotify='sudo -u ubuntu notify-send '
alias grep='grep -v grep | grep'
alias ll='ls -al'
alias nvgstplayer='nvgstplayer --stats'
alias cactive="while true; do cat /sys/kernel/cluster/active; sleep 1; done"
alias enlog='echo 7 > /proc/sys/kernel/printk'
alias delog='echo 4 > /proc/sys/kernel/printk'
alias reboot_stress='echo "init 6" >> /root/.bashrc'
alias drop_caches='echo 3 > /proc/sys/vm/drop_caches'
alias hostinfo='cat ~/.host_info'
alias buildinfo='cat /home/ubuntu/.build_info'
alias nvg="nvgstplayer --svs=\"ximagesink\" --svd=\"jpegdec\" --disable-vnative"
alias hclear='history -c' # Use it carefully
alias lp0_on='echo lp0 > /sys/power/suspend/mode'
alias lp1_on='echo lp1 > /sys/power/suspend/mode'
alias lp_on='echo mem > /sys/power/state'
alias lp2_on='xset +dpms && xset s on'
alias lp2_off='xset -dpms && xset s off'
alias doff='xset dpms force off'
alias dtemp='cat /sys/devices/platform/tegra-i2c.4/i2c-4/4-004c/ext_temperature'
alias stemp='cat /sys/devices/platform/tegra-i2c.4/i2c-4/4-004c/temperature'
alias iplay='for i in `ls -t | grep -ie jpg`; do echo -e "\n$YELL_COLOR Playing $i ... $NORM_COLOR\n"; nvg -i $i; done'
alias vplay='for i in `ls -t | grep -ie "mp4\|avi\|wmv\|3gp"`; do echo -e "\n\n$YELL_COLOR Playing $i ... $NORM_COLOR"; sleep 2; nvgstplayer --stats -i $i $NORM_COLOR\n; done'
alias hseparator='seq -s= 50 | tr -d [:digit:]'
alias which_governor='cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'

alias mmplugininstall1.0='sudo apt-get install gstreamer1.0-tools gstreamer1.0-alsa gstreamer1.0-plugins-base\
       	gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-plugins-bad gstreamer1.0-libav -y'
alias mmplugininstall='sudo apt-get install gstreamer-tools gstreamer0.10-alsa gstreamer0.10-plugins-good\
	gstreamer0.10-plugins-base gstreamer0.10-plugins-ugly gstreamer0.10-plugins-bad gstreamer0.10-ffmpeg -y'
alias mmallmount='mount -t cifs //10.24.121.7/u_create /mnt -o ro,username=mohits,sec=ntlm'
alias miscinstall='apt-get update && apt-get install man cifs-utils evtest mlocate usbutils x11-xserver-utils scrot vim sysstat libav-tools file -y && updatedb' #gdisk dosfstools
alias pyproperties='sudo apt-get install python-software-properties'
alias mininstall='sudo apt-get update && apt-get install cifs-utils'
alias minimumInstall='sudo apt-get install xorg xterm gdm menu gksu synaptic gnome-session gnome-panel metacity gnome-terminal --no-install-recommends'

alias btinstall='sudo apt-get install bluez-compat bluez blueman -y'
rfkillnode=`find /sys/devices/platform/bluedroid_pm.0/rfkill/ -name state`
alias bt_on='echo 1 > ${rfkillnode}'
alias bt_off='echo 0 > ${rfkillnode}'
function bt_help ()
{
cat <<"DEV_MODE_EOF"
Usage:
	hciconfig -a hci0			Finding HCI/LMP version
	sdptool browse local			Finding available BT profiles
	hcitool scan				Discovering available nearby BT devices
	hcotool info BDADDRESS			H/W capabilities
	sdptool browse BDADDRESS		sdptool browse BDADDRESS
	sudo hidd -i hci0 --connect BDADDRESS	Connecting to a HID device
DEV_MODE_EOF
}
export -f bt_help

export MINICOM='-c on -o -w -C /tmp/mini.cap'
export PATH=$PATH:/home/ubuntu/
export DISPLAY=:0
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/ubuntu/
readonly export YELL_COLOR='\E[7m\E[33m'	# Red BG
readonly export FINE_COLOR='\E[7m\E[32m'	# Green BG
readonly export NORM_COLOR='\E[0m'       	# Normalize BG
readonly export L4T_HOST_UNAME=mohits

audio_files=( "AAC_01_Alone.mp4" "AMRNB_monsters_10.2.3gp" "AMRWB_monsters_24Kbps_16KHz.3GP" "MP3_01_Rhythm_Is_A_Dancer_12_Mix.mp3" 'MP3_01_Rhythm_Is_A_Dancer_12_Mix.mp3 --cxpr="r10 s25 w5 s12 w20"' 'Hotel-California_ac3_2ch_256_48k.mka --disable-anative' "chakdeindia_Alaw_8bit.wav" "LMRstereo.wav" "chakdeindia_mulaw_8bit.wav" "Blues.wma" "03 Track 3_WMA_9.1_Lossless_VBRQuality_100_44kHz_2channel_16bit_1-pass_VBR.asf" "Track_16_WMA_10_Professional_192 kbps_44kHz_2channel_16bit_1-pass_CBR.wma" )

video_files=( "TEGRA_Mpeg2-mp-hl_1080i_30fps_12Mbps.ts" "vantage_point_90s_mpeg4_asp_1080p_10M_30p_cbr_aac128_44.mp4" "3_transformers_divx_1080_30_10M.avi" "Princessandthefrog_XVID_1080p_2M_30fps_Mp3_128_32.avi" "TS_mpeg2_aaclc_2_bahara_main@high.ts" "transformers_h264_bp_1080_30_20M.mp4" "medusa_h264_bp_720_2M.mp4" "h263_aac_VGA.mp4" "TEGRA_h264_hp_1080i_20M_60i_aac.MP4" 'wallpapaer-robo-450x337.jpg --svs="ximagesink" --svd="jpegdec" --disable-vnative -e elem.txt' "medusa_mpeg4_sp_720_30_6M.mp4" "casino_royal_wmv_1080P_24fps_20M_AP_wma_128_48.wmv" "Birds_VC1_sp_cif_15fps_384kbps_wma9_256kbps_44khz.asf" 'casino_royal_wmv_1080P_24fps_20M_AP_wma_128_48.wmv --svs="nvxvimagesink"' "H.264_HP_1080p_Cabac_WP.mp4" "H.264_MP_1080p_Cabac_WP.mp4" )

stream_files=( "http://10.25.20.77/MP3/CemeteriesOfLondon.mp3" "http://10.25.20.77/ASF/Blue_One_Love_320kbps_44KHz_S_WMA.asf" "http://10.25.20.77/AVI/8_DivX_5.x_QVGA_30fps_1000Kbps_Mp3_94_44S.avi" "http://10.25.20.77/wma/Dishrag64-44s.wma" "http://10.25.20.77/ASF/golden_flower_wmv_wma_720_30p_1M.wmv" "rtsp://10.25.20.77:554/RTSP_contents/AUDIO/AAC/3GP/AAC_LC_96kbps_44khz_stereo.3GP" "rtsp://10.25.20.77:554/3gp/amr/monsters_12.2_8khz.3gp" "rtsp://10.25.20.77:554/3gp/h263+amrnb/Crazy_Frog_h.263_amrnw.3gp" "rtsp://10.25.20.77:554/3gp/H264+aac/H264_BP_level3_2000kbps_320x240_36fps_aac_112kbps_44.1khz_stereo.3gp" "rtsp://10.25.20.77:554/mp4/mpeg4+aac/medusa_mpeg4_qvga_30fps_192kbps_aac_16khz_64kbps_stereo.mp4" "rtsp://10.25.20.77:554/RTSP_contents/AUDIO+VIDEO/MPEG+AACP/mpegaacp.3gp" "rtsp://10.25.20.77:554/RTSP_contents/VIDEO/MPEG/MPEG4_BR128_QVGA_FR30.3gp" )

alsa_files=( "colorofmagic.wav" "alban16m16.wav" "LMRstereo.wav" )

graphic=( "nvtest testardrv_all" "graphics_submit" "nvtest nvddk2d_rendering_tests.so" "nvtest nvddk2d_rendering_tests.so --sanity" "nvtest nvddk_2d_test_brush.so" "nvtest nvddk_2d_test_sanity.so" "nvtest nvddk2d_stress.so -l -c10" "nvtest gles1_all -atslevel 0" "nvtest gles2_all --Tsrc -atslevel 0" "gles2_conform -noimagefileio -run=/home/ubuntu/data/conform/opengles2/mustpass.run -id=1 -width=113 -height=47" "nvtest gles2_gears.so 10 --Twinsys x11" )

camera=( "nvgstcapture -A -C -e 0" "nvgstcapture -A -C -e 100" "nvgstcapture -A -C -e 200" "nvgstcapture -A -C -I 640x480" "nvgstcapture -A -C -I 1280x720" "nvgstcapture -A -C -I 2560x1920" "nvgstcapture -A -C -w 4" "nvgstcapture -A -C -w 2" "nvgstcapture -A -C -Z 2" "nvgstcapture -A -C -Z 4" "nvgstcapture -A -C -Z 5" "nvgstcapture -A -C -Z 8" "nvgstcapture -A -C -m 2 -V 1280x720" "nvgstcapture -A -C -m 2 -V 176x144" "nvgstcapture -A -C -m 2 -V 1920x1080" )

usbcamera=( "nvgstcapture --svs=ximagesink --usbcam" "nvgstcapture --svs=ximagesink --usbcam -H 1" "nvgstcapture --svs=ximagesink --usbcam -I 640x480" "nvgstcapture --svs=ximagesink --usbcam -H 1 -I 640x480" "nvgstcapture --svs=ximagesink --usbcam -V 640x480 -m 2" "nvgstcapture --svs=ximagesink --usbcam -H 1 -V 640x480 -m 2" "nvgstcapture --svs=ximagesink --usbcam -V 640x480 -m 2 -v 2" )

function mm_sanity_test ()
{
	input=$1
	[ "$input" == "audio" ] && for (( i=0;i<${#audio_files[@]};i++ )); do echo -e "\n$YELL_COLOR Playing ${audio_files[$i]} ... $NORM_COLOR\n"; nvgstplayer -i ${audio_files[$i]}; done
	[ "$input" == "video" ] && for (( i=0;i<${#video_files[@]};i++ )); do echo -e "\n$YELL_COLOR Playing ${video_files[$i]} ... $NORM_COLOR\n"; nvgstplayer --stats -i ${video_files[$i]}; done
	[ "$input" == "alsa" ] && for (( i=0;i<${#alsa_files[@]};i++ )); do echo -e "\n$YELL_COLOR Playing ${alsa_files[$i]} ... $NORM_COLOR\n"; aplay ${alsa_files[$i]}; done
	[ "$input" == "stream" ] && for (( i=0;i<${#stream_files[@]};i++ )); do echo -e "\n$YELL_COLOR Playing ${stream_files[$i]} ... $NORM_COLOR\n"; nvgstplayer --stats -i ${stream_files[$i]}; done
	[ "$input" == "graphic" ] && for (( i=0;i<${#graphic[*]};i++ )); do hseparator && echo -e "\n$YELL_COLOR Running ${graphic[$i]} ... $NORM_COLOR" && script -c "${graphic[$i]}" | tail -8 | head -5; done
	[ "$input" == "camera" ] && for i in `seq 1 ${#camera[@]}`; do hseparator && echo -e "\n$YELL_COLOR Running ${camera[$i]} ... $NORM_COLOR\n"; sleep 2; ${camera[$i]}; done 
	[ "$input" == "usbcamera" ] && for i in `seq 1 ${#usbcamera[@]}`; do hseparator && echo -e "\n$YELL_COLOR Running ${usbcamera[$i]} ... $NORM_COLOR\n"; sleep 2; ${usbcamera[$i]}; done 
}
export -f mm_sanity_test

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

function snd_level_ctrl()
{
	CURRENT_VAL=`amixer cget name='Speaker Volume' | grep ":" | cut -d "," -f2`
	# "+" will override "-"
	if [ `echo $1 | grep -c +` -gt 0 ]; then
		CURRENT_VAL=$(( CURRENT_VAL + (10*${#1}) ))
	else
		CURRENT_VAL=$(( CURRENT_VAL - (10*${#1}) ))
	fi
	[ $CURRENT_VAL -lt 0 ] && CURRENT_VAL=20
	amixer cset name='Speaker Volume' $CURRENT_VAL $CURRENT_VAL
}
export -f snd_level_ctrl

function amixer_for_mic_enable()
{
	#To enable the mic input using following commands. 
	if [ `cat /proc/cpuinfo | grep -c cardhu` -gt 0 ]; then
	# Cardhu/ventana have built-in MIC, No external Headset mic is allowed
		amixer cset name='Int Mic Switch' on 
		amixer cset name='ADC Input' 1 
		amixer cset name='Left Input PGA Switch' on 
		amixer cset name='Right Input PGA Switch' on 
		amixer cset name='Left Input Mux' on 
		amixer cset name='Right Input Mux' on 
		amixer cset name='Headphone Volume' 63,63 
		amixer cset name='Left Input PGA Volume' 31,31 
		amixer cset name='Right Input PGA Volume' 31,31 
	elif [ `cat /proc/cpuinfo | grep -c dalmore` -gt 0 ]; then
	# Dalmore has no built-in MIC, only external Headset mic is allowed
		amixer cset name="ADC Capture Switch" 1
		amixer cset name="RECMIXR BST1 Switch" 1
		amixer cset name="RECMIXL BST1 Switch" 1
		amixer cset name="RECMIXR BST2 Switch" 0
		amixer cset name="RECMIXL BST2 Switch" 0
		amixer cset name="Mic Jack Switch" 1
	fi
}
export -f amixer_for_mic_enable

function amixer_for_loud_speaker()
{
	#To route audio via loudspeaker 
	if [ `cat /proc/cpuinfo | grep -c cardhu` -gt 0 ]; then
		amixer cset name='Speaker Switch' on
		amixer cset name='Speaker ZC Switch' on
		amixer cset name='Line Out ZC Switch' on
		amixer cset name='Right Speaker Mixer DACL Switch' on
		amixer cset name='Right Speaker Mixer DACR Switch' on
		amixer cset name='Right Speaker Mixer Left Bypass Switch' on
		amixer cset name='Right Speaker Mixer Right Bypass Switch' on
		amixer cset name='Left Speaker Mixer DACL Switch' on
		amixer cset name='Left Speaker Mixer DACR Switch' on
		amixer cset name='Left Output Mixer Left Bypass Switch' on
		amixer cset name='Left Output Mixer Right Bypass Switch' on
		amixer cset name='Digital Playback Volume' 120,120
		amixer cset name='Speaker Volume' 63,63
	elif [ `cat /proc/cpuinfo | grep -c dalmore` -gt 0 ]; then
		amixer cset name="Int Spk Switch" 1 #(1 for ON, 0 for OFF)
	fi
}
export -f amixer_for_loud_speaker

function attention_fire()
{
	EXCEPT1='init: Failed to create pty - disabling logging for job'
	echo -e "$YELL_COLOR ALERTS: on failure/err/warn/" un"/"mis"/Not/Negative_values $NORM_COLOR"
	cat $1 | grep -ie 'err\|fail\|no \|can\| un\| non\|mis\| too\|warn\| -[0-9]\+\|except' | sort | uniq  #| grep -v $EXCEPT1
}
export -f attention_fire

function sqa_play()
{
	[ `which bc | wc -l` -ne 1 ] && echo "bc is missing, pls install bc with apt-get" && return 1
	[ $# -lt 2 ] && echo -e "Usage: $0: \n\t \
	parse arguments as you do for nvgstplayer,\n\t \
	This will display frame drop percentage and any suspicious strings found to be warned of" && return 2

	MM_ARGS="$@"
	rm -rf gst_statistics.txt
        script -c "nvgstplayer --stats $MM_ARGS" && echo -e "$FINE_COLOR played successfully $NORM_COLOR"

	if [ `cat gst_statistics.txt | grep -c -ie "appox.rend" -ie "approx"` -gt 0 ]; then
		rendered=`tail -2 gst_statistics.txt | head -1 | cut -d ',' -f1 | tr -d ' ' | cut  -d ":" -f 2`
		dropped=`tail -2 gst_statistics.txt | head -1 | cut -d ',' -f2 | tr -d ' ' | cut  -d ":" -f 2`

		drop_percent=`echo 100*$dropped/\($dropped+$rendered\) | bc -l`

		echo -e "$YELL_COLOR dropped=$dropped\n rendered=$rendered\n drop_percent=$drop_percent $NORM_COLOR"
	fi
	attention_fire ./typescript
	rm typescript gst_statistics.txt
}
export -f sqa_play

function nvmm_packages()
{
	EXTRA_ARGS=""
	[ -z $1 ] && EXTRA_ARGS="rm /var/cache/apt/archives/*.deb"
	apt-get install gstreamer-tools gstreamer0.10-alsa gstreamer0.10-plugins-good \
	gstreamer0.10-plugins-base gstreamer0.10-plugins-ugly gstreamer0.10-plugins-bad \
	gstreamer0.10-ffmpeg smbfs evtest locate vim tmux bc -y && $EXTRA_ARGS
}
export -f nvmm_packages

function hdmi_resolution_changer_blanker_unblanker()
{
	WHICH_FB=$1
	: ${WHICH_FB:=1}
	: ${HDMI_ACTION_GAP:=5}
	: ${HDMI_PRIMARY_DISPLAY:=0}	

	[ $HDMI_PRIMARY_DISPLAY -eq 0 ] && ${DISPLAY_TYPE:="HDMI-1"} || ${DISPLAY_TYPE:="LVDS-1"}

	echo WHICH_FB=$WHICH_FB HDMI_ACTION_GAP=$HDMI_ACTION_GAP

	MODES_FILE=`find /sys/ -name modes | grep fb${WHICH_FB}`
	BLANK_FILE=`find /sys -name blank | grep fb${WHICH_FB}`

	let total_modes=`cat $MODES_FILE |wc -l`
	let count=0
	
	cat $MODES_FILE | tac | while read line; do
		FLAG_OK=0

		RESOLUTION=`echo $line | cut -d ":" -f2- | cut -d "p" -f1`
		FREQUENCY=`echo $line | cut -d ":" -f2- | cut -d "-" -f2`
	
		# Set/keep the mode for HDMI_ACTION_GAP Seconds
		echo -e "$YELL_COLOR ALERT: Changing the mode to resolution/frequency=$RESOLUTION/$FREQUENCY $NORM_COLOR"
	
		xrandr --output $DISPLAY_TYPE --mode $RESOLUTION --rate $FREQUENCY
	
		sleep $HDMI_ACTION_GAP

		[ `echo $line | grep $RESOLUTION | wc -l` -gt 0 ] && let count++ && \
			echo "Entry  number is $count/$total_modes" \
			&& sleep $HDMI_ACTION_GAP && FLAG_OK=1
		echo -e "$YELL_COLOR blanking: ...$NORM_COLOR" && echo 1 > $BLANK_FILE && sleep $HDMI_ACTION_GAP
		echo -e "$YELL_COLOR unblanking: ...$NORM_COLOR" && echo 0 > $BLANK_FILE && sleep $HDMI_ACTION_GAP
		[ $FLAG_OK -eq 1 ] && continue

		echo -e "$YELL_COLOR ERROR: resolution set has mismatched while cross checking $NORM_COLOR"
	done
}
export -f hdmi_resolution_changer_blanker_unblanker

function dev_mode_Usage()
{
cat <<"DEV_MODE_EOF"
		Usage: $0 -c <device_name>
		Options:
		-c	To connect the device in device mode with <device_name> as MSD
		-d	To disconnect and remove the driver module
		-h	To print this usage format
		-u	To print this usage format
		Example: $0 -c /dev/mmcblk1p1
DEV_MODE_EOF
	exit 1;
}

function dev_mode_parse_args ()
{
	local OPTIND=$OPTIND
	local OPTARG=$OPTARG
	while getopts "dhuc:" opt; do
		case "$opt" in
			c) CONNECT=1 && DEV_NAME=$OPTARG
				[ `echo $DEV_NAME | grep -c "^/"` -eq 0 ] && \
				echo -e "$YELL_COLOR ERROR: Device name should be absolute, not relative $NORM_COLOR" && \
				dev_mode_Usage
				;;
			d) DISCONNECT=1;;
			h|u|*) dev_mode_Usage;;
		esac
	done
	[ $CONNECT -eq 1 ] && [ $DISCONNECT -eq 1 ] && \
	echo -e "$YELL_COLOR ERROR: Argument conflict, use either -c or -d, but not both $NORM_COLOR"&& dev_mode_Usage
}

function dev_mode ()
{
	MODULE=g_mass_storage
	CONNECT=0
	DISCONNECT=0

	[ $# -lt 1 ] && dev_mode_Usage
	dev_mode_parse_args $@

	if [ 1 -eq $CONNECT ]; then
		DEVICE_LIST=`echo $dev | tr -d ' '| tr -s ',' '\n'`
		for EACH in $DEVICE_LIST; do
			[ ! -b $DEV_NAME ] && \
			echo Device file $EACH not found, Please enter a valid device file name && \
			exit 1
		done
		modprobe $MODULE removable=1 iSerialNumber=1 file=$DEV_NAME && sleep 1 && \
		echo connect > `find /sys -name soft_connect`
		[ $? -eq 0 ] && echo -e "$FINE_COLOR SUCCESS: mounted $DEV_NAME in device mode $NORM_COLOR" \
			|| echo -e "$YELL_COLOR FAILED to put the device to device mode $NORM_COLOR"
	elif [ 1 -eq $DISCONNECT ]; then
		echo disconnect > `find /sys -name soft_connect` && modprobe -r $MODULE
	fi
}
export -f dev_mode 

function read_line()
{
        FILE=$1 && echo FILE=$FILE # file_name
        shift 1

        LINES="$@" && LINES=`echo $LINES | tr -s ' '` && echo LINES=$LINES
        for i in $LINES; do
                echo `head -$i $FILE | tail -1`
        done
}
export -f read_line

function run_loop()
{
	RUN_TEST=$@

	: ${NLIMIT:=20}
	for i in `seq 1 $NLIMIT`; do
		echo -e "$YELL_COLOR Started: Iteration number = $i $NORM_COLOR" 
		#do run the test 
		$RUN_TEST 
		echo -e "$YELL_COLOR Exiting: Iteration number = $i $NORM_COLOR" 
	done
}
export -f run_loop

function run_line ()
{
	FILE=$1 && echo FILE=$FILE # file_name
	shift 1

	LINES="$@" && LINES=`echo $LINES | tr -s ' '` && echo LINES=$LINES
    
        LAST_LINE="${@: -1}" && TOTAL_LINES=`wc -l $FILE | cut -d ' ' -f1`
        [ $LAST_LINE -gt $TOTAL_LINES ] && \
		echo -e "\n\t*** Invalid line number to be executed; check bounds of file before mentioning lines ***" && return 1

	for i in $LINES; do
		echo LINE=$i && . `head -$i $FILE | tail -1`
	done
}
export -f run_line

function mkcd()
{
	mkdir $1 && cd $1
}
export -f mkcd

function join_files()
{
	lines=`wc -l $1 | cut -d' ' -f1`

	for i in `seq 1 $lines`; do
		str1=`head -$i $1 |tail -1`
		str2=`head -$i $2 |tail -1`
		echo "$str1 $str2"   
	done
}
export -f join_files

function swap_files()
{
	TEMP=`mktemp` && cp $2 $TEMP && cp $1 $2 && cp $TEMP $1 && rm -f $TEMP
}
export -f swap_files

function reflashfs()
{
	if [ "$#" -ne 1 ]; then
		echo -e "\nUsage:\t$FUNCNAME <mount_point>\n"
		echo -e "\nExample:\n\t$FUNCNAME /media/40be3b92-e63e-4583-ba85-5d528c19368d\n"
		return 1
	fi
	MNT_POINT=$1

	[ ! -d $MNT_POINT ] && echo $MNT_POINT is not a directory && return 2

#	Do it carefully, or else you can wipe off the host rootfs, and can harm self
	if [ `echo $MNT_POINT |grep -c media` -gt 0 ] && [ `echo $MNT_POINT | grep -o "-" | wc -l` -gt 3 ]; then
		echo will remove data on $MNT_POINT, abort now for not doing so
		rm -rf $MNT_POINT/lib* $MNT_POINT/[a-k,m-z]* && cp -aprf ./rootfs/* $MNT_POINT/ && umount -v $MNT_POINT/
	else
		echo -e "$YELL_COLOR Invalid partition mentioned for wipe-off, Check the partitions and mount point for valid ext3 fs on it $NORM_COLOR"
	fi
}
export -f reflashfs

function convert_resize_image()
{
	percentage=$1
	in_file=$2
	out_file=$3
	convert $in_file -resize $percentage $out_file
}
export -f convert_resize_image

function chrooter()
{
	if [ ! -z $1 ]; then
		DEVICE=$1
		mount -o bind /dev $DEVICE/dev/
		mount -o bind /proc $DEVICE/proc/
		mount -o bind /run $DEVICE/run/
		chroot $DEVICE
	else
		echo -e "$YELL_COLOR Error: Enter the mount point which should be considered as New root $NORM_COLOR"
		return 1
	fi
}
export -f chrooter

function smb_mm()
{
	mount -t cifs //netapp-pu02/mobile_content2/Content/L4T_Sanity /media -o ro,username=$L4T_HOST_UNAME,sec=ntlm
}
export -f smb_mm

function nvx()
{
	export DISPLAY=:0.0 && xinit & sleep 2
}
export -f nvx

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
		if [ $RELEASE == R16 ]; then
			MODULE=bcm4329
		elif [ $RELEASE == R17 ]; then
			[ `lsmod | grep ^bcm -c` -gt 0 ] && MODULE=bcmdhd || MODULE=brcmfmac
		elif [ $RELEASE == "R17.1" ]; then
			[ `lsmod | grep ^bcm -c` -gt 0 ] && MODULE=bcmdhd || MODULE=brcmfmac
		elif [ $RELEASE == main ]; then
			MODULE=brcmfmac
		fi
			export MDOULE
	fi
	[ -z $IFACE ] && export IFACE=`iwconfig 2>&1 | grep EEE | grep -v p2p | cut -d ' ' -f1`
}

function wifi_down ()
{
	wifi_config_table
	[ -z $MODULE ] && echo Wifi Module not found && return 1
	[ `lsmod | grep -c $MODULE` -eq 0 ] &&  echo "Wifi Driver is already removed" && return 1

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
	if [ `ps -ef | grep dhclient | grep -c $IFACE` -gt 0 ]; then 
		echo "dhclient already running on $IFACE"
	else
		dhclient $IFACE && ADDR=`ifconfig | grep "^$IFACE " -A1 | grep inet | grep -v inet6 | cut -d ':' -f2 | cut -d ' ' -f1` && export ADDR
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

function wifi_up ()
{
	local OPTIND=$OPTIND
	wifi_parse_args $@
	[ $TURN_DOWN ] && wifi_down && return 0
	wifi_config_table
	[ `lsmod | grep -c $MODULE` -eq 0 ] && echo "inserting the driver $MODULE" && modprobe $MODULE
	wifi_generate_wpa_supplicant
	[ `ps -ef | grep wpa | grep -c $IFACE` -eq 0 ] && wpa_supplicant -D nl80211 -D wext -i $IFACE -c $WPA_SUPP_CONF_FILE -B && sleep 1
	acquire_ip
}
export -f wifi_up

CUSTOM_EOF

}

function Usage()
{
cat << EOF
		Usage: $0 -e  <additional package set name> 
		Options:
		-c	To clean_up the usunsed packages and untarred tar balls, 
			default action is to keep, but better to flush out after untarring
		-k	Source tar ball cleanup
		-e	package to be included in rootfs (NOT SUPPORTED YET)
		-r	To Redo the package and setup ready, deleting the existing setup
		-h	To print this usage format
		-u      To print this usage format
EOF
 return 0
}

function parse_args ()
{
	while getopts "chkure:" opt; do
		case "$opt" in
			e) EXTRA_PLUGINS=$OPTARG;;
			c) CLEAN_UP=1;;
			k) CLEAN_UP=1 && SOURCE_CLEAN=1;;
			r) REDO=1;;
			h|u|*) Usage;;
		esac
	done
}

check_file_missing ()
{
	TARGET_FILE=$1
	[ ! -e $TARGET_FILE ] && echo $TARGET_FILE is missing, Dying here && exit 1
	return 0
}

check_dir_missing ()
{
	TARGET_FILE=$1 && \
	[ ! -d $TARGET_FILE ] && echo $TARGET_FILE is missing, Dying here && exit 1
	return 0
}

__cleanup_unused ()
{
	[ $SOURCE_CLEAN -eq 1 ] && rm -rf $L1_DIR/*.*bz2
	rm -rf 	$L1_DIR/README* \
		$L1_DIR/buildbrain.txt \
		$L1_DIR/build-tree-manifest.xml \
		; # Leave this line as it is, don't try to club to previous line
	rm -rf $L2_DIR/*.*bz2 \
		$L2_DIR/README* \
		$L2_DIR/install_bbb.sh \
		$L2_DIR/sanity* \
		$L2_DIR/manifest* \
		$L2_DIR/file_dependency_check.txt \
		$L2_DIR/WARNING_manifest_audit.txt \
		; # Leave this line as it is, don't try to club to previous line
}

main ()
{
	parse_args $@
	FULL_LIN_TB=full_linux_for_tegra.tbz2 	
	if [ $REDO -eq 1 ]; then
		check_file_missing $FULL_LIN_TB 	&& rm -rf $L2_DIR && tar xpf $FULL_LIN_TB
	else
		check_file_missing $FULL_LIN_TB 	&& tar xpf $FULL_LIN_TB
	fi
	cd $L2_DIR

	FIN_LIN_TB=linux_for_tegra.tbz2		&& check_file_missing $FIN_LIN_TB	&& tar xpf $FIN_LIN_TB 
	TARGETFS="Linux_for_Tegra/rootfs"	&& check_dir_missing $TARGETFS 
	SAMPLEFS_TB=sample_fs.tbz2 		&& check_file_missing $SAMPLEFS_TB 	&& tar xpf $SAMPLEFS_TB    -C $TARGETFS 
	RESTRICTED_BTB=restricted_binaries.tbz2	&& check_file_missing $RESTRICTED_BTB	&& tar xpf $RESTRICTED_BTB -C $TARGETFS
	RESTRICTED_CTB=restricted_codecs.tbz2	&& check_file_missing $RESTRICTED_CTB	&& tar xpf $RESTRICTED_CTB -C $TARGETFS
	FIRMWARE_TB=firmware_3rdparty.tbz2 	&& check_file_missing $FIRMWARE_TB	&& tar xpf $FIRMWARE_TB    -C $TARGETFS
	NV_USE_ONLY_TB=nvidia_use_only.tbz2	&& check_file_missing $NV_USE_ONLY_TB 	&& tar xpf $NV_USE_ONLY_TB -C $TARGETFS 
	TESTS_TB=tests_output.tbz2 		&& check_file_missing $TESTS_TB 	&& tar xpf $TESTS_TB	   -C $TARGETFS 

	FP_OPTION="hfp"	# To use hfp set of files or hfp set of files due to COMPILER_FLOATING_POINTER_OPTION

	LIN_FT=Linux_for_Tegra			&& check_dir_missing $LIN_FT		&& 
	cd $LIN_FT 
	ROOTFS=rootfs 			 	&& ./apply_binaries.sh 
	DEF_HOME=$ROOTFS/home/ubuntu
	DEF_BIN=$ROOTFS/bin
	DEF_LIB=$ROOTFS/lib

	#Create Custom Tools/Utils/functions for the target ease
	create_custom_tools $DEF_BIN && chmod a+x $DEF_BIN/custom_functions
    	echo ". /bin/custom_functions" >> $DEF_HOME/.bashrc
    	echo ". /bin/custom_functions" >> $ROOTFS/root/.bashrc
	echo "PS1='\u@\W$ '" | tee -a $ROOTFS/home/ubuntu/.bashrc $ROOTFS/root/.bashrc > /dev/null
	echo "export LD_LIBRARY_PATH=/usr/lib" >> $ROOTFS/root/.bashrc
	echo "resize >/dev/null 2>&1" >> $ROOTFS/etc/bash.bashrc

	# To enable more verbose Kernel Logging on debug console and on every console that gets opened by default
	echo "[ \$USER == root ] &&  echo 10 > /proc/sys/kernel/printk" >> $ROOTFS/root/.bashrc
	echo 'echo -e "System boot time:`dmesg | tail -1 | cut -d"[" -f 2 | cut -d"]" -f1` secs\n"' >>  $ROOTFS/etc/bash.bashrc
	#echo "dmesg | attention_fire" >> $ROOTFS/etc/bash.bashrc

	HIST_CONTENT="apt-get install ubuntu-desktop -y\n"
	HIST_CONTENT+="dhclient eth0\n"
	HIST_CONTENT+="hwclock -uw\n"
	HIST_CONTENT+="poweroff\n"
	HIST_CONTENT+="reboot\n"
	HIST_CONTENT+="nvmm_packages\n"
	HIST_CONTENT+="ping gmail.com\n"
	HIST_CONTENT+="ping x.com\n"
	HIST_CONTENT+="echo b > /proc/sysrq-trigger\n"	#To Reboot
	HIST_CONTENT+="echo o > /proc/sysrq-trigger\n"	#To shutdown
	HIST_CONTENT+="wifi_up -a nvtestwireless -p Sp33doflight\n"
	HIST_CONTENT+="wifi_down\n"
	echo -e $HIST_CONTENT >> $ROOTFS/root/.bash_history

#<<"COMMENT"
	# Extra setups to ease
	sed -i 's/qeDTPsnM\/ZMUo//g' $ROOTFS/etc/shadow	# Remove ubuntu user password
	sed -i 's/ubuntu:x/ubuntu:/g' $ROOTFS/etc/passwd # Remove ubuntu user password

	sed -i 's/\!\*//g' $ROOTFS/etc/shadow	# Remove Root password
	sed -i 's/root:x/root:/g' $ROOTFS/etc/passwd # Remove Root user password

	#Autologin to root account on UART console
	sed -i 's/115200 ttyS0/115200 ttyS0 -a ubuntu/g' $ROOTFS/etc/init/ttyS0.conf

#COMMENT
	HOST_INFO="$ROOTFS/home/ubuntu/.host_info"
	echo -e "host side settings:\nhost_working_Directory|build_directory=$PWD\nhostname/username=$HOSTNAME/$USER" >> $HOST_INFO
	cp $HOST_INFO $ROOTFS/root/
	mkdir -p $ROOTFS/etc/vim/

	SPECIAL_FILES_AT="/bin/"
	#WIFI_SCRIPT="$SPECIAL_FILES_AT/wifi_up.sh" && check_file_missing $WIFI_SCRIPT && cp $WIFI_SCRIPT $ROOTFS/bin/
	#WIFI_SCRIPT="$SPECIAL_FILES_AT/wifi_simple.sh" && check_file_missing $WIFI_SCRIPT && cp $WIFI_SCRIPT $ROOTFS/bin/
	AUTO_TEST_SCRIPT="$SPECIAL_FILES_AT/bsp_test.sh" && check_file_missing $AUTO_TEST_SCRIPT && cp $AUTO_TEST_SCRIPT $ROOTFS/bin/
	#APT_FAST_SCRIPT="$SPECIAL_FILES_AT/apt-fast" && check_file_missing $APT_FAST_SCRIPT && cp $SPECIAL_FILES_AT/apt-fast $ROOTFS/bin/ && chmod a+x $SPECIAL_FILES_AT/apt-fast
	VIMRC_FILE="/etc/vim/vimrc" && cp $VIMRC_FILE $ROOTFS/etc/vim/
	#TESTL4T="$SPECIAL_FILES_AT/testl4t" && check_file_missing $TESTL4T && cp $TESTL4T $ROOTFS/bin/

	CPU_STRESS="$SPECIAL_FILES_AT/cpu_loop_${FP_OPTION}" && check_file_missing $CPU_STRESS && cp $CPU_STRESS $ROOTFS/bin/

	[ $CLEAN_UP -eq 1 ] && __cleanup_unused

	echo -e "$FINE_COLOR rootfs is SUCCESFULLY built, you may flash it now $NORM_COLOR"

}

main $@

