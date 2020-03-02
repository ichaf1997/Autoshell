#!/bin/bash

# --------------------------------------------------------------------- #

# This script will forbid root login and create general user for secure

# --------------------------------------------------------------------- # 

     # Create general user
     while true
     do
          read -p "General user : " user
          id $user >/dev/null 2>&1
          [ "$?" != "0" ] && break || echo "$user is already exist !"
     done
     while true
     do
          read -p "$user password : " pass
          [ -n "$pass" ] && break || echo "password is empty !"          
     done    
     useradd $user 
     echo "$pass"|passwd --stdin ${user}
     # Add sudo authentication
     [ "$(cat /etc/sudoers | grep "$user"|wc -l)" == "0" ] && echo "$user  ALL=(ALL)      NOPASSWD: ALL" >> /etc/sudoers
     clear
     echo -e "general user\t$user"
     echo -e "general pass\t$pass"
     echo "general user create completely !"          
     # Deny login with root
     [ "$(cat /etc/ssh/sshd_config|grep "^PermitRootLogin"|wc -l)" == "1" ] && sed -i 's/^PermitRootLogin/PermitRootLogin no/g' || echo "PermitRootLogin no" >> /etc/ssh/sshd_config
     systemctl restart sshd
     echo
     echo "Root is forbidden from remote link . instead of , use general user to login system is a safe way ."
     echo "you can get root privileges by command : sudo su -"
