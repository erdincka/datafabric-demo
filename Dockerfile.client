FROM --platform=linux/amd64 ubuntu:20.04

ENV MAPR_UID=5000 \
  MAPR_GID=5000 \
  MAPR_USER=mapr \
  MAPR_PASS=mapr \
  MAPR_GROUP=mapr \
  MAPR_HOME=/opt/mapr \
  MAPR_CLUSTER=demo.df.io \
  container=docker \
  DEBIAN_FRONTEND=noninteractive
# Only for fuse client - not avialable on M1 
# MAPR_MOUNT_PATH=/mapr \

RUN apt update
RUN apt upgrade -y
RUN apt install -y --no-install-recommends gnupg2 wget python3-pip \
  libgcc1 libgcc1 openjdk-11-jdk python2 openssh-server sudo curl \
  libltdl7 libpython2.7 gcc python3-dev rpcbind nfs-common locales \
  default-jdk openssh-client wamerican lsb-release apt-utils 

ENV SHELL=/bin/bash \
  LC_ALL=en_US.UTF-8 \
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US.UTF-8

RUN locale-gen $LC_ALL

RUN wget -O - https://package.mapr.hpe.com/releases/pub/maprgpg.key | apt-key add -
RUN echo 'deb https://package.mapr.hpe.com/releases/v7.0.0/ubuntu binary bionic' >> /etc/apt/sources.list
RUN echo 'deb https://package.mapr.hpe.com/releases/MEP/MEP-8.1.0/ubuntu binary bionic' >> /etc/apt/sources.list
RUN apt update -y

RUN apt install -y mapr-client
# only for fuse client, not available on M1
# RUN apt install -y mapr-posix-client-basic

RUN groupadd -g ${MAPR_GID} ${MAPR_GROUP} && useradd -m -u ${MAPR_UID} -g ${MAPR_GID} -d ${MAPR_HOME} -s /bin/bash ${MAPR_USER} && usermod -aG ${MAPR_GROUP} ${MAPR_USER}
RUN echo "${MAPR_USER}:${MAPR_PASS}" | chpasswd

RUN mkdir /mapr
COPY ssl_truststore ssl_truststore.pem ssl-client.xml maprtrustcreds.jceks maprtrustcreds.conf /opt/mapr/conf/
RUN pip install --global-option=build_ext --global-option="--library-dirs=/opt/mapr/lib" --global-option="--include-dirs=/opt/mapr/include/" mapr-streams-python
RUN pip install maprdb-python-client

COPY configure-client.sh /first-run.sh
RUN chmod +x /first-run.sh
CMD ["/first-run.sh"]