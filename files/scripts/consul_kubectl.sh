#!/bin/bash

set -e 

# Export kubeconfig
export KUBECONFIG=/etc/kubernetes/admin.conf

# Export hostname
export HOSTNAME="$(hostname)"
# Setup consul cluster role binding
kubectl apply -f /tmp/consul_cluster_rolebinding.yaml
# Retrieve data
CONSUL_SA_SECRET="$(kubectl -n kube-system get sa consul-node-check -o jsonpath='{.secrets[0].name}')"
export CONSUL_TOKEN="$(kubectl -n kube-system get secret ${CONSUL_SA_SECRET} -o jsonpath='{.data.token}' | base64 -d)"
export CONSUL_CRT="$(kubectl -n kube-system get secret ${CONSUL_SA_SECRET} -o jsonpath='{.data.ca\.crt}')"

mkdir -p /opt/consul/.kube

cat > /opt/consul/.kube/config <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${CONSUL_CRT}
    server: https://${HOSTNAME}:6443
  name: cluster.local
contexts:
- context:
    cluster: cluster.local
    user: consul-node-check
  name: consul-node-check@cluster.local
current-context: consul-node-check@cluster.local
kind: Config
preferences: {}
users:
- name: consul-node-check
  user:
    token: ${CONSUL_TOKEN}
EOF
chown consul:consul -R /opt/consul/.kube
