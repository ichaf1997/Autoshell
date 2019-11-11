#!/bin/bash

if [ -e "/tmp/chaff_init.lock" ]
then
    echo "you have already ran this script before !"
fi

# Edit ssh client connect timeout

if [ "$(cat /etc/ssh/ssh_config|grep '^ConnectTimeout'|wc -l)" == "1" ]
then
    sed -i 's/^ConnectTimeout.*$/ConnectTimeout 1/g' /etc/ssh/ssh_config
else
    echo 'ConnectTimeout 1' >> /etc/ssh/ssh_config
fi

# Edit chaff.ini to adapt your environment

localdir=$(echo $(pwd)|sed 's/\//\\\//g')

sed -i "s/^chaff_groupdir.*$/chaff_groupdir=$localdir\/group/g" chaff.ini
sed -i "s/^chaff_log.*$/chaff_log=$localdir\/chaff.log/g" chaff.ini
sed -i "s/^chaff_moduledir.*$/chaff_moduledir=$localdir\/chaff_modules/g" chaff.ini

# Generate lock file

touch /tmp/chaff_init.lock >/dev/null 2>&1

