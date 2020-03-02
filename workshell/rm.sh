#!/bin/bash
# Remove files by Keyword
# Usage : sh $0 "Keyword"
if [ $# -ne 1 ];then
  echo "Usage:sh $0 \"Keyword\" :: :: Example - sh $0 \"Nov 11\"" && exit 0
fi
Keyword=$1
ls -la|grep "$Keyword"|awk '{print $NF}'
while true
do
    read -p "These files(Total:$(ls -la|grep "$Keyword"|awk '{print $NF}'|wc -l)) here will be deleted , Do you want to continue ? [y or n] " choice
    case $choice in
    y|Y)break
    ;;
    n|N)echo "Nothing to do" && exit
    esac
done 
for NAME in $(ls -la |grep "$Keyword"|awk '{print $NF}')
do
    rm -rf $(pwd)/$NAME
    if [ $? -eq 0 ];then
       echo "delete $(pwd)/$NAME [ok]"
    else
       echo "delete $(pwd)/$NAME [failed]"
   fi
done

