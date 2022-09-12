#!/usr/bin/env bash

# Enable amd64 bin translation for containers
# sudo docker run --privileged --rm tonistiigi/binfmt --install all

# docker run --rm -it \
docker run -it \
  -e MAPR_CLDB_HOSTS=13.40.61.12 \
  -e LD_LIBRARY_PATH=/opt/mapr/lib \
  --cap-add SYS_ADMIN \
  --security-opt apparmor:unconfined \
  local/dfclient
