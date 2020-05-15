#!/bin/bash
export DATE=$(date +%Y%m%d)
share_file_dir=/data/file-1_rsync
local_compressed_dir=/data/backup/share_files
remote_host=59.37.40.252
remote_port=8158
remote_dir=/home/dg-bak/db-backup/
keep_count=3
[ ! -f $local_compressed_dir/scp.log ] && touch $local_compressed_dir/scp.log
cd $local_compressed_dir
tar zcf $DATE-share_file.tar.gz -C ${share_file_dir%/*}/ ${share_file_dir##*/}
scp -P $remote_port $local_compressed_dir/$DATE-share_file.tar.gz root@$remote_host:$remote_dir > /dev/null 2>&1
if [ $? -eq 0 ];then
  echo "[ok] $DATE - Send $DATE-share_file.tar.gz to $remote_host:$remote_dir" >> $local_compressed_dir/scp.log
else
  echo "[no] $DATE - Send $DATE-share_file.tar.gz to $remote_host:$remote_dir" >> $local_compressed_dir/scp.log
fi
file_count=$(ls *share_file.tar.gz|wc-l)
if [ $file_count -gt $keep_count ];then
   dc=$((file_count-keep_count))
   for name in `ls -lt |tail -$dc|awk '{print $NF}'`
   do
       rm -rf $local_compressed_dir/$name
   done
fi
