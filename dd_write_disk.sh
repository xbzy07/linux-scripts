#!/bin/bash
#########################################
#dd comm write  disk                    #
#2016-09-07 @by xbzy007                 #
#########################################

DD_write()
{
  local Write_path=$1
  local Filename="$(head  /dev/urandom |md5sum |head -c 5)"
  #dd if=/dev/zero of=${Write_path}/${Filename}  bs=1M count=20240  conv=fdatasync
  dd if=/dev/zero of=${Write_path}/${Filename}  bs=1M count=10240
#  echo "_____________________________  ${Write_path}"
}


Dirlist=$(cat  /proc/mounts |grep "/home/disk" |awk '{print $2}')

temp_fifo_file=$$.info
mkfifo $temp_fifo_file
exec 6<>$temp_fifo_file
rm $temp_fifo_file    

function f_sleep             
{
      sleep 1
  }

  temp_thread=12

  for ((c=0;c<temp_thread;c++))
  do
        echo                      
  done >&6                    
    for i in ""$Dirlist""
    do
          read
            {
                    f_sleep
                    echo "#########turn to $i"
                    DD_write $i
                    echo >&6
            }&       
    done <&6

  wait       
  exec 6>&-

