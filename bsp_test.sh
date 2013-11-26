#!/bin/bash

export CORES=`grep processor /proc/cpuinfo | wc -l`; 
export PLATFORM=`grep Hardware /proc/cpuinfo | cut -d ' ' -f2` 

main ()
{
case $1 in
    rtc)
        echo "Testing RTC"
        #Test1: RealTime Clock 
        if [ -e /dev/rtc0 ]; then 
            echo RTC is available; 
            time=`date -u +%s`
            sleep 10
            if [ `expr $time + 10` -ne `date -u +%s` ]
            then
                echo "Time check failed"
                exit 1;
            fi
            exit 0; 
        else 
            echo ERROR: RTC device file /dev/rtc0 missing; 
            exit 1; 
        fi 
        ;;
    smp)
        [ -z $PLATFORM ] && echo Unable to get Platform data && exit 1;
        [ $PLATFORM == cardhu -a $CORES -eq 4 ] && echo $PLATFORM with $CORES cores && exit 0;
        [ $PLATFORM == harmony -a $CORES -eq 2 ] && echo $PLATFORM with $CORES cores && exit 0;
        [ $PLATFORM == ventana -a $CORES -eq 2 ] && echo $PLATFORM with $CORES cores && exit 0;
        [ $PLATFORM == dalmore -a $CORES -eq 4 ] && echo $PLATFORM with $CORES cores && exit 0;
        ;;
    tickless)
 	[ `cat /proc/config.gz | gunzip - | tee | grep NO_HZ=y | wc -l` -gt 1 ] && return 1
	return 0

        ;;
    timer)
        records=`cat /proc/interrupts | grep "Local timer interrupts" | awk '{print NF;}'`
        if [ $records -lt 6 ]; then
            echo "Local timer interrupts entry not found in /proc/interrupts file"
            exit 1
        else
            echo "Local timer interrupts enabled"
            exit 0
        fi
        ;;
    pci)
        #Test5: PCI Device Enumeration 
        if [ `grep pci /var/log/dmesg | wc -c` -gt 3 ]; then 
            echo "pci messages found in dmesg output" 
            if [ `lspci | wc -c` -gt 3 ]; then 
                echo "lspci yielded in pci devices"; 
                exit 0; 
            fi 
        else 
            echo PCI messages are not found in dmesg output; 
            exit 1; 
        fi 
        ;;
    kernel)
        version="3.1"
        if [ -n "$2" ]
        then
            version=$2
        fi
        uname -r | grep -e $version
        exit $?
        ;;
    ethernet)
        #Test7: Ethernet Browsing - RJ45_LAN/USB-RJ45_LAN 
        IFACE=`grep -e Ethernet /var/log/dmesg |grep -e eth | cut -d ':' -f3` && \ 
        dhclient $IFACE && sleep 5 && \ 
        IPADDR=`ifconfig | grep $IFACE -A1| grep inet | cut -d ':' -f2 | cut -d ' ' -f1` 
        if [ `echo $IPADDR | wc -c` -gt 4 ]; then 
            echo SUCCESS:$IFACE:$IPADDR 
            exit 0 
        else 
            echo IP Address=$IPADDR 
            echo Interface=$IFACE 
            exit 1 
        fi 
        ;;
    comp_date)
        begin=`date --date="now" +%s`
        end=`date --date="now" +%s`
        if [ -n "$2" ]; then
            begin=`date --date="$2" +%s`
        fi
        difference=`expr ${end} - ${begin}` 
        if [[ ${end} -ge ${begin} && ${difference} -le 180 ]]; then
            echo "Date Comparison Passed"
            exit 0
        else
            echo "Date Comparison Failed"
            exit 1
        fi
        ;;
    *)
        echo "Usage: bash l4t_test.sh {kernel <version>|ethernet|rtc|smp|tickless|timer|pci|comp_date <date string>}"
        exit 1
        ;;
esac
}

main $@


