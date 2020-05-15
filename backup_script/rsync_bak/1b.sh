#!/bin/bash
export DATE=$(date +%Y%m%d)
export pw_file=/etc/rsyncd.password
app_name1=enter-nginx
app_name2=tomcat_sm
app_name3=log-parsing
app_name4=keepalived
app_dir1=/data/nginx
app_dir2=/data/tomcat_sm
app_dir3=/data/log-parsing
app_dir4=/usr/local/keepalived
exclude_dir1=$app_dir1/logs
exclude_dir2=$app_dir2/logs
exclude_dir3=$app_dir3/log
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
rm -rf $app_dir4/keepalived.conf
cp /etc/keepalived/keepalived.conf $app_dir4/
tar zcf $app_name4-$DATE.tar.gz -C ${app_dir4%/*}/ ${app_dir4##*/}
rm -rf $app_dir4/keepalived.conf
/usr/bin/rsync -avz $bak_dir $rsync_user@$rsync_host::$rsync_module --password-file=$pw_file
find $bak_dir -mtime +$keep_time -exec rm -rf {} \;
