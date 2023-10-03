import subprocess
import pytest
import os
import yaml
import requests
import base64
import time
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
API_KEY_B64 = base64.b64encode(API_KEY.encode()).decode()
CLUSTER_NAME = os.environ.get("CLUSTER_NAME", "helm-chart-test-mk")
RELEASE_NAME = os.environ.get("RELEASE_NAME", "helm-test")
CHART_PATH = os.environ.get("CHART_PATH", "../charts/k8s-watcher")
VALUES_FILE_PATH = os.environ.get("VALUES_FILE_PATH", "")
NAMESPACE = os.environ.get("NAMESPACE", "komodor")
BE_BASE_URL = os.environ.get("BE_BASE_URL", "https://app.komodor.com")


@pytest.fixture(scope='module')
def setup_cluster():
    cluster_name = "test"
    cmd(f"kind create cluster --name {cluster_name} --wait 5m")
    config.load_kube_config()
    cmd(f"kubectl apply -f ./test-data/*.yaml")
    yield
    cmd(f"kind delete cluster --name {cluster_name}")


@pytest.fixture
def kube_client():
    return client.CoreV1Api()


@pytest.fixture(scope="function", autouse=True)
def cleanup_agent_from_cluster(request):

    yield
    # Skip teardown for tests marked with 'no_cleanup'
    # To skip cleanup, add the following decorator to the test: @pytest.mark.no_agent_cleanup
    if request.node.get_closest_marker('no_agent_cleanup'):
        return

    helm_agent_uninstall()


def helm_agent_install(settings=f'--set apiKey={API_KEY} --set clusterName={CLUSTER_NAME} --create-namespace',
                       additional_settings=""):
    output, exit_code = cmd(
        f"helm install {RELEASE_NAME} {CHART_PATH} {settings} {additional_settings} --namespace={NAMESPACE} --wait")
    return output, exit_code


def helm_agent_template(settings=f'--set apiKey={API_KEY} --set clusterName={CLUSTER_NAME} --create-namespace',
                        additional_settings="", values_file=False):
    if values_file:
        temp_path = os.path.join(os.path.dirname(__file__), "temp-values.yaml")
        print(f"Using values file: {temp_path}, content: {values_file}")
        if os.path.exists(temp_path):
            os.remove(temp_path)
        with open(temp_path, "w") as f:
            f.write(values_file)
        additional_settings += f" -f {temp_path}"

    output, exit_code = cmd(
        f"helm template {RELEASE_NAME} {CHART_PATH} {settings} {additional_settings} --namespace={NAMESPACE}")
    return output, exit_code


def helm_agent_uninstall():
    output, exit_code = cmd(f"helm uninstall {RELEASE_NAME} {CHART_PATH} --namespace={NAMESPACE} --wait")
    return output, exit_code


def get_value_from_helm_template(helm_output, resource_kind, resource_name, field_path_str):
    keys = field_path_str.split('.')
    documents = list(yaml.safe_load_all(helm_output))
    for doc in documents:
        if doc.get("kind") == resource_kind and doc.get("metadata", {}).get("name") == resource_name:
            temp = doc
            for key in keys:
                if key.isdigit():
                    temp = temp[int(key)]
                else:
                    temp = temp[key]
            return temp
    raise ValueError(f"Resource of kind {resource_kind} and name {resource_name} not found in helm output.")


def check_pods_running(kube_client, label_selector):
    pods = kube_client.list_pod_for_all_namespaces(label_selector=label_selector)
    if len(pods.items) == 0:
        assert False, f"No pods found with label selector {label_selector}"
    for pod in pods.items:
        for container_status in pod.status.container_statuses:
            assert container_status.ready, f"Container {container_status.name} in Pod {pod.metadata.name} is not ready"


def create_namespace(kube_client, namespace_name):
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


def create_komodor_uid(kind, name, namespace=NAMESPACE, cluster_name=CLUSTER_NAME):
    return f"{kind}|{cluster_name}|{namespace}|{name}"


def query_resources_api(url):
    payload={}
    headers = {
        'Accept': 'application/json',
        'x-api-key': API_KEY
    }

    response = requests.request("GET", url, headers=headers, data=payload)
    return response

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


def test_helm_installation(setup_cluster):
    output, exit_code = helm_agent_install()
    assert exit_code == 0, "helm install failed, output: {}".format(output)


def test_all_pods_are_running_in_chart(setup_cluster, kube_client):
    output, exit_code = helm_agent_install()
    assert exit_code == 0, "helm install failed, output: {}".format(output)

    check_pods_running(kube_client, 'app.kubernetes.io/name=k8s-watcher')
    check_pods_running(kube_client, 'app.kubernetes.io/name=k8s-watcher-daemon')


def test_get_configmap_from_resources_api(setup_cluster):
    output, exit_code = helm_agent_install()
    kuid = create_komodor_uid("configmap", "k8s-watcher-config")
    url = f"{BE_BASE_URL}/resources/api/v1/configurations/config-maps/events/search?komodorUids={kuid}&limit=1&fields=clusterName&order=DESC"

    response = query_resources_api(url)

    assert response.status_code == 200, f"Failed to get configmap from resources api, response: {response}"
    assert len(response.json()['data']) > 0, f"Failed to get configmap from resources api, response: {response}"
    assert response.json()['data'][0]['clusterName'] == CLUSTER_NAME, f"Wrong configmap returned from resources api, response: {response}"


def test_get_network_mapper_from_resources_api(setup_cluster):
    namespace = "client-namespace"
    deployment_name = "nc-client"

    output, exit_code = helm_agent_install()
    assert exit_code == 0, "Agent installation failed, output: {}".format(output)

    kuid = create_komodor_uid("Deployment", deployment_name, namespace)
    url = f"{BE_BASE_URL}/resources/api/v1/network-maps/graph?clusterNames={CLUSTER_NAME}&namespaces={namespace}&komodorUids={kuid}"

    for i in range(120):  # ~2 minutes
        response = query_resources_api(url)
        if len(response.json()['nodes']) != 0:
            break
        time.sleep(1)
    else:
        assert False, f"Failed to get network map from resources api, response: {response.json()}"

    assert response.status_code == 200, f"Failed to get configmap from resources api, response: {response}"
    assert len(response.json()['nodes']) == 2, f"Expected two items in the 'nodes', response: {response}"
    assert len(response.json()['edges']) == 1, f"Expected one item in the 'edges', response: {response}"
    assert kuid in response.json()['nodes'], f"Expected to find {kuid} in the 'nodes', response: {response}"


def test_get_metrics_from_metrics_api():
    # Placeholder assertion, implement actual logic
    assert True


# apiKeysecret as apikey
def test_api_key_secret_as_api_key(setup_cluster, kube_client):
    cmd(f"kubectl delete namespace {NAMESPACE}")
    create_namespace(kube_client, NAMESPACE)
    create_secret(kube_client, NAMESPACE, "api-secret", {"apiKey": API_KEY_B64})
    output, exit_code = helm_agent_install(f"--set apiKeySecret=api-secret --set clusterName={CLUSTER_NAME}")
    assert exit_code == 0, f"helm install failed, output: {output}"

# tags and policies

# use an existing service_account with annotations

# use a proxy + customCA

# changing image repository -t

# changing pull policy - t

# providing an image pull secret for the service account -t

# disable installation capabilities (mapper, metrics) -t

# disable agent capabilities (helm, actions) -t

# define events.watchnamespace

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

# change kubernetes Agent settings (affinity, annotations, nodeSelector, tolerations, podAnnotations)

def test_override_deployment_tolerations():
    values_file = """
    components:
        komodorAgent:
          tolerations:
          - key: "gpu"
            operator: "Equal"
            value: "true"
            effect: "NoSchedule"
    """

    yaml_templates, exit_code = helm_agent_template(values_file=values_file)

    resp = get_value_from_helm_template(yaml_templates, "Deployment", f"{RELEASE_NAME}-k8s-watcher",
                                                       "spec.template.spec.tolerations")
    response_yaml = yaml.dump(resp)
    values_file_yaml = yaml.dump(yaml.safe_load(values_file))

    assert exit_code == 0, f"helm template failed, output: {yaml_templates}"
    assert response_yaml in values_file_yaml, f"Expected tolerations: {response_yaml} in values file {values_file_yaml}"

def test_override_deployment_node_selector():
    expected_value = "test_value"

    yaml_templates, exit_code = helm_agent_template(
        additional_settings=f"--set components.komodorAgent.nodeSelector.test_node_selector={expected_value}")

    actual_node_selector = get_value_from_helm_template(yaml_templates, "Deployment",
                                                        f"{RELEASE_NAME}-k8s-watcher",
                                                        "spec.template.spec.nodeSelector.test_node_selector")

    assert exit_code == 0, f"helm template failed, output: {yaml_templates}"
    assert actual_node_selector == expected_value, f"Expected deployment annotation to be {expected_value}, got {actual_node_selector}"


def test_override_deployment_annotations():
    expected_value = "test_value"

    yaml_templates, exit_code = helm_agent_template(
        additional_settings=f"--set components.komodorAgent.annotations.test={expected_value}")

    actual_deployment_annotation = get_value_from_helm_template(yaml_templates, "Deployment",
                                                                f"{RELEASE_NAME}-k8s-watcher",
                                                                "metadata.annotations.test")

    assert exit_code == 0, f"helm template failed, output: {yaml_templates}"
    assert actual_deployment_annotation == expected_value, f"Expected deployment annotation to be {expected_value}, got {actual_deployment_annotation} "


def test_override_deployment_affinity():
    values_file = """
    components:
        komodorAgent:
          affinity:
            nodeAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                - matchExpressions:
                  - key: kubernetes.io/e2e-az-name
                    operator: In
                    values:
                    - e2e-az1
                    - e2e-az2
    """

    yaml_templates, exit_code = helm_agent_template(values_file=values_file)

    resp = get_value_from_helm_template(yaml_templates, "Deployment", f"{RELEASE_NAME}-k8s-watcher",
                                                       "spec.template.spec.affinity")
    values_dict = yaml.load(values_file)

    assert exit_code == 0, f"helm template failed, output: {yaml_templates}"
    assert not is_subset_dict(resp, values_dict), f"Expected affinity {resp} in values file {values_dict}"


def test_override_image_tag():
    test_image_tag = "13"
    yaml_templates, exit_code = helm_agent_template(
        additional_settings=f"--set components.komodorAgent.networkMapper.image.tag={test_image_tag}")
    mapper_tag_value = get_value_from_helm_template(yaml_templates, "Deployment", f"{RELEASE_NAME}-k8s-watcher",
                                                    "spec.template.spec.containers.1.image")

    assert exit_code == 0, f"helm template failed, output: {yaml_templates}"
    assert test_image_tag in mapper_tag_value, f"Expected image name {mapper_tag_value} in watcher image value {test_image_tag}"


def test_override_image_name():
    test_image_name = "other-image-name"
    yaml_templates, exit_code = helm_agent_template(
        additional_settings=f"--set components.komodorAgent.watcher.image.name={test_image_name}")
    watcher_image_value = get_value_from_helm_template(yaml_templates, "Deployment", f"{RELEASE_NAME}-k8s-watcher",
                                                       "spec.template.spec.containers.2.image")

    assert exit_code == 0, f"helm template failed, output: {yaml_templates}"
    assert test_image_name in watcher_image_value, f"Expected image name {test_image_name} in watcher image value {watcher_image_value}"
