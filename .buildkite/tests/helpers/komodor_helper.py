import requests
import time
from config import API_KEY, PUBLIC_API_KEY


def create_komodor_uid(kind, name, namespace, cluster_name):
    return f"{kind}|{cluster_name}|{namespace}|{name}"


def query_backend(url, agent_api_key=False):
    payload={}
    headers = {
        'Accept': 'application/json',
    }
    if agent_api_key:
        headers['x-api-key'] = API_KEY
    else:
        headers['x-api-key'] = PUBLIC_API_KEY
        headers['x-app-key'] = 'API'

    response = requests.request("GET", url, headers=headers, data=payload)
    return response


def query_backend_with_retry(url, retries=3, sleep_time=5, object_to_wait_for=None):
    for i in range(retries):
        response = query_backend(url)
        if (response.status_code == 200 and
                (not object_to_wait_for or len(response.json().get(object_to_wait_for, [])) > 0)):
            return response

        time.sleep(sleep_time)

    print(f"Failed to get desired response from backend after {retries} retries,\nresponse: {response}")
    return  response
