#!/usr/bin/env bash

export MAPR_CLUSTER=demo.df.io
export MAPR_TZ=Europe/London
export MAPR_CLDB_HOSTS=demo.df.io
export MAPR_CONTAINER_USER=mapr
export MAPR_CONTAINER_PASSWORD=mapr
export MAPR_CONTAINER_UID=5000
export MAPR_CONTAINER_GID=5000
export MAPR_MOUNT_PATH=/mapr
export TICKET_FILE_PATH=/tmp/maprticket_1000

docker run -it \
	-e MAPR_CLUSTER=${MAPR_CLUSTER} \
	-e MAPR_TZ=${MAPR_TZ} \
	-e MAPR_CLDB_HOSTS=${MAPR_CLDB_HOSTS} \
	-e MAPR_CONTAINER_USER=${MAPR_CONTAINER_USER} \
	-e MAPR_CONTAINER_PASSWORD=${MAPR_CONTAINER_PASSWORD} \
	-e MAPR_CONTAINER_UID=${MAPR_CONTAINER_UID} \
	-e MAPR_CONTAINER_GID=${MAPR_CONTAINER_GID} \
	-e MAPR_CONTAINER_GROUP=${MAPR_CONTAINER_GROUP} \
	-e MAPR_TICKETFILE_LOCATION=/tmp/mapr_ticket \
	-v ${TICKET_FILE_PATH}:/tmp/mapr_ticket:ro \
	-e MAPR_MOUNT_PATH=${MAPR_MOUNT_PATH} \
	--cap-add SYS_ADMIN \
	--cap-add SYS_RESOURCE \
	--device /dev/fuse \
	--security-opt apparmor:unconfined \
	local/pacc
