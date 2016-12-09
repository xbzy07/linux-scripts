#!/bin/bash
#########################################
#mount and format disk                  #
#2015-12-31 @by xbzy007                 #
#mod at 2016-09-07                      #
#########################################

set -o nounset

########set -o errexit

function Chown_disk()
{

  if(grep -q  xiaoju  /etc/passwd);then

    /bin/chown  -R xiaoju.xiaoju  /home/disk*
  else
    echo  -e "\e[1;31mUser xiaoju  not exist\e[0m\n"
  fi
}



function Check_mount()
{

  if(mount -a);then
    echo  -e "\e[1;32m All disk  mount ok \e[0m\n"
  else
    echo -e "\e[1;31m Mount disk have a or more  failed \e[0m\n" 
  fi 
}

function run_mkfsdisk()
{

    mkdir -p "${MountNode}$n"
    #mkfs.ext4 -F -T largefile   -N 10016160  ${disk}
    mkfs.ext4 -F -T largefile   -N 5008080  ${disk} >/dev/null
    if [ $? -eq 0 ];then
       echo  -e "\e[1;32m \n $Host_name Format $disk  [ Success ] \e[0m\n"
       grep -q "$disk" /etc/fstab && sed -i "/${disk##*/}/d"  /etc/fstab && echo -e "${disk}\t${MountNode}${n}\text4\tnoatime,acl,user_xattr\t0 0"  >>/etc/fstab
    else
       echo  -e "\e[1;31m \n$Host_name Format $disk  [ Failed ] \e[0m\n"
    fi
    mount ${disk}  "${MountNode}$n"
    df -h|grep "${disk}" &>/dev/null
    if [ $? -eq 0 ];then
       echo  -e "\e[1;32m"${MountNode}$n" mount [ Success ] \e[0m\n"
    else 
      echo -e "\e[1;31m "${MountNode}$n" mount [ Failed ] \e[0m\n"
    fi

}

function mounting(){

        disklist=$(/sbin/fdisk -l 2>/dev/null | grep -v "/dev/sda" |grep -e "Disk /dev/sd" |cut -d" " -f2|sed "s/://g"|sort)
        MountNode="/home/disk"
        DiskDev=""

        if [[ -z $disklist ]];then
           echo -e "\e[1;31m Disk device $disk   not exist \e[0m"
           exit -1
        fi
        n=1
        for disk in  $disklist
        do
            #Fs_type=$(/sbin/blkid "$disk" |awk '{print $3}'|awk -F"TYPE=" '{print $2}' |sed 's/"//g')
            Fs_type=$(/sbin/blkid  "$disk" | awk '{for(i=1;i<=NF;i++) if($i ~ /\<TYPE\>/)  print $i}'|awk -F"TYPE=" '{print $2}' |sed 's/"//g')
            if [[ "$Fs_type" = "ext4" || "$Fs_type" = "ext3" || "$Fs_type" = "xfs" ]];then
               echo -e  "\e[1;33m $disk File System  already exist: $Fs_type \e[0m"
               if (df -h |grep -q "$disk");then
                  echo -e "\e[1;35m $disk already mounted to  $(df -h |grep $disk |awk '{print $6}') \e[0m\n"
                  sleep 1
               else 
                  mkdir -p "${MountNode}$n"
                  mount "$disk"  "${MountNode}$n"
                  sed -i "/${disk##*/}/d"  /etc/fstab && echo -e "${disk}\t${MountNode}${n}\t${Fs_type}\tnoatime,acl,user_xattr\t0 0"  >>/etc/fstab
                  mount -a && echo -e "\e[1;35m $disk had mounted to  $(df -h |grep $disk |awk '{print $6}') \e[0m\n"||echo -e "\e[1;31m $disk mount to ${MountNode}$n  mount failed \e[0m\n"
                  sleep 1
               fi   
               n=`expr $n + 1`
            else  
               run_mkfsdisk
               Chown_disk
               n=`expr $n + 1`
            fi
        done
        echo -e "\n"
        echo -e "\e[1;32m$(df -h |grep "${MountNode}")\e[0m"
        Chown_disk
        Check_mount
}


function UMount_dev()
{
    cat  /proc/mounts |grep -oP "/home/disk[0-9]+"|xargs -i umount {} &>/dev/null
    df -h 2>/dev/null |grep '/home/disk'|awk '{print $NF}'|xargs -i umount {}  &>/dev/null
    Check_disk="$(cat  /proc/mounts |grep -oP '/home/disk[0-9]+')"
    if [ -z "$Check_disk" ];then
       echo  -e "\n\e[1;32m Umount all disk  [ Success ]\e[0m\n"
    else
       echo  -e "\e[1;31m Umount all disk  [ Failed ]\e[0m\n"
       exit 4
    fi
}

function Clear_homedir()
{

   if [ -n "$F_list" ];then

        for i in $F_list
        do
          echo  -e "\n\e[1;33m######### Turn to Delete $i ########\e[0m\n"
          /bin/rm -fr  "$i"
        done
        echo  -e "\n\e[1;32m######### Clearn /home/xiaoju  done ########\e[0m\n"
   else 
       echo -e "\n\e[1;32m######### /home/xiaoju no file exist ########\e[0m\n" 
   fi
}


function Clear_Rootdir()
{
  F_list=$(find /root   -maxdepth 1 ! -path '/root'  ! -name '.*')
  if [ -n "$F_list" ];then
         for i in $F_list
         do
            echo  -e "\n\e[1;33m######### Turn to Delete $i ########\e[0m\n"
            /bin/rm -fr  "$i"
         done
         echo  -e "\n\e[1;32m######### Clearn /root done ########\e[0m\n"
  else
        echo -e "\n\e[1;32m######### /root  no file exist ########\e[0m\n" 
  fi
}


function format(){
        disklist=$(/sbin/fdisk -l 2>/dev/null | grep -v "/dev/sda" |grep -e "Disk /dev/sd" |cut -d" " -f2|sed "s/://g"|sort)
        if [[ -z $disklist ]];then
           echo -e "\e[1;31m Disk device not exist \e[0m"
           exit -1
        fi

        MountNode="/home/disk"
        DiskDev=""
        n=1
        UMount_dev
##       Clear_homedir
##        Clear_Rootdir
        sleep 0.2
        for disk in  $disklist
        do
               #Disk_mounted=$(cat /proc/mounts|grep "$disk"|awk '{print $2}')
               echo -e "\e[1;33m##########Turn to format $disk\e[0m\n"
               run_mkfsdisk
               n=`expr $n + 1`
        done
        Chown_disk
        echo -e "\n"
        echo -e "\e[1;32m$(df -h |grep "${MountNode}")\e[0m"
        Check_mount
}


if [ $# -ne 1 ];then
   echo "Usage: sh $0 format|mounting" 
   exit 1
fi

Item="$1"
Host_name="$(hostname -f)"

case "$Item" in 
   format)
   format
   ;;
   mounting)
   mounting
   ;;
   *)
   echo "Usage: sh $0 format|mounting"   
esac
