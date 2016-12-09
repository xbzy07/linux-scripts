#!/bin/bash
#########################################
#check  more disk
# 2016-02-18@by xbzy
#########################################
set -o nounset
set -o errexit

Disknum_OK=0
Disknum_WARNING=1
Disknum_CRITICAL=2
Disknum_UNKNOWN=3
Disk_num=""
Mount_disk=""
Mount_disk=$(df -h|grep -v data|grep "/dev/sd[b-z]"|wc -l)
Orig_num="12"
#Disk_num=$(fdisk  -l  2>/dev/null |grep -v sda |grep G|wc -l)
Disk_num=$(ls /dev/sd[b-z] 2>/dev/null|wc -l)
if [ $Disk_num -eq 0 ];then
   echo "OK not more disk"
   exit  $Disknum_OK
elif [ $Disk_num -gt 1 ];then
   Data_dirnums=$(ls /home/|grep "disk*" 2>/dev/null|wc -l)
   test $Data_dirnums -ne $Orig_num && echo "CRITICAL  Data_dirnums:$Data_dirnums" && exit $Disknum_CRITICAL
   Disk_owner=$(ls -ld  /home/disk*|grep -v xiaoju|awk '{print $3","$NF}') 
   if [ $Disk_num -eq $Orig_num ] && [ $Mount_disk -eq $Orig_num ] && [ -z "$Disk_owner" ];then
      echo "OK Disk num is $Disk_num"
      exit  $Disknum_OK
   elif [ $Disk_num -eq $Orig_num ] && [ $Mount_disk -eq $Orig_num ] && [ -n "$Disk_owner" ];then
      echo "CRITICAL Disk_owner:"$Disk_owner""
      exit $Disknum_CRITICAL
   elif [ $Disk_num -eq $Orig_num ] && [ $Mount_disk -ne $Orig_num ] && [ -z "$Disk_owner" ];then
      echo "CRITICAL Mount_nums:$Mount_disk"
      exit $Disknum_CRITICAL
   else      
      echo "CRITICAL Disk_nums:$Disk_num Mount_nums:$Mount_disk Disk_owner:"$Disk_owner""
      exit $Disknum_CRITICAL
   fi
else
   echo "WARNING Disk_num is $Disk_num"
   exit  $Disknum_UNKNOWN
fi
