#!/usr/bin/env bash

#Remove tars
#pssh -i -h hosts -l root rm -rf /root/jdk-8u161-linux-i586.rpm
#pssh -i -h hosts -l root rm -rf /root/hadoop-2.7.7.tar.gz
pssh -i -h hosts -l root rm -rf /root/hbase-3.0.0-SNAPSHOT-bin.tar.gz


#pssh -i -h hosts -l root rm -rf /root/hadoop
#pssh -i -h hosts -l root rm -rf /root/tmp
pssh -i -h hosts -l root rm -rf /root/zookeeper
pssh -i -h hosts -l root rm -rf /root/hbase

#pssh -i -h hosts -l root 'yes | yum remove jdk'

#pssh -i -h hosts -l root rm -rf /root/.ssh
