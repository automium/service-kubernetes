FROM automium/service-provisioner:1.0.30

COPY config.tf.tmpl /tmp/config.tf.tmpl
RUN cat /tmp/config.tf.tmpl >> config.tf.tmpl

ENV PROVISIONER_ROLE https://github.com/automium/service-kubernetes
ENV PROVISIONER_CONFIG_WAIT_CLEANUP true
ENV PROVISIONER_CONFIG_WAIT_CLEANUP_TIMEOUT 30
ENV KUBE_CONF dummy_value: true
