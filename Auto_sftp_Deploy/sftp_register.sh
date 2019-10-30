#!/bin/bash

SFTP_DIR=/var/sftp
ENABLE_QUOTA=1
QUOTA_SIZE_EVERY=1024000       # 1GB


[ ! -e "$(pwd)/sftp_account.txt" ] && mkdir -p $(pwd)/sftp_account.txt
[ ! -e "$(pwd)/sftp_userinfo.txt" ] && touch $(pwd)/sftp_userinfo.txt
Disk_name=$(df -h ${SFTP_DIR}|grep -v "Filesystem"|awk -F[" "]+ '{print $1}')
[ "$ENABLE_QUOTA" = "1" ] && quotaon $Disk_name
for line in $(cat $(pwd)/sftp_account.txt)
do
    case $1 in
    create)
    useradd -g sftp -d ${SFTP_DIR}/${line} -s /bin/false ${line}
    chown root ${SFTP_DIR}/${line}
    chmod 755 ${SFTP_DIR}/${line}
    mkdir ${SFTP_DIR}/${line}/upload
    chown ${line}.sftp ${SFTP_DIR}/${line}/upload
    password=$(openssl rand -base64 6)
    echo ${password}|passwd --stdin ${line}
    echo -e "\tAccount:${line}\tPassword:${password}" >>$(pwd)/sftp_userinfo.txt
    if [ "$ENABLE_QUOTA" == "1" ];then
       setquota -u ${line} 0 ${QUOTA_SIZE_EVERY} 0 0 ${Disk_name}
    fi
    ;;
    delete)
    userdel -rf ${line}
    ;;
    *)echo "Usage:$0 [create|delete]"
      exit 0
    esac
done
if [ "$1" == "create" ];then
echo -e "
\tCreate_Time:\t$(date +%F\ %T)
" >> $(pwd)/sftp_userinfo.txt
[ "$ENABLE_QUOTA" == "1" ] && echo -e "\tQuota_Size\t${QUOTA_SIZE_EVERY}">> $(pwd)/sftp_userinfo.txt
fi
echo "Completed !"
