#!/usr/bin/env bash

### CHANGE THESE
export MAPR_CLUSTER="df.demo"
export MAPR_DISKS="/dev/nvme1n1,/dev/nvme2n1,/dev/nvme3n1"
export MAPR_UID=5000
export MAPR_GID=5000
export MAPR_USER=mapr
export MAPR_PASS=mapr
export MAPR_GROUP=mapr
export MAPR_USER_HOME=/home/mapr
export MAPR_MOUNT_PATH=/mapr


### DO NOT CHANGE
export DEBIAN_FRONTEND=noninteractive

# Core packages
apt update
apt install -y ca-certificates locales syslinux syslinux-utils

export SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
locale-gen $LC_ALL

# Core packages
apt install -y --no-install-recommends sed perl sudo wget curl gnupg2 iproute2 \
    libgcc1 lsof libgcc1 openjdk-11-jdk net-tools vim apt-file python adduser openssh-server \
    libltdl7 libpython2.7 irqbalance iputils-arping iputils-ping iputils-tracepath dmidecode hdparm sdparm \
    default-jdk openssh-client file tar wamerican lsb-release apt-utils rpcbind nfs-common cron

sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

wget -O - https://package.mapr.hpe.com/releases/pub/maprgpg.key | apt-key add -
echo 'deb https://package.mapr.hpe.com/releases/v7.0.0/ubuntu binary bionic' >> /etc/apt/sources.list
echo 'deb https://package.mapr.hpe.com/releases/MEP/MEP-8.1.0/ubuntu binary bionic' >> /etc/apt/sources.list
apt update; apt upgrade -y

apt install -y mapr-fileserver \
    mapr-client \
    mapr-cldb \
    mapr-zookeeper \
    mapr-mastgateway \
    mapr-webserver \
    mapr-apiserver \
    mapr-s3server \
    mapr-kafka \
    mapr-gateway 

groupadd -g ${MAPR_GID} ${MAPR_GROUP}
useradd -m -u ${MAPR_UID} -g ${MAPR_GID} -d ${MAPR_USER_HOME} -s /bin/bash ${MAPR_USER}
usermod -a -G sudo ${MAPR_GROUP}
echo "${MAPR_USER}:${MAPR_PASS}" | chpasswd 

mkdir ${MAPR_MOUNT_PATH}

export LD_LIBRARY_PATH=/opt/mapr/lib
echo "LD_LIBRARY_PATH=/opt/mapr/lib" >> /root/.bashrc

echo "session       required       pam_limits.so" >> /etc/pam.d/common-session

/opt/mapr/server/configure.sh -N ${MAPR_CLUSTER} -C $(hostname -i):7222 -Z $(hostname -i) -u ${MAPR_USER} -g ${MAPR_GROUP} -genkeys -secure -dare -D ${MAPR_DISKS}

# Enable posix client
apt install -y mapr-posix-client-basic

# create ticket for user
echo "${MAPR_PASS}" | maprlogin password -user ${MAPR_USER}
# create ticket for fuseclient
maprlogin generateticket -type service -out /opt/mapr/conf/maprfuseticket -duration 3650:0:0 -renewal 9000:0:0 -user ${MAPR_USER}

# start posix client
service mapr-posix-client-basic start

