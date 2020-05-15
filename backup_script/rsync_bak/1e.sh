#!/bin/bash
export DATE=$(date +%Y%m%d)
export pw_file=/etc/rsyncd.password
app_name1=rsa
app_name2=mina
app_dir1=/data/jboss_rsa/server/default
app_dir2=/data/jboss_mina/standalone
exclude_dir1=$app_dir1/log
exclude_dir2=$app_dir2/log
bak_dir=/data/backup/
keep_time=90
rsync_user=backup
rsync_host=10.147.2.241
rsync_module=application_backup

[ ! -d $bak_dir ] && mkdir -p $bak_dir
cd $bak_dir

tar zcf $app_name1-$DATE.tar.gz -C ${app_dir1%/*}/ ${app_dir1##*/} --exclude ${exclude_dir1##*/}
tar zcf $app_name2-$DATE.tar.gz -C ${app_dir2%/*}/ ${app_dir2##*/} --exclude ${exclude_dir2##*/}
/usr/bin/rsync -avz $bak_dir $rsync_user@$rsync_host::$rsync_module --password-file=$pw_file
find $bak_dir -mtime +$keep_time -exec rm -rf {} \;
