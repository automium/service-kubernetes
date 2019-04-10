FROM automium/service-provisioner

COPY .env .env
COPY config.tf.tmpl config.tf.tmpl
