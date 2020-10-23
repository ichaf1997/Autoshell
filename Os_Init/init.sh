#!/bin/bash
# Apply to Centos - 7 
# Control this script by Input parameters
# Usage : $0 

# Input [ boolean ]
# value 1 means open , value 0 means close

SELINUX_ENABLE=0  
FIREWALLD_ENABLE=0
POSTFIX_ENABLE=0
NetworkManager_ENABLE=0
TIMESYNC_ENABLE=0

# Input [ string ]

HOST_NAME=""           # custom hostname , add here
SOFT_NOFILE=65535      # modify /etc/security/limits.conf 
HARD_NOFILE=65535
SOFT_NOPROC=65535
HARD_NOPROC=65535
YUM_repo="DVD"         # If you don't want to use local repo . modify here as remote repo URL 
                       # If you don't want to change anything . modify here as "None"
TIME_SYNC_FROM="ntp1.aliyun.com" 
APP_LIST=(vim wget mlocate net-tools gcc* openssl* pcre-devel) # APPS arrary , add apps you want to install here , Be careful to use space as separator for every app .

[ -e "/tmp/init.lock" ] && echo "Don't run this script repeatedly !" && exit 0
echo -e "Time\t$(date +%Y.%m.%d\ %T\ %a) - [Start]" > init.log
log_path=$(pwd)/init.log

# Define log format
LOG_DUMP(){
  case $1 in
  ok)
       echo "$(date +%Y.%m.%d\ %T\ %a) - [ok] $2" >> $log_path
  ;;
  no)
       echo "$(date +%Y.%m.%d\ %T\ %a) - [no] $2" >> $log_path
  esac
}

# Repo 
func1(){
  case $1 in
  DVD)
      if [ "$(blkid|grep iso9660|wc -l)" == "1" ]
      then
          dvd=$(blkid|grep iso9660|awk 'BEGIN{FS=":"}{print $1}')
          mount_point=$(df -h|grep "$dvd"|awk '{print $6}')
          if [ -n "$mount_point" ] 
          then
              cd /etc/yum.repos.d
              for name in $(ls)
              do
                  mv $name $name.bak
              done
              cat >>/etc/yum.repos.d/local.repo<<EOF
[Admin]
name=admin
baseurl=file://$mount_point
enabled=1 
gpgcheck=0
EOF
              yum clean all >/dev/null 2>&1
              yum makecache >/dev/null 2>&1
              LOG_DUMP ok "Use local dvd repo"
          else
              LOG_DUMP no "Use local dvd repo :: DVD no mount in the Filesystem"
          fi
     else
          LOG_DUMP no "Use local dvd repo :: DVD no found"
     fi
  ;;
  None)
  ;;
  *)
    curl -o /etc/yum.repos.d/Custom.repo $YUM_repo >/dev/null 2>&1
    if [ "$?" == "0" ] 
    then 
        LOG_DUMP ok "Download repo from $YUM_repo"
        cd /etc/yum.repos.d
        for name in $(ls|grep -v "Custom.repo")
        do
            mv $name $name.bak
        done
        yum clean all >/dev/null 2>&1
        yum makecache >/dev/null 2>&1
    else
        LOG_DUMP no "Download repo from $YUM_repo"
    fi
  esac
}
func1 $YUM_repo


# Apps Install
func2(){
  for ((i=0;i<${#APP_LIST[*]};i++))
  do
      yum -y install ${APP_LIST[$i]} >/dev/null 2>&1
      if [ "$?" == "0" ]
      then
          LOG_DUMP ok "install ${APP_LIST[$i]}"
      else
          LOG_DUMP no "install ${APP_LIST[$i]}"
      fi
  done
}
func2

# Time SYNC
if [ $TIMESYNC_ENABLE -eq 1 ];then
  rpm -qa|grep ntp >/dev/null 2>&1
  if [ "$?" != "0" ];then
      yum -y install ntp >/dev/null 2>&1
      if [ "$?" == "0" ];then
          echo "*/5 * * * * /usr/sbin/ntpdate $TIME_SYNC_FROM">/var/spool/cron/root
          LOG_DUMP ok "time sync from $TIME_SYNC_FROM"
      else
          LOG_DUMP no "time sync from $TIME_SYNC_FROM :: Download ntp failed"
      fi
  else
      echo "*/5 * * * * /usr/sbin/ntpdate $TIME_SYNC_FROM">/var/spool/cron/root
      LOG_DUMP ok "time sync from $TIME_SYNC_FROM"
  fi        
fi
# Hostname
if [ -n "$HOST_NAME" ]
then
    hostnamectl set-hostname $HOST_NAME 
    LOG_DUMP ok "modify hostname : $HOST_NAME"
fi

# Max Files open
grep "ulimit -SHn" /etc/rc.local >/dev/null 2>&1
if [ "$?" != "0" ]
then
    echo "ulimit -SHn 102400" >> /etc/rc.local
    LOG_DUMP ok "add \"ulimit -SHn 102400\" to /etc/rc.local"
fi
grep "# MaxFileControl" /etc/rc.local >/dev/null 2>&1
if [ "$?" != "0" ]
then
    cat >> /etc/security/limits.conf << EOF
# MaxFileControl by Init.sh
*           soft   nofile       $SOFT_NOFILE
*           hard   nofile       $HARD_NOFILE
*           soft   nproc       $SOFT_NOPROC
*           hard   nproc       $HARD_NOPROC     
EOF
    ulimit -n $HARD_NOFILE
    LOG_DUMP ok "modify MaxFileControl soft=$SOFT_NOFILE hard=$HARD_NOFILE"
fi

# SELINUX
if [ "$SELINUX_ENABLE" == "0" ]
then
    if [ "$(cat /etc/selinux/config | grep -v "#" | grep -w "SELINUX" | cut -d "=" -f 2)" == "enforcing" ]
    then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config >/dev/null 2>&1           
    fi
    LOG_DUMP ok "close selinux"
fi

# Postix NetworkManager Firewalld

if [ $FIREWALLD_ENABLE == "0" ] 
then
    systemctl stop firewalld >/dev/null 2>&1
    [ "$?" == "0" ] && LOG_DUMP ok "close firewalld" || LOG_DUMP no "close firewalld"
    systemctl disable firewalld >/dev/null 2>&1
fi

if [ $POSTFIX_ENABLE == "0" ]
then
    systemctl stop postfix >/dev/null 2>&1
    [ "$?" == "0" ] && LOG_DUMP ok "close postfix" || LOG_DUMP no "close postfix"
    systemctl disable postfix >/dev/null 2>&1
fi

if [ $NetworkManager_ENABLE == "0" ]
then
    systemctl stop NetworkManager >/dev/null 2>&1
    [ "$?" == "0" ] && LOG_DUMP ok "close NetworkManager" || LOG_DUMP no "close NetworkManager"
    systemctl disable NetworkManager >/dev/null 2>&1
fi
    
# Custom optimize

func0(){
  sed -i '/linux16 \/boot\/vmlinuz-3/{s/rhgb quiet/vga=817/}' /boot/grub2/grub.cfg
  echo "set ts=2" >> /etc/vimrc
  sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
  #sed -i 's/LANG="en_US.UTF-8"/LANG="zh_CN.UTF-8"/' /etc/locale.conf
  echo LANG=\"zh_CN.UTF-8\" /etc/locale.conf
  sed -i 's/\\w]/\\W]/g' /etc/bashrc
  rm -rf /etc/localtime
  ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  cat >> /etc/sysctl.conf << EOF
vm.overcommit_memory = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_abort_on_overflow = 0
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 65500
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
#net.ipv4.netfilter.ip_conntrack_max = 2097152
#net.nf_conntrack_max = 655360
#net.netfilter.nf_conntrack_tcp_timeout_established = 1200
EOF
/sbin/sysctl -p
}
func0

echo -e "Time\t$(date +%Y.%m.%d\ %T\ %a) - [Complete]" >> $log_path

# Generate lock file
touch /tmp/init.lock

# reboot
init 6
