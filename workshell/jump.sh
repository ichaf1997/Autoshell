#!/bin/bash
# --------------------
#       Jumper
# --------------------

#server ip
#Nginx-Upstream-1
host1="172.16.0.122"
#Nginx-Upstream-2
host2="172.16.0.121"
#PHP-1
host3="172.16.0.117"
#PHP-2
host4="172.16.0.119"
#Mycat-1
host5="172.16.0.116"
#Mycat-2
host6="172.16.0.120"
#Mysql-Master-1
host7="172.16.0.115"
#Mysql-Master-2
host8="172.16.0.118"
#Mysql-Slave
host9="172.16.0.114"
#function
getstatus(){
    h=$1
    ping -c 1 -W 1 ${h} >/dev/null 2>&1
    [ "$?" == "0" ] && echo "Connect" || echo "Disconnect"
}
jump(){
   n=$1
   if [ "$(getstatus ${n})" != "Connect" ];then
      read -p "This Server you selecting is unable to connect,Do you want to continue?[y or n]" sel
      case ${sel} in
      Y|y)ssh ${n};return 0
      ;;
      N|n)return 1
      ;;
      *)return 1
      esac
   else
      ssh ${n}
      return 0
   fi
}
#Display illustration
Menu(){
echo "
==========JumpServer==========

Server Name            Status

(1)Nginx-Upstream-1            $(getstatus ${host1}) 
(2)Nginx-Upstream-2            $(getstatus ${host2})
(3)PHP-1                       $(getstatus ${host3})
(4)PHP-2                       $(getstatus ${host4})
(5)Mycat-1                     $(getstatus ${host5})                 
(6)Mycat-2                     $(getstatus ${host6})
(7)MySQL-Master-1              $(getstatus ${host7})
(8)MySQL-Master-2              $(getstatus ${host8})
(9)MySQL-Slave                 $(getstatus ${host9})

==========Operation===========

(h)Help       (q)quit
"
}
#interactive
Menu
while true
do
    read -p "Please chose the number between 1-9 for action:" act
    case ${act} in
    1)jump ${host1};[ "$?" == "0" ] && Menu || continue
    ;;
    2)jump ${host2};[ "$?" == "0" ] && Menu || continue
    ;;
    3)jump ${host3};[ "$?" == "0" ] && Menu || continue
    ;;
    4)jump ${host4};[ "$?" == "0" ] && Menu || continue
    ;;
    5)jump ${host5};[ "$?" == "0" ] && Menu || continue
    ;;
    6)jump ${host6};[ "$?" == "0" ] && Menu || continue
    ;;
    7)jump ${host7};[ "$?" == "0" ] && Menu || continue
    ;;
    8)jump ${host8};[ "$?" == "0" ] && Menu || continue
    ;;
    9)jump ${host9};[ "$?" == "0" ] && Menu || continue
    ;;
    h|H)echo "This is a JumpSever . for operators .";continue
    ;;
    q|Q)echo "Good Bye";exit 0
    ;;
    *)echo "Warning:You can input 1-9,h,q for operation";continue
esac
done
