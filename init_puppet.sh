#!/bin/bash
#init_new_devices
#Pre_init  @by xbzy at 2015-11-28
#########################################
#init_new_devices                       #
#Pre_init  @by xbzy at 2015-11-28       #
#                                       #
#########################################

function Run_puppet()
{
      Puppet_failed_log=./logs/puppet_failed
      local Host="$1"
      sshpass -p xxxxxxxx@2015   ssh   -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o GSSAPIAuthentication=no  $Host  "puppet agent -t;puppet agent -t"
      sshpass -p xxxxxxxx@2015   ssh   -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o GSSAPIAuthentication=no  $Host  "grep -q 'root@bigdata-col-ser01.bh' /root/.ssh/authorized_keys"
      test $? -ne 0  && echo -e "\e[1;31m$(date +%F_%H-%M-%S)  $Host  run_puppet  failed\e[0m" |tee -a  $Puppet_failed_log && exit 123
      sshpass -p xxxxxxxx@2015   ssh   -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o GSSAPIAuthentication=no  $Host  "userdel -r rd"
      sshpass -p xxxxxxxxx@2015   ssh   -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o GSSAPIAuthentication=no  $Host  "chkconfig   puppet off ; /etc/init.d/puppet stop"
      sshpass -p xxxxxxxxx@2015   ssh   -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o GSSAPIAuthentication=no  $Host  "cp /etc/skel/.bash_profile /home/xiaoju/&&chown -R xiaoju.xiaoju /home/xiaoju"

}

function Install_nagios_client()
{
	##############old##########
	#cat $List |xargs -i -P 10 ssh {}  "wget -q -O - 10.234.50.123:8000/install-nagsclient.sh|sh"
	######new######################################################################

      Install_nagios_log="./logs/nagios_install_failed.log" 
	  
      local Host="$1"
      ssh -o PasswordAuthentication=no -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o GSSAPIAuthentication=no $Host "wget -T20 -t2 -q -O - 10.234.50.123:8000/install-nagsclient.sh|sh"
      if [ $? -ne 0 ];then
         echo -e "\e[1;31m$(date +%F_%H-%M-%S)  Host:$Host  install_nagios_client   [ Failed ]\e[0m"| tee -a $Install_nagios_log

      fi
}

function Chag_passwd()
{

   #local List=$1
   sh Change_passwd.sh root -f $List
   sh init_xiaoju_Change_passwd.sh  xiaoju -f $List
 

}

function Install_Jdk()
{
    local Host="$1"
    local CMD="rpm -ivh http://10.234.50.123:8000/jdk-1.7.0_79-1.el6.x86_64.rpm"
    ssh  -o PasswordAuthentication=no -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o GSSAPIAuthentication=no $Host "rpm -q jdk-1.7.0_79 &>/dev/null || $CMD"
    if [ $? -ne 0 ];then
       echo -e "\e[1;31m$(date +%F_%H-%M-%S)  Host:$Host  install_Jdk   [ Failed ]\e[0m"| tee -a $Install_jkd_log

    fi

}


function  Multi_threading()
{
    local RUN_function="$1"
	
	temp_fifo_file=$$.info
	mkfifo $temp_fifo_file
	exec 6<>$temp_fifo_file
	rm $temp_fifo_file    
	
	function f_sleep             
	{
	sleep 1
	}
	
	temp_thread="$Muthread"
	
	for ((c=0;c<temp_thread;c++))
	  do
	    echo                      
	  done >&6                    
	for i in `cat $List`
	  do
	    read
	    {
	    	f_sleep
			echo "#######################Turn to $i";
	    	$RUN_function  $i 
			
	    	echo >&6
	    }&       
	  done <&6
	
	wait       
	exec 6>&-

}



if [ $# -ne 1 ];then
   echo -e "\e[1;33mUsage:sh $0 list[ip or hostname]\e[0m"
   exit -1
fi

List=$1
Filepath=$(cd "$(dirname "$0")"; pwd)
mkdir -p $Filepath/logs

####################
Muthread=60

if [ ! -f $List ];then
   echo  -e "\e[1;31m$List not  exits\e[0m"
else
   Multi_threading Run_puppet

   Multi_threading Install_nagios_client

   Chag_passwd
fi 
