#!/bin/bash
status="$(kubectl get node ${HOSTNAME} | awk 'NR > 1' | awk '{print $2}')"
echo $status
if [[ $status == "NotReady" ]]; then
 echo "Node $HOSTNAME dead"
 exit 1
elif [[ $status == "Ready" ]]; then
 echo "Node is OK"
 exit 0
else
  echo not found
  exit 3
fi
