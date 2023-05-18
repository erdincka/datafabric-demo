#!/usr/bin/env bash

CLUSTER_NAME=demo.df.io

sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

sudo chmod u+s /sbin/unix_chkpwd

[ -f ./mapr-setup.sh ] || wget -O mapr-setup.sh https://package.mapr.hpe.com/releases/installer/mapr-setup.sh; chmod +x mapr-setup.sh
[ -f /opt/mapr/installer/bin/mapr-installer-cli ] || sudo ./mapr-setup.sh -y
# [ -f /home/ubuntu/.ssh/id_rsa ] || ssh-keygen -N '' -f /home/ubuntu/.ssh/id_rsa -b 2048 -t rsa

## Private key for SSH login
echo "
-----BEGIN RSA PRIVATE KEY-----
REPLACE WITH YOUR PRIVATE KEY
-----END RSA PRIVATE KEY-----" >> ~/private.key
chmod 600 ~/private.key

echo "
environment:
  mapr_core_version: 7.0.0
config:
  hosts:
    - $(hostname -f)
  ssh_id: ${USER}
  ssh_password: mapr
  cluster_admin_id: mapr
  cluster_admin_password: mapr
  ssh_key_file: ${HOME}/private.key
  db_admin_user: root
  db_admin_password: mapr
  log_admin_password: mapr
  metrics_ui_admin_password: mapr
  enable_encryption_at_rest: True
  license_type: M7
  mep_version: 8.1.0
  disks:
    - /dev/nvme1n1
  disk_format: true
  disk_stripe: 1
  cluster_name: ${CLUSTER_NAME}
  services:
    template-05-converged:
    mapr-hivemetastore:
      database:
        name: hive
        user: hive
        password: mapr
    mapr-grafana:
      enabled: True
    mapr-opentsdb:
      enabled: True
    mapr-collectd:
    mapr-fluentd:
    mapr-kibana:
      enabled: True
    mapr-elasticsearch:
      enabled: True
    mapr-data-access-gateway:
    mapr-mastgateway:
" > ~/mapr.stanza

echo "Wait for installer to be ready"; sleep 30

echo y | sudo /opt/mapr/installer/bin/mapr-installer-cli install -nv -t /home/ubuntu/mapr.stanza
[ -f /opt/mapr/bin/maprlogin ] && ( sleep 30; [ -f /tmp/maprticket_$(id -u) ] || (echo mapr | maprlogin password -user mapr) )

## Only needed if clients from external (Internet) network access required
PUBLIC_IP=$(curl http://ifconfig.me)
grep -v "MAPR_EXTERNAL" /opt/mapr/conf/env_override.sh | sudo tee /opt/mapr/conf/env_override.sh
echo "export MAPR_EXTERNAL=$PUBLIC_IP" | sudo tee -a /opt/mapr/conf/env_override.sh
sudo /opt/mapr/server/configure.sh -R

for file in "ssl_truststore" "ssl_truststore.pem" "ssl-client.xml" "maprtrustcreds.jceks" "maprtrustcreds.conf"
do
  sudo cp /opt/mapr/conf/$file ${HOME}/
  sudo chown ubuntu ${HOME}/$file
done
