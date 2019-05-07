Automium Service: kubernetes 
======================================

[![Build Status](https://travis-ci.org/automium/service-kubernetes.svg?branch=master)](https://travis-ci.org/automium/service-kubernetes)

this project is meant to be used by [automium provisioner](https://github.com/automium/provisioner)

## variables

### MASTER

if true configure the instance as a kubernetes master node

### NODE

if true configure the instance as a kubernetes worker node

### ETCD

if true configure the instance as a etcd node

## usage

setup service var:
```
export SERVICE=automium/service-kubernetes
export MASTER=true
export NODE=true
export ETCD=true
export RANCHER_URL=http://rancher.local
export RANCHER_CLUSTER_TOKEN=237dh928gd2
```

and follow the guide [here](https://github.com/automium/provisioner/blob/master/README.md#guide)
