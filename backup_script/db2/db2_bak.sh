#!/bin/bash
# db2 backup script
export DATE=$(date +%Y%m%d)
export BAK_SAVE_DIR=
export BAK_SAVE_TIME=
export DB_NAME=
export DB_USER=
export BAK_METHOD=

# ------------------------------------------------- #

# Header Info
header(){
[ -f $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log ] && exit 0
[ ! -d $BAK_SAVE_DIR/$BAK_METHOD ] && mkdir -p $BAK_SAVE_DIR/$BAK_METHOD
mkdir -p $BAK_SAVE_DIR/$BAK_METHOD/$DATE
touch $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
chown -Rf $DB_USER.$(cat /etc/group|grep $(id -g $DB_USER)|awk -F ":" '{print $1}') $BAK_SAVE_DIR 
echo "
             _ _    ___    _                _                        
   _        | | |  |__ \  | |              | |                   _   
 _| |_    __| | |__   ) | | |__   __ _  ___| | ___   _ _ __    _| |_ 
|_   _|  / _\` | '_ \ / /  | '_ \ / _\` |/ __| |/ / | | | '_ \  |_   _|
  |_|   | (_| | |_) / /_  | |_) | (_| | (__|   <| |_| | |_) |   |_|  
         \__,_|_.__/____| |_.__/ \__,_|\___|_|\_\\__,_| .__/         
                                                      | |            
                                                      |_| 
" > $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
echo -e "\tStart Time:\t$(date +%Y.%m.%d\ %T)" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
echo -e "\tDb Name:\t$DB_NAME" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
echo -e "\tBackup Method:\t$BAK_METHOD" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
echo -e "\tBackup Save Dir:\t$BAK_SAVE_DIR/$DATE" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
echo -e "\tBackup Log Path:\t$BAK_SAVE_DIR/$DATE.log" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
echo -e "\tBackup files Saving Time:\t$BAK_SAVE_TIME days" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
}

# Full Backup
full_bak(){
    su - $DB_USER -c /usr/local/sbin/exec_bak.sh >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log  
    if [ "$(cat $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log|grep "Backup successful"|wc -l)" == "0" ];then
      bak_status=FAILED
      bak_file=None
      bak_size=0
      compressed_file=None
      compressed_size=0
    else
      bak_status=SUCCESS
      bak_file=$(ls -l $BAK_SAVE_DIR/$BAK_METHOD/$DATE|awk 'NF>2{print $NF}')
      bak_size=$(ls -l $BAK_SAVE_DIR/$BAK_METHOD/$DATE|awk 'NF>2{print $5}')
      cd $BAK_SAVE_DIR/$BAK_METHOD/$DATE
      gzip $bak_file >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
      compressed_file=$(ls -l $BAK_SAVE_DIR/$BAK_METHOD/$DATE|awk 'NF>2{print $NF}')
      compressed_size=$(ls -l $BAK_SAVE_DIR/$BAK_METHOD/$DATE|awk 'NF>2{print $5}')
    fi
}

# Incremental backup
inc_bak(){
   su - $DB_USER -c /usr/local/sbin/exec_incbak.sh >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
   image_num=$(cat $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log|grep image|awk '{print $NF}')
   su - $DB_USER -c "db2ckrst -d $DB_NAME -t $image_num -r database" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
   if [ "$(cat $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log|grep "Backup successful"|wc -l)" == "0" ];then
      bak_status=FAILED
      bak_file=None
      bak_size=0
      compressed_file=None
      compressed_size=0
    else
      bak_status=SUCCESS
      bak_file=$(ls -l $BAK_SAVE_DIR/$BAK_METHOD/$DATE|awk 'NF>2{print $NF}')
      bak_size=$(ls -l $BAK_SAVE_DIR/$BAK_METHOD/$DATE|awk 'NF>2{print $5}')
      cd $BAK_SAVE_DIR/$BAK_METHOD/$DATE
      gzip $bak_file >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
      compressed_file=$(ls -l $BAK_SAVE_DIR/$BAK_METHOD/$DATE|awk 'NF>2{print $NF}')
      compressed_size=$(ls -l $BAK_SAVE_DIR/$BAK_METHOD/$DATE|awk 'NF>2{print $5}')
    fi
}

# Expired files prune
prunefile(){
    expire_files_count=$(find $BAK_SAVE_DIR/$BAK_METHOD \( -type d -name "*202*" -o -name "*.log*" \) -mtime +$BAK_SAVE_TIME|wc -l)
    if [ $expire_files_count -ne 0 ];then
      for files in $(find $BAK_SAVE_DIR/$BAK_METHOD \( -type d -name "*202*" -o -name "*.log*" \) -mtime +$BAK_SAVE_TIME)
      do
          echo -e "\texpire file:\t$files" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
      done
    else
      echo -e "\texpire file:\tNone" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
    fi
    find $BAK_SAVE_DIR/$BAK_METHOD \( -type d -name "*202*" -o -name "*.log*" \) -mtime +$BAK_SAVE_TIME -exec rm -rf {} \;
}

# Main
starttime=`date +'%Y-%m-%d %H:%M:%S'`
start_seconds=$(date --date="$starttime" +%s)
if [ "$BAK_METHOD" == "full" ];then
   header
   full_bak
   prunefile 
else
   header
   inc_bak
   prunefile
fi
endtime=`date +'%Y-%m-%d %H:%M:%S'`
end_seconds=$(date --date="$endtime" +%s)
delta_seconds=$((end_seconds-start_seconds))
hours=$((delta_seconds / 3600))
minutes=$((delta_seconds % 3600 / 60))
seconds=$((delta_seconds % 60))
echo "================================================================" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
echo -e "\tStatus:$bak_status" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
echo -e "\tBackup file:$bak_file" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
echo -e "\tBackup file Size:$bak_size" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
echo -e "\tCompressed file:$compressed_file" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
echo -e "\tCompressed Size:$compressed_size" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
echo -e "\tExpired file Count:$expire_files_count" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
echo -e "\tTime Spend:\t $hours h $minutes m $seconds s" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log
echo "================================================================" >> $BAK_SAVE_DIR/$BAK_METHOD/$DATE.log

 

