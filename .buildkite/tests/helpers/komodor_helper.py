import requests
from config import API_KEY, CLUSTER_NAME, NAMESPACE


def create_komodor_uid(kind, name, namespace=NAMESPACE, cluster_name=CLUSTER_NAME):
    return f"{kind}|{cluster_name}|{namespace}|{name}"


def query_backend(url):
    payload={}
    headers = {
        'Accept': 'application/json',
        'x-api-key': API_KEY
    }

    response = requests.request("GET", url, headers=headers, data=payload)
    return response
