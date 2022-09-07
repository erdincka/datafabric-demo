#!/bin/bash

set -euo pipefail

# Only for PACC image
# sudo sed -i 's|secure=false|secure=true|' /opt/mapr/conf/mapr-clusters.conf
# sudo sed -i 's|#fuse.ticketfile.location=|fuse.ticketfile.location=/tmp/mapr_fuseticket|' /opt/mapr/conf/fuse.conf
echo "Configuring cluster ${MAPR_CLUSTER} at IP: ${MAPR_CLDB_HOSTS}"
/opt/mapr/server/configure.sh -c -N ${MAPR_CLUSTER} -C ${MAPR_CLDB_HOSTS}:7222 -HS ${MAPR_CLDB_HOSTS} -u mapr -g mapr -secure
echo "enable cluster name resolution"
echo "${MAPR_CLDB_HOSTS} ${MAPR_CLUSTER}" >> /etc/hosts
echo "Creating ticket for user ${MAPR_USER}"
echo mapr | /opt/mapr/bin/maprlogin password -user ${MAPR_USER}
# Only for fuse client (not available on M1)
# echo 'mapr' | /opt/mapr/bin/maprlogin generateticket -type service -cluster ${MAPR_CLUSTER} -duration 30:0:0 -out /tmp/mapr_fuseticket -user mapr
# export MAPR_TICKETFILE_LOCATION=/tmp/mapr_fuseticket
# service mapr-posix-client-basic start

/bin/bash
