export MAPR_UID=5000
export MAPR_GID=5000
export MAPR_USER=mapr
export MAPR_PASS=mapr
export MAPR_GROUP=mapr
export MAPR_USER_HOME=/home/mapr
export MAPR_MOUNT_PATH=/mapr
export MAPR_DATA_PATH=/data
export MAPR_HOST=demo.df.io
export MAPR_CLUSTER=demo.df.io

export DEBIAN_FRONTEND=noninteractive

# Core packages
sudo apt update; sudo apt install -y ca-certificates locales syslinux syslinux-utils

export SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
sudo locale-gen $LC_ALL

# Core packages
sudo apt install -y --no-install-recommends sed perl sudo wget curl gnupg2 iproute2 \
    libgcc1 lsof libgcc1 openjdk-11-jdk net-tools vim apt-file python adduser openssh-server \
    libltdl7 libpython2.7 irqbalance iputils-arping iputils-ping iputils-tracepath dmidecode hdparm sdparm \
    default-jdk openssh-client file tar wamerican lsb-release apt-utils rpcbind nfs-common cron

sudo sed -i 's/#PasswordAuthentication/PasswordAuthentication/' /etc/ssh/sshd_config; \
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config; \
sudo sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd; \
sudo /usr/bin/ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa; \
sudo cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys 

wget -O - https://package.mapr.hpe.com/releases/pub/maprgpg.key | sudo apt-key add -
echo 'deb https://package.mapr.hpe.com/releases/v7.0.0/ubuntu binary bionic' | sudo tee -a /etc/apt/sources.list
echo 'deb https://package.mapr.hpe.com/releases/MEP/MEP-8.1.0/ubuntu binary bionic' | sudo tee -a /etc/apt/sources.list
sudo apt update; sudo apt upgrade -y

sudo apt install -y mapr-fileserver \
    mapr-client \
    mapr-cldb \
    mapr-zookeeper \
    mapr-mastgateway \
    mapr-nfs \
    mapr-webserver \
    mapr-apiserver \
    mapr-s3server \
    mapr-gateway 

sudo groupadd -g ${MAPR_GID} ${MAPR_GROUP} && sudo useradd -m -u ${MAPR_UID} -g ${MAPR_GID} -d ${MAPR_USER_HOME} -s /bin/bash ${MAPR_USER}; sudo usermod -a -G sudo ${MAPR_GROUP}
echo "root:${MAPR_PASS}" | sudo chpasswd 
echo "${MAPR_USER}:${MAPR_PASS}" | sudo chpasswd 
# sudo sed -i 's!/proc/meminfo!/opt/mapr/conf/meminfofake!' /opt/mapr/server/initscripts-common.sh    

sudo mkdir ${MAPR_MOUNT_PATH}
sudo mkdir ${MAPR_DATA_PATH}

### replace ens5 with your primary eth interface
IP=$(/sbin/ip -o -4 addr list ens5 | awk '{print $4}' | cut -d/ -f1)
HOSTNAME=$(hostname -f)
grep -v $IP /etc/hosts | sudo tee /etc/hosts
echo "$IP  ${MAPR_CLUSTER} ${HOSTNAME}" | sudo tee -a /etc/hosts
echo "session       required       pam_limits.so" | sudo tee -a /etc/pam.d/common-session

# Configure server
sudo /opt/mapr/server/configure.sh -N ${MAPR_CLUSTER} -C ${IP}:7222 -Z ${IP} -u ${MAPR_USER} -g ${MAPR_GROUP} -genkeys -secure -dare

# Enable posix client
sudo apt install -y mapr-posix-client-basic

# create ticket for user
echo "${MAPR_PASS}" | maprlogin password -user ${MAPR_USER}
# create ticket for fuseclient
maprlogin generateticket -type service -out /opt/mapr/conf/maprfuseticket -duration 3650:0:0 -renewal 9000:0:0 -user mapr

sudo service mapr-posix-client-basic start

