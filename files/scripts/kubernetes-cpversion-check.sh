#!/bin/bash

set -e 

CONTENT="$(cat /etc/kubernetes/cpversion_check)"

if [ "${CONTENT}" == "True" ]; then
  echo "Control plane version check passed "
  exit 0
elif [ "${CONTENT}" == "False"]; then
  echo "Control plane version check failed - node will execute control plane upgrade"
  exit 2
else
  echo "Unknown content: ${CONTENT}"
  exit 2
fi

exit 3
