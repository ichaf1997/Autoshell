#!/bin/bash

SFTP_DIR=/var/sftp        ## Recommanded as a sparate Filesystem
ENABLE_QUOTA=1

cat /etc/group |grep sftp >/dev/null 2>&1
[ "$?" != "0" ] && groupadd sftp >/dev/null 2>&1
[ ! -d "$SFTP_DIR" ] && mkdir -p $SFTP_DIR >/dev/null 2>&1

sed -i '/^Subsystem.*$/d' /etc/ssh/sshd_config
sed -i '/^Match/d' /etc/ssh/sshd_config
sed -i '/^Chroot/d' /etc/ssh/sshd_config
sed -i '/^ForceCommand/d' /etc/ssh/sshd_config
sed -i '/^AllowTcpForwarding/d' /etc/ssh/sshd_config
sed -i '/^X11Forwarding/d' /etc/ssh/sshd_config

echo "# SFTP
Subsystem sftp internal-sftp
Match Group sftp
ChrootDirectory ${SFTP_DIR}/%u
ForceCommand internal-sftp
AllowTcpForwarding no
X11Forwarding no" >> /etc/ssh/sshd_config

systemctl restart sshd
if [ "$ENABLE_QUOTA" == "1" ];then
      rpm -qa|grep quota >/dev/null 2>&1
      if [ "$?" != "0" ];then
         yum -y install quota >/dev/null 2>&1
         if [ "$?" != "0" ];then
            echo -e "\tQuota_Status:\toff\tPlease check your reposity ."
         fi
      fi
      if [ "$(df -h ${SFTP_DIR}|grep -v "Filesystem"|wc -l)" != "1" ];then
         echo -e "\tQuota_Status:\toff\t${SFTP_DIR} have more than 1 Filesystem"
         exit 0
      else
         Disk_name=$(df -h ${SFTP_DIR}|grep -v "Filesystem"|awk -F[" "]+ '{print $1}')
         Disk_type=$(blkid ${Disk_name}|awk -F[" "]+ '{print $3}'|cut -d "=" -f 2|sed 's/"//g')
         Disk_UUID=$(blkid ${Disk_name}|awk -F[" "]+ '{print $2}'|cut -d "=" -f 2|sed 's/"//g')
         if [ "${Disk_type}" == "xfs" ];then
            cat /etc/fstab|grep "${Disk_UUID}"|grep "usrquota" >/dev/null 2>&1
            if [ "$?" == "0" ];then
               echo -e "\tQuota_Status:\ton"
               exit 0
            else
               sed -i "s/^.*${Disk_UUID}.*$/$(cat /etc/fstab |grep "${Disk_UUID}"|sed 's/\//\\\//g'|sed 's/defaults/defaults,usrquota/g')/g" /etc/fstab
               while true
               do
                    read -p "Reboot to finish the Quota setting ? [y or n] " ack
                    case $ack in
                    y)echo -e "\tQuota_Status:\ton"
                      echo "Reboot after 10 seconds"
                      init 6
                    ;;
                    n)echo -e "\tQuota_Status:\ton"
                      echo "Warnning ! Quota doesn't work until it is restarted"
                      exit 0
                    ;;
                    *)echo "y or n"
                    esac
               done
            fi
         else
            mount -o defaults,usrquota,remount $Disk_name >/dev/null 2>&1
            quotacheck -avug $Disk_name >/dev/null 2>&1
            quotaon -avug >/dev/null 2>&1
            echo -e "\tQuota_Status:\ton"
         fi
      fi
else 
    echo -e "\tQuota_Status:\toff"
fi                      
echo "Complete !"
