#!/bin/bash

# Export role path
export TESTROLE_PATH=$(pwd)

# Generate a SSH key for test instances
ssh-keygen -q -N "" -f testkey.pem

# Lint test
molecule test
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
  molecule destroy
  exit 1
else
  echo "*** CLUSTER BUILD COMPLETED ***"
  sleep 20
  docker exec testcluster-testcluster-0 kubectl --kubeconfig /etc/kubernetes/admin.conf get nodes -o wide
  echo "*** Cleaning up..."
  molecule destroy
  echo "*** Done"
  exit 0
fi

exit 2
