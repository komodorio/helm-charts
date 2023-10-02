import subprocess
import pytest
import os
from kubernetes import client, config


def cmd(commands, silent=False):
    if isinstance(commands, str):
        commands = commands.split(" ")
    output = ""
    cmd_as_string = " ".join(commands)
    if not silent:
        print("Doing cmd: {}".format(cmd_as_string))
    with subprocess.Popen(
            cmd_as_string,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            bufsize=1,
            universal_newlines=True,
            shell=True,
    ) as p:
        for line in p.stdout:
            output += line
            if not silent:
                print(line, end="")
    return output.strip(), p.wait()


API_KEY = os.environ.get("API_KEY", "92dc9cf8-dcf6-40c9-87e1-a0fd2835ef47")
CLUSTER_NAME = os.environ.get("CLUSTER_NAME", "helm-chart-test")
RELEASE_NAME = os.environ.get("RELEASE_NAME", "helm-test")
CHART_PATH = os.environ.get("CHART_PATH", "../charts/k8s-watcher")
VALUES_FILE_PATH = os.environ.get("VALUES_FILE_PATH", "")
NAMESPACE = os.environ.get("NAMESPACE", "komodor")


@pytest.fixture(scope='module')
def setup_cluster():
    cluster_name = "banana"
    cmd(f"kind create cluster --name {cluster_name} --wait 5m")
    config.load_kube_config()
    yield
    cmd(f"kind delete cluster --name {cluster_name}")


@pytest.fixture
def kube_client():
    return client.CoreV1Api()


def helm_agent_install(settings=f'--set apiKey={API_KEY} --set clusterName={CLUSTER_NAME} --create-namespace',
                       additional_settings=""):
    output, exit_code = cmd(f"helm install {RELEASE_NAME} {CHART_PATH} {settings} {additional_settings} --namespace={NAMESPACE} --wait")
    return output, exit_code


def check_pods_running(kube_client, label_selector):
    pods = kube_client.list_pod_for_all_namespaces(label_selector=label_selector)
    if len(pods.items) == 0:
        assert False, f"No pods found with label selector {label_selector}"
    for pod in pods.items:
        for container_status in pod.status.container_statuses:
            assert container_status.ready, f"Container {container_status.name} in Pod {pod.metadata.name} is not ready"


# Starting tests here #

@pytest.mark.parametrize(
    "settings, missing_value",
    [
        (f"--set clusterName={CLUSTER_NAME}", "apiKey"),
        (f"--set apiKey={API_KEY}", "clusterName")
    ]
)
def test_dont_provide_required_values(setup_cluster, settings, missing_value):
    output, exit_code = helm_agent_install(settings)

    assert f"{missing_value} is a required" in output, f"Expecting to fail installation in case {missing_value} was not provided, output: {output}"
    assert exit_code != 0, f"helm install should fail, output: {output}"


def test_helm_installation():
    output, exit_code = helm_agent_install()
    assert exit_code == 0, "helm install failed, output: {}".format(output)


def test_all_pods_are_running_in_chart(setup_cluster, kube_client):
    output, exit_code = helm_agent_install()
    assert exit_code == 0, "helm install failed, output: {}".format(output)

    check_pods_running(kube_client, 'app.kubernetes.io/name=k8s-watcher')
    check_pods_running(kube_client, 'app.kubernetes.io/name=k8s-watcher-daemon')


def test_get_configmap_from_resources_api(setup_cluster, api_key, cluster_name, config_map_name):
    # Placeholder assertion, implement actual logic
    assert True


def test_get_network_mapper_from_resources_api():
    # Placeholder assertion, implement actual logic
    assert True


def test_get_metrics_from_metrics_api():
    # Placeholder assertion, implement actual logic
    assert True


# apiKeysecret as apikey

# tags and policies

# use an existing service_account with annotations

# use a proxy + customCA

# changing image repository -t

# changing pull policy - t

# providing an image pull secret for the service account -t

# disable installation capabilities (mapper, metrics) -t

# disable agent capabilities (helm, actions) -t

# define events.watchnamespace
def validate_configmap_from_resources_api(api_key, clusterName):
    url = "https://app.komodor.com/resources/api/v1/configurations/config-maps/events/search?komodorUids=configmap%7Cproduction%7Ckomodor%7Ck8s-watcher-config&limit=1&fields=clusterName&order=DESC"

    payload={}
    headers = {
        'Accept': 'application/json',
        'x-api-key': '2b08f337-d5e9-4d60-ba6c-53263a77ba9b'
    }

    response = requests.request("GET", url, headers=headers, data=payload)
    # check if the response is 200

    if response.json()['data'][0]['clusterName'] == clusterName:
        print("Success : Configmap from resources api validated successfully")
        return True

    print(response)
    return False

# ---reached events.watchNamespace

# Block namespace and validate that no events are sent

# Event redaction - validate that workload is redacted in komodor

# disable logs

# log deny list

# log allow list

# log redact regex

# disable allowedResources.allowReadAll and dont allow clusterrole, validate that we are not getting clusterroles

# debug Allow collection of api metrics and validate that it sends metrics to collector

# change kubernetes deployment settings (affinity, annotations, nodeSelector, tollerations, podAnnotations)

# change kubernetes Agent settings (affinity, annotations, nodeSelector, tollerations, podAnnotations)

# change an image tag -t

# change an image name -t