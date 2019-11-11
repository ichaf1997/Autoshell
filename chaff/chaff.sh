#!/bin/bash
# Management Tool for Linux
# Version : 0.2
# --------------------
#       Gopppog
#      2019-10-22
#   2279746031@qq.com
# --------------------

if [ ! -e "/tmp/chaff_init.lock" ]
then
    echo "please run this script after running init.sh !"
    exit 0
fi
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
     log_dump error "chaff.ini test failed in line $(grep -n "^chaff_groupdir" $(pwd)/chaff.ini|cut -d ":" -f 1)"
  fi
  if [ ! -d "${chaff_moduledir}" ];then
     log_dump error "chaff.ini test failed in line $(grep -n "^chaff_moduledir" $(pwd)/chaff.ini|cut -d ":" -f 1)"
  fi
  log_dump info "Environment check OK!"
}

# Load Group Info from ${chaff_groupdir}/group/*.group
load_info(){
  log_dump info "Loading groups information"
  num=0
  for line in $(ls ${chaff_groupdir}/*.group|awk '{print $NF}')
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
           col=$(echo ${lines}|awk '{print NF}')
           if [ "$col" != "2" ];then
              log_dump error "${group_name[$i]}.group test failed in ${chaff_groupdir} at line $t"
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
                            e) Send command

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
      if [ "${sel}" == "$e" ]
      then
         r=1
      elif [ "$sel" == "a" ] || [ "$sel" == "b" ]
      then
         r=1
         break       
      fi
   done
   if [ "$r" == "1" ]
   then 
       break
   else
       echo "input error ! please try again"
       continue
   fi
done
}

# Send File
File(){
          scp -r $3 $1:$2
          if [ "$?" != "0" ];then
             log_dump warnning "Send $3 to [$4]:::$1:$2 failed ."
          fi
}

# Send and Excute Command 
send_cmd(){
      exec_status=$(ssh $1 "$2 >/dev/null 2>&1 && echo 0 || echo 1")
      if [ "$exec_status" == "255" ]
      then
          log_dump warnning "Excute command \"$2\" fail ::: Couldn't connect - [$3]:$1"
      elif [ "$exec_status" == "1" ]
      then
          log_dump warnning "Excute command \"$2\" fail ::: in [$3]:$1"
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
    1)   
             if [ -e "/tmp/kg.lock" ]
             then
                 last_kg=$(cat /tmp/kg.lock)
                 now_kg=$(md5sum ${chaff_groupdir}/*|awk 'BEGIN{ORS=""}{print $1}')
                 if [ "$last_kg" == "$now_kg" ]
                 then
                     echo "Hosts Not be modified , nothing to do"
                     continue
                 fi 
             fi           
             log_dump info "Generate keygen to groups [$(echo ${group_name[@]})]"
             ssh_keygen
             log_dump info "Copy keygen to groups [$(echo ${group_name[@]})]"
             for ((r=0;r<${num};r++))
             do
                 while read line
                 do
                    ssh_keygen $(echo ${line} | awk '{print $1}') $(echo ${line} | awk '{print $2}') ${group_name[$r]}       
                 done < ${chaff_groupdir}/${group_name[$r]}.group
             done
             echo "$(md5sum ${chaff_groupdir}/*|awk 'BEGIN{ORS=""}{print $1}')" > /tmp/kg.lock
             Menu
    ;;
    2)
      if [ ! -e "/tmp/kg.lock" ]
      then
             echo "Please generate Keygen at first !"
             continue
      else
             last_kg=$(cat /tmp/kg.lock)
             now_kg=$(md5sum ${chaff_groupdir}/*|awk 'BEGIN{ORS=""}{print $1}')
             if [ "$last_kg" != "$now_kg" ]
             then
                 echo "Groups had been modified , please generate keygen again !"
                 continue
             fi
      fi
      Select
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
                   File $(echo ${line} | awk '{print $1}') ${dfiles} ${sfiles} $(echo ${group_name[@]})
                done < ${chaff_groupdir}/${group_name[$r]}.group
            done
         else
            log_dump info "Send $sfiles to groups [${group_name[$sel]}]:$dfiles"
            while read line
            do
                File $(echo ${line} | awk '{print $1}') ${dfiles} ${sfiles} ${group_name[$sel]}
            done < ${chaff_groupdir}/${group_name[$sel]}.group    
         fi
         Menu
      fi
      Menu
    ;;
    e)
      if [ ! -e "/tmp/kg.lock" ]
      then
             echo "Please generate Keygen at first !"
             continue
      else
             last_kg=$(cat /tmp/kg.lock)
             now_kg=$(md5sum ${chaff_groupdir}/*|awk 'BEGIN{ORS=""}{print $1}')
             if [ "$last_kg" != "$now_kg" ]
             then
                 echo "Groups had been modified , please generate keygen again !"
                 continue
             fi
      fi

      Select
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
                  for line in `cat ${chaff_groupdir}/${group_name[$r]}.group`
                  do
                     send_cmd $(echo ${line} | awk '{print $1}') "$com" "$(echo ${group_name[@]})" >/dev/null 2>&1
                  done 
              done
           else    
              log_dump info "Excute command \"$com\" in [${group_name[$sel]}]"
              for line in `cat ${chaff_groupdir}/${group_name[$sel]}.group`
              do
                  send_cmd $(echo ${line} | awk '{print $1}') "$com" "$(echo ${group_name[$sel]})" >/dev/null 2
>&1
              done
           fi
      fi
      Menu
    ;;
    q)break
    ;;
    *)echo "Usage [1-2] e or q"
    esac
done
