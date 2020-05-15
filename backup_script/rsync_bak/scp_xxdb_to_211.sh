#!/bin/bash
export DATE=$(date +%Y%m%d)
db_dir=/home/rmis_backup/autobackup
#wsjydb_dir=/data/backup/database/wsjy
#rmisdb_dir=/data/backup/database/rmis
remote_host=59.37.40.252
remote_port=8158
remote_dir=/home/dg-bak/db-backup/
[ ! -f $db_dir/scp.log ] && touch $db_dir/scp.log
for n in `seq 1 600`
do
    if [ ! -f $db_dir/full/$DATE.log ];then
       #echo "No log file" #
       sleep 120
       continue
    else
       cat $db_dir/full/$DATE.log | grep "Compressed file" > /dev/null 2>&1
       if [ $? -eq 0 ];then
         compress_file=$(cat $db_dir/full/$DATE.log | grep "Compressed file"|cut -d: -f2)
         total_size=$(cat $db_dir/full/$DATE.log | grep "Compressed Size"|cut -d: -f2)
       else
         compress_file=None
         total_size=0
       fi
       ls -l $db_dir/full/$DATE/$compress_file > /dev/null 2>&1
       if [ $? -eq 0 ];then
         real_size=$(ls -l $db_dir/full/$DATE/$compress_file |awk '{print $5}')
       else
         real_size=-1
       fi
       if [ $total_size -eq $real_size ];then
         #echo OK #
         starttime=`date +'%Y-%m-%d %H:%M:%S'`
         start_seconds=$(date --date="$starttime" +%s)
         scp -P $remote_port $db_dir/full/$DATE/$compress_file root@$remote_host:$remote_dir > /dev/null 2>&1
         if [ $? -eq 0 ];then
            endtime=`date +'%Y-%m-%d %H:%M:%S'`
            end_seconds=$(date --date="$endtime" +%s)
            delta_seconds=$((end_seconds-start_seconds))
            hours=$((delta_seconds / 3600))
            minutes=$((delta_seconds % 3600 / 60))
            seconds=$((delta_seconds % 60))
            echo "[ok] $starttime - send $compress_file total $total_size to $remote_host:$remote_dir Time Required: $hours h $minutes m $seconds s " >> $db_dir/scp.log
         else
            echo "[no] $starttime - send $compress_file total $total_size to $remote_host:$remote_dir Time Required: 0" >> $db_dir/scp.log
         fi
         exit 0
       else
         #echo NO #
         sleep 120
         continue
       fi
    fi
done
