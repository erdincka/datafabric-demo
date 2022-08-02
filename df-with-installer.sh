#!/usr/bin/env bash

## Using AWS EC2 
# Ubuntu 20.04 ami-0bd2099338bc55e6d
# m5.4xlarge - 16 vCPU and 64GB memory
# 150GB root (gp2) + 150GB data disks (gp3)

set -eo pipefail

usage() { echo "Usage: $0 [-u <username>] -h <hostname/ip> [-k <private key>] [-c <cluster_name>]" 1>&2; exit 1; }

# set defaults
username="ubuntu"
keyfile="~/.ssh/id_rsa"
cluster_name="core.df.io"

while getopts ":u:h:k:c:" o; do
    case "${o}" in
        u)
            username=${OPTARG}
            ;;
        h)
            hostname=${OPTARG}
            ;;
        k)
            keyfile=${OPTARG}
            ;;
        c)
            cluster_name=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${hostname}" ]; then
    usage
fi

# Helpers
SSHOPTS="-t -i ${keyfile} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -l ${username}"
SSH_COMMAND="ssh ${SSHOPTS} ${hostname}"
FQDN=$($SSH_COMMAND hostname -f)

# TODO: should select the disk(s) without any partition
DATADISK=/dev/nvme1n1

# Transfer data
[[ -f LatestDemoLicense-M7.txt ]] && LICENSE=$(<LatestDemoLicense-M7.txt)
PRVKEY=$(<${keyfile})
STANZA="""
environment:
  mapr_core_version: 7.0.0
config:
  admin_id: mapr
  cluster_name: "${cluster_name}"
  db_admin_password_set: true
  db_admin_password: mapr
  db_admin_user: root
  debug_set: false
  elasticsearch_path: /opt/mapr/es_db
  enable_encryption_at_rest: true
  enable_min_metrics_collection: true
  enable_nfs: true
  hosts:
    - "${FQDN}"
  license_type: M7
  log_admin_password: mapr
  mep_version: 8.1.0
  metrics_ui_admin_password: mapr
  nfs_type: "NFSv4"
  security: true
  ssh_id: "${username}"
  ssh_key_file: /tmp/private_key
  disks:
    - "${DATADISK}"
  disk_format: true
  disk_stripe: 1
  services:
    template-05-converged:
    mapr-hivemetastore:
      database:
        create: true
        name: hive
        user: hive
        password: mapr
    mapr-hue-livy:
          enabled: true
    mapr-grafana:
      enabled: true
    mapr-opentsdb:
      enabled: true
    mapr-collectd:
    mapr-fluentd:
    mapr-kibana:
      enabled: true
    mapr-elasticsearch:
      enabled: true
    mapr-data-access-gateway:
    mapr-mastgateway:
"""

# Prepare node
$SSH_COMMAND bash <<EOF

export DEBIAN_FRONTEND=noninteractive
export TERM=vt100
sudo chmod u+s /sbin/unix_chkpwd

# update system
sudo apt update
sudo apt upgrade -y

# get installer
[ -f mapr-setup.sh ] || wget -O mapr-setup.sh https://package.mapr.hpe.com/releases/installer/mapr-setup.sh
chmod +x mapr-setup.sh

# prepare installer 
[ -f /opt/mapr/installer/bin/mapr-installer-cli ] || sudo /home/${username}/mapr-setup.sh -y

nohup sudo reboot &>/dev/null & exit
EOF

# Wait for reboot
echo "Wait for reboot"
sleep 60

# Execute install
$SSH_COMMAND bash <<EOF
export TERM=vt100

# copy files
echo "${STANZA}" > /tmp/mapr.stanza
[ -f LatestDemoLicense-M7.txt ] || echo "${LICENSE}" > /tmp/LatestDemoLicense-M7.txt
echo "$PRVKEY" > /tmp/private_key
chmod 600 /tmp/private_key

# install DF
echo y | sudo /opt/mapr/installer/bin/mapr-installer-cli install -nv -t /tmp/mapr.stanza

# check install
[ -f /opt/mapr/bin/maprlogin ] || exit 1

# configure user
[ -f /tmp/maprticket_$(id -u) ] || (echo mapr | maprlogin password -user mapr)

# install license - not needed for single node
[ -f /tmp/LatestDemoLicense-M7.txt ] && maprcli license add -license /tmp/LatestDemoLicense-M7.txt -is_file true 

EOF

exit 0
