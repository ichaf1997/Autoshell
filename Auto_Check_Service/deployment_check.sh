#!/bin/bash

# Check MySQL and Application status
#        Keep them Running stably
#           By Gopppog

# Default unit : Second
time_out=5
# number of times to retry if return code not equal 0
retry_count=3
# Check command
declare -A check_cmd
check_cmd=(
    [nctomcat]="curl -Is http://192.168.1.110:8080/ncsz/|grep 'HTTP/1.1 200'" 
    [mysql]="mysqladmin -ucjx -p'a123456@' ping"
)
# Restart command
declare -A restart_cmd
restart_cmd=(
    [nctomcat]="systemctl restart tomcat" 
    [mysql]="mysqladmin -ucjx -p'a123456@' shutdown;sudo -u mysql /data/application/mysql/mysql8/bin/mysqld_safe --user=mysql &"
)

function app_status() {
for ((i=0;i<${retry_count};i++))
do 
   echo $1|sh > /dev/null 2>&1
   if [ $? -eq 0 ];then
      return 0
   fi
   [ $i -ne 1 ] && time_out=$(expr $time_out \* 2)
   sleep $time_out
done 
return 1
}

for app in ${!check_cmd[*]};
do {
    app_status "${check_cmd[$app]}" && echo $app check OK || echo "${restart_cmd[$app]}"|sh
} &
done

wait
