#!/bin/bash
export DATE=$(date +%Y%m%d)
export pw_file=/etc/rsyncd.password
app_name=tomcat6-mas
app_dir=/data/tomcat6-mas
bak_dir=/data/backup/
keep_time=90
exclude_dir=$app_dir/logs
rsync_user=backup
rsync_host=10.147.2.241
rsync_module=application_backup

[ ! -d $bak_dir ] && mkdir -p $bak_dir
cd $bak_dir
tar zcf $app_name-$DATE.tar.gz -C ${app_dir%/*}/ ${app_dir##*/} --exclude ${exclude_dir##*/}

rm -rf /tmp/mosquitto
mkdir -p /tmp/mosquitto
cp /usr/local/sbin/mosquitto /tmp/mosquitto/
cp -r /etc/mosquitto /tmp/mosquitto/etc
cd /tmp/
tar zcf mosquitto-$DATE.tar.gz -C /tmp/ mosquitto
mv /tmp/mosquitto-$DATE.tar.gz $bak_dir

/usr/bin/rsync -avz $bak_dir $rsync_user@$rsync_host::$rsync_module --password-file=$pw_file
find $bak_dir -mtime +$keep_time -exec rm -rf {} \;
