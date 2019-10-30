#!/bin/bash
# Management Tool for Linux
# Version : 0.1
# --------------------
#       Gopppog
#      2019-10-22
#   2279746031@qq.com
# --------------------


source $(pwd)/chaff.ini >/dev/null 2>&1

# Dumpping Logs
log_dump(){
  case $1 in 
  error)
       echo "$(date +%a\ %b\ %d\ %T\ %Y) - [$1] $2" >>${chaff_log}
       echo "Unable to run Chaff , See more in ${chaff_log}"
       exit 1
  ;;
  *)
       echo "$(date +%a\ %b\ %d\ %T\ %Y) - [$1] $2" >>${chaff_log}
  esac      
}

# Environment Check , Make sure you can run this script better 
chk_env(){
  [ -z "${chaff_log}" ] && chaff_log=/tmp/chaff.log
  [ ! -d "${chaff_log%/*}" ] && mkdir -p ${chaff_log%/*} >/dev/null 2>&1
  [ ! -e "${chaff_log}" ] && touch ${chaff_log}
  log_dump info "Chaff - version 0.1"
  if [ ! -e "$(pwd)/chaff.ini" ];then
     log_dump error "Chaff is relied on configuration file chaff.ini "
  fi
  rpm -qa|grep expect >/dev/null 2>&1
  if [ "$?" != "0" ];then
     yum -y install expect >/dev/null 2>&1
     if [ "$?" != "0" ];then
        log_dump error "Check Environment failed ! expect is unalbe to install in your enviroment ."
     fi
  fi  
  if [ ! -d "${chaff_groupdir}" ];then
     log_dump error "chaff.ini test failed in line $(grep -n "chaff_groupdir" $(pwd)/chaff.ini|cut -d ":" -f 1)"
  fi
  if [ ! -d "${chaff_moduledir}" ];then
     log_dump error "chaff.ini test failed in line $(grep -n "chaff_moduledir" $(pwd)/chaff.ini|cut -d ":" -f 1)"
  fi
  log_dump info "Environment check OK!"
}

# Load Group Info from $(pwd)/group/*.group
load_info(){
  log_dump info "Loading groups information"
  num=0
  for line in $(ls ${chaff_groupdir}/*.group|awk -F[" "]+ '{print $NF}')
  do
     line=${line%.*}
     group_name[$num]=${line##*/}
     let num=${num}+1
  done
  if [ "$num" == "0" ];then
     log_dump error "No groups are set , unable to load group information . No file such as XX.group in ${chaff_groupdir}"  
  else
     for ((i=0;i<${num};i++))
     do
        t=1
        while read lines
        do
           col=$(echo ${lines}|awk -F[" "] '{a+=NF}END{print a}')
           if [ "$col" != "2" ];then
              log_dump error "${group_name[$i]}.group test failed in ${chaff_groupdir} line $t"
           fi
           let t=${t}+1
        done < ${chaff_groupdir}/${group_name[$i]}.group        
     done
  fi
  log_dump info "Groups: [$(echo ${group_name[@]})] had been loaded successfully"
}

# Display Function Menu contented
Menu(){
echo "
 # ---------------------------------------------- #

    1) Send ssh-keygen      2) Send File
    3) Check Os status      e) Send command

                            q) Quit

 # ---------------------------------------------- #
"
}

# Select a group or groups you want to manage
Select(){
echo " # ---------------------------------------------- #
"
   for ((q=0;q<${num};q++))
   do
      echo -e " $q)\t${group_name[$q]}\t(include $(cat ${chaff_groupdir}/${group_name[$q]}.group|wc -l) host)"
   done
echo "
         a) all                  b) Back "
echo "
 # ---------------------------------------------- #"
while true
do
   read -p "select a group for your operation : " sel
   for ((e=0;e<${num};e++))
   do
      if [ "${sel}" == "$e" ];then
         r=1
      elif [ "$sel" == "a" ];then
         r=1
         break       
      elif [ "$sel" == "b" ];then
         r=1
         break
      fi
   done
   [ "$r" == "1" ] && break || continue
done
}

# Send File
File(){
   if [ ! -e "${chaff_moduledir}/scp.sh" ];then
          log_dump error "Send file failed . ${chaff_moduledir}/scp.sh not be found"
      else
          cd ${chaff_moduledir}
          [ ! -x "${chaff_moduledir}/scp.sh" ] && chmod +x ${chaff_moduledir}/scp.sh
          ./scp.sh $1 $2 $3 $4
          if [ "$?" != "0" ];then
             log_dump warnning "Send $4 to [$5]:::$1:$3 failed ."
          fi
      fi
}

# Send and Excute Command 
send_cmd(){
   if [ ! -e "${chaff_moduledir}/exc_cmd.sh" ];then
          log_dump error "Excute command failed . ${chaff_moduledir}/exc_cmd.sh not be found"
   elif [ ! -e "${chaff_moduledir}/chk_cmd.sh" ];then
          log_dump error "Unable to check your command whether if excute . ${chaff_moduledir}/chk_cmd.sh not be found"
   else
      [ ! -x "${chaff_moduledir}/chk_cmd.sh" ] && chmod +x ${chaff_moduledir}/chk_cmd.sh
      [ ! -x "${chaff_moduledir}/exc_cmd.sh" ] && chmod +x ${chaff_moduledir}/exc_cmd.sh
      cd ${chaff_moduledir}
      ./exc_cmd.sh $1 $2 "$3"               #1 ip 2 passwd 3 cmd 4 group_name
      if [ "$?" != "0" ];then
          log_dump warnning "Excute command \"$3\" fail ::: Couldn't connect - [$4]:$1"
          continue
      fi
      ./chk_cmd.sh $1 $2                   
      if [ "$(cat /tmp/qwerasdf)" != "0" ];then
          log_dump warnning "Excute command \"$3\" fail :::[$4]:$1"
      fi
   fi
}

# Send ssh-keygen
ssh_keygen(){
   if [ "$#" == "0" ];then
      rm -rf ~/.ssh/*
      if [ ! -e "${chaff_moduledir}/create_keygen.sh" ];then
          log_dump error "Generate keygen failed . ${chaff_moduledir}/create_keygen.sh not be found"
      else
          cd ${chaff_moduledir}
          [ ! -x "${chaff_moduledir}/create_keygen.sh" ] && chmod +x ${chaff_moduledir}/create_keygen.sh
          ./create_keygen.sh
          if [ "$?" != "0" ];then
             log_dump error "Generate localhost keygen failed ."
          fi
      fi
   else
      if [ ! -e "${chaff_moduledir}/copy_keygen.sh" ];then
          log_dump error "Copy keygen failed . ${chaff_moduledir}/copy_keygen.sh not be found"
      else
          cd ${chaff_moduledir}
          [ ! -x "${chaff_moduledir}/copy_keygen.sh" ] && chmod +x ${chaff_moduledir}/copy_keygen.sh
          ./copy_keygen.sh $1 $2
          if [ "$?" != "0" ];then
             log_dump warnning "copy public ssh-keygen to [$3]:::$1 failed"
          fi
      fi
   fi   
}

# Main 
chk_env
load_info
Menu
while true 
do
    read -p "Select one that you want to do : " sele
    case $sele in
    1)Select
      if [ "$sel" == "b" ];then
         Menu
         continue
      elif [ "$sel" == "a" ];then
         log_dump info "Generate keygen to groups [$(echo ${group_name[@]})]"
         ssh_keygen
         log_dump info "Copy keygen to groups [$(echo ${group_name[@]})]"
         for ((r=0;r<${num};r++))
         do
             while read line
             do
                ssh_keygen $(echo ${line} | awk -F[" "]+ '{print $1}') $(echo ${line} | awk -F[" "]+ '{print $2}') ${group_name[$r]}       
             done < ${chaff_groupdir}/${group_name[$r]}.group
         done
      else
         log_dump info "Generate keygen to groups [${group_name[$sel]}]"
         ssh_keygen
         log_dump info "Copy keygen to groups [${group_name[$sel]}]"
         while read line
         do
            ssh_keygen $(echo ${line} | awk -F[" "]+ '{print $1}') $(echo ${line} | awk -F[" "]+ '{print $2}') ${group_name[$sel]}
         done < ${chaff_groupdir}/${group_name[$sel]}.group
      fi
      Menu
    ;;
    2)Select
      if [ "$sel" == "b" ];then
         Menu
         continue
      else
         while true
         do
             read -p "Input a source file you want to send ( Such as /root/test.txt ) : " sfiles
             read -p "Input a target path , ( your source will be send to the target path ) : " dfiles
             if [ "$sel" == "a" ];then
                read -p "$sfiles will be send to [$(echo ${group_name[@]})] in $dfiles . Confirm it ? y or n : " sd
             else 
                read -p "$sfiles will be send to [${group_name[$sel]}] in $dfiles . Confirm it ? y or n : " sd
             fi
             case $sd in
             y)break
             ;;
             n)continue
             ;;
             *)read "please input y or n :" sd
               while true
               do
                   if [ "$sd" == "y" ];then
                      break 
                      sdd=1
                   elif [ "$sd" == "n" ];then
                      break
                   else
                      read "please input y or n : " sd
                   fi
               done
               [ "$sdd" == "1" ] && break || continue
             esac
         done
         if [ "$sel" == "a" ];then   
            log_dump info "Send $sfiles to groups [$(echo ${group_name[@]})]:$dfiles"
            for ((r=0;r<${num};r++))
            do 
                while read line
                do
                   File $(echo ${line} | awk -F[" "]+ '{print $1}') $(echo ${line} | awk -F[" "]+ '{print $2}') ${dfiles} ${sfiles} $(echo ${group_name[@]})
                done < ${chaff_groupdir}/${group_name[$r]}.group
            done
         else
            log_dump info "Send $sfiles to groups [${group_name[$sel]}]:$dfiles"
            while read line
            do
                File $(echo ${line} | awk -F[" "]+ '{print $1}') $(echo ${line} | awk -F[" "]+ '{print $2}') ${dfiles} ${sfiles} ${group_name[$sel]}
            done < ${chaff_groupdir}/${group_name[$sel]}.group    
         fi
         Menu
      fi
      Menu
    ;;
    3)[ ! e "${chaff_moduledir}/get_status.sh" ] && log_dump error "${chaff_moduledir}/get_status.sh is needed ."      
      Select
    if [ "$sel" == "b" ];then
         Menu
         continue
    else
         if [ "$sel" == "a" ];then
            log_dump info "Check System load and Memory usage in [$(echo ${group_name[@]})]"
            for ((r=0;r<${num};r++))
            do  
                
                while read line
                do
                   [ ! -e "/tmp/${group_name[$r]}-mem.info" ] && touch /tmp/${group_name[$r]}-mem.info
                   [ ! -e "/tmp/${group_name[$r]}-load.info" ] && touch /tmp/${group_name[$r]}-load.info
                   send_cmd $(echo ${line} | awk -F[" "]+ '{print $1}') $(echo ${line} | awk -F[" "]+ '{print $2}') "awk 'BEGIN{printf \"%.2f%\\n\",('$(free |grep "Mem"|awk -F[" "]+ '{print $3}')'/'$(free |grep "Mem"|awk -F[" "]+ '{print $2}')')*100}'>/tmp/mem.info" "$(echo ${group_name[@]})" 
                   if [ "$(cat /tmp/qwerasdf)" == "0" ];then                    
                      cd ${chaff_moduledir}
                      [ ! -x "${chaff_moduledir}/get_status.sh" ] && chmod +x ${chaff_moduledir}/get_status.sh
                      ./get_status.sh $(echo ${line} | awk -F[" "]+ '{print $1}') $(echo ${line} | awk -F[" "]+ '{print $2}') "/tmp/mem.info" "/tmp"
                      echo "$(cat /tmp/mem.info)">>/tmp/${group_name[$r]}-mem.info
                   else
                      echo "">>/tmp/${group_name[$r]}-mem.info
                   fi
                   send_cmd $(echo ${line} | awk -F[" "]+ '{print $1}') $(echo ${line} | awk -F[" "]+ '{print $2}') "uptime|cut -d ":" -f 5|sed 's/^ //g'>/tmp/load.info" "$(echo ${group_name[@]})"
                   if [ "$(cat /tmp/qwerasdf)" == "0" ];then
                      cd ${chaff_moduledir}
                      [ ! -x "${chaff_moduledir}/get_status.sh" ] && chmod +x ${chaff_moduledir}/get_status.sh
                      ./get_status.sh $(echo ${line} | awk -F[" "]+ '{print $1}') $(echo ${line} | awk -F[" "]+ '{print $2}') "/tmp/load.info" "/tmp"
                      echo "$(cat /tmp/load.info)">>/tmp/${group_name[$r]}-load.info
                   else
                      echo "">>/tmp/${group_name[$r]}-load.info
                   fi
                done < ${chaff_groupdir}/${group_name[$r]}.group
            done
            echo " # ---------------------------------------------------- #
"
            for ((r=0;r<${num};r++))
            do
            echo -e "\t[${group_name[$r]}]"
                 n=0
                 while read line
                 do
                    let n=$n+1
                    echo -e "\t$(echo ${line}|awk -F[" "]+ '{print $1}')\tMemory_Usage:$(grep -n "$(cat "/tmp/${group_name[$r]}-mem.info")" "/tmp/${group_name[$r]}-mem.info"|grep "$n:"|cut -d ":" -f 2)\tLoad average:$(grep -n "$(cat "/tmp/${group_name[$r]}-load.info")" "/tmp/${group_name[$r]}-load.info"|grep "$n:"|cut -d ":" -f 2)"
                    #echo -e "\t$(echo ${line}|awk -F[\" \"]+ '{print $1}')\tMemory_Usage:$(grep -n \"$(cat /tmp/${group_name[$r]}-mem.info)\" /tmp/${group_name[$r]}-mem.info)|grep \"$n:\"|cut -d ":" -f 2)"
   #  grep -n "$(cat haha.txt)" haha.txt |grep "1:"|cut -d ":" -f 2
                 done < ${chaff_groupdir}/${group_name[$r]}.group
                 rm -rf /tmp/${group_name[$r]}-mem.info
                 rm -rf /tmp/${group_nane[$r]}-load.info
            done
            #rm -rf 
         else
            log_dump info "Check System load and Memory usage in [$(echo ${group_name[$sel]})]"
            [ ! -e "/tmp/${group_name[$sel]}-mem.info" ] && touch /tmp/${group_name[$sel]}-mem.info
            [ ! -e "/tmp/${group_name[$sel]}-load.info" ] && touch /tmp/${group_name[$sel]}-load.info
            while read line
            do
               send_cmd $(echo ${line} | awk -F[" "]+ '{print $1}') $(echo ${line} | awk -F[" "]+ '{print $2}') "awk 'BEGIN{printf \"%.2f%\\n\",('$(free |grep "Mem"|awk -F[" "]+ '{print $3}')'/'$(free |grep "Mem"|awk -F[" "]+ '{print $2}')')*100}'>/tmp/mem.info" "$(echo ${group_name[$sel]})"
               if [ "$(cat /tmp/qwerasdf)" == "0" ];then
                      cd ${chaff_moduledir}
                      [ ! -x "${chaff_moduledir}/get_status.sh" ] && chmod +x ${chaff_moduledir}/get_status.sh
               ./get_status.sh $(echo ${line} | awk -F[" "]+ '{print $1}') $(echo ${line} | awk -F[" "]+ '{print $2}') "/tmp/mem.info" "/tmp"
                      echo "$(cat /tmp/mem.info)">>/tmp/${group_name[$sel]}-mem.info
               else
                      echo "">>/tmp/${group_name[$sel]}-mem.info
               fi

               send_cmd $(echo ${line} | awk -F[" "]+ '{print $1}') $(echo ${line} | awk -F[" "]+ '{print $2}') "uptime|cut -d ":" -f 5|sed 's/^ //g'>/tmp/load.info" "$(echo ${group_name[$sel]})"
               if [ "$(cat /tmp/qwerasdf)" == "0" ];then
                      cd ${chaff_moduledir}
                      [ ! -x "${chaff_moduledir}/get_status.sh" ] && chmod +x ${chaff_moduledir}/get_status.sh
                      ./get_status.sh $(echo ${line} | awk -F[" "]+ '{print $1}') $(echo ${line} | awk -F[" "]+ '{print $2}') "/tmp/load.info" "/tmp"
                      echo "$(cat /tmp/load.info)">>/tmp/${group_name[$sel]}-load.info
               else
                      echo "">>/tmp/${group_name[$sel]}-load.info
               fi
            done < ${chaff_groupdir}/${group_name[$sel]}.group

            echo " # ---------------------------------------------------- #
"
            echo -e "\t[${group_name[$sel]}]"
            n=0
            while read line
            do
               let n=$n+1
               echo -e "\t$(echo ${line}|awk -F[" "]+ '{print $1}')\tMemory_Usage:$(grep -n "$(cat "/tmp/${group_name[$sel]}-mem.info")" "/tmp/${group_name[$sel]}-mem.info"|grep "$n:"|cut -d ":" -f 2)\tLoad average:$(grep -n "$(cat "/tmp/${group_name[$sel]}-load.info")" "/tmp/${group_name[$sel]}-load.info"|grep "$n:"|cut -d ":" -f 2)"
            done < ${chaff_groupdir}/${group_name[$sel]}.group
            rm -rf /tmp/${group_name[$sel]}-mem.info
         fi
    fi
    echo "
 # ---------------------------------------------------- #"
    Menu
    ;;
    e)Select
    if [ "$sel" == "b" ];then
         Menu
         continue
    else
         while true
         do
            read -p "Command:" com
            [ "$sel" == "a" ] && echo "Excute command \"$com\" [$(echo ${group_name[@]})]" || echo "Excute command \"$com\" [$(echo ${group_name[$sel]})]"
            read -p "Confirm y|n:" cf
            case $cf in
            y)break
            ;;
            *)continue
            esac
         done
         if [ "$sel" == "a" ];then            
            log_dump info "Excute command \"$com\" in [$(echo ${group_name[@]})]"  
            for ((r=0;r<${num};r++))
            do
                while read line
                do
                   send_cmd $(echo ${line} | awk -F[" "]+ '{print $1}') $(echo ${line} | awk -F[" "]+ '{print $2}') "$com" "$(echo ${group_name[@]})" 
                done < ${chaff_groupdir}/${group_name[$r]}.group
            done
         else    
            log_dump info "Excute command \"$com\" in [${group_name[$sel]}]"
            while read line
            do
                send_cmd $(echo ${line} | awk -F[" "]+ '{print $1}') $(echo ${line} | awk -F[" "]+ '{print $2}') "$com" "$(echo ${group_name[$sel]})"
            done < ${chaff_groupdir}/${group_name[$sel]}.group
         fi
    fi
    Menu
    ;;
    q)break
    ;;
    *)echo "Usage [1-3] e or q"
    esac
done
