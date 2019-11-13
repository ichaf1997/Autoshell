#!/bin/bash
# This script will close Arp response and bind a virtual ipaddress to lo

# Input
V_ip=192.168.142.20

# Define function
case $1 in
start)
      ifconfig lo:0 down
      ifconfig lo:0 ${V_ip} broadcast ${V_ip} netmask 255.255.255.255
      echo "1" > /proc/sys/net/ipv4/conf/lo/arp_ignore
      echo "2" > /proc/sys/net/ipv4/conf/lo/arp_announce
      echo "1" > /proc/sys/net/ipv4/conf/all/arp_ignore
      echo "2" > /proc/sys/net/ipv4/conf/all/arp_announce
;;
stop)
      ifconfig lo:0 down
      echo "0" > /proc/sys/net/ipv4/conf/lo/arp_ignore
      echo "0" > /proc/sys/net/ipv4/conf/lo/arp_announce
      echo "0" > /proc/sys/net/ipv4/conf/all/arp_ignore
      echo "0" > /proc/sys/net/ipv4/conf/all/arp_announce
;;
enable)
      if [ "$(cat /etc/rc.d/rc.local|grep $0|wc -l)" == "0" ]
      then
          Path=$(pwd)/$0
          echo "sh $Path start" >> /etc/rc.d/rc.local
          chmod u+x /etc/rc.d/rc.local
          echo "Enabled bootup OK !"
      else
          echo "added bootup already !"
      fi
;;
*)
     echo "Usage : sh $0 [start|stop|enable]"
esac

