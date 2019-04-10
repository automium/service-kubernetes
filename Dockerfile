FROM automium/service-provisioner

COPY config.tf.tmpl /tmp/config.tf.tmpl
RUN cat /tmp/config.tf.tmpl >> config.tf.tmpl
