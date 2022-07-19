#!/usr/bin/env bash

# NO NEED TO CHANGE THESE
export MAPR_UID=5000
export MAPR_GID=5000
export MAPR_USER=mapr
export MAPR_PASS=mapr
export MAPR_GROUP=mapr
export MAPR_USER_HOME=/home/mapr
export MAPR_MOUNT_PATH=/mapr
export MAPR_DATA_PATH=/data

export DEBIAN_FRONTEND=noninteractive

## CHANGE THESE
export MAPR_HOST_IP=10.1.0.48
export MAPR_CLUSTER=dfcore.datafabric.io

# System pre-requisites
sudo apt update; sudo apt install -y ca-certificates locales locales syslinux syslinux-utils

export SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

sudo locale-gen $LC_ALL

# Required packages
sudo apt install -y --no-install-recommends gnupg2 iproute2 \
    libgcc1 lsof libgcc1 openjdk-11-jdk net-tools apt-file python2 openssh-server \
    libltdl7 libpython2.7 irqbalance iputils-arping iputils-ping iputils-tracepath dmidecode hdparm sdparm \
    default-jdk openssh-client wamerican lsb-release apt-utils rpcbind nfs-common cron

# Enable password auth
sudo sed -i 's/#PasswordAuthentication/PasswordAuthentication/' /etc/ssh/sshd_config
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd
sudo systemctl restart sshd

# Enable package repo
wget -O - https://package.mapr.hpe.com/releases/pub/maprgpg.key | sudo apt-key add -
echo 'deb https://package.mapr.hpe.com/releases/v7.0.0/ubuntu binary bionic' | sudo tee -a /etc/apt/sources.list
echo 'deb https://package.mapr.hpe.com/releases/MEP/MEP-8.1.0/ubuntu binary bionic' | sudo tee -a /etc/apt/sources.list
sudo apt update; sudo apt upgrade -y

# Install only the client packages
sudo apt install -y mapr-client mapr-posix-client-basic

sudo groupadd -g ${MAPR_GID} ${MAPR_GROUP} && sudo useradd -m -u ${MAPR_UID} -g ${MAPR_GID} -d ${MAPR_USER_HOME} -s /bin/bash ${MAPR_USER} && sudo usermod -a -G sudo ${MAPR_GROUP}
echo "${MAPR_USER}:${MAPR_PASS}" | sudo chpasswd 

sudo mkdir ${MAPR_MOUNT_PATH}
sudo mkdir ${MAPR_DATA_PATH}

echo "${MAPR_HOST_IP} ${MAPR_CLUSTER}" | sudo tee -a /etc/hosts

### SECURE CLUSTER ONLY -- YOU WILL NEED TO ENTER PASSWORD HERE AT: "ssh-copy-id" line
  [ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/id_rsa
  ssh-copy-id ${MAPR_USER}@$MAPR_HOST_IP

  scp ${MAPR_USER}@$MAPR_HOST_IP:/opt/mapr/conf/ssl_truststore ssl_truststore
  scp ${MAPR_USER}@$MAPR_HOST_IP:/opt/mapr/conf/ssl-client.xml ssl-client.xml
  scp ${MAPR_USER}@$MAPR_HOST_IP:/opt/mapr/conf/maprtrustcreds.jceks maprtrustcreds.jceks
  scp ${MAPR_USER}@$MAPR_HOST_IP:/opt/mapr/conf/maprtrustcreds.conf maprtrustcreds.conf

  sudo mv ssl_truststore ssl-client.xml maprtrustcreds.jceks maprtrustcreds.conf /opt/mapr/conf/
  sudo /opt/mapr/server/configure.sh -c -N ${MAPR_CLUSTER} -C ${MAPR_HOST_IP}:7222 -HS ${MAPR_HOST_IP} -u mapr -g mapr -secure
  maprlogin password -user mapr
### SECURE CLUSTER ONLY

### NON-SECURE CLUSTER ONLY
  sudo /opt/mapr/server/configure.sh -c -N ${MAPR_CLUSTER} -C ${MAPR_HOST_IP}:7222 -HS ${MAPR_HOST_IP} -u mapr -g mapr
### NON-SECURE CLUSTER ONLY

# Enable services
sudo systemctl restart mapr-posix-client-basic
