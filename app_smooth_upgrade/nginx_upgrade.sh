#!/bin/bash
# To Upgrade nginx smoothly 
 
# Input

OLD_NGINX=/usr/local/nginx/sbin/nginx
NEW_NGINX=/usr/local/src/nginx-1.16.0/objs/nginx

# Check variables
[ ! -e "$OLD_NGINX" ] && echo -e "\033[31m[Input Check failed] $OLD_NGINX is not exist\033[0m" && exit 0
[ ! -e "$NEW_NGINX" ] && echo -e "\033[31m[Input Check failed] $NEW_NGINX is not exist\033[0m" && exit 0
# backup 
echo "Backup old version ..."
sleep 1
if [ ! -e "/var/backup" ]
then
    mkdir /var/backup
    cp -fp $OLD_NGINX /var/backup/nginx_bak
    echo "#Generate by $0 - $(date +%a\ %b\ %d\ %T\ %Y)" > /var/backup/readme
fi
echo -e "\033[32m[OK]Backup old version\033[0m"

# Replace
echo "Upgrade new version ..."
sleep 1
if [ "$(netstat -lntp|grep nginx|wc -l)" != "0" ]
then
    chown nginx.nginx $NEW_NGINX
    ${OLD_NGINX} -s stop
    rm -rf $OLD_NGINX
    cp -p $NEW_NGINX $OLD_NGINX
    $OLD_NGINX
    if [ "$?" != "0" ]
    then
        echo -e "\033[31m[failed]Upgrade new version\033[0m"
        cp -fp /var/backup/nginx_bak $OLD_NGINX
        $OLD_NGINX
        echo -e "\033[32m[OK]Recovery old version\033[0m"
    else
        echo -e "\033[32m[OK]Upgrade new version\033[0m" 
    fi
else
    chown nginx.nginx $NEW_NGINX
    rm -rf $OLD_NGINX
    cp -p $NEW_NGINX $OLD_NGINX
    echo -e "\033[32m[OK]Upgrade new version\033[0m"
fi
