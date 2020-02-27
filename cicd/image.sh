#!/bin/bash

# Wait until the instance is ready
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do sleep 1; done

source /usr/src/cloud/venv/bin/activate
export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1
export ANSIBLE_ROLES_PATH=:/tmp/:/usr/src/cloud/roles
export ANSIBLE_BECOME=True
export ANSIBLE_BECOME_METHOD=sudo
export ANSIBLE_BECOME_USER=root
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_SSH_ARGS='-o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s'
ansible-playbook --tags=image -e ansible_python_interpreter=/usr/bin/python3 --connection=local /tmp/service-kubernetes/molecule/default/build_image.yml