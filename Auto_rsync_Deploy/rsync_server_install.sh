#!/bin/bash

# Input
LOG_FILE=/var/log/rsyncd.log
HOSTS_ALLOW="192.168.142.0/24"
AUTH_PASSWORD=$(openssl rand -base64 6)
BACKUP_DIR=/data
AUTH_BAKUSER=rsync_backup

rpm -qa|grep rsync >/dev/null 2>&1
[ "$?" != "0" ] && yum -y install rsync >/dev/null 2>&1

echo "#GLOBAL VARIABLES
uid = rsync
gid = rsync
use chroot = no
max connections = 100
pid file = /var/run/rsyncd.pid
lock file = /var/run/rsyncd.lock
log file = $LOG_FILE

#Module Configuration
[mysql]
comment = \"MySQL backup dir\"
path = $BACKUP_DIR
read only = false
list = false
hosts allow = $HOSTS_ALLOW
hosts deny = 0.0.0.0/24
auth users = $AUTH_BAKUSER
secrets file = /etc/rsyncd.password

#[nginx]
#comment = \"nginx backup dir\"
#path = $BACKUP_DIR/nginx
#read only = false
#list = false
#hosts allow = $HOSTS_ALLOW
#hosts deny = 0.0.0.0/24
#auth users = $AUTH_BAKUSER
#secrets file = /etc/rsyncd.password

#[tomcat]
#comment = \"tomcat backup dir\"
#path = $BACKUP_DIR/tomcat
#read only = false
#list = false
#hosts allow = $HOSTS_ALLOW
#hosts deny = 0.0.0.0/24
#auth users = $AUTH_BAKUSER
#secrets file = /etc/rsyncd.password" > /etc/rsyncd.conf

# Create User for Rsync
useradd -s /sbin/nologin -r rsync >/dev/null 2>&1

# Create Auth File for Rsync client
echo "${AUTH_BAKUSER}:${AUTH_PASSWORD}" > /etc/rsyncd.password
chmod 600 /etc/rsyncd.password

# Create backup dir
mkdir -p $BACKUP_DIR >/dev/null 2>&1
chown -R rsync.rsync $BACKUP_DIR

# bootup
echo "/bin/rsync --daemon">>/etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local

# Create admin script
echo "
#!/bin/bash
case \$1 in
start)
if [ -e \"/var/run/rsyncd.pid\" ];then
   echo \"Rsync is Running!\"
else
   /bin/rsync --daemon
fi
;;
stop)
if [ ! -e \"/var/run/rsyncd.pid\" ];then
   echo \"Rsync is not Running!\"
else
   kill -s 9 \$(ps -ef |grep \"rsync --daemon\"|grep -v \"grep\"|awk -F[\" \"]+ '{print \$2}')
   rm -rf /var/run/rsyncd.*
fi
;;
restart)
kill -s 9 \$(ps -ef |grep \"rsync --daemon\"|grep -v \"grep\"|awk -F[\" \"]+ '{print \$2}') >>/dev/null 2>&1
rm -rf /var/run/rsyncd.*
/bin/rsync --daemon
;;
*)echo \"Usage:\$0 [start|stop|restart]\" 
esac" >/usr/bin/rsync_admin
chmod +x /usr/bin/rsync_admin

# Create client_install script
echo "#!/bin/bash
echo ${AUTH_PASSWORD} >/etc/rsyncd.password
chmod 600 /etc/rsyncd.password
echo \"Usage: rsync -avz [--delete] [backup_dir] [backup_user]@[server_host]::[module_name] --password-file=/etc/rsyncd.password \"
">$(pwd)/rsync_cilent_install.sh

echo -e "\tadmin script:\t/usr/bin/rsync_admin"
echo -e "\tclient install script:\t$(pwd)/rsync_cilent_install.sh"
echo -e "\tauth_user:\t${AUTH_BAKUSER}"
echo -e "\tpassword:\t${AUTH_PASSWORD}"
echo -e "\tbackupdir:\t${BACKUP_DIR}"
echo "Completed!"
