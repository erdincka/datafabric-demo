# Install DFaaS

## Prepare template

Use one of the supported Linux versions from [requirements page](https://docs.ezmeral.hpe.com/datafabric/73/installation/fabric_node_reqs.html).

Ensure you have set up passwordless ssh and sudo within the template, and also you have configured dns settings properly.

## Edit settings

Edit hosts.yml and vmware-config.yml files to match your environment.

## Run Ansible playbook

You need to install ansible and pyvmomi package to use this.

```sh
python3 -m pip install --user ansible pyvmomi
```

Then you can run:

```sh
ansible-playbook -i hosts.yml deploy-vms.yml
```

## Install the seed node

First create the seed container on your docker machine as described in [docs](https://docs.ezmeral.hpe.com/datafabric/73/installation/aws_seed_node_deployment.html).

This includes:

```sh
wget https://raw.githubusercontent.com/mapr-demos/mapr-db-730-getting-started/main/datafabric_container_setup.sh
chmod +x datafabric_container_setup.sh
./datafabric_container_setup.sh -image maprtech/dev-sandbox-container:7.3.0_9.1.1_dfaas
```

It takes ~10 minutes for all services to come up. Once ready, you can connect to it (assuming you are running docker locally) using the [installer UI](https://localhost:8443/app/dfui/#/resources).

## Finish DFaaS Installation

Follow the steps for [On-prem Deployment with seed node](https://docs.ezmeral.hpe.com/datafabric/73/installation/on_prem_seed_node_deployment.html#concept_kg5_cxs_zwb__section_qvy_cpp_hxb).
