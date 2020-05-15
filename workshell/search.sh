#!/bin/bash
# Usage:sh $0 dir_path "key_words"
[ $# -ne 2 ] && echo 'Usage:sh $0 dir_path "key_words"' && exit 0

dir_path=$1
key_words=$2

get_path(){
   n=0
   while read path
   do
       Possible_Conf_files_Array[$n]=${path}
       let n=$n+1
   done < find.tmp
}

dump_files_with_keywords(){
   for ((i=0;i<${n};i++))
   do
       cat ${Possible_Conf_files_Array[$i]} | grep "$key_words" > /dev/null 2>&1
       [ $? -eq 0 ] && echo "${Possible_Conf_files_Array[$i]}"
   done
   rm -rf find.tmp
}
echo "=============Start to find $key_words in $dir_path============="
find $dir_path \( -name "*.xml" -o -name "*.json" -o -name "*.properties" \) -exec echo {} > find.tmp \;
get_path
dump_files_with_keywords
echo "Done."

