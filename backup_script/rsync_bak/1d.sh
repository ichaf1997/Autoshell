#!/bin/bash
export DATE=$(date +%Y%m%d)
export pw_file=/etc/rsyncd.password
app_name1=jbosspm
app_name2=tomcat6_zfzjj
app_name3=CGB
app_name4=sftp
app_dir1=/data/jbosspm
app_dir2=/data/tomcat6_zfzjj
app_dir3=/data/CGB
app_dir4=/data/sftp
exclude_dir1=$app_dir1/logs
exclude_dir2=$app_dir2/logs
bak_dir=/data/backup/
keep_time=90
rsync_user=backup
rsync_host=10.147.2.241
rsync_module=application_backup

[ ! -d $bak_dir ] && mkdir -p $bak_dir
cd $bak_dir

tar zcf $app_name1-$DATE.tar.gz -C ${app_dir1%/*}/ ${app_dir1##*/} --exclude ${exclude_dir1##*/}
tar zcf $app_name2-$DATE.tar.gz -C ${app_dir2%/*}/ ${app_dir2##*/} --exclude ${exclude_dir2##*/}
tar zcf $app_name3-$DATE.tar.gz -C ${app_dir3%/*}/ ${app_dir3##*/}
tar zcf $app_name4-$DATE.tar.gz -C ${app_dir4%/*}/ ${app_dir4##*/}
/usr/bin/rsync -avz $bak_dir $rsync_user@$rsync_host::$rsync_module --password-file=$pw_file
find $bak_dir -mtime +$keep_time -exec rm -rf {} \;
