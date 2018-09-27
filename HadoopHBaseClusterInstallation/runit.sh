#!/usr/bin/env bash
#MASTER_NODE=sakthi-hbase-test-1.gce.abc.com

#: <<'END'
#Install sshpass 
if [ $1 == InstallSSHPass ]; then
echo "Installing SSHPass locally..."
brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb
fi


#Set up passwordless ssh to all the hosts
if [ $2 == SetPLessSSH ]
then 
 echo "Setting up passwordless ssh to all the hosts..."
 while IFS='' read -r host || [[ -n "$host" ]]; do
  if [[ -z "$MASTER_NODE" ]]; then
   MASTER_NODE=$host
  fi 
  cat "$HOME/.ssh/id_rsa.pub" | sshpass -p "abc" ssh -o "StrictHostKeyChecking no" root@$host '[ -d .ssh ] || mkdir .ssh; cat >> .ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys'
 done < "hosts"
else
 read -r MASTER_NODE<hosts
fi

echo "Master Node >>$MASTER_NODE<<"

#Can change this to point to some other HBase Master Node as well(here Hadoop Master is assumed same as HBase Master)
HBASE_MASTER_NODE=$MASTER_NODE



if [ $3 == DownloadAndInstallJava ]
then
 OPTS="-c --no-check-certificate --no-cookies --header Cookie:oraclelicense=accept-securebackup-cookie"
 URL="http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/jdk-8u181-linux-i586.rpm"

 echo "Downloading JDK in all hosts..."
 pssh -h hosts -l root wget $OPTS $URL

 echo "Installing Java(Oracle JDK 1.8) on all nodes..."
 pssh -i -h hosts -l root yum localinstall -y jdk-8u181-linux-i586.rpm
 pssh -i -h hosts -l root export JAVA_HOME=/usr/java/jdk1.8.0_181
elif [ $3 == CopyAndInstallJava ]
then
 echo "Copying Java to all the hosts..."
 pscp -v -h hosts -l root conf/jdk-8u181-linux-i586.rpm /root/

 echo "Installing Java(Oracle JDK 1.8) on all nodes..."
 pssh -i -h hosts -l root yum localinstall -y jdk-8u181-linux-i586.rpm
 pssh -i -h hosts -l root export JAVA_HOME=/usr/java/jdk1.8.0_181
fi

if [ $5 == SetPLessSSHFromMasterToAll ]
then
 echo "Setting up Password-less ssh between Master Node to all other nodes..."
 #Generate keys in all machines
 pssh -h hosts -l root -t 0 'echo | ssh-keygen -t rsa -P ""'

 #Copy All Node's public key to all hosts
 echo "Copying all nodes' public keys to all hosts..."
 touch known_hosts
 touch authorized_keys
 cat "$HOME/.ssh/id_rsa.pub" >> authorized_keys
 while IFS='' read -r host1 || [[ -n "$host1" ]]; do
  ssh-keyscan -H $host1 >> known_hosts
  scp root@$host1:/root/.ssh/id_rsa.pub .
  cat id_rsa.pub >> authorized_keys
 done < "hosts"
 pscp -v -h hosts -l root authorized_keys /root/.ssh/
 pscp -v -h hosts -l root known_hosts /root/.ssh/
 rm known_hosts
 rm id_rsa.pub
 rm authorized_keys
 
 #while IFS='' read -r host1 || [[ -n "$host1" ]]; do
  #ssh-keyscan -H $host1 >> known_hosts
  #scp root@$MASTER_NODE:/root/.ssh/id_rsa.pub .
  #cat id_rsa.pub >> authorized_keys
 #done < "hosts"
 

 #scp root@$MASTER_NODE:/root/.ssh/id_rsa.pub .
  #while IFS='' read -r host2 || [[ -n "$host2" ]]; do
   #cat id_rsa.pub | sshpass -p "abc" ssh -o "StrictHostKeyChecking no" root@$host2 'cat >> .ssh/authorized_keys;'
  #done < "hosts"
 #done < "hosts"
 #scp known_hosts root@$MASTER_NODE:/root/.ssh/
 #rm known_hosts
 #rm id_rsa.pub
fi

if [ $4 == DownloadAndInstallHadoop ]
then
 echo "Downloading Hadoop..."
 pssh -h hosts -l root -t 0 wget -P /root/ http://apache.mirrors.spacedump.net/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz
elif [ $4 == CopyAndInstallHadoop ]
then
 #To copy the local version to the hosts
 if [ ! -f conf/hadoop-2.7.7.tar.gz ]; then
  echo "Downloading Hadoop to local first..."
  wget -P conf/ http://apache.mirrors.spacedump.net/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz
 fi
 echo "Copying Hadoop to all the hosts..."
 pscp -v -e errors/ -h hosts -l root conf/hadoop-2.7.7.tar.gz /root/
fi

if [ $4 == DownloadAndInstallHadoop ] || [ $4 == CopyAndInstallHadoop ] || [ $4 == InstallHadoop ]
then
 echo "Unzipping Hadoop in all hosts..."
 pssh -h hosts -l root -t 0 tar -xvf /root/hadoop-2.7.7.tar.gz --gzip
 pssh -h hosts -l root -t 0 mv /root/hadoop-2.7.7 /root/hadoop

 #Set rbashrc for all
 echo "Setting up environment variables for Hadoop..."
 pscp -v -e errors/ -h hosts -l root conf/.bashrc/ /root/.bashrc
 pssh -h hosts -l root -t 0  source /root/.bashrc
 pssh -i -h hosts -l root -t 0 'echo The Hadoop_Home env variable for all: $HADOOP_HOME' 
 
 #Set Hadoop Configuration Files
 #Edit the config files appropriately
 cp -rf hadoop_conf_org/ hadoop_conf/
 cp hosts hadoop_conf/slaves
 perl -pi -w -e "s/\[MASTER_NODE\]/$MASTER_NODE/g;" hadoop_conf/*

 echo "Copying the config files to hosts"
 pscp -v -e errors/ -h hosts -l root hadoop_conf/* /root/hadoop/etc/hadoop/ 
fi

#Start Hadoop
if [ $6 == StartHadoop ]
then
 echo "Starting Hadoop..."
 ssh root@$MASTER_NODE<<'ENDSSH'
 yes | ./hadoop/bin/hadoop namenode -format
 ./hadoop/sbin/start-all.sh
ENDSSH
 echo "Hadoop Started. Please visit http://$MASTER_NODE:50070 for the GUI"
fi

#HBase
if [ $7 == DownloadAndInstallHBase ]
then
 echo "Downloading HBase..."
 pssh -h hosts -l root -t 0 wget -P /root/hadoop/ http://apache.mirrors.spacedump.net/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz
elif [ $7 == CopyAndInstallHBase ]
then 
 echo "Copying HBase to all the hosts..."
 pscp -v -e errors/ -h hosts -l root conf/hbase-2.0.0-bin.tar.gz /root/
fi

if [ $7 == DownloadAndInstallHBase ] || [ $7 == CopyAndInstallHBase ] || [ $7 == InstallHBase ]
then
 echo "Unzipping HBase..."
 pssh -h hosts -l root -t 0 tar -xvf /root/hbase-2.0.0-bin.tar.gz --gzip
 pssh -i -h hosts -l root -t 0 mv /root/hbase-2.0.0 /root/hbase

 #Set HBase Configuration Files
 #Edit the config files appropriately
 cp -rf hbase_conf_org/ hbase_conf/
 
 perl -pi -w -e "s/\[HBase_Master\]/$HBASE_MASTER_NODE/g;" hbase_conf/*
 
 zookeepers=""
 while IFS='' read -r host || [[ -n "$host" ]]; do
  zookeepers="$zookeepers,$host"
 done < "zookeepers"
 zookeepers=${zookeepers:1}
 perl -pi -w -e "s/\[Zookeeper_Nodes\]/$zookeepers/g;" hbase_conf/*
 
 cp regionservers hbase_conf/
 
 echo "Copying config files to all the hosts..."
 pscp -e errors/ -h hosts -l root hbase_conf/* /root/hbase/conf/
fi

if [ $8 == StartHBase ]
then
 echo "Starting Hbase..."
 pssh -i -H $MASTER_NODE -l root -t 0 /root/hbase/bin/start-hbase.sh
echo "Hbase Started. Please visit http://$MASTER_NODE:16010 for the GUI"
fi

################################################################   NOTES  #################################################################################
#To add line to a particular file
#pssh -i -h hosts -l root -t 0 'echo 'export APP=/opt/tinyos-2.x/apps' >> /root/.bashrc' 


#To delete added lines in the file
#pssh -h hosts -l root -t 0 "sed -i '$ d' /root/.bashrc" 
#To execute commands in particular host
#ssh root@sakthi-hbase-test-1.gce.abc.com <<'ENDSSH'
#ls
#ls -l
#ENDSSH
#END
