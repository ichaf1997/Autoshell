#!/bin/bash
export DATE=$(date +%Y%m%d)
export pw_file=/etc/rsyncd.password
app_name=82rmis
app_dir=/data/tomcat_rmis
bak_dir=/data/backup/
keep_time=30
exclude_dir=/data/tomcat_rmis/logs
rsync_user=backup
rsync_host=10.147.2.241
rsync_module=application_backup

[ ! -d $bak_dir ] && mkdir -p $bak_dir
cd $bak_dir
tar zcf $app_name-$DATE.tar.gz -C ${app_dir%/*}/ ${app_dir##*/} --exclude ${exclude_dir##*/}
/usr/bin/rsync -avz $bak_dir $rsync_user@$rsync_host::$rsync_module --password-file=$pw_file
find $bak_dir -mtime +$keep_time -exec rm -rf {} \;
