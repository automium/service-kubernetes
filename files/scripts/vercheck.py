import sys
import http.client
import ssl
import json
from dns.resolver import query

def usage():
    print("Usage: {} <service name> <kubernetes version>".format(sys.argv[0]))
    sys.exit(1)


if len(sys.argv) != 3:
    usage()

if sys.argv[1] == "" or sys.argv[2] == "":
    usage()

SERVICE_NAME = sys.argv[1]
KUBERNETES_VERSION = sys.argv[2]
VERSION_FOUND = False

try:
    ctx = ssl.create_default_context(cafile="/etc/kubernetes/pki/ca.crt")
    answer = query("{}-kube-apiserver.service.automium.consul".format(SERVICE_NAME), "A")
    for k8snode in answer:
        conn = http.client.HTTPSConnection(k8snode.address, 6443, context=ctx)
        conn.request("GET", "/version")
        jsonResp = json.loads(conn.getresponse().read())
        conn.close()
        if jsonResp["gitVersion"] == KUBERNETES_VERSION:
            VERSION_FOUND = True
            break
    print("{}".format(VERSION_FOUND))
    sys.exit(0)
except Exception as e:
    print("ERROR: {}".format(e))
    sys.exit(1)
