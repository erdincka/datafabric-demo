#!/usr/bin/env bash

## CHANGE THESE
export MAPR_HOST_IP=172.31.18.168
export MAPR_CLUSTER=demo.df.io

echo "
-----BEGIN RSA PRIVATE KEY-----
REPLACE WITH YOUR PRIVATE KEY
-----END RSA PRIVATE KEY-----" >> ~/private.key
chmod 600 ~/private.key


# DO NOT CHANGE THESE
export MAPR_UID=5000
export MAPR_GID=5000
export MAPR_USER=mapr
export MAPR_PASS=mapr
export MAPR_GROUP=mapr
export MAPR_USER_HOME=/home/mapr
export MAPR_MOUNT_PATH=/mapr
export MAPR_DATA_PATH=/data

export DEBIAN_FRONTEND=noninteractive

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
  # [ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/id_rsa
  # ssh-copy-id ${MAPR_USER}@${MAPR_HOST_IP}

  # scp ${MAPR_USER}@${MAPR_HOST_IP}:/opt/mapr/conf/ssl_truststore ssl_truststore
  # scp ${MAPR_USER}@${MAPR_HOST_IP}:/opt/mapr/conf/ssl_truststore.pem ssl_truststore.pem
  # scp ${MAPR_USER}@${MAPR_HOST_IP}:/opt/mapr/conf/ssl-client.xml ssl-client.xml
  # scp ${MAPR_USER}@${MAPR_HOST_IP}:/opt/mapr/conf/maprtrustcreds.jceks maprtrustcreds.jceks
  # scp ${MAPR_USER}@${MAPR_HOST_IP}:/opt/mapr/conf/maprtrustcreds.conf maprtrustcreds.conf


for file in "ssl_truststore" "ssl_truststore.pem" "ssl-client.xml" "maprtrustcreds.jceks" "maprtrustcreds.conf"
do
  scp ${MAPR_USER}@${MAPR_HOST_IP}:/opt/mapr/conf/$file ~/
  sudo cp ~/$file /opt/mapr/conf/
done

  sudo mv ssl_truststore ssl_truststore.pem ssl-client.xml maprtrustcreds.jceks maprtrustcreds.conf /opt/mapr/conf/
  sudo /opt/mapr/server/configure.sh -c -N ${MAPR_CLUSTER} -C ${MAPR_HOST_IP}:7222 -HS ${MAPR_HOST_IP} -u mapr -g mapr -secure
  maprlogin password -user mapr
### SECURE CLUSTER ONLY

# Enable services
sudo maprlogin password -user mapr -out /opt/mapr/conf/maprfuseticket
sudo systemctl restart mapr-posix-client-basic

sudo apt install -y python3-pip
sudo pip install --global-option=build_ext --global-option="--library-dirs=/opt/mapr/lib" --global-option="--include-dirs=/opt/mapr/include/" mapr-streams-python
pip install maprdb-python-client

# Spark and Delta Lake

## Install livy and airflow on the server - https://github.com/fbercken/fingrid

# sudo apt install -y mapr-spark
# wget https://repo1.maven.org/maven2/io/delta/delta-core_2.12/1.2.0/delta-core_2.12-1.2.0.jar
# pip3 install pyspark==3.2.0
# pip3 install importlib-metadata
# pip3 install delta_spark
# pip3 install avro

# wget https://repository.mapr.com/nexus/content/groups/mapr-public/org/apache/spark/spark-sql_2.12/3.2.0.0-eep-810/spark-sql_2.12-3.2.0.0-eep-810.jar
# wget https://repository.mapr.com/nexus/content/groups/mapr-public/org/apache/spark/spark-avro_2.12/3.2.0.0-eep-810/spark-avro_2.12-3.2.0.0-eep-810.jar

# Create volume /mydata 
# create folder resources and copy telemetry.avsc to /mydata/resources
# follow README.md on github