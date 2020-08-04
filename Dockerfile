FROM automium/service-provisioner:1.0.39

COPY config.tf.tmpl /tmp/config.tf.tmpl
RUN cat /tmp/config.tf.tmpl >> config.tf.tmpl

ENV PROVISIONER_ROLE https://github.com/automium/service-kubernetes
ENV PROVISIONER_CONFIG_WAIT_CLEANUP true
ENV PROVISIONER_CONFIG_WAIT_CLEANUP_TIMEOUT 30
ENV KUBE_CONF dummy_value: true
ENV KUBEADM_CUSTOM kubeletExtraArgs:\n  kube-reserved: cpu=300m,memory=0.3Gi,ephemeral-storage=1Gi\n  system-reserved: cpu=200m,memory=0.2Gi,ephemeral-storage=1Gi\n  eviction-hard: memory.available<200Mi,nodefs.available<10%

