#!/bin/bash

# Functions
cleanup(){
  echo "*** Cleaning up..."
  molecule destroy
  echo "*** Done"
}

# Export role path
export TESTROLE_PATH=$(pwd)
export ANSIBLE_STDOUT_CALLBACK=debug

# Generate a SSH key for test instances
ssh-keygen -q -N "" -f testkey.pem

# Lint test
molecule test
if [ $? -ne 0 ]; then
  echo "*** molecule test FAILED ***"
  exit 1
fi

# Start test cluster with molecule
molecule converge
if [ $? -ne 0 ]; then
  echo "*** CLUSTER BUILD FAILED ***"
  echo "*** Kubelet service log for master:"
  docker exec testcluster-testcluster-0 journalctl -xe -u kubelet --no-pager
  docker exec testcluster-testcluster-0 docker version
  docker exec testcluster-testcluster-0 docker info
  docker exec testcluster-testcluster-0 docker ps -a
  echo ""
  echo "*** Kubelet service log for worker:"
  docker exec testcluster-testworker-0 journalctl -xe -u kubelet --no-pager
  docker exec testcluster-testworker-0 docker version
  docker exec testcluster-testworker-0 docker info
  docker exec testcluster-testworker-0 docker ps -a
  sleep 10
  cleanup
  exit 1
fi

sleep 5

# Launch cluster verification
molecule verify
if [ $? -ne 0 ]; then
  echo "*** CLUSTER VERIFICATION FAILED ***"
  cleanup
  exit 1
fi

cleanup
exit 0