#!/bin/bash
##Display
menu(){
echo "
=================================

 (1)NFS      (2)HTTP      (3)FTP

 (5)Scripts add  

 (6)Use Server Repos

       (h)help     (q)quit

================================="
}
##Install and Configure DHCP
idhcp(){
   . /etc/rc.d/init.d/functions
   echo "Installing dhcp..."
   sleep 1
   yum -y install dhcp >/dev/null 2>&1
   if [ "$?" != "0" ];then
       action "Installing Failed ... Please Check your network or Repo Setting !" /bin/false
       exit 1
   else
       action "Installing Successfully !" /bin/true
   fi
   echo "Configure DHCP ..."
   ip=$(ip a|grep "brd"|grep "inet"|awk '{print $2}'|cut -d "/" -f 1)
   gw=$(route -n|grep "UG"|awk '{print $2}')   
   sleep 1
   while true 
   do 
      echo "Your IP is ${ip} .."
      read -p "Please set the range of dynamic-bootp ... start of : " fir
      read -p "Please set the range of dynamic-bootp ... end of : " fin
      echo "Range of ${fir} to ${fin} ."
      read -p "Confirm it ? y or n : " ans
      case ${ans} in
      y|Y)break
      ;;
      *)continue
      esac
   done
   echo "ddns-update-style interim;
ignore client-updates;
subnet ${ip%.*}.0 netmask 255.255.255.0 {
        option routers                  ${gw};
        option subnet-mask              255.255.255.0;
        option domain-name              \"gz.com\";
        option domain-name-servers      202.96.128.166;
        range dynamic-bootp ${fir}  ${fin};
        default-lease-time 21600;
        max-lease-time 43200;
    allow bootp;
    allow booting;
    next-server ${ip};
    filename \"pxelinux.0\";
}">/etc/dhcp/dhcpd.conf   
    action "Configure Successfully !" /bin/true
}

##Install Tftp
itftp(){
   echo "Installing TFTP ..."
   sleep 1
   yum -y install tftp tftp-server >/dev/null 2>&1
   if [ "$?" != "0" ];then
       action "Installing Failed ... Please Check your network or Repo Setting !" /bin/false
       exit 1
   else
       action "Installing Successfully !" /bin/true
   fi
}

##Install Syslinux
isyslinux(){
   echo "Installing Syslinux ..."
   sleep 1
   yum -y install syslinux* >/dev/null 2>&1
   if [ "$?" != "0" ];then
       action "Installing Failed ... Please Check your network or Repo Setting !" /bin/false
       exit 1
   else
       action "Installing Successfully !" /bin/true
   fi
   echo "Configure Syslinux ..."
   sleep 1
   cp -f /usr/share/syslinux/pxelinux.0  /var/lib/tftpboot/
   while true
   do
      read -p "Please input the OS direction ( Example /mnt/iso ) : " osdir
      [ ! -d "${osdir}" ] && echo "${osdir} is not a direction ! " || break
   done
   cd ${osdir}/isolinux
   cp -f ./* /var/lib/tftpboot/
   action "Syslinux configure successfully !" /bin/true   
}

##Configure pexlinux
ipex(){
   case ${1} in
   1)
   echo "Configure pexlinux ..."
   sleep 1
   [ ! -d "/var/lib/tftpboot/pxelinux.cfg/" ] && mkdir /var/lib/tftpboot/pxelinux.cfg/
   echo "Checking ks.cfg ..."
   sleep 1
   [ ! -d "/public/cfg" ] && mkdir -p /public/cfg
   if [ ! -f "$(pwd)/ks.cfg" ];then
      action "Checking ks.cfg failed ! " /bin/false
      while true
      do
         read -p "Please input the ks.cfg path ( example: /root/ks.cfg ) : " ks
         [ ! -f "${ks}" ] && echo "$ks is not exist ! " || break
      done
      cp -f ${ks} /public/cfg
      action "Checking ks.cfg Successfully ! " /bin/true
   else
      cp -f $(pwd)/ks.cfg /public/cfg
      action "Checking ks.cfg Successfully ! " /bin/true      
   fi 
   chmod +r /public/cfg/ks.cfg
   #sed -i '/^nfs.*/d' /public/cfg/ks.cfg
   if [ "$(cat /public/cfg/ks.cfg|grep "^nfs --server="|wc -l)" == "0" ]
   then
       sed -i "4a nfs --server=${ip} --dir=${osdir}" /public/cfg/ks.cfg
   fi
   echo "default 1
timeout 100
display boot.msg
prompt 1

label 1
        kernel vmlinuz
        append initrd=initrd.img  method=nfs://${ip}${osdir}" ks=nfs://${ip}/public/cfg/ks.cfg >/var/lib/tftpboot/pxelinux.cfg/default
   action "Pexlinux configure successfully !" /bin/true
   ;;
   2)
   echo "Configure pexlinux ..."
   sleep 1
   [ ! -d "/var/lib/tftpboot/pxelinux.cfg/" ] && mkdir /var/lib/tftpboot/pxelinux.cfg/
   echo "Checking ks.cfg ..."
   sleep 1
   [ ! -d "/var/www/html/cfg" ] && mkdir -p /var/www/html/cfg
   if [ ! -f "$(pwd)/ks.cfg" ];then
      action "Checking ks.cfg failed ! " /bin/false
      while true
      do
         read -p "Please input the ks.cfg path ( example: /root/ks.cfg ) : " ks
         [ ! -f "${ks}" ] && echo "${ks} is not exist ! " || break
      done
      cp -f ${ks} /var/www/html/cfg
      action "Checking ks.cfg Successfully ! " /bin/true
   else
      cp -f $(pwd)/ks.cfg /var/www/html/cfg
      action "Checking ks.cfg Successfully ! " /bin/true
   fi
   chmod +r /var/www/html/cfg/ks.cfg
   if [ "$(cat /var/www/html/cfg/ks.cfg|grep "^url --url"|wc -l)" == "0" ]
   then
       sed -i "4a url --url=\"http\:\/\/${ip}\/iso\"" /var/www/html/cfg/ks.cfg
   fi
   echo "default 1
timeout 100
display boot.msg
prompt 1

label 1
        kernel vmlinuz
        append initrd=initrd.img ks=http://${ip}/cfg/ks.cfg ">/var/lib/tftpboot/pxelinux.cfg/default
   action "Pexlinux configure successfully !" /bin/true
   ;;
   3)
   echo "Configure pexlinux ..."
   sleep 1
   [ ! -d "/var/lib/tftpboot/pxelinux.cfg/" ] && mkdir /var/lib/tftpboot/pxelinux.cfg/
   echo "Checking ks.cfg ..."
   sleep 1
   [ ! -d "/var/ftp/cfg" ] && mkdir -p /var/ftp/cfg
   if [ ! -f "$(pwd)/ks.cfg" ];then
      action "Checking ks.cfg failed ! " /bin/false
      while true
      do
         read -p "Please input the ks.cfg path ( example: /root/ks.cfg ) : " ks
         [ ! -f "${ks}" ] && echo "${ks} is not exist ! " || break
      done
      cp -f ${ks} /var/ftp/cfg/
      action "Checking ks.cfg Successfully ! " /bin/true
   else
      cp -f $(pwd)/ks.cfg /var/ftp/cfg/
      action "Checking ks.cfg Successfully ! " /bin/true
   fi
   chmod +r /var/ftp/cfg/ks.cfg
   if [ "$(cat /var/ftp/cfg/ks.cfg|grep "^url --url="|wc -l)" == "0" ]
   then
       sed -i "4a url --url=\"ftp\:\/\/${ip}\/iso\"" /var/ftp/cfg/ks.cfg   
   fi
   echo "default 1
timeout 100
display boot.msg
prompt 1

label 1
        kernel vmlinuz
        append initrd=initrd.img ks=ftp://${ip}/cfg/ks.cfg ">/var/lib/tftpboot/pxelinux.cfg/default
   action "Pexlinux configure successfully !" /bin/true
   esac
}

##Install NFS
infs(){
   echo "Installing NFS ..."
   sleep 1
   yum -y install rpcbind nfs-utils >/dev/null 2>&1
   if [ "$?" != "0" ];then
       action "Installing Failed ... Please Check your network or Repo Setting !" /bin/false
       exit 1
   else
       action "Installing Successfully !" /bin/true
   fi
   echo "Configure NFS ..."
   sleep 1
   echo "/public ${ip%.*}.0/255.255.255.0(ro)">/etc/exports
   echo "${osdir} ${ip%.*}.0/255.255.255.0(ro)">>/etc/exports
   exportfs -rv
   action "NFS configure successfully !" /bin/true
}

##Install httpd
ihttp(){
  echo "Installing HTTP ..."
  sleep 1
  yum -y install httpd >/dev/null 2>&1
   if [ "$?" != "0" ];then
       action "Installing Failed ... Please Check your network or Repo Setting !" /bin/false
       exit 1
   else
       action "Installing Successfully !" /bin/true
   fi
   echo "Configure HTTP ..."
   sleep 1
   sed -i "277i ServerName 127.0.0.1:80" /etc/httpd/conf/httpd.conf
   #[ ! -d "/var/www/html/iso" ] && mkdir -p /var/www/html/iso
   #blkid | grep "sr0" >/dev/null 2>&1
   #[ "$?" == "0" ] && umount -lf /dev/sr0 >/dev/null 2>&1
   #mount /dev/sr0 /var/www/html/iso >/dev/null 2>&1
   sr0_dir=$(df -h|grep sr0|awk '{print $NF}')
   ln -s ${sr0_dir} /var/www/html/iso
   action "HTTP configure successfully !" /bin/true
}

##Install FTP
iftp(){
  echo "Installing VsFTP ..."
  sleep 1
  yum -y install vsftpd >/dev/null 2>&1
   if [ "$?" != "0" ];then
       action "Installing Failed ... Please Check your network or Repo Setting !" /bin/false
       exit 1
   else
       action "Installing Successfully !" /bin/true
   fi
   echo "Configure VsFTP ..."
   sleep 1
  # [ ! -d "/var/ftp/iso" ] && mkdir -p /var/ftp/iso
  # blkid | grep "sr0" >/dev/null 2>&1
  # [ "$?" == "0" ] && umount -lf /dev/sr0 >/dev/null 2>&1
  # mount /dev/sr0 /var/ftp/iso >/dev/nul 2>&1
   sr0_dir=$(df -h|grep sr0|awk '{print $NF}')
   ln -s ${sr0_dir} /var/www/html/iso
   action "VsFTP configure successfully !" /bin/true
}

##Services start
call(){
  case ${1} in
  1)
  ser=(dhcpd tftp rpcbind nfs-server) 
  echo "Making the last step ..."
  for ((i=0;i<${#ser[@]};i++));
  do  
      systemctl enable ${ser[$i]} >/dev/null 2>&1
      systemctl restart ${ser[$i]} >/dev/null 2>&1
      if [ "$?" == "0" ];then
          action "${ser[$i]} start successfully !" /bin/true
      else
          action "${ser[$i]} failed to start ! please check it manually " /bin/false
      fi
  done
  ;;
  2)
  ser=(dhcpd tftp httpd) 
  echo "Making the last step ..."
  for ((i=0;i<${#ser[@]};i++));
  do  
      systemctl enable ${ser[$i]} >/dev/null 2>&1
      systemctl restart ${ser[$i]} >/dev/null 2>&1
      if [ "$?" == "0" ];then
          action "${ser[$i]} start successfully !" /bin/true
      else
          action "${ser[$i]} failed to start ! please check it manually " /bin/false
      fi
  done
  ;;
  3)
  ser=(dhcpd tftp vsftpd)
  echo "Making the last step ..."
  for ((i=0;i<${#ser[@]};i++));
  do
      systemctl enable ${ser[$i]} >/dev/null 2>&1
      systemctl restart ${ser[$i]} >/dev/null 2>&1
      if [ "$?" == "0" ];then
          action "${ser[$i]} start successfully !" /bin/true
      else
          action "${ser[$i]} failed to start ! please check it manually " /bin/false
      fi
  done
  esac
  echo "Completed !"
}

##Scripts add
scrtadd(){
    while true
    do
       read -p "Please input your Scripts direction ( example:/root/sh/init.sh ) : " she
       [ ! -f "${she}" ] && echo "${she} is not exist ! " || break
    done
    echo "Modifying ..."
    sleep 1
    case ${1} in
    1)
    #[ ! -d "/public/sh" ] && mkdir -p /public/sh
    cp -f ${she} /public/init.sh
    #chmod -R +x /public/sh
    grep "post" /public/cfg/ks.cfg
    if [ "$?" != "0" ];then
    echo "%post
mkdir /nfsfile
mount -t nfs ${ip}:/public /nfsfile
cp /nfsfile/init.sh /root
chmod +x /root/init.sh
sh /root/init.sh
%end">>/public/cfg/ks.cfg
    else
    #sed -i '/\%post/,$d' /public/cfg/ks.cfg
    #sed -i '/\%post/a test' ks.cfg
    
    sed -i '/\%post/a sh \/root\/init\.sh' /public/cfg/ks.cfg
    sed -i '/\%post/a chmod \+x \/root\/init\.sh' /public/cfg/ks.cfg
    sed -i '/\%post/a cp \/nfsfile\/init\.sh \/root' /public/cfg/ks.cfg
    sed -i "/\%post/a mount \-t nfs ${ip}\:\/public \/nfsfile" /public/cfg/ks.cfg
    sed -i '/\%post/a mkdir \/nfsfile' /public/cfg/ks.cfg
#    echo "%post
#mkdir /nfsfile
#mount -t nfs ${ip}:/public /nfsfile
#cp /nfsfile/init.sh /root
#chmod +x /root/init.sh
#sh /root/init.sh
#">>/public/cfg/ks.cfg
    fi
#    action "Scripts add successfully !" /bin/true
    ;;
    2)
    cp -f ${she} /var/www/html/init.sh
    grep "post" /var/www/html/cfg/ks.cfg
    if [ "$?" != "0" ];then
       echo "%post
cd /tmp
wget http://${ip}/init.sh
chmod +x /tmp/init.sh
sh /tmp/init.sh
%end">>/var/www/html/cfg/ks.cfg
    else
        sed -i '/\%post/a sh \/tmp\/init\.sh' /var/www/html/cfg/ks.cfg
        sed -i '/\%post/a chmod \+x \/tmp\/init\.sh' /var/www/html/cfg/ks.cfg
        sed -i "/\%post/a wget http\:\/\/${ip}\/init\.sh" /var/www/html/cfg/ks.cfg
        sed -i '/\%post/a cd \/tmp' /var/www/html/cfg/ks.cfg
    fi
    ;;
    3)
    cp -f ${she} /var/ftp/init.sh
    grep "post" /var/ftp/cfg/ks.cfg
    if [ "$?" != "0" ];then
       echo "%post
cd /tmp
wget ftp://${ip}/init.sh
chmod +x /tmp/init.sh
sh /tmp/init.sh
%end">>/var/ftp/cfg/ks.cfg
    else
        sed -i '/\%post/a sh \/tmp\/init\.sh' /var/ftp/cfg/ks.cfg
        sed -i '/\%post/a chmod \+x \/tmp\/init\.sh' /var/ftp/cfg/ks.cfg
        sed -i "/\%post/a wget ftp\:\/\/${ip}\/init\.sh" /var/ftp/cfg/ks.cfg
        sed -i '/\%post/a cd \/tmp' /var/ftp/cfg/ks.cfg
    fi
    esac
    action "Scripts add successfully !" /bin/true
    s=1
}

##Repo add
rpoadd(){
    echo "Modifying ..."
    sleep 1
    case ${1} in
    1)
    echo "[Admin]
name=admin
baseurl=file:///media/iso
enabled=1
gpgcheck=0
">/public/local.repo
    grep "post" /public/cfg/ks.cfg
    if [ "$?" != "0" ];then
       echo "%post
mkdir /media/iso
mount -t nfs ${ip}:${osdir} /media/iso
mkdir /tmp/repobak
cd /etc/yum.repos.d
cp ./* /tmp/repobak
rm -rf ./*
cp /nfsfile/local.repo /etc/yum.repos.d
%end" >>/public/cfg/ks.cfg
    else
       sed -i '/\%post/a cp \/nfsfile\/local\.repo \/etc\/yum\.repos\.d' /public/cfg/ks.cfg
       sed -i '/\%post/a rm -rf \.\/\*' /public/cfg/ks.cfg
       sed -i '/\%post/a cp \.\/\* \/tmp\/repobak' /public/cfg/ks.cfg
       sed -i '/\%post/a cd \/etc\/yum\.repos\.d' /public/cfg/ks.cfg
       sed -i '/\%post/a mkdir \/tmp\/repobak' /public/cfg/ks.cfg
       sed -i "/\%post/a mount \-t nfs ${ip}\:${osdir} \/media\/iso" /public/cfg/ks.cfg
       sed -i '/\%post/a mkdir \/media\/iso' /public/cfg/ks.cfg
    fi
    ;;
    2)
       echo "[Http]
name=www
baseurl=http://${ip}/iso
enabled=1
gpgcheck=0
">/var/www/html/local.repo
    grep "post" /var/www/html/cfg/ks.cfg
    if [ "$?" != "0" ];then
       echo "%end
mkdir /tmp/repobak
cd /etc/yum.repos.d
cp ./* /tmp/repobak
rm -rf ./*
wget http://${ip}/local.repo
%end">>/var/www/html/cfg/ks.cfg
    else
    sed -i "/\%post/a wget http\:\/\/${ip}\/local\.repo" /var/www/html/cfg/ks.cfg
    sed -i '/\%post/a rm \-rf \.\/\*' /var/www/html/cfg/ks.cfg
    sed -i '/\%post/a cp \.\/\* \/tmp\/repobak' /var/www/html/cfg/ks.cfg
    sed -i '/\%post/a cd \/etc\/yum\.repos\.d' /var/www/html/cfg/ks.cfg
    sed -i '/\%post/a mkdir \/tmp\/repobak' /var/www/html/cfg/ks.cfg
    fi
    ;;
    3)
       echo "[VsFTP]
name=FTP
baseurl=ftp://${ip}/iso
enabled=1
gpgcheck=0
">/var/ftp/local.repo
    grep "post" /var/ftp/cfg/ks.cfg
    if [ "$?" != "0" ];then
       echo "%post
mkdir /tmp/repobak
cd /etc/yum.repos.d
cp ./* /tmp/repobak
rm -rf ./*
wget ftp://${ip}/local.repo
%end">>/var/ftp/cfg/ks.cfg
    else
    sed -i "/\%post/a wget ftp\:\/\/${ip}\/local\.repo" /var/ftp/cfg/ks.cfg
    sed -i '/\%post/a rm \-rf \.\/\*' /var/ftp/cfg/ks.cfg
    sed -i '/\%post/a cp \.\/\* \/tmp\/repobak' /var/ftp/cfg/ks.cfg
    sed -i '/\%post/a cd \/etc\/yum\.repos\.d' /var/ftp/cfg/ks.cfg
    sed -i '/\%post/a mkdir \/tmp\/repobak' /var/ftp/cfg/ks.cfg
    fi
    esac
    action "Repos add successfully !" /bin/true
    r=1
}

##Main
while true
do
  menu
  read -p "Which way do you want to use working on PXE ? " choice
  case ${choice} in
  1)
  idhcp
  itftp
  isyslinux 
  ipex 1
  infs
  call 1
  bk=1
  ;;
  2)
  idhcp
  itftp
  isyslinux
  ihttp
  ipex 2
  call 2
  bk=2
  ;;
  3)
  idhcp
  itftp
  isyslinux
  iftp
  ipex 3
  call 3
  bk=3
  ;;
  5) 
     if [ "${s}" != "1" ];then
         scrtadd ${bk}
       #  [ "${bk}" == "1" ] && scrtadd 1 || scrtadd 2
     else
        echo "You have added before . Nothing to do ! "
     fi
  ;;
  6)
     if [ "${r}" != "1" ];then
         rpoadd ${bk}
       # [ "${bk}" == "1" ] && rpoadd 1 || rpoadd 2
     else
        echo "You have modified before . Nothing to do ! "
     fi
  ;;
  h)echo "The author is lazy ... "
  ;;
  q)exit 0
  ;;
  *)echo "Usage : 1 2 3 4 5 h q"
  esac
done
