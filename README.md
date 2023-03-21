# Data Fabric Demo Env - WORK IN PROGRESS

## Server on Ubuntu 20.04

SSH keypair for passwordless access

### Server Installation

Minimum node with 16 core 64GB Memory, 150GB OS disk + 150GB+ data disk

Automated using jupyter notebook:

- Run [Create Server Node on AWS](./00a-create-dfserver-aws.ipynb)
- Run [Install DF on Single Node on Ubuntu Host](./server-on-ubuntu.sh)

Manually install with ansible:

- edit dfcore.ini file for your environment
- run `ansible-playbook -K -v -i dfcore.ini server-install-manual.yaml`

## Client Installation Notes

- Run [Create Client Node on AWS](./02a-create-dfclient-aws.ipynb)
- Set up [Client on Ubuntu](./client-on-ubuntu.sh)
- Set up [Client on MacOS ARM](./client-on-armmac.sh)
- Use docker on M1 Mac to use client container - built via [Dockerfile](./Dockerfile)

## ISSUES

A lot

[ ] MacOS on Apple Silicon seg11 fault with Kafka consumer (client-on-armmac.sh)

[ ] After reboot of DF Server Node, update MAPR_EXTERNAL in /opt/mapr/conf/env_override.sh with new Public IP, and run following:

- `sudo systemctl mapr-warden restart`

- `sudo /opt/mapr/server/configure.sh -R`
