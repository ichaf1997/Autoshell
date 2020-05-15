#!/bin/bash
export DATE=$(date +%Y%m%d)
export pw_file=/etc/rsyncd.password
app_name1=leader-view
app_name2=admin
app_name3=timed-task
app_name4=leader-nginx
app_dir1=/data/leader-view
app_dir2=/data/admin
app_dir3=/data/timed-task
app_dir4=/data/nginx
exclude_dir1=$app_dir1/log
exclude_dir2=$app_dir2/log
exclude_dir3=$app_dir3/log
exclude_dir4=$app_dir4/logs
bak_dir=/data/backup/
keep_time=90
rsync_user=backup
rsync_host=10.147.2.241
rsync_module=application_backup

[ ! -d $bak_dir ] && mkdir -p $bak_dir
cd $bak_dir

tar zcf $app_name1-$DATE.tar.gz -C ${app_dir1%/*}/ ${app_dir1##*/} --exclude ${exclude_dir1##*/}
tar zcf $app_name2-$DATE.tar.gz -C ${app_dir2%/*}/ ${app_dir2##*/} --exclude ${exclude_dir2##*/}
tar zcf $app_name3-$DATE.tar.gz -C ${app_dir3%/*}/ ${app_dir3##*/} --exclude ${exclude_dir3##*/}
tar zcf $app_name4-$DATE.tar.gz -C ${app_dir4%/*}/ ${app_dir4##*/} --exclude ${exclude_dir4##*/}
/usr/bin/rsync -avz $bak_dir $rsync_user@$rsync_host::$rsync_module --password-file=$pw_file
find $bak_dir -mtime +$keep_time -exec rm -rf {} \;
