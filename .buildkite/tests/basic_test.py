import pytest
import time
from fixtures import setup_cluster, kube_client, cleanup_agent_from_cluster
from helpers.utils import get_filename_as_cluster_name
import helpers.kubernetes_helper as kubernetes_helper
from helpers.komodor_helper import create_komodor_uid, query_backend
from config import API_KEY, BE_BASE_URL, NAMESPACE
from helpers.helm_helper import helm_agent_install

CLUSTER_NAME = get_filename_as_cluster_name(__file__)


@pytest.mark.parametrize(
    "settings, missing_value",
    [
        (f"--set clusterName={CLUSTER_NAME}", "apiKey"),
        (f"--set apiKey={API_KEY}", "clusterName")
    ]
)
def test_dont_provide_required_values(setup_cluster, settings, missing_value):
    output, exit_code = helm_agent_install(None, settings)

    assert f"{missing_value} is a required" in output, f"Expecting to fail installation in case {missing_value} was not provided, output: {output}"
    assert exit_code != 0, f"helm install should fail, output: {output}"


def test_helm_installation(setup_cluster, kube_client):
    output, exit_code = helm_agent_install(CLUSTER_NAME)
    assert exit_code == 0, "helm install failed, output: {}".format(output)

    last_exception = None
    for _ in range(10):
        try:
            kubernetes_helper.check_pods_running(kube_client, 'app.kubernetes.io/name=komodor-agent')
            kubernetes_helper.check_pods_running(kube_client, 'app.kubernetes.io/name=komodor-agent-daemon')
            break
        except AssertionError as e:
            print("Waiting for pods to be ready")
            last_exception = e
            time.sleep(10)
    else:
        assert False, f"Pods are not ready: {last_exception}"


def test_get_configmap_from_resources_api(setup_cluster):
    output, exit_code = helm_agent_install(CLUSTER_NAME)
    assert exit_code == 0, f"Agent installation failed, output: {output}"

    kuid = create_komodor_uid("configmap", "komodor-agent-config", NAMESPACE, CLUSTER_NAME)
    url = f"{BE_BASE_URL}/resources/api/v1/configurations/config-maps/events/search?komodorUids={kuid}&limit=1&fields=clusterName&order=DESC"

    response = query_backend(url)

    assert response.status_code == 200, f"Failed to get configmap from resources api, response: {response}"
    assert len(response.json()['data']) > 0, f"Failed to get configmap from resources api, response: {response}"
    assert response.json()['data'][0]['clusterName'] == CLUSTER_NAME, f"Wrong configmap returned from resources api, response: {response}"

