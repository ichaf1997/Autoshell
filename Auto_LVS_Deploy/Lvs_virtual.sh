#!/bin/bash
# This script will set ipvs to virtual server by ipvsadm automatically 

# Input
V_ip=192.168.142.20
R_iparray=(192.168.142.100 192.168.142.120) # Real server Iparrary . use space as separator if you want to add more than one real server
PORT=80

# Install ipvsadm 
[ "$(rpm -qa|grep ipvsadm|wc -l)" == "0" ] && yum -y install ipvsadm
[ "$(ipvsadm -v|wc -l)" == "0" ] && echo "ipvsadm install failed . Please check your repo"

# Define function
case $1 in
start)
     ifconfig ens33:0 down
     ipvsadm -A -t ${V_ip}:${PORT} -s rr
     for ((i=0;i<${#R_iparray[*]};i++))
     do
         ipvsadm -a -t ${V_ip}:${PORT} -r ${R_iparray[$i]}:${PORT} -g
     done
     ifconfig ens33:0 ${V_ip}
;;
stop)
     ipvsadm -C
     ifconfig ens33:0 down
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
