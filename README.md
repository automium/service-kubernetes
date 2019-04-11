Automium Service: kubernetes 
======================================

[![Build Status](https://travis-ci.org/automium/service-kubernetes.svg?branch=master)](https://travis-ci.org/automium/service-kubernetes)

## example

create a .env file, see .env.example

`PROVISIONER_ROLE` and `PROVISIONER_ROLE_VERSION` define which role and which version is used to be deployed

then deploy it
```
docker-compose pull
docker-compose run --rm deploy
```

## contribute

download the repo
```
git clone https://github.com/automium/provisioner.git
cd provisioner
```

edit, build and test locally
```
docker-compose -f docker-compose.dev.yml build
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run --rm deploy
```
