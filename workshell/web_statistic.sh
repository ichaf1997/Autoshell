#!/bin/bash

# 每天自动统计UV、PV脚本、请求次数top20的path

# Output file
result_dir=/var/log/ngaccess
pv_log=$result_dir/pv.log
uv_log=$result_dir/uv.log
cmsuv_log=$result_dir/cmsuv.log
top20_log=$result_dir/top20.log
nginx_access_log_dir=/data/nginx/logs
parttern=dgnzb_access.log*

# (CMS_PC + WSJY_PC) total UV
function uv(){
  uv_count=$(cat $(ls -l --time-style '+%Y%m%d' $nginx_access_log_dir/$parttern|grep $(date +%Y%m%d)|awk '{print $NF}')|awk '{COUNT[$1]++}END{for(IP in COUNT) print IP}'|wc -l)
  [ ! -f $uv_log ] && touch $uv_log
  echo $(date +%Y%m%d):$uv_count|tee -a $uv_log
}

# CMS_PC UV
function cms_uv(){
  cmsuv_count=$(cat $(ls -l --time-style '+%Y%m%d' $nginx_access_log_dir/$parttern|grep $(date +%Y%m%d)|awk '{print $NF}')|awk '{if($0 !~ /trade/)COUNT[$1]++}END{for(IP in COUNT) print IP}'|wc -l)
  [ ! -f $cmsuv_log ] && touch $cmsuv_log
  echo $(date +%Y%m%d):$cmsuv_count|tee -a $cmsuv_log
}

# (CMS_PC + WSJY_PC) PV
function pv(){
  pv_count=$(cat $(ls -l --time-style '+%Y%m%d' $nginx_access_log_dir/$parttern|grep $(date +%Y%m%d)|awk '{print $NF}')|grep shtml|wc -l)
  [ ! -f $pv_log ] && touch $pv_log
  echo $(date +%Y%m%d):$pv_count|tee -a $pv_log
}

# (CMS_PC + WSJY_PC) Top20 path
function top_path(){
  top20=$(cat $(ls -l --time-style '+%Y%m%d' $nginx_access_log_dir/$parttern|grep $(date +%Y%m%d)|awk '{print $NF}')|awk '{split($7,a,"?");COUNT[a[1]]++}END{for(URL in COUNT) print COUNT[URL]":"URL}'|sort -t: -k1 -n -r|head -20)
  [ ! -f $top20_log ] && touch $top20_log
  echo Generate Time: $(date +%Y%m%d-%H:%M:%S)|tee -a $top20_log
  for line in $top20;
  do 
      echo $line|tee -a $top20_log
  done
  echo |tee -a $top20_log
}

# Main
[ ! -d $result_dir ] && mkdir -p $result_dir
uv
cms_uv
pv
top_path
