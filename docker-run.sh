#!/usr/bin/env bash

export PORTS='-p 8580:8580 -p 8998:8998 -p 9998:9998 -p 8042:8042 -p 8888:8888 -p 8088:8088 -p 9997:9997 -p 10001:10001 -p 8190:8190
  -p 8243:8243 -p 2222:22 -p 4040:4040 -p 7221:7221 -p 8090:8090 -p 5660:5660 -p 8443:8443 -p 19888:19888 -p 50060:50060 -p 18080:18080
  -p 8032:8032 -p 14000:14000 -p 19890:19890 -p 10000:10000 -p 11443:11443 -p 12000:12000 -p 8081:8081 -p 8002:8002 -p 8080:8080 -p 31010:31010
  -p 8044:8044 -p 8047:8047 -p 11000:11000 -p 2049:2049 -p 8188:8188 -p 7077:7077 -p 7222:7222 -p 5181:5181 -p 5661:5661 -p 5692:5692 -p 5724:5724
  -p 5756:5756 -p 10020:10020 -p 50000-50050:50000-50050 -p 9001:9001 -p 5693:5693 -p 9002:9002 -p 31011:31011 -p 5678:5678 -p 8082:8082 -p 8087:8087
  -p 8780:8780 -p 8793:8793 -p 9083:9083 -p 50111:50111'

CID=$(docker ps --filter "ancestor=erdincka/datafabric" -q)

[ -z ${CID} ] && docker run -d --platform linux/amd64 \
  --device /dev/fuse \
  --cap-add SYS_ADMIN \
  --cgroupns=host \
  --privileged \
  --tmpfs /tmp --tmpfs /run --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup \
  ${PORTS} erdincka/datafabric

CID=$(docker ps --filter "ancestor=erdincka/datafabric" -q)

docker exec -it $CID /bin/bash