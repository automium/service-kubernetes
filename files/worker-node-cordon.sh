#!/bin/bash

KUBECTL=$(which kubectl)
KUBECONFIG="/root/.kube/config"

# Verifica che sul worker da dismettere non ci siano pod in esecuzione.
# Viceversa esegue cordon + drain del nodo prima di rimuoverlo.
# NOTA: nel drain si aggiunge l'opzione --ignore-daemonsets

kubectl_get_pods () {
    POD_NUMS=$(${KUBECTL} --kubeconfig=${KUBECONFIG} get pods \
               --all-namespaces \
               --field-selector spec.nodeName=${HOSTNAME} \
               -o=custom-columns=NAME:metadata.name | wc -l)

    echo ${POD_NUMS}
}

kubectl_cordon () {
    ${KUBECTL} --kubeconfig=${KUBECONFIG} cordon ${HOSTNAME}
}

kubectl_drain () {
    ${KUBECTL} --kubeconfig=${KUBECONFIG} drain ${HOSTNAME} --ignore-daemonsets
}

kubectl_delete_node () {
    ${KUBECTL} --kubeconfig=${KUBECONFIG} delete node ${HOSTNAME}
}

if [[ kubectl_get_pods == 1 ]]; then
    echo "There are no pods running on this node."
    kubectl_delete_node
else
    echo "There are some pods running on this node."
    kubectl_cordon
    kubectl_drain
    kubectl_delete_node
fi
