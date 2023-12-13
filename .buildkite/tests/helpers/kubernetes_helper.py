import time
import json
from helpers.utils import cmd
from kubernetes import client
from config import NAMESPACE


def check_pods_running(kube_client, label_selector):
    pods = kube_client.list_pod_for_all_namespaces(label_selector=label_selector)
    if len(pods.items) == 0:
        assert False, f"No pods found with label selector {label_selector}"
    for pod in pods.items:
        for container_status in pod.status.container_statuses:
            assert container_status.ready, f"Container {container_status.name} in Pod {pod.metadata.name} is not ready"


def create_namespace(kube_client, namespace_name=NAMESPACE):
    namespace_body = client.V1Namespace(
        metadata=client.V1ObjectMeta(name=namespace_name)
    )
    kube_client.create_namespace(body=namespace_body)


def create_secret(kube_client, namespace_name, secret_name, data):
    secret_body = client.V1Secret(
        metadata=client.V1ObjectMeta(name=secret_name, namespace=namespace_name),
        data=data
    )
    kube_client.create_namespaced_secret(namespace=namespace_name, body=secret_body)


def create_service_account(service_account_name, namespace=NAMESPACE) -> bool:
    v1 = client.CoreV1Api()

    service_account = client.V1ServiceAccount(
        metadata=client.V1ObjectMeta(
            name=service_account_name,
            namespace=namespace
        )
    )

    try:
        v1.create_namespaced_service_account(
            namespace=namespace,
            body=service_account
        )
        print("Service account created successfully.")
        return True
    except client.exceptions.ApiException as e:
        print(f"Failed to create service account: {e}")
        return False


def wait_for_pod_ready(pod_name, namespace, timeout=300):
    v1 = client.CoreV1Api()
    start_time = time.time()
    while True:
        try:
            pod = v1.read_namespaced_pod(name=pod_name, namespace=namespace)
            if all(container.ready for container in pod.status.container_statuses):
                print(f"Pod {pod_name} is ready.")
                return True
        except client.exceptions.ApiException as e:
            print(f"An error occurred: {e}")

        elapsed_time = time.time() - start_time
        if elapsed_time > timeout:
            print(f"Timed out waiting for pod {pod_name} to be ready.")
            return False

        print(f"Waiting for pod {pod_name} to be ready...")
        time.sleep(2)


def find_pod_name_by_deployment(deployment_name, namespace):
    v1 = client.CoreV1Api()
    apps_v1 = client.AppsV1Api()

    try:
        # Get the Deployment object
        deployment = apps_v1.read_namespaced_deployment(
            name=deployment_name,
            namespace=namespace
        )
        # Get the label selector from the Deployment object
        label_selector = ",".join(
            [f"{k}={v}" for k, v in deployment.spec.selector.match_labels.items()]
        )
        # List Pods using the label selector
        pods = v1.list_namespaced_pod(
            namespace=namespace,
            label_selector=label_selector
        )
        # If there are any Pods, return the name of the first one
        if pods.items:
            return pods.items[0].metadata.name
        else:
            print(f"No Pods found for Deployment {deployment_name}")
            return None
    except client.exceptions.ApiException as e:
        print(f"An error occurred: {e}")
        return None


def get_pod_logs(namespace, pod_name, container_name=None, tail_lines=100):
    """
    Retrieve the logs for a specific pod and container.
    """
    v1 = client.CoreV1Api()

    return v1.read_namespaced_pod_log(
        name=pod_name,
        namespace=namespace,
        container=container_name,  # None will get the first container
        tail_lines=tail_lines
    )


def look_for_errors_in_pod_log(pod_name, container_name="k8s-watcher"):
    assert pod_name, "Pod name is required"
    logs = get_pod_logs(NAMESPACE, pod_name, container_name)
    for line in logs.splitlines():
        if not line.startswith("{"):
            continue
        json_log = json.loads(line)
        if "level" in json_log and json_log["level"] == "error":
            assert False, f"Found error in logs of {pod_name}\nLog: {json_log['msg']}"


def rollout_restart_and_wait(deployment_name, namespace):
    cmd(f'kubectl rollout restart deployment/{deployment_name} -n {namespace}')
    output, exit_code = cmd(f'kubectl rollout status deployment/{deployment_name} -n {namespace}')
    return exit_code == 0


def read_file_from_pod(pod_name, namespace, file_path):
    get_file_content_command = f"kubectl exec {pod_name} -n {namespace} -- cat {file_path}"

    output, exit_code = cmd(get_file_content_command)
    return output if exit_code == 0 else None

