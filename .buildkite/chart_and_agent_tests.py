import subprocess
import pytest
import os
import yaml
import requests
import base64
import time
from deepdiff import DeepDiff
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
    cmd(f"kubectl apply -f ./test-data")
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
            return yaml.dump(temp)
    raise ValueError(f"Resource of kind {resource_kind} and name {resource_name} not found in helm output.")


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


def validate_template_value_by_values_path(test_value, values_path, resource_type, resource_name, yaml_path):
    yaml_templates, exit_code = helm_agent_template(additional_settings=f"--set {values_path}={test_value}")
    actual_value = get_value_from_helm_template(yaml_templates, resource_type, resource_name, yaml_path)

    assert exit_code == 0, f"helm template failed, output: {yaml_templates}"
    assert test_value in actual_value, f"Expected {test_value} in value {actual_value}"


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

    response = query_backend(url)

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
        response = query_backend(url)
        if len(response.json()['nodes']) != 0:
            break
        time.sleep(1)
    else:
        assert False, f"Failed to get network map from resources api, response: {response.json()}"

    assert response.status_code == 200, f"Failed to get configmap from resources api, response: {response}"
    assert len(response.json()['nodes']) == 2, f"Expected two items in the 'nodes', response: {response}"
    assert len(response.json()['edges']) == 1, f"Expected one item in the 'edges', response: {response}"
    assert kuid in response.json()['nodes'], f"Expected to find {kuid} in the 'nodes', response: {response}"


def test_get_metrics_from_metrics_api(setup_cluster, kube_client):
    def wait_for_metrics():
        start_time = int(time.time() * 1000) - 120_000  # two minutes ago
        for _ in range(120):  # ~2 minutes
            end_time = int(time.time() * 1000)
            url = (f"{BE_BASE_URL}/metrics/api/v1/fullMetrics/pod/{container_name}/cpu?"
                   f"clusterName={CLUSTER_NAME}&namespace={NAMESPACE}&podName={pod_name}&"
                   f"fromEpoch={start_time}&pageSize=1&timeWindow=1d&endTime={end_time}&"
                   f"aggregationTypes=p96&aggregationTypes=p99")
            response = query_backend(url)
            if response.json().get('request'):
                return response
            time.sleep(1)
        return None

    def verify_metrics_response(response):
        assert response.status_code == 200, f"Failed to get metrics from metrics api, response: {response}"
        assert response.json().get('request'), f"Expected at least one item in the 'request', response: {response}"
        assert response.json().get('avgUtilization'), f"Expected at least one item in the 'avgUtilization', response: {response}"

    #######################
    # Starting here       #
    #######################
    output, exit_code = helm_agent_install()
    assert exit_code == 0, f"Agent installation failed, output: {output}"

    container_name = "k8s-watcher"
    deployment_name = f"{RELEASE_NAME}-{container_name}"
    pod_name = find_pod_name_by_deployment(deployment_name, NAMESPACE)
    assert pod_name, "Failed to find pod by deployment name"

    response = wait_for_metrics()
    assert response, "Failed to get metrics from metrics API"

    verify_metrics_response(response)


# apiKeysecret as apikey
def test_api_key_secret_as_api_key(setup_cluster, kube_client):
    cmd(f"kubectl delete namespace {NAMESPACE}")
    create_namespace(kube_client, NAMESPACE)
    create_secret(kube_client, NAMESPACE, "api-secret", {"apiKey": API_KEY_B64})
    output, exit_code = helm_agent_install(f"--set apiKeySecret=api-secret --set clusterName={CLUSTER_NAME}")
    assert exit_code == 0, f"helm install failed, output: {output}"

# tags and policies
# ToDo: Check with Mick


# use an existing service_account with annotations
def test_use_existing_service_account(setup_cluster, kube_client):
    create_namespace(kube_client, NAMESPACE)
    service_account_name = "test-service-account"
    create_service_account(service_account_name, NAMESPACE)

    output, exit_code = helm_agent_install(additional_settings=f"--set serviceAccount.create=false "
                                                               f"--set serviceAccount.name={service_account_name}")
    assert exit_code == 0, f"Agent installation failed, output: {output}"


# use a proxy + customCA
def test_use_proxy_and_custom_ca(setup_cluster, kube_client):
    def extract_root_ca(pem_file_path, output_file_path):
        with open(pem_file_path, 'r') as file:
            pem_data = file.read()

        certificates = pem_data.split('-----END RSA PRIVATE KEY-----')
        # Get the last certificate, ignoring any trailing whitespace or empty strings
        root_ca_certificate = next((cert for cert in reversed(certificates) if cert.strip()), None)

        if root_ca_certificate:
            root_ca_certificate = root_ca_certificate.strip() + "\n"
            with open(output_file_path, 'w') as file:
                file.write(root_ca_certificate)
            print(f'Root CA certificate extracted to {output_file_path}')
            return True

        print('No certificate found')
        return False

    #################
    # Starting here #
    #################
    proxy_ready = wait_for_pod_ready("mitm", "proxy")
    assert proxy_ready, "Failed to wait for mitmproxy pod to be ready"

    root_ca_pem = "/tmp/mitmproxy-ca.pem"
    output, exit_code = cmd(f"kubectl cp -n proxy  mitm:root/.mitmproxy/mitmproxy-ca.pem  {root_ca_pem}")
    assert exit_code == 0, f"Failed to copy ca from mitmproxy pod, output: {output}"

    # Extract ca from pem file
    root_ca_path = root_ca_pem.replace(".pem", ".crt")
    ca_extracted = extract_root_ca(root_ca_pem, root_ca_path)
    assert ca_extracted, f"Failed to extract root ca from {root_ca_pem}"

    # create ns and secret
    create_namespace(kube_client)
    secret_name = "mitmproxysecret"
    cmd(f"kubectl create secret generic {secret_name}  --from-file={root_ca_path} -n {NAMESPACE}")
    # install with proxy and custom ca
    output, exit_code = helm_agent_install(additional_settings=f"--set proxy.enabled=true "
                                                               f"--set proxy.http=http://mitm.proxy:8080 "
                                                               f"--set proxy.https=http://mitm.proxy:8080 "
                                                               f"--set customCa.enabled=true "
                                                               f"--set customCa.secretName={secret_name} ")

    assert exit_code == 0, f"Agent installation failed, output: {output}"

# changing image repository -t

# changing pull policy - t

# providing an image pull secret for the service account -t

# disable installation capabilities (mapper, metrics) -t

# disable agent capabilities (helm, actions) -t
# def test_disable_helm_capabilities():
#     test_value = "false"
#     set_path = "capabilities.helm"
#     template_path = "test"
#
#     # check configmap
#     validate_template_value_by_values_path(test_value, set_path, "ConfigMap", "k8s-watcher-config",
#                                            'data.komodor-k8s-watcher.yaml')
#     # check clusterRole
#     validate_template_value_by_values_path(test_value, set_path, "ClusterRole", "k8s-watcher",
#                                            template_path)

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

# change kubernetes Agent settings (affinity, annotations, nodeSelector, tolerations, podAnnotations)


def test_override_deployment_pod_annotations():
    test_value = "test_value"
    set_path = "components.komodorAgent.podAnnotations.test"
    template_path = "spec.template.metadata.annotations.test"

    validate_template_value_by_values_path(test_value, set_path, "Deployment", f"{RELEASE_NAME}-k8s-watcher",
                                           template_path)


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
    response_yaml = yaml.safe_load(resp)
    values_dict = yaml.safe_load(values_file)
    validate_diff = DeepDiff(values_dict['components']['komodorAgent']['tolerations'], response_yaml)

    assert exit_code == 0, f"helm template failed, output: {yaml_templates}"
    assert validate_diff == {}, f"Expected affinity: {values_dict['components']['komodorAgent']['tolerations']} in values file {response_yaml}"


def test_override_deployment_node_selector():
    test_value = "test_node_selector"
    set_path = "components.komodorAgent.nodeSelector.test_node_selector"
    template_path = "spec.template.spec.nodeSelector.test_node_selector"

    validate_template_value_by_values_path(test_value, set_path, "Deployment", f"{RELEASE_NAME}-k8s-watcher",
                                           template_path)

def test_override_deployment_annotations():
    test_value = "test_value"
    set_path = "components.komodorAgent.annotations.test"
    template_path = "metadata.annotations.test"

    validate_template_value_by_values_path(test_value, set_path, "Deployment", f"{RELEASE_NAME}-k8s-watcher",
                                           template_path)

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
    response_yaml = yaml.safe_load(resp)
    values_dict = yaml.safe_load(values_file)
    validate_diff = DeepDiff(values_dict['components']['komodorAgent']['affinity'], response_yaml)

    assert exit_code == 0, f"helm template failed, output: {yaml_templates}"
    assert validate_diff == {}, f"Expected affinity: {values_dict['components']['komodorAgent']['affinity']} in values file {response_yaml}"

def test_override_image_tag():
    test_value = "13"
    set_path = "components.komodorAgent.networkMapper.image.tag"
    template_path = "spec.template.spec.containers.1.image"

    validate_template_value_by_values_path(test_value, set_path, "Deployment", f"{RELEASE_NAME}-k8s-watcher", template_path)


def test_override_image_name():
    test_value = "other-image-name"
    set_path = "components.komodorAgent.watcher.image.name"
    template_path = "spec.template.spec.containers.2.image"

    validate_template_value_by_values_path(test_value, set_path, "Deployment", f"{RELEASE_NAME}-k8s-watcher", template_path)

