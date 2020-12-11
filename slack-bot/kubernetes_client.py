from kubernetes.client.rest import ApiException
from kubernetes import client, config
import json

config.load_kube_config()
NAMESPACE = "product-extraction"
try:
    print(NAMESPACE)
    kube_api = client.CoreV1Api()
    pods = kube_api.list_namespaced_pod(NAMESPACE).items
    pods_count = len(pods)
    statuses = []
    for pod in pods:
        statuses.append([pod.metadata.name,pod.status.phase])
    print(pods_count)
    print(json.dumps(statuses))
    
    # logs = kube_api.read_namespaced_pod_log(name='',namespace=NAMESPACE,pretty=true)
    # print(status.status.phase)
except ApiException as e:
    print('Found exception in reading the logs')