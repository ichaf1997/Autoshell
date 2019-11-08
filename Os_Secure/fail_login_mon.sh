#!/bin/bash
# ---------------------------------------------------------- #
# this script will monitor login . 
# if login failed over some times , add this ip to iptables
# Usage : nohup sh fail_login_mon.sh >/dev/null 2>&1 &
# ---------------------------------------------------------- #

# Input setting
max_failed_times=5       
interval=30              ## Default unit : second
mon_log=/tmp/failed.log

# Ip in white_list will not be add to iptables 
white_list_enable=1         ## value 1 means open white_list , value 0 means close white_list
white_list=(192.168.142.86) ## IP Arrary . notice that IP format whether if correct , use blank as separator if you want add more than one ip in white_list

[ ! -e "$mon_log" ] && touch $mon_log
echo >> $mon_log
echo "$(date +%F\ %T) - [Info] Start monitoring ..." >> $mon_log

while true
do  
    for line in $(lastb|awk 'BEGIN{OFS=":"}/[.]/{COUNT[$3]++}END{for(ip in COUNT){print COUNT[ip],ip}}')
    do
        if [ "$(echo $line|cut -d ":" -f 1)" -ge "$max_failed_times" ];then
            if [ "$(cat $mon_log|grep "$(echo $line|cut -d ":" -f 2)"|wc -l)" == "0" ];then
                if [ "$white_list_enable" == "1" ];then
                   for ((i=0;i<${#white_list[*]};i++))
                   do
                     [ "${white_list[$i]}" == "$(echo $line|cut -d ":" -f 2)" ] && value=1
                   done
                   if [ "$value" != "1" ];then
                        iptables -A INPUT -s $(echo $line|cut -d ":" -f 2) -j DROP >/dev/null 2>&1
                        echo "$(date +%F\ %T) - [Warnning] add $(echo $line|cut -d ":" -f 2) to iptables (failed retry = $(echo $line|cut -d ":" -f 1))" >> $mon_log
                   else
                        echo "$(date +%F\ %T) - [Info] add $(echo $line|cut -d ":" -f 2) is in the white_list (failed retry = $(echo $line|cut -d ":" -f 1)) without any handle." >> $mon_log   
                   fi   
                else
                   iptables -A INPUT -s $(echo $line|cut -d ":" -f 2) -j DROP >/dev/null 2>&1
                   echo "$(date +%F\ %T) - [Warnning] add $(echo $line|cut -d ":" -f 2) to iptables (failed retry = $(echo $line|cut -d ":" -f 1))" >> $mon_log
                fi
            fi
        fi
    done
    sleep $interval
done

