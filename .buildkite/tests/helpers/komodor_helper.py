import requests
import time
from config import API_KEY


def create_komodor_uid(kind, name, namespace, cluster_name):
    return f"{kind}|{cluster_name}|{namespace}|{name}"


def query_backend(url):
    payload={}
    headers = {
        'Accept': 'application/json',
        'x-api-key': API_KEY
    }

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
