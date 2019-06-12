#!/usr/bin/env bash

# Ref:
# - https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/
# - https://kubernetes.io/docs/tasks/administer-cluster/cluster-management/

kubectl_drain () {
  timeout 30 \
  kubectl --kubeconfig /root/.kube/config drain ${1} --ignore-daemonsets --delete-local-data
}

kubectl_delete () {
  kubectl --kubeconfig /root/.kube/config delete node ${1}
}

kubectl_uncordon () {
  kubectl --kubeconfig /root/.kube/config uncordon ${1}
}

(

# Save stdin to DATA
DATA=$(cat -)

if [ "$DATA" == "null" ]; then
  echo "Nothing to cleanup"
  exit 0
fi

while read i; do
  NODES=$(echo $i | base64 -d | jq -r .name)
done < <( echo $DATA | jq -r '.[].Value // empty' )

for n in $NODES; do
  echo "Cleanup node $n"
  kubectl_drain $n
  kubectl_delete $n
done

) > >(logger -t kubernetes-maint) 2>&1
