#!/bin/bash

# Generate a SSH key for test instances
ssh-keygen -q -N "" -f testkey.pem

# Start molecule
docker-compose run --rm -e TESTROLE_PATH=$(pwd) molecule molecule converge