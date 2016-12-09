#!/bin/bash
#######################################
#for set hdfs quota
#
#2016-11-15@by xby007 in didichuxing
######################################
set -u
set -e

####################################################################

function f_sleep()             
{
  sleep 1
}

####################################################################

function Echo_Success()
{
 local value="$1"
 local value_size="$2"
 echo "$(date +%F_%H:%M:%S) :###set $value to $value_size  Success"| tee -a "$Logsuccess"

}

#####################################################################

function Echo_Failed()
{
 local value="$1"
 local value_size="$2"
 echo "$(date +%F_%H:%M:%S) :###set $value to $value_size  Falied"| tee -a "$Logfalied"

}

#####################################################################

function Do_action()
{
        local Quota_Ty="$1"	
        #local Quota_key="$2"
        temp_fifo_file=$$.info
	mkfifo $temp_fifo_file
	exec 6<>$temp_fifo_file
	rm $temp_fifo_file    
	
	temp_thread=10
	
	for ((c=0;c<temp_thread;c++))
	do
	  echo                      
	done >&6                    
	for (( k=0;k<${A_num};k++ ))
	do
	  read
	  {
	    f_sleep
            if [ "$Space_quota" == "1" ];then
               [[ ! "${size_arr[$k]}" =~ [0-9]*[g|G|t|T] ]] && { echo -e "\e[1;31m Unvalue illegal quota value, please check you list\e[0m"; Echo_Failed ${users_arr[$k]} ${size_arr[$k]};continue; }
            fi
	    if [ "${users_arr[$k]}"x != x ] && [ "${size_arr[$k]}"x != x ] ;then
	       echo " turn to $k ################# set ${users_arr[$k]} to size: ${size_arr[$k]}"
                 /usr/local/hadoop-2.7.2/bin/hdfs  dfsadmin -"${Quota_Ty}" "${size_arr[$k]}"  "${users_arr[$k]}" && Echo_Success ${users_arr[$k]} ${size_arr[$k]} || Echo_Failed ${users_arr[$k]} ${size_arr[$k]}
	       sleep 0.5
            else
               Echo_Failed "user_or_size_is_none"
	    fi
	    echo >&6
	  }&       
	done <&6
	
	wait       
	exec 6>&-

}

#######################################################################

Usage()
{
#  cat << EOF
  echo -e "\e[1;32m
  _+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+__+
  
  Usage:sh $0 options
  
  OPTIONS:
   -l  file list 
       example: limit file numbers /user/xuebaiji 10g
                limit  space   /user/xuebaiji  10000
   -s  to set quota limit space 
   -f  to set quota limit file numbers
   -h  for help

  _+_+_+_+_+_+_+_+_+_+_+_+_+__+_+_+_+_+_+_+_++_+_+_+_+_+_+_+_+
   \e[0m"
#EOF
}

#######################################################################


if [ $# -lt 3 ];then
   Usage
   exit 1
fi

########################################################################
Space_quota=""
Filenums_quota=""
userlist=""
while getopts  ":l:sfh" opt 2>/dev/null; do 
case $opt in 
l) 
  userlist=$OPTARG 
  [[ ! -e "$userlist" ]] && { echo -e "\e[1;31m Oh,darling : The $userlist file not exsit, please check\e[0m"; exit 1; } 
  ;; 
s) 
  Space_quota="1"
#  [[ ! $Space_q"uota =~ [0-9]*[g|G|t|T] ]] && { echo -e "\e[1;31mIncorrect options provided\e[0m";Usage; exit 1; }
  ;; 
f) 
  Filenums_quota="1"
#  [[ ! $COLOR1 =~ BLUE|RED|GREEN ]] && { echo -e "\e[1;31mIncorrect options provided\e[0m";Usage; exit 1; } 
#  echo "Hello the $COLOR1"
  ;;
h)
  Usage
  exit 0
  ;; 
\?) 
  echo -e "\e[1;31mIncorrect options provided\e[0m" 
  echo -e "\e[1;33mPlease input -h for help\e[0m"
  exit 1 
  ;;
:)
  echo -e "\e[1;31mOption -$OPTARG  requires an argument.\e[0m" >&2
  echo  -e "\e[1;32mPlease input -h for help\e[0m"
  exit 2
  ;;
esac 
done 


######################################################################

[[ -z "$userlist" ]] && { echo -e "\e[1;31m Oh,darling : You  must give a list of what user and quota value in it\e[0m"; Usage;exit 1; }

i=0
while read line
  do
     if [ -z "$line" ];then
     continue
     fi
     users_arr[$i]=$(echo $line|awk '{print $1}')
     size_arr[$i]=$(echo $line|awk '{print $2}')
     i=`expr $i + 1`
  done < "$userlist"

A_num=${#users_arr[@]}
test -d logs || mkdir logs
Logsuccess="logs/success_$(date +%F_%H-%M-%S).log"
Logfalied="logs/failed_$(date +%F_%H-%M-%S).log"


if [ -n "$Space_quota" ] && [ -z "$Filenums_quota" ];then
   Do_action setSpaceQuota 
elif [ -z "$Space_quota" ] && [ -n "$Filenums_quota" ];then
   Do_action setQuota
else
   Usage
fi
exit 0
