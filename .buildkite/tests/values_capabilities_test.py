import time
from config import BE_BASE_URL, NAMESPACE, RELEASE_NAME
from helpers.utils import get_filename_as_cluster_name
from fixtures import setup_cluster, cleanup_agent_from_cluster
from helpers.helm_helper import helm_agent_install, validate_template_value_by_values_path, helm_agent_template, \
    get_value_from_helm_template
from helpers.komodor_helper import query_backend, create_komodor_uid
from helpers.kubernetes_helper import find_pod_name_by_deployment
import yaml

CLUSTER_NAME = get_filename_as_cluster_name(__file__)




def wait_for_metrics(container_name, pod_name):
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
    assert response.json().get(
        'avgUtilization'), f"Expected at least one item in the 'avgUtilization', response: {response}"


def test_get_metrics_from_metrics_api(setup_cluster):
    output, exit_code = helm_agent_install(CLUSTER_NAME)
    assert exit_code == 0, f"Agent installation failed, output: {output}"

    container_name = "k8s-watcher"
    deployment_name = f"{RELEASE_NAME}-{container_name}"
    pod_name = find_pod_name_by_deployment(deployment_name, NAMESPACE)
    assert pod_name, "Failed to find pod by deployment name"

    response = wait_for_metrics(container_name, pod_name)
    assert response, "Failed to get metrics from metrics API"

    verify_metrics_response(response)


##################
# Network-Mapper #
##################


def test_get_network_mapper_from_resources_api(setup_cluster):
    namespace = "client-namespace"
    deployment_name = "nc-client"

    output, exit_code = helm_agent_install(CLUSTER_NAME)
    assert exit_code == 0, "Agent installation failed, output: {}".format(output)

    kuid = create_komodor_uid("Deployment", deployment_name, namespace, CLUSTER_NAME)
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


def test_disable_helm_capabilities():
    test_value = "false"
    test_path = "capabilities.helm"

    yaml_templates, exit_code = helm_agent_template(additional_settings=f"--set {test_path}={test_value}")
    assert exit_code == 0, f"Failed to get helm template, output: {yaml_templates}"

    config_map_string = get_value_from_helm_template(yaml_templates, "ConfigMap", "komodor-agent-config", ["data"])
    helm_enabled_in_configmap = yaml.safe_load(yaml.safe_load(config_map_string)['komodor-k8s-watcher.yaml'])['enableHelm']
    assert not helm_enabled_in_configmap, f"Expected enableHelm to be false, got: {helm_enabled_in_configmap}"

def test_disable_actions_capabilities():
    test_value = "false"
    test_path = "capabilities.actions"

    yaml_templates, exit_code = helm_agent_template(additional_settings=f"--set {test_path}={test_value}")
    assert exit_code == 0, f"Failed to get helm template, output: {yaml_templates}"

    config_map_string = get_value_from_helm_template(yaml_templates, "ConfigMap", "komodor-agent-config", ["data"])
    agent_configuration_yaml = yaml.safe_load(yaml.safe_load(config_map_string)['komodor-k8s-watcher.yaml'])

    assert not agent_configuration_yaml['actions']['basic'], f"Expected actions.basic to be false, got: {agent_configuration_yaml['actions']['basic']}"
    assert not agent_configuration_yaml['actions']['advanced'], f"Expected actions.basic to be false, got: {agent_configuration_yaml['actions']['basic']}"
    assert not agent_configuration_yaml['actions']['podExec'], f"Expected actions.basic to be false, got: {agent_configuration_yaml['actions']['basic']}"
    assert not agent_configuration_yaml['actions']['portforward'], f"Expected actions.basic to be false, got: {agent_configuration_yaml['actions']['basic']}"
