#!/bin/bash
# DB2 Full backup script 
# Control this script by Input Variables
# Usage : 0. Modify Variables of db2_bak.sh , exec_full_bak.sh , exec_inc_bak.sh
#         1. cp $(pwd)/exec_{full,inc}_bak.sh /usr/local/sbin/
#         2. chmod 777 /usr/local/sbin/exec_{full,inc}_bak.sh
#         3. Full Backup : sh $(pwd)/db2_bak.sh full
#             Inc Backup : sh $(pwd)/db2_bak.sh inc
#
# By Gopppog 
# 2020.1.20
# Gever @ Copyright Ltd

# Global Variables

# Input Variables
export LANG=en_US.UTF-8
export BAK_SAVE_DIR=/data002/backup       # If not exist , generate it automatically
                                          # Directory tree Example [Full]
                                          # ----/data/db2_bak/full/
                                          #     ------------------/20200101
                                          #     ------------------/20200101.log
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
export BAK_SAVE_TIME=3                    # Backup files more than 3 days will be delete , You can Modify value of BAK_SAVE_TIME to control it
export DB_NAME=rmis_dg                    # Backup database name
export DB_USER=db2admin                   # this value means the user you create when you install db2

# Log manager
Log_dump(){
   if [ "$2" == "full" ];then
      [ ! -f $BAK_SAVE_DIR/full/$(date +%Y%m%d).log ] && touch $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
      case $1 in
      success)
             echo "$(date +%Y.%m.%d\ %T\ %a) - [success] $3" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
      ;;
      failed)
             echo "$(date +%Y.%m.%d\ %T\ %a) - [failed] $3" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
      ;;
      info)  
             echo "$(date +%Y.%m.%d\ %T\ %a) - [info] $3" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
      esac
   else   
   # Inc Log dump
      [ ! -f $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log ] && touch $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
      case $1 in
      success)
             echo "$(date +%Y.%m.%d\ %T\ %a) - [success] $3" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
      ;;
      failed)
             echo "$(date +%Y.%m.%d\ %T\ %a) - [failed] $3" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
      ;;
      info)
             echo "$(date +%Y.%m.%d\ %T\ %a) - [info] $3" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
      esac
   fi
}

# Directory manager
Dir_manager(){
   case $2 in
   create)
   # Generate BAK_SAVE_DIR/{full,inc} and BAK_SAVE_DIR/{full,inc}/$(date +%Y%m%d)
   if [ "$1" == "full" ];then
      if [ ! -d $BAK_SAVE_DIR/full ];then
         mkdir -p $BAK_SAVE_DIR/full
         if [ $? -eq 0 ];then 
            Log_dump success full "execute mkdir -p $BAK_SAVE_DIR/full"
         else
            Log_dump failed full "execute mkdir -p $BAK_SAVE_DIR/full"
            exit 1
         fi
      fi
      if [ ! -d $BAK_SAVE_DIR/full/$(date +%Y%m%d) ];then
         mkdir -p $BAK_SAVE_DIR/full/$(date +%Y%m%d)
         if [ $? -eq 0 ];then 
            Log_dump success full "execute mkdir -p $BAK_SAVE_DIR/full/$(date +%Y%m%d)"
         else
            Log_dump failed full "execute mkdir -p $BAK_SAVE_DIR/full/$(date +%Y%m%d)"
            exit 1
         fi
      fi
   else
      if [ ! -d $BAK_SAVE_DIR/inc ];then
         mkdir -p $BAK_SAVE_DIR/inc
         if [ $? -eq 0 ];then
            Log_dump success inc "execute mkdir -p $BAK_SAVE_DIR/inc"
         else
            Log_dump failed inc "execute mkdir -p $BAK_SAVE_DIR/inc"
            exit 1
         fi
      fi 
      if [ ! -d $BAK_SAVE_DIR/inc/$(date +%Y%m%d) ];then
         mkdir -p $BAK_SAVE_DIR/inc/$(date +%Y%m%d)
         if [ $? -eq 0 ];then
            Log_dump success inc "execute mkdir -p $BAK_SAVE_DIR/inc/$(date +%Y%m%d)"
         else
            Log_dump failed inc "execute mkdir -p $BAK_SAVE_DIR/inc/$(date +%Y%m%d)"
            exit 1
         fi
      fi 
   fi
   # Modify Directory privileges
   chown -Rf $DB_USER.$(cat /etc/group|grep $(id -g $DB_USER)|awk -F ":" '{print $1}') $BAK_SAVE_DIR
   ;;
   delete)
   # Delete Backup files depend on BAK_SAVE_TIME
   if [ "$1" == "full" ];then
      Log_dump info full "Prune expire files"
      expire_files_count=$(find $BAK_SAVE_DIR/full \( -type d -name "*202*" -o -name "*.log*" \) -mtime +$BAK_SAVE_TIME|wc -l)
      if [ $expire_files_count -ne 0 ];then
         for files in $(find $BAK_SAVE_DIR/full \( -type d -name "*202*" -o -name "*.log*" \) -mtime +$BAK_SAVE_TIME) 
         do
            Log_dump info full "expire file : $files" 
         done
         Log_dump info full "delete $expire_files_count expire files"
         find $BAK_SAVE_DIR/full \( -type d -name "*202*" -o -name "*.log*" \) -mtime +$BAK_SAVE_TIME -exec rm -rf {} \;
      else
         Log_dump info full "No files match expire time , Nothing to do"
      fi
      Log_dump info full "Prune complete"
   else
      Log_dump info inc "Prune expire files"
      expire_files_count=$(find $BAK_SAVE_DIR/inc \( -type d -name "*202*" -o -name "*.log*" \) -mtime +$BAK_SAVE_TIME|wc -l)
      if [ $expire_files_count -ne 0 ];then
         for files in $(find $BAK_SAVE_DIR/inc \( -type d -name "*202*" -o -name "*.log*" \) -mtime +$BAK_SAVE_TIME)
         do
            Log_dump info inc "expire file : $files"
         done
         Log_dump info inc "delete $expire_files_count expire files"
         find $BAK_SAVE_DIR/inc \( -type d -name "*202*" -o -name "*.log*" \) -mtime +$BAK_SAVE_TIME -exec rm -rf {} \;
      else
         Log_dump info inc "No files match expire time , Nothing to do"
      fi
      Log_dump info inc "Prune complete"
   fi
   esac
}

# Backup manager
Full_Bak_manager(){
   Dir_manager full create
   echo "# -------------------------------------------------------------- #" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
   echo -e "\tTask:\tDB2 database full backup && delete expire files"  >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
   echo -e "\tBackup db:\t$DB_NAME" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
   echo -e "\tStart Time:\t$(date +%Y.%m.%d\ %T)" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
   echo -e "\tGever @ Copyright Ltd" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
   echo "# -------------------------------------------------------------- #" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
   echo "" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
   Log_dump info full "Backup Start"
   n=$(cat $BAK_SAVE_DIR/full/$(date +%Y%m%d).log | grep -wi image | wc -l)
   su - $DB_USER -c /usr/local/sbin/exec_full_bak.sh
   N=$(cat $BAK_SAVE_DIR/full/$(date +%Y%m%d).log | grep -wi image | wc -l)
   if [ $N -gt $n ];then
      Log_dump success full "Backup Completed"
      BAK_NUM=$(cat $BAK_SAVE_DIR/full/$(date +%Y%m%d).log|grep -i image|tail -1|awk '{print $NF}')
      echo "# ----------------------------------------------------------- #" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
      echo -e "\tBackup file:\t$(ls -l $BAK_SAVE_DIR/full/$(date +%Y%m%d)/*${BAK_NUM}*|awk 'NF>2{print $NF}')" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
      echo -e "\tSize:\t$(du -sh $(ls -l $BAK_SAVE_DIR/full/$(date +%Y%m%d)/*${BAK_NUM}* |awk '{print $NF}')|awk '{print $1}')" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
      echo "# ----------------------------------------------------------- #" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
   else
      Log_dump failed full "Backup Interrupt , Please check out logs for reason"
      exit 1
   fi
   Log_dump info full "Compress Start"
   cd $BAK_SAVE_DIR/full/$(date +%Y%m%d)
   gzip $(ls -l *$BAK_NUM*|awk '{print $NF}') >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log 2>&1
   Log_dump success full "Compress completed"
   echo "# ----------------------------------------------------------- #" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
   echo -e "\tCompress file:\t$(ls -l $BAK_SAVE_DIR/full/$(date +%Y%m%d)/*${BAK_NUM}*|awk 'NF>2{print $NF}')" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
   echo -e "\tSize:$(du -sh $(ls -l $BAK_SAVE_DIR/full/$(date +%Y%m%d)/*${BAK_NUM}*|awk '{print $NF}')|awk '{print $1}')" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
   echo "# ----------------------------------------------------------- #" >> $BAK_SAVE_DIR/full/$(date +%Y%m%d).log
   Dir_manager full delete
   Log_dump info full "Backup task Completed!"
}

Inc_Bak_manager(){
   Dir_manager inc create
   echo "# -------------------------------------------------------------- #" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
   echo -e "\tTask:\tDB2 database incremental backup && delete expire files"  >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
   echo -e "\tBackup db:\t$DB_NAME" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
   echo -e "\tStart Time:\t$(date +%Y.%m.%d\ %T)" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
   echo -e "\tGever @ Copyright Ltd" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
   echo "# -------------------------------------------------------------- #" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
   echo "" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
   Log_dump info inc "Backup Start"
   n=$(cat $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log | grep -wi image | wc -l)
   su - $DB_USER -c /usr/local/sbin/exec_inc_bak.sh
   BAK_NUM=$(cat $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log|grep -i image|tail -1|awk '{print $NF}')
   N=$(cat $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log | grep -wi image | wc -l)
   su - $DB_USER -c "db2ckrst -d $DB_NAME -t $BAK_NUM -r database" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
   if [ $N -gt $n ];then
      Log_dump success inc "Backup Completed"
      echo "# ----------------------------------------------------------- #" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
      echo -e "\tBackup file:\t$(ls -l $BAK_SAVE_DIR/inc/$(date +%Y%m%d)/*${BAK_NUM}*|awk 'NF>2{print $NF}')" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
      echo -e "\tSize:\t$(du -sh $(ls -l $BAK_SAVE_DIR/inc/$(date +%Y%m%d)/*${BAK_NUM}* |awk '{print $NF}')|awk '{print $1}')" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
      echo "# ----------------------------------------------------------- #" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
   else
      Log_dump failed inc "Backup Interrupt , Please check out logs for reason"
      exit 1
   fi
   Log_dump info inc "Compress Start"
   cd $BAK_SAVE_DIR/inc/$(date +%Y%m%d)
   gzip $(ls -l *$BAK_NUM*|awk '{print $NF}') >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log 2>&1
   Log_dump success inc "Compress completed"
   echo "# ----------------------------------------------------------- #" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
   echo -e "\tCompress file:\t$(ls -l $BAK_SAVE_DIR/inc/$(date +%Y%m%d)/*${BAK_NUM}*|awk 'NF>2{print $NF}')" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
   echo -e "\tSize:$(du -sh $(ls -l $BAK_SAVE_DIR/inc/$(date +%Y%m%d)/*${BAK_NUM}*|awk '{print $NF}')|awk '{print $1}')" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
   echo "# ----------------------------------------------------------- #" >> $BAK_SAVE_DIR/inc/$(date +%Y%m%d).log
   Dir_manager inc delete
   Log_dump info inc "Backup task Completed!"
}
# Main
case $1 in 
full|FULL)
   Full_Bak_manager
;;
inc|INC)
   Inc_Bak_manager
;;
*)
   echo "Usage:$0 [full|inc]"
esac
