#!/bin/bash
# This script will install redis automatically
# Set variables in redis_install.ini to control this script
# Usage : sh $0 


# Check lg.cnf is primary
[ ! -f "$(pwd)/redis_install.ini" ] && echo "$(pwd)/redis_install.ini is needed ..Stop here" && exit 1
source $(pwd)/redis_install.ini

# Check existence of Src Package 
if [ ! -f "$REDIS_PACKAGE_PATH" ];then
   [ ! -d "${REDIS_PACKAGE_PATH%/*}" ] && mkdir -p ${REDIS_PACKAGE_PATH%/*}
   yum -y install wget >/dev/null 2>&1
   wget -T 60 $REDIS_URL -O $REDIS_PACKAGE_PATH
fi

# Uncompress Src Package
[ ! -d "${REDIS_PACKAGE_PATH%/*}/redis" ] && mkdir -p ${REDIS_PACKAGE_PATH%/*}/redis
tar -zxvf $REDIS_PACKAGE_PATH -C ${REDIS_PACKAGE_PATH%/*}/redis --strip-components 1

# Make && Make install
cd ${REDIS_PACKAGE_PATH%/*}/redis
make
cd ${REDIS_PACKAGE_PATH%/*}/redis/src
make install

# Configuration edit
[ ! -d "/etc/redis" ] && mkdir -p /etc/redis
cp ${REDIS_PACKAGE_PATH%/*}/redis/redis.conf /etc/redis/${REDIS_PORT}.conf
sed -i 's/^daemonize.*/daemonize yes/g' /etc/redis/${REDIS_PORT}.conf
sed -i "/^requirepass.*/d" /etc/redis/${REDIS_PORT}.conf
sed -i "/^bind.*/d" /etc/redis/${REDIS_PORT}.conf
redis_persistence_dir=$(echo ${REDIS_PERSISTENCE_DIR}|sed 's/\//\\\//g')
if [ "$REDIS_log_enable" == "1" ];then
   [ ! -d "${REDIS_log_file%/*}" ] && mkdir -p ${REDIS_log_file%/*} 
   log_file=$(echo ${REDIS_log_file}|sed 's/\//\\\//g')
   sed -i "s/^logfile.*/logfile ${log_file}/g" /etc/redis/${REDIS_PORT}.conf
   sed -i "s/^loglevel.*/loglevel ${REDIS_log_level}/g" /etc/redis/${REDIS_PORT}.conf
fi
sed -i "/^rename-command.*/d" /etc/redis/${REDIS_PORT}.conf
sed -i "s/^dir.*/dir ${redis_persistence_dir}/g" /etc/redis/${REDIS_PORT}.conf
sed -i "s/6379/${REDIS_PORT}/g" /etc/redis/${REDIS_PORT}.conf
sed -i "s/^protected-mode.*/protected-mode no/g" /etc/redis/${REDIS_PORT}.conf
echo "requirepass ${REDIS_PASSWORD}" >> /etc/redis/${REDIS_PORT}.conf
echo "bind ${REDIS_BIND}" >>/etc/redis/${REDIS_PORT}.conf
[ ! -d "$REDIS_PERSISTENCE_DIR" ] && mkdir -p $REDIS_PERSISTENCE_DIR
# Add Systemd
echo "#!/bin/bash
REDISPORT=$REDIS_PORT
EXEC=/usr/local/bin/redis-server
CLIEXEC=/usr/local/bin/redis-cli
BIND=$REDIS_BIND
PASSWORD=$REDIS_PASSWORD

PIDFILE=/var/run/redis_\${REDISPORT}.pid
CONF=\"/etc/redis/\${REDISPORT}.conf\"
case \"\$1\" in
    start)
        if [ -f \$PIDFILE ]
        then
                echo \"\$PIDFILE exists, process is already running or crashed\"
        else
                echo \"Starting Redis server...\"
                \$EXEC \$CONF --port \$REDISPORT
        fi
        ;;
    stop)
        if [ ! -f \$PIDFILE ]
        then
                echo \"\$PIDFILE does not exist, process is not running\"
        else
                PID=\$(cat \$PIDFILE)
                echo \"Stopping ...\"
                \$CLIEXEC -p \$REDISPORT -h \$BIND -a \$PASSWORD shutdown
                while [ -x /proc/\${PID} ]
                do
                    echo \"Waiting for Redis to shutdown ...\"
                    sleep 1
                done
                echo \"Redis stopped\"
        fi
        ;;
    *)
        echo \"Please use start or stop as first argument\"
        ;;
esac" >/etc/init.d/redis
chmod +x /etc/init.d/redis
systemctl daemon-reload 
systemctl enable redis >/dev/null 2>&1
echo "        Port     : $REDIS_PORT" >>${REDIS_PACKAGE_PATH%/*}/Redis_auth.txt
echo "  Auth Password  : $REDIS_PASSWORD " >>${REDIS_PACKAGE_PATH%/*}/Redis_auth.txt
[ "$REDIS_log_enable" == "1" ] && echo "      Log Dir    : $REDIS_log_file" >>${REDIS_PACKAGE_PATH%/*}/Redis_auth.txt
echo "     Conf Path   : /etc/redis/${REDIS_PORT}.conf" >>${REDIS_PACKAGE_PATH%/*}/Redis_auth.txt
echo "     Dump dir    : $REDIS_PERSISTENCE_DIR" >>${REDIS_PACKAGE_PATH%/*}/Redis_auth.txt
echo "Primary information was saved in ${REDIS_PACKAGE_PATH%/*}/Redis_auth.txt"
echo "Sever Manage : systemctl [start|stop] redis"
echo "    Usage    : redis-cli"
echo "  Password   : $REDIS_PASSWORD"
