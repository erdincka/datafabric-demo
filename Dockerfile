FROM --platform=amd64 jrei/systemd-ubuntu:20.04

ENV MAPR_UID 5000
ENV MAPR_GID 5000
ENV MAPR_USER mapr
ENV MAPR_PASS mapr
ENV MAPR_GROUP mapr
ENV MAPR_USER_HOME /home/mapr
ENV MAPR_MOUNT_PATH /mapr
ENV MAPR_DATA_PATH /data
ENV MAPR_HOST maprdemo.mapr.io 
ENV MAPR_CLUSTER maprdemo.mapr.io

ENV container docker
ENV DEBIAN_FRONTEND=noninteractive

# Core packages
RUN apt update; apt install -y ca-certificates locales locales syslinux syslinux-utils

ENV SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
RUN locale-gen $LC_ALL

# Core packages
RUN apt install -y --no-install-recommends sed perl sudo wget curl gnupg2 iproute2 \
    libgcc1 lsof libgcc1 openjdk-11-jdk net-tools vim apt-file python adduser openssh-server \
    libltdl7 libpython2.7 irqbalance iputils-arping iputils-ping iputils-tracepath dmidecode hdparm sdparm \
    default-jdk openssh-client file tar wamerican lsb-release apt-utils rpcbind nfs-common cron

RUN sed -i 's/#PasswordAuthentication/PasswordAuthentication/' /etc/ssh/sshd_config; \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config; \
    sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd; \
    /usr/bin/ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa; \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys 

RUN wget -O - https://package.mapr.hpe.com/releases/pub/maprgpg.key | sudo apt-key add -
RUN echo 'deb https://package.mapr.hpe.com/releases/v7.0.0/ubuntu binary bionic' >> /etc/apt/sources.list
RUN echo 'deb https://package.mapr.hpe.com/releases/MEP/MEP-8.1.0/ubuntu binary bionic' >> /etc/apt/sources.list
RUN apt update; apt upgrade -y

RUN apt install -y mapr-fileserver \
    mapr-client \
    mapr-cldb \
    mapr-zookeeper \
    mapr-mastgateway \
    mapr-nfs \
    mapr-webserver \
    mapr-apiserver \
    mapr-s3server \
    mapr-gateway 
# mapr-posix-client-basic

RUN groupadd -g ${MAPR_GID} ${MAPR_GROUP} && useradd -m -u ${MAPR_UID} -g ${MAPR_GID} -d ${MAPR_USER_HOME} -s /bin/bash ${MAPR_USER} && usermod -a -G sudo ${MAPR_GROUP}
RUN echo "root:${MAPR_PASS}" | chpasswd 
RUN echo "${MAPR_USER}:${MAPR_PASS}" | chpasswd 
RUN sed -i 's!/proc/meminfo!/opt/mapr/conf/meminfofake!' /opt/mapr/server/initscripts-common.sh    

RUN mkdir ${MAPR_MOUNT_PATH}
RUN mkdir ${MAPR_DATA_PATH}

COPY start-datafabric.sh /start-datafabric.sh
RUN chmod +x /start-datafabric.sh

EXPOSE 8580 8998 9998 8042 8888 8088 9997 10001 8190 8243 22 4040 7221 8090 5660 8443 19888 50060 18080 8032 14000 19890 10000 11443 12000 8081 8002 8080 31010 8044 8047 11000 2049 8188 7077 7222 5181 5661 5692 5724 5756 10020 50000-50050 9001 5693 9002 31011 5678 8082 8087 8780 8793 9083 50111
