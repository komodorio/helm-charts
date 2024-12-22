import time

import yaml

from config import BE_BASE_URL, NAMESPACE, RELEASE_NAME, API_KEY
from fixtures import setup_cluster, cleanup_agent_from_cluster  # noqa # pylint: disable=unused-import
from helpers.helm_helper import helm_agent_install, get_yaml_from_helm_template
from helpers.komodor_helper import query_backend, create_komodor_uid
from helpers.kubernetes_helper import find_pod_name_by_deployment
from helpers.utils import get_filename_as_cluster_name

CLUSTER_NAME = get_filename_as_cluster_name(__file__)


def wait_for_metrics(container_name, pod_name):
    start_time = int(time.time() * 1000) - 120_000  # two minutes ago
    for _ in range(120):  # ~2 minutes
        end_time = int(time.time() * 1000)
        url = (f"{BE_BASE_URL}/metrics/api/v1/fullMetrics/pod/{container_name}/cpu?"
               f"clusterName={CLUSTER_NAME}&namespace={NAMESPACE}&podName={pod_name}&"
               f"fromEpoch={start_time}&pageSize=1&timeWindow=1d&endTime={end_time}&"
               f"aggregationTypes=p96&aggregationTypes=p99")
        response = query_backend(url, agent_api_key=False)
        if response.json().get('request'):
            return response
        time.sleep(1)
    return None


def verify_metrics_response(response):
    assert response.status_code == 200, f"Failed to get metrics from metrics api, response: {response}"
    assert response.json().get('request'), f"Expected at least one item in the 'request', response: {response}"
    assert response.json().get(
        'avgUtilization'), f"Expected at least one item in the 'avgUtilization', response: {response}"


def test_get_metrics(setup_cluster):
    output, exit_code = helm_agent_install(CLUSTER_NAME)
    assert exit_code == 0, f"Agent installation failed, output: {output}"

    deployment_name = f"{RELEASE_NAME}-komodor-agent"
    pod_name = find_pod_name_by_deployment(deployment_name, NAMESPACE)
    assert pod_name, "Failed to find pod by deployment name"

    response = wait_for_metrics("k8s-watcher", pod_name)
    assert response, "Failed to get metrics from metrics API"

    verify_metrics_response(response)


##################
# Network-Mapper #
##################


def test_network_mapper(setup_cluster):
    namespace = "client-namespace"
    deployment_name = "nc-client"
    start_time = int(time.time() * 1000)
    end_time = int(time.time() * 1000) + 180_000  # three minutes from now

    output, exit_code = helm_agent_install(CLUSTER_NAME, f'--set apiKey={API_KEY} --set clusterName={CLUSTER_NAME} --create-namespace --set capabilities.networkMapper=true')
    assert exit_code == 0, "Agent installation failed, output: {}".format(output)

    kuid = create_komodor_uid("Deployment", deployment_name, namespace, CLUSTER_NAME)
    url = (f"{BE_BASE_URL}/resources/api/v1/network-maps/graph"
           f"?fromEpoch={start_time}"
           f"&toEpoch={end_time}"
           f"&clusterNames={CLUSTER_NAME}"
           f"&namespaces={namespace}"
           f"&komodorUids={kuid}")

    for i in range(180):  # ~3 minutes
        response = query_backend(url)
        if response.status_code == 200 and len(response.json()['nodes']) != 0:
            break
        time.sleep(1)
    else:
        assert False, f"Failed to get network map from resources api, response: {response.json()}"

    assert response.status_code == 200, f"Failed to get configmap from resources api, response: {response}"
    assert len(response.json()['nodes']) == 2, f"Expected two items in the 'nodes', response: {response}"
    assert len(response.json()['edges']) == 1, f"Expected one item in the 'edges', response: {response}"
    assert kuid in response.json()['nodes'], f"Expected to find {kuid} in the 'nodes', response: {response}"


def test_disable_helm_capabilities():
    set_path = "capabilities.helm.enabled"
    value = "false"
    set_command = f"{set_path}={value}"

    configmap_name = "komodor-agent-config"
    configmap_data = get_yaml_from_helm_template(set_command, "ConfigMap", configmap_name, ["data"])

    agent_configuration_yaml = yaml.safe_load(configmap_data['komodor-k8s-watcher.yaml'])
    assert agent_configuration_yaml[
               'enableHelm'] == False, f"Expected enableHelm to be false, got: {agent_configuration_yaml['enableHelm']} "


def test_disable_actions_capabilities():
    set_path = "capabilities.actions"
    value = "false"
    set_command = f"{set_path}={value}"

    configmap_name = "komodor-agent-config"
    configmap_data = get_yaml_from_helm_template(set_command, "ConfigMap", configmap_name, ["data"])

    agent_configuration_yaml = yaml.safe_load(configmap_data['komodor-k8s-watcher.yaml'])

    assert not agent_configuration_yaml['actions'][
        'basic'], f"Expected actions.basic to be false, got: {agent_configuration_yaml['actions']['basic']}"
    assert not agent_configuration_yaml['actions'][
        'advanced'], f"Expected actions.basic to be false, got: {agent_configuration_yaml['actions']['basic']}"
    assert not agent_configuration_yaml['actions'][
        'podExec'], f"Expected actions.basic to be false, got: {agent_configuration_yaml['actions']['basic']}"
    assert not agent_configuration_yaml['actions'][
        'portforward'], f"Expected actions.basic to be false, got: {agent_configuration_yaml['actions']['basic']}"


def test_log_redact_multiline():
    values_file = '''
  capabilities:
    logs:
      logsNamespacesDenylist: 
        - 'kube-system'
        - 'banana'
      redact:
        - "password"
        - "session"
    '''

    configmap_name = "komodor-agent-config"
    configmap_data = get_yaml_from_helm_template("test=test", "ConfigMap", configmap_name,
                                                 ["data"], values_file=values_file)




    agent_configuration_yaml = yaml.safe_load(configmap_data['komodor-k8s-watcher.yaml'])


    assert len(agent_configuration_yaml['redactLogs']) == 2, f"Expected two items in the 'redactLogs', got: {agent_configuration_yaml['redactLogs']}"
    assert len(agent_configuration_yaml['logsNamespacesDenylist']) == 2, f"Expected two items in the 'logsNamespacesDenylist', got: {agent_configuration_yaml['logsNamespacesDenylist']}"

