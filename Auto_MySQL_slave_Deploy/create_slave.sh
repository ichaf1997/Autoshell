#!/bin.bash
# Generate slave fast with GTID Automatically
# 2019-10-8
# By Goppppog

#Loaded configuration file
if [ ! -f "$(pwd)/mysql_slave.ini" ];then
    echo "$(pwd)/mysql_slave.ini unable to be loaded ..."
    exit 1
fi
source $(pwd)/mysql_slave.ini

if [ ! -f "$(pwd)/autoget.sh" ];then
    echo "$(pwd)/autoget.sh is not available ..."
    exit 1
fi

if [ ! -f "$(pwd)/autoexec_xtra.sh" ];then
    echo "$(pwd)/autoexec_xtra.sh is not available ..."
    exit 1
fi

if [ ! -f "$(pwd)/autoexec_phy.sh" ];then
    echo "$(pwd)/autoexec_phy.sh is not available ..."
    exit 1
fi

if [ ! -f "$(pwd)/autoexec_dump.sh" ];then
    echo "$(pwd)/autoexec_dump.sh is not available ..."
    exit 1
fi


#Create MySQL user 
cat /etc/group | grep "mysql" >/dev/null 2>&1
[ "$?" != "0" ] && groupadd mysql
cat /etc/passwd | grep "mysql" >/dev/null 2>&1
[ "$?" != "0" ] && useradd -g mysql mysql
ln -s -f /dev/null /home/mysql/.bash_history >/dev/null 2>&1
ln -s -f /dev/null /home/mysql/.mysql_history >/dev/null 2>&1

#Create Slave relay direction
[ ! -d "/tmp/relay" ] && mkdir -p /tmp/relay
[ ! -d "/tmp/relay/conf" ] && mkdir -p /tmp/relay/conf
[ ! -d "/tmp/relay/data" ] && mkdir -p /tmp/relay/data

#Chk Env
rpm -qa|grep expect >/dev/null 2>&1
[ "$?" != "0" ] && yum -y install expect

#Get Source Server file my.cnf
./autoget.sh ${Source_HOST} ${Source_PASSWORD} ${Source_ACCOUNT} /tmp/relay/conf ${Source_conf_PATH} 
sed -i "s/^server_id.*$/server_id=${Slave_server_id}/g" /tmp/relay/conf/my.cnf
cat /tmp/relay/conf/my.cnf |egrep -i '^rpl_semi_sync_master_enabled.*' >/dev/null 2>&1
[ "$?" == "0" ] && Master_semi_status=1 || Master_semi_status=0
sed -i '/^rpl_semi_sync_slave_enabled.*/d' /tmp/relay/conf/my.cnf
sed -i '/^rpl_semi_sync_master_enabled.*/d' /tmp/relay/conf/my.cnf
sed -i '/^rpl_semi_sync_master_timeout.*/d' /tmp/relay/conf/my.cnf

#Get Dir Info from my.cnf
mysql_dir=$(cat /tmp/relay/conf/my.cnf |egrep "^basedir.*$"|head -1|cut -d "=" -f 2|sed 's/^ //g')
data_dir=$(cat /tmp/relay/conf/my.cnf |egrep "^datadir.*$"|head -1|cut -d "=" -f 2|sed 's/^ //g') 
tmp_dir=$(cat /tmp/relay/conf/my.cnf |egrep "^tmpdir.*$"|head -1|cut -d "=" -f 2|sed 's/^ //g')
log_bin_dir=$(cat /tmp/relay/conf/my.cnf |egrep "^log-bin.*$"|head -1|cut -d "=" -f 2|sed 's/^ //g')

#Create Slave MySQL Direction
mkdir -p ${mysql_dir} ${data_dir} ${tmp_dir} ${log_bin_dir%/*} ${Source_conf_PATH%/*} >/dev/null 2>&1
chown -R mysql.mysql ${mysql_dir} ${data_dir} ${tmp_dir} ${log_bin_dir%/*} ${Source_conf_PATH%/*} >/dev/null 2>&1
chown -R mysql.mysql ${data_dir}
#Copy Source Server my.cnf to Slave conf_dir
cp /tmp/relay/conf/my.cnf ${Source_conf_PATH}
chown -R mysql.mysql /$(echo ${Source_conf_PATH}|cut -d "/" -f 2)

#Tar MySQL in Slave
tar -xvf ${MySQL_BIN_PACKAGE} -C ${mysql_dir} --strip-components 1
chown -R mysql.mysql ${mysql_dir} >/dev/null 2>&1

#Generate DATA BACKUP in Source Server
data_backup(){
  case ${Create_method} in
    physical)
    ${mysql_dir}/bin/mysql -u${Source_MySQL_ROOT_ACCOUNT} -p${Source_MySQL_ROOT_PASSWORD} -h${Source_HOST} -e "stop slave;"
    ./autoexec_phy.sh ${Source_HOST} ${Source_PASSWORD} ${Source_ACCOUNT} ${data_dir} $(echo ${data_dir}|awk -F ["/"]+ '{print $NF}')/
    ./autoget.sh ${Source_HOST} ${Source_PASSWORD} ${Source_ACCOUNT} /tmp/relay/data /tmp/phy_fullbak.tar.gz
    ${mysql_dir}/bin/mysql -u${Source_MySQL_ROOT_ACCOUNT} -p${Source_MySQL_ROOT_PASSWORD} -h${Source_HOST} -e "start slave;"
    ;;
    mysqldump)
    ./autoexec_dump.sh ${Source_HOST} ${Source_PASSWORD} ${Source_ACCOUNT} ${mysql_dir} ${Source_MySQL_ROOT_ACCOUNT} ${Source_MySQL_ROOT_PASSWORD}
    ./autoget.sh ${Source_HOST} ${Source_PASSWORD} ${Source_ACCOUNT} /tmp/relay/data /tmp/dump_fullbak.sql.gz
    ;;
    xtrabackup)   ### completed OK!
    #Tar Xtrabackup in Slave
    [ ! -d "/usr/local/xtrabackup" ] && mkdir -p /usr/local/xtrabackup
    yum -y install libaio*
    tar -xvf ${Xtra_BIN_PACKAGE} -C /usr/local/xtrabackup --strip-components 1

    ./autoexec_xtra.sh ${Source_HOST} ${Source_PASSWORD} ${Source_ACCOUNT} ${Source_Xtra_PATH} ${Source_conf_PATH} ${Source_MySQL_backup_ACCOUNT} ${Source_MySQL_backup_PASSWORD}
    ./autoget.sh ${Source_HOST} ${Source_PASSWORD} ${Source_ACCOUNT} /tmp/relay/data /tmp/xtra_fullbak.tar.gz
    ;;
    *)
    echo "data backup failed . \"Create_method\" at line $(cat $(pwd)/mysql_slave.ini |grep -n Create_method|cut -d ":" -f 1) test failed ."
    exit 6
  esac
}
data_backup

#Recovery DATA in Slave Server
data_recovery(){
  case ${Create_method} in
    physical)
    cd /tmp/relay/data
    tar -zxvf phy_fullbak.tar.gz -C ${data_dir} --strip-components 1
    rm ./phy_fullbak.tar.gz
    chown -R mysql.mysql ${data_dir}
    rm -rf ${data_dir}/auto.cnf
    ;;
    mysqldump)
    cd /tmp/relay/data
    gzip -d /tmp/relay/data/dump_fullbak.sql.gz
    ${mysql_dir}/bin/mysqld --defaults-file=${Source_conf_PATH} --initialize-insecure --user=mysql
    ${mysql_dir}/bin/mysqld_safe --defaults-file=${Source_conf_PATH} &
    sleep 10
    ${mysql_dir}/bin/mysql -uroot --skip-password -e "alter user root@'localhost' identified by '${Source_MySQL_ROOT_PASSWORD}'"
    ${mysql_dir}/bin/mysql -u${Source_MySQL_ROOT_ACCOUNT} -p${Source_MySQL_ROOT_PASSWORD} -e "source /tmp/relay/data/dump_fullbak.sql"    
    ;;
    xtrabackup)
    cd /tmp/relay/data
    tar -zxvf xtra_fullbak.tar.gz
    rm -rf ./xtra_fullbak.tar.gz
    /usr/local/xtrabackup/bin/innobackupex --defaults-file=${Source_conf_PATH} --apply-log /tmp/relay/data
    /usr/local/xtrabackup/bin/innobackupex --defaults-file=${Source_conf_PATH} --copy-back /tmp/relay/data/
    chown -R mysql.mysql ${data_dir} 
  esac
}
data_recovery
#Change Master to 
sudo -i -u mysql ${mysql_dir}/bin/mysqld_safe --defaults-file=${Source_conf_PATH} &
sleep 10
${mysql_dir}/bin/mysql -u${Source_MySQL_ROOT_ACCOUNT} -p${Source_MySQL_ROOT_PASSWORD} -e "CHANGE MASTER TO MASTER_HOST='${Master_HOST}',MASTER_PORT=${Master_PORT},MASTER_USER='${Master_USER}',MASTER_PASSWORD='${Master_PASSWORD}',MASTER_AUTO_POSITION=1;"
${mysql_dir}/bin/mysql -u${Source_MySQL_ROOT_ACCOUNT} -p${Source_MySQL_ROOT_PASSWORD} -e "start slave;"

#Slave Semi Set
if [ "${Slave_semi_open}" == "1" ];then
   ${mysql_dir}/bin/mysql -u${Source_MySQL_ROOT_ACCOUNT} -p${Source_MySQL_ROOT_PASSWORD} -e "install plugin rpl_semi_sync_slave SONAME'semisync_slave.so';" 
   ${mysql_dir}/bin/mysql -u${Source_MySQL_ROOT_ACCOUNT} -p${Source_MySQL_ROOT_PASSWORD} -e "set global rpl_semi_sync_slave_enabled=1;"
   ${mysql_dir}/bin/mysql -u${Source_MySQL_ROOT_ACCOUNT} -p${Source_MySQL_ROOT_PASSWORD} -e "stop slave io_thread;"
   ${mysql_dir}/bin/mysql -u${Source_MySQL_ROOT_ACCOUNT} -p${Source_MySQL_ROOT_PASSWORD} -e "start slave io_thread;"
   lines=$(cat ${Source_conf_PATH} |grep -n "mysqld"|cut -d ":" -f 1)
   sed -i "${lines}a rpl_semi_sync_slave_enabled=1" ${Source_conf_PATH}   
fi

#PowerBoot
echo "sudo -i -u mysql ${mysql_dir}/bin/mysqld_safe --defaults-file=${Source_conf_PATH} &" >> /etc/rc.d/rc.local
chmod u+x /etc/rc.d/rc.local >/dev/null 2>&1        
