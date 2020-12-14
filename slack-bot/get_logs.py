from kubernetes.client.rest import ApiException
from kubernetes import client, config
from slackeventsapi import SlackEventAdapter
from slack import WebClient
from get_env import get_release, get_namespace
import datetime
import json
import os

config.load_kube_config()
now = datetime.datetime.now()
DEPLOYMENT_CHANEL='C01FSQD0XNF'
TOKEN='xoxb-225729104246-1448815445218-dg5WCy77BgSfOVJqXiLbwqaQ'
slack_client = WebClient(token=TOKEN)
DEPLOYMENT_NAME = get_release()
NAMESPACE = get_namespace()

try:
    print(NAMESPACE)
    api_app = client.AppsV1Api()
    api_v1 = client.CoreV1Api()
    logs = {}
    deployment = api_app.read_namespaced_deployment(name=DEPLOYMENT_NAME,namespace=NAMESPACE)
    deployment_name = deployment.metadata.name
    print(deployment_name)
    aviliable_pods = deployment.status.ready_replicas
    print(aviliable_pods)
    pods = []
    
    pods_items = api_v1.list_namespaced_pod(namespace=NAMESPACE).items
    for item in pods_items:
        pod_name = item.metadata.name
        pod_status = item.status.phase
        if pod_name.startswith(DEPLOYMENT_NAME):
            pods.append([pod_name,pod_status])
    logs[DEPLOYMENT_NAME] =  {"deployment_name": deployment_name, "aviliable_replicas": aviliable_pods}
    pods_logs = []
    for pod in pods:
        pod_name = pod[0]
        pod_status = pod[1]
        log = api_v1.read_namespaced_pod_log(name=pod_name,namespace=NAMESPACE,tail_lines=10,pretty=True,timestamps=False)
        pods_logs.append(log)
    
    
    logs = json.dumps(logs)
    block_0 = {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": f"{now.strftime('%A'), {now.strftime('%D')}}"
      }
    }
    block_1 = {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": f":docker: NEW DEPLOYMENT: {NAMESPACE}"
      }
    }
    block_2={
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": f"*Deployment:* \n```{logs}```"
      }
    }
    block_3 = {
        "type": "section",
        "text": {
            "type": "mrkdwn",
            "text": f"*Logs:*\n```{pods_logs}```"
        }
    }
    block_4 = {
        
    }
    send = slack_client.chat_postMessage(channel=DEPLOYMENT_CHANEL,blocks=[block_1,block_2,block_3])
except ApiException as e:
    block_err = {
      "type": "section",
        "text": {
            "type": "mrkdwn",
            "text": f"```No Support for Knative yet!```"
        }
    }
    send = slack_client.chat_postMessage(channel=DEPLOYMENT_CHANEL,blocks=[block_1,block_err])