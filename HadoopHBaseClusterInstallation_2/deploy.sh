#!/usr/bin/env bash

#PRE
#1. Include System name in 'hosts' file
#2. Copy it to 'regionservers' and 'zookeepers' file

#Initialize all variables mentioned over here
read -r MASTER_NODE<hosts
HBASE_MASTER_NODE=$MASTER_NODE

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
        -h|--help)

        echo -e "./deploy.sh\n\
-h | --help\n\
-iSP | --installSSHPass\n\
-iJ|--installJava\n\
-sPLSFMTA|--SetPLessSSHFromMasterToAll\n\
-dHad|--downloadHadoop\n\
-cHad|--copyHadoop\n\
-iHad|--installHad\n\
-sHad|--startHadoop\n\
-cHBase|--copyHBase\n\
-iHBase|--installHBase\n\
-sHBase|--startHBase\n\
-sPLS | --setPLessSSH"

        shift # past argument
        ;;

        -iSP|--installSSHPass)

	echo "Installing SSHPass locally..."
	brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb
        shift # past argument
        ;;

        -sPLS|--setPLessSSH)
	echo "Setting up passwordless ssh to all the hosts..."
	while IFS='' read -r host || [[ -n "$host" ]]; do
	 if [[ -z "$MASTER_NODE" ]]; then
	  MASTER_NODE=$host
	 fi
	 cat "$HOME/.ssh/id_rsa.pub" | sshpass -p "password" ssh -o "StrictHostKeyChecking no" root@$host '[ -d .ssh ] || mkdir .ssh; cat >> .ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys'
	done < "hosts"
        echo "Master Node >>$MASTER_NODE<<"
        HBASE_MASTER_NODE=$MASTER_NODE
        shift
	;;

        -iJ|--installJava)

        echo "Installing Java..."
        pssh -i -h hosts -l root sudo apt-get install -y software-properties-common
        pssh -i -h hosts -l root "echo 'deb http://ftp.debian.org/debian jessie-backports main' >> /etc/apt/sources.list"
        pssh -i -h hosts -l root sudo apt-get update
        pssh -i -h hosts -l root sudo apt-get install -y -t jessie-backports ca-certificates-java
        pssh -i -h hosts -l root sudo apt-get install -y openjdk-8-jdk
        echo "Setting JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64"
        pssh -i -h hosts -l root "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 && echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> ~/.bashrc"

        shift # past argument
        ;;

	-sPLSFMTA|--SetPLessSSHFromMasterToAll)

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

	shift
	;;

	-dHad|--downloadHadoop)
        echo "Downloading Hadoop..."
        pssh -h hosts -l root -t 0 wget -P /root/ http://apache.mirrors.spacedump.net/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz 	
	shift
        ;;

        -cHad|--copyHadoop)
        #TODO change the conf/xxx to be passed as an argument
        echo "Copying Hadoop to all the hosts..."
        pscp -v -e errors/ -h hosts -l root conf/hadoop-2.7.7.tar.gz /root/
        shift
        ;;


	-iHad|--installHad)
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
        shift
        ;;

        -sHad|--startHadoop)

        echo "Starting Hadoop..."
	ssh root@$MASTER_NODE<<'ENDSSH'
	 yes | ./hadoop/bin/hadoop namenode -format
	 ./hadoop/sbin/start-all.sh
ENDSSH
        echo "Hadoop Started. Please visit http://$MASTER_NODE:50070 for the GUI"
        shift
        ;;

        -cHBase|--copyHBase)
        #TODO change the conf/xxx to be passed as an argument
	echo "Copying HBase to all the hosts..."
	pscp -v -e errors/ -h hosts -l root conf/hbase-3.0.0-SNAPSHOT-bin.tar.gz /root/
        shift
        ;;

	-iHBase|--installHBase)
	echo "Unzipping HBase..."
	pssh -h hosts -l root -t 0 tar -xvf /root/hbase-3.0.0-SNAPSHOT-bin.tar.gz --gzip
	pssh -i -h hosts -l root -t 0 mv /root/hbase-3.0.0-SNAPSHOT /root/hbase

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
	shift
	;;

	-sHBase|--startHBase)
	echo "Starting Hbase..."
	pssh -i -H $MASTER_NODE -l root -t 0 /root/hbase/bin/start-hbase.sh
	echo "Hbase Started. Please visit http://$MASTER_NODE:16010 for the GUI"
	shift
	;;

        *)    # unknown option
        echo "Do ./deploy.sh -h"
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;

esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

exit 1

#IMP
#Download openjdk jdk. Not JRE. Set JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
#When java version is to be changed, change in hadoop_conf_org/hadoop-env.sh, conf/.bashrc
#
#TODO
#1. sudo apt-get update

#STEPS
#gpg --verify hbase-1.4.9-bin.tar.gz.asc
#gpg --verify hbase-1.4.9-src.tar.gz.asc
#'sha512sum hbase-1.4.9-bin.tar.gz' must match with 'cat hbase-1.4.9-bin.tar.gz.sha512'
#'sha512sum hbase-1.4.9-src.tar.gz' must match with 'cat hbase-1.4.9-src.tar.gz.sha512'

# How to check whether they are equal:
#1. copy both to vim
#2. ggVGu to convert all to lowercase
#3. %s/ //g to replace all whitespace
#4. go to end of current line and do Shift+j to append next line
#5. :sort u to remove duplicates.

# MAKE A NOTE OF THIS:
#https://askubuntu.com/questions/464755/how-to-install-openjdk-8-on-14-04-lts
