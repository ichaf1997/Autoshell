#!/bin/bash
# This script will create redis slave from redis master automatically 
# Usage:
# Step 1 : Set variables in redis_slave_deploy.ini depend on your enviroment
# Step 2 : Run $0 
# Notice : Please run this script in ready redis slave host.

# Check configuration 
[ ! -f "$(pwd)/autoget.sh" ] && echo "$(pwd)/autoget.sh is needed" && exit 1
[ ! -e "$(pwd)/redis_slave_deploy.ini" ] && echo "$(pwd)/redis_slave_deploy.ini is needed" && exit 1
[ -z "$MASTER_CONF_PATH" ] && MASTER_CONF_PATH=/etc/redis.conf
[ -z "$REDIS_PACKAGE_DIR" ] && REDIS_PACKAGE_DIR=/usr/local/src
[ -z "$REDIS_LOG_PATH" ] && REDIS_LOG_PATH=/tmp/redis.log
[ -z "$sentinel_log_dir" ] && sentinel_log_dir=/tmp
[ ! -d "$sentinel_log_dir" ] && mkdir -p $sentinel_log_dir
[ ! -e "$REDIS_LOG_PATH" ] && touch ${REDIS_LOG_PATH}
source $(pwd)/redis_slave_deploy.ini

# Check whether if run this script before
[ -f "/tmp/redis_instll.lock" ] && echo "Installed already !" && exit 0

# Define Log dump
log_dump(){
   if [ "$1" == "error" ];then
      echo "$(date +%F\ %T) [error] - $2" >> $REDIS_LOG_PATH
      exit 1
   else
      echo "$(date +%F\ %T) [$1] - $2" >> $REDIS_LOG_PATH
   fi   
}

# Get Master configuration file
[ "$(rpm -qa|grep expect|wc -l)" == "0" ] && yum -y install expect >/dev/null 2>&1
[ ! -x "$(pwd)/autoget.sh" ] && chmod +x $(pwd)/autoget.sh
./autoget.sh $M_HOST $M_PASS root /tmp/redis.conf $MASTER_CONF_PATH 
if [ "$?" != "0" ];then
   log_dump error "Get Master configuration file failed from $M_HOST"
else
   log_dump main "Get Master configuration file success from $S_HOST"
fi

# Install wget
rpm -qa|grep wget >/dev/null 2>&1
if [ "$?" != "0" ];then 
   yum -y install wget >/dev/null 2>&1
   log_dump 
   if [ "$?" != "0" ];then
       log_dump error "install wget failed"
   else 
       log_dump main "install wget success"
   fi
fi

# Download redis
[ ! -d "${REDIS_PACKAGE_DIR}" ] && mkdir -p ${REDIS_PACKAGE_DIR}
if [ ! -e "${REDIS_PACKAGE_DIR}/redis.tar.gz" ];then
   wget ${redis_Download_url} -O ${REDIS_PACKAGE_DIR}/redis.tar.gz > /dev/null 2>&1
   if [ "$?" != "0" ];then 
     log_dump error "Download redis from ${redis_Download_url} failed"
   else
     log_dump main "Download redis from ${redis_Download_url} success . Package_PATH=${REDIS_PACKAGE_DIR}/redis.tar.gz"
   fi
fi

# Install redis
[ ! -d "${REDIS_PACKAGE_DIR}/redis" ] && mkdir -p ${REDIS_PACKAGE_DIR}/redis
tar -zxvf ${REDIS_PACKAGE_DIR}/redis.tar.gz -C ${REDIS_PACKAGE_DIR}/redis --strip-components 1 >/dev/null 2>&1
if [ "$?" != "0" ];then
   log_dump error "Tar ${REDIS_PACKAGE_DIR}/redis.tar.gz failed"
else
   log_dump main "Tar ${REDIS_PACKAGE_DIR}/redis.tar.gz success"
fi
cd ${REDIS_PACKAGE_DIR}/redis
make >/dev/null 2>&1
if [ "$?" != "0" ];then
   log_dump error "Make install failed ."
else
   log_dump main "Make install success ."
fi
cd src/
cp -f redis-benchmark redis-check-aof redis-check-rdb redis-cli redis-sentinel redis-server redis-trib.rb /usr/local/bin/

# Edit configuration
IP=$(ip a|grep global|awk '{print $2}'|cut -d "/" -f 1)
M_IP=$(cat /tmp/redis.conf |grep '^bind'|awk '{print $2}')
M_PORT=$(cat /tmp/redis.conf |grep '^port'|awk '{print $2}')
M_PASS=$(cat /tmp/redis.conf |grep '^requirepass'|awk '{print $2}'|sed 's/"//g')
M_PERSISTENCE_DIR=$(cat /tmp/redis.conf|grep '^dir'|awk '{print $2}')
if [ "$M_PERSISTENCE_DIR" != "./" ];then
   [ ! -d "$M_PERSISTENCE_DIR" ] && mkdir -p $M_PERSISTENCE_DIR
fi
sed -i "s/^bind.*/bind ${IP}/g" /tmp/redis.conf
sed -i '/^slaveof.*/d' /tmp/redis.conf
sed -i '/^masterauth/d' /tmp/redis.conf
echo "slaveof $M_IP $M_PORT" >> /tmp/redis.conf
echo "masterauth \"${M_PASS}\"" >> /tmp/redis.conf
mkdir /etc/redis >/dev/null 2>&1
cp /tmp/redis.conf /etc/redis/${M_PORT}.conf

# Sentinel configuration
if [ "$sentinel_enable" == "1" ]
then
    [ ! -d "/etc/sentinel" ] && mkdir -p /etc/sentinel
    echo "port 1${M_PORT}
bind ${M_IP}
daemonize yes
logfile ${sentinel_log_dir}/1${M_PORT}_sentinel.log
sentinel monitor manager1 ${M_IP} ${M_PORT} 2
sentinel auth-pass manager1 ${M_PASS}
sentinel down-after-milliseconds manager1 60000
sentinel failover-timeout manager1 180000
sentinel parallel-syncs manager1 1" > /etc/sentinel/${M_PORT}.conf
fi

# Add Systemd and bootup
echo "#!/bin/bash
REDISPORT=$M_PORT
EXEC=/usr/local/bin/redis-server
CLIEXEC=/usr/local/bin/redis-cli
BIND=$IP
PASSWORD=$M_PASS

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
systemctl daemon-reload >/dev/null 2>&1
systemctl enable redis >/dev/null 2>&1

# Start redis
systemctl start redis >/dev/null 2>&1
if [ "$?" == "0" ];then
   log_dump main "Redis start success"
else
   log_dump warnning "Redis start failed"
fi

# Create lock file
touch /tmp/redis_instll.lock

# Finally
log_dump main "Redis slave create success"
