#!/bin/bash
n=0
for File in $(find / -name "*.xml" -o -name "*.properties")
do
    cat $File |grep ProjMService > /dev/null 2>&1
    if [ $? -eq 0 ];then
       echo "$File 存在关键字\"ProjMService\""
       let n=n+1
    fi
done
if [ $n -eq 0 ];then
   echo "查找完成，没有找到符合要求的文件"
else
   echo "查找完成，找到$n个符合要求的文件"
fi
