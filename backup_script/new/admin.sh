#!/bin/bash

# Input Variables

# backup store directory::
# If not exist , generate it automatically
# Directory tree Example [Full]
# ----/data/db2_bak/full/
#     ------------------/20200101      --> directory
#     ------------------/20200101.log  --> log file
#     ------------------/20200102
#     ------------------/20200102.log
#     ------------------/20200103
#     ------------------/20200103.log
# Directory tree Example [Inc]
# ----/data/db2_bak/inc/
#     -----------------/20200101
#     -----------------/20200101.log
#     -----------------/20200102
#     -----------------/20200102.log
#     -----------------/20200103
#     -----------------/20200103.log
# Warning: the end of BAK_SAVE_DIR can not be '/'
BAK_SAVE_DIR=/home/backup

# Backup files more than 3 days will be delete , You can Modify value of BAK_SAVE_TIME to control it
BAK_SAVE_TIME=3

# Backup database name
DB_NAME=GCMS_DGS

# the user you create when you install db2
DB_USER=db2admin

# Backup Method, 'full' and 'inc' can be supported.
BAK_METHOD=inc

# Show Info
show_info(){
  echo "BAK_SAVE_DIR:$BAK_SAVE_DIR"
  echo "BAK_SAVE_TIME:$BAK_SAVE_TIME days"
  echo "DB_NAME:$DB_NAME"
  echo "DB_USER:$DB_USER"
  echo "BAK_METHOD:$BAK_METHOD"
}

case $BAK_METHOD in
full)
  case $1 in 
  install)
        if [ "$(cat /opt/db2_script.lock)" == "1" ];then
           echo "You had installed before ! Nothing to do"
           exit 0
        fi
        show_info
        read -p "Db2 Backup Script will be installed [y/n]:" yep
        case $yep in
        Y|y)
            bak_save_dir=$(echo $BAK_SAVE_DIR|sed 's/\//\\\//g')
            cp -f $(pwd)/db2_bak.sh /usr/local/sbin/db2_bak.sh
            cp -f $(pwd)/exec_bak.sh /usr/local/sbin/exec_bak.sh
            chmod 777 /usr/local/sbin/db2_bak.sh /usr/local/sbin/exec_bak.sh            
            sed -i "s/BAK_SAVE_DIR=/BAK_SAVE_DIR=$bak_save_dir/g" /usr/local/sbin/db2_bak.sh
            sed -i "s/BAK_SAVE_TIME=/BAK_SAVE_TIME=$BAK_SAVE_TIME/g" /usr/local/sbin/db2_bak.sh
            sed -i "s/BAK_METHOD=/BAK_METHOD=$BAK_METHOD/g" /usr/local/sbin/db2_bak.sh
            sed -i "s/DB_USER=/DB_USER=$DB_USER/g" /usr/local/sbin/db2_bak.sh
            sed -i "s/DB_NAME=/DB_NAME=$DB_NAME/g" /usr/local/sbin/db2_bak.sh
            sed -i "s/BAK_SAVE_DIR=/BAK_SAVE_DIR=$bak_save_dir/g" /usr/local/sbin/exec_bak.sh
            sed -i "s/BAK_SAVE_TIME=/BAK_SAVE_TIME=$BAK_SAVE_TIME/g" /usr/local/sbin/exec_bak.sh
            sed -i "s/BAK_METHOD=/BAK_METHOD=$BAK_METHOD/g" /usr/local/sbin/exec_bak.sh
            sed -i "s/DB_USER=/DB_USER=$DB_USER/g" /usr/local/sbin/exec_bak.sh
            sed -i "s/DB_NAME=/DB_NAME=$DB_NAME/g" /usr/local/sbin/exec_bak.sh
            echo "#* * * * * /bin/sh /usr/local/sbin/db2_bak.sh" >> /var/spool/cron/root
            echo "1" > /opt/db2_script.lock
            echo "Success."
        ;;
        *)
            echo "Bye bye"
            exit 0
        esac
         
  ;;
  remove)
       if [ "$(cat /opt/db2_script.lock)" == "0" ];then
           exit 0
       fi
       [ -f /usr/local/sbin/db2_bak.sh ] && rm -rf /usr/local/sbin/db2_bak.sh
       [ -f /usr/local/sbin/exec_bak.sh ] && rm -rf /usr/local/sbin/exec_bak.sh
       sed -i '/db2_bak.sh/d' /var/spool/cron/root
       echo "0" > /opt/db2_script.lock
  ;;
  *) echo "Usage : /bin/sh $0 [install|remove]"
     exit 0
  esac

;;
inc)
  case $1 in
  install)
        if [ "$(cat /opt/db2_incscript.lock)" == "1" ];then
           echo "You had installed before ! Nothing to do"
           exit 0
        fi
        show_info
        read -p "Db2 Backup Script will be installed [y/n]:" yep
        case $yep in
        Y|y)
            bak_save_dir=$(echo $BAK_SAVE_DIR|sed 's/\//\\\//g')
            cp -f $(pwd)/db2_bak.sh /usr/local/sbin/db2_incbak.sh
            cp -f $(pwd)/exec_incbak.sh /usr/local/sbin/exec_incbak.sh
            chmod 777 /usr/local/sbin/db2_incbak.sh /usr/local/sbin/exec_incbak.sh
            sed -i "s/BAK_SAVE_DIR=/BAK_SAVE_DIR=$bak_save_dir/g" /usr/local/sbin/db2_incbak.sh
            sed -i "s/BAK_SAVE_TIME=/BAK_SAVE_TIME=$BAK_SAVE_TIME/g" /usr/local/sbin/db2_incbak.sh
            sed -i "s/BAK_METHOD=/BAK_METHOD=$BAK_METHOD/g" /usr/local/sbin/db2_incbak.sh
            sed -i "s/DB_USER=/DB_USER=$DB_USER/g" /usr/local/sbin/db2_incbak.sh
            sed -i "s/DB_NAME=/DB_NAME=$DB_NAME/g" /usr/local/sbin/db2_incbak.sh
            sed -i "s/BAK_SAVE_DIR=/BAK_SAVE_DIR=$bak_save_dir/g" /usr/local/sbin/exec_incbak.sh
            sed -i "s/BAK_SAVE_TIME=/BAK_SAVE_TIME=$BAK_SAVE_TIME/g" /usr/local/sbin/exec_incbak.sh
            sed -i "s/BAK_METHOD=/BAK_METHOD=$BAK_METHOD/g" /usr/local/sbin/exec_incbak.sh
            sed -i "s/DB_USER=/DB_USER=$DB_USER/g" /usr/local/sbin/exec_incbak.sh
            sed -i "s/DB_NAME=/DB_NAME=$DB_NAME/g" /usr/local/sbin/exec_incbak.sh
            echo "#* * * * * /bin/sh /usr/local/sbin/db2_incbak.sh" >> /var/spool/cron/root
            echo "1" > /opt/db2_incscript.lock
            echo "Success."
        ;;
        *)
            echo "Bye bye"
            exit 0
        esac

  ;;
  remove)
       if [ "$(cat /opt/db2_incscript.lock)" == "0" ];then
           exit 0
       fi
       [ -f /usr/local/sbin/db2_incbak.sh ] && rm -rf /usr/local/sbin/db2_incbak.sh
       [ -f /usr/local/sbin/exec_incbak.sh ] && rm -rf /usr/local/sbin/exec_incbak.sh
       sed -i '/db2_incbak.sh/d' /var/spool/cron/root
       echo "0" > /opt/db2_incscript.lock
  ;;
  *) echo "Usage : /bin/sh $0 [install|remove]"
     exit 0
  esac
;;
*) echo "Only 'full' and 'inc' can be supported"
   exit 0
esac

