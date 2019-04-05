#!/bin/bash

# Prerequisite

#terraform
wget https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip -O terraform.zip
unzip terraform_0.11.13_linux_amd64.zip -d /usr/local/bin/
chmod +x ./terraform

#jq
apt-get install jq -y

#json2hcl
wget https://github.com/kvz/json2hcl/releases/download/v0.0.6/json2hcl_v0.0.6_linux_amd64 -O /usr/local/bin/json2hcl
chmod +x ./json2hcl

# Run provisioner
git clone https://github.com/automium/provisioner
cd provisioner

# Prefix  OS_ env var with TF_VAR_
while read i; do
  KEY=$(echo $i | cut -f 1 -d '=')
  VALUE=$(echo $i | cut -f 2 -d '=')
  declare TF_VAR_$KEY=$VALUE
  echo $TF_VAR_OS_NETWORK
done < <(env | grep -e '^OS')

NAME=$(cat /usr/share/dict/words | tr -d \' | tr [:upper:] [:lower:] | shuf -n1)
CLUSTER_NAME=$(cat /usr/share/dict/words | tr -d \' | tr [:upper:] [:lower:] | shuf -n1)
IMAGE=kubernetes-${TRAVIS_BRANCH}-${TRAVIS_BUILD_NUMBER}

cat <<EOF > config.tf
# generic config

variable "quantity" { default = "3" }
variable "name" { default = "${NAME}" }
variable "cluster_name" { default = "${CLUSTER_NAME}" }
variable "image" { default = "${IMAGE}" }
variable "consul" { default = "consul.service.automium.consul" }
variable "consul_port" { default = "8500" }
variable "consul_encrypt" { default = "${CONSUL_ENCRYPT}" }
variable "consul_datacenter" { default = "automium" }

# service config

variable "provisioner_role" { default = "https://github.com/automium/ansible-kubernetes" }
variable "provisioner_role_version" { default = "master" }
variable "master" { default = "true" }
variable "node" { default = "true" }
variable "etcd" { default = "true" }

# openstack config

variable "flavor" { default = "e3standard.x4" }
variable "keypair_name" { default = "automium" }
variable "network_name" { default = "generic" }
variable "region" { default = "${OS_REGION_NAME}" }
variable "auth_url" { default = "${OS_AUTH_URL}" }
variable "tenant_name" { default = "${OS_AUTH_URL}" }
variable "user_name" { default = "${OS_USERNAME}" }
variable "password" { default = "${OS_PASSWORD}" }
EOF

terraform init providers/$1
terraform apply providers/$1
