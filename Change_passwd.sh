#!/bin/bash
#########################################
#2015-11-11				#
#reset root passwd @by xbzy007 in  didi #
#					#
#########################################
User="$1"
LogFile="/home/bigdataops/init/logs/modify_passwd_"
Faillog="/home/bigdataops/init/logs/fail_"

mkdir -p /home/bigdataops/logs

function Change_passwd()
{

IP=$1 

#_passwd=$(head  /dev/urandom |md5sum |head -c 16)
 
ssh -o PasswordAuthentication=no  -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o GSSAPIAuthentication=no  $IP   "echo '$User:${_passwd}' | chpasswd" 
if [ $? -eq 0 ];then

   echo -e "Password modify\e[1;32m                        [ success ]\e[0m\n"
   test -f $LogFile$User && sed -i "/$IP/d"  $LogFile$User
   echo "$(date +%F_%H-%M-%S)      Host:$IP  User:$User      PASS:${_passwd}" |tee -a $LogFile$User
else
   test -f $LogFile$User && sed -i "/$IP/d"   ${Faillog}$User
   echo -e "\e[1;31mHost:$IP  User:$User  Password modify  [ Failed ]\e[0m"| tee -a ${Faillog}$User

fi
}


function More_IP()
{

_passwd=$(head  /dev/urandom |md5sum |head -c 16)
List="$1"
for i in `cat $List`
  do
    echo -e "########$i\n"
#       Change_passwd $i  ${_passwd}
        Change_passwd $i
  done
}

function One_IP()
{
        _passwd=$(head  /dev/urandom |md5sum |head -c 16)
        Change_passwd $1
} 

function Mesage()
{

 echo -e "\e[1;32mUsage:sh $0 username IP 
     :sh $0 username  -f iplist\e[0m"
 exit 3
}

if [ $# -ne 2 ] && [ $# -ne 3 ];then
   Mesage
fi

if [ "$2" == "-f" ] && [ $# -eq 3 ];then
   More_IP $3
elif [ $# -eq 2 ];then
   echo $2 |  grep  -E "([a-z]+\-)([a-z]+\-)([a-z]+[0-9]+\.)([a-z])|([0-9]+\.)([0-9]+\.)([0-9]+\.)[0-9]+"  && One_IP $2||Mesage 
else
   Mesage
fi
