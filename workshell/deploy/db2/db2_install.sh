#!/bin/bash
Version=10.5
License_Map=/opt/db2v10.5ese_u.lic
sed -i "s/127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4/127.0.0.1   $(hostname) localhost localhost.localdomain localhost4 localhost4.localdomain4/g" /etc/hosts
sed -i "s/::1         localhost localhost.localdomain localhost6 localhost6.localdomain6/::1         $(hostname) localhost localhost.localdomain localhost6 localhost6.localdomain6/g" /etc/hosts
groupadd  db2iadm1  
groupadd  db2fadm1  
groupadd  dasadm1 
useradd  -g db2iadm1 -m -d /home/db2admin db2admin 
useradd  -g db2fadm1 -m -d /home/db2fenc1 db2fenc1  
useradd  -g dasadm1 -m -d /home/dasusr1 dasusr1
echo "db2admin" |passwd --stdin db2admin
echo "db2fenc1" |passwd --stdin db2fenc1  
echo "dasusr1" |passwd --stdin dasusr1
cd /opt/ibm/db2/V$Version/adm
./db2licm -a $License_Map || exit 0
cd /opt/ibm/db2/V$Version/instance
./dascrt -u dasusr1 || exit 0
./db2icrt -a SERVER -u db2fenc1 db2admin || exit 0
su - db2admin -c "db2set DB2_EXTENDED_OPTIMIZATION=ON"
su - db2admin -c "db2set DB2_DISABLE_FLUSH_LOG=ON"
su - db2admin -c "db2set AUTOSTART=YES"
su - db2admin -c "db2set DB2_HASH_JOIN=YES"
su - db2admin -c "db2set DB2COMM=tcpip"
su - db2admin -c "db2set DB2_PARALLEL_IO=*"
su - db2admin -c "db2set DB2CODEPAGE=1208"
