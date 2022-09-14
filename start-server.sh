#!/bin/bash

MAPR_CLUSTER=maprdemo.mapr.io
MAPR_USER=mapr
MAPR_GROUP=mapr
 
echo "${MAPR_CLUSTER}" > /etc/hostname 

systemctl start sshd
echo "connect with 'ssh -p 2222 root@localhost'"

IP=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
HOSTNAME=$(hostname -f)
head -n -1  /etc/hosts > tmp.txt && cp tmp.txt /etc/hosts && rm tmp.txt
echo "$IP  ${MAPR_CLUSTER} ${HOSTNAME}" >> /etc/hosts
echo "session       required       pam_limits.so" >> /etc/pam.d/common-session

/opt/mapr/server/configure.sh -N ${MAPR_CLUSTER} -C ${IP}:7222 -Z ${IP} -u ${MAPR_USER} -g ${MAPR_GROUP} -genkeys -secure -dare

# apt install -y mapr-posix-client-basic
# service mapr-posix-client-basic start
