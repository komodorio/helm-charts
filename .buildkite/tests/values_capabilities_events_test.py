import time
import json
import pytest
from helpers.kubernetes_helper import rollout_restart_and_wait
from config import BE_BASE_URL
from fixtures import setup_cluster, cleanup_agent_from_cluster
from helpers.utils import cmd, get_filename_as_cluster_name
from helpers.helm_helper import helm_agent_install
from helpers.komodor_helper import create_komodor_uid, query_backend

CLUSTER_NAME = get_filename_as_cluster_name(__file__)


def query_events(namespace, deployment, start_time, end_time):
    kuid = create_komodor_uid("Deployment", deployment, namespace, CLUSTER_NAME)
    url = f"{BE_BASE_URL}/resources/api/v1/events/general?fromEpoch={start_time}&toEpoch={end_time}&komodorUids={kuid}"
    return query_backend(url)


@pytest.fixture
def install_agent(setup_cluster):
    def _install_agent(cluster_name, additional_settings):
        output, exit_code = helm_agent_install(cluster_name, additional_settings=additional_settings)
        assert exit_code == 0, f"Agent installation failed, output: {output}"
    return _install_agent


@pytest.fixture
def restart_deployment():
    def _restart_deployment(deployment, namespace):
        assert rollout_restart_and_wait(deployment, namespace), f"Failed to restart deployment {deployment} in namespace {namespace}"
    return _restart_deployment


@pytest.mark.parametrize(
    "watch_namespace, watch_deployment, un_watch_namespace, un_watch_deployment, additional_settings",
    [
        ("client-namespace", "nc-client", "server-namespace", "nc-server", "--set capabilities.events.watchNamespace=client-namespace"),
        ("server-namespace", "nc-server", "client-namespace", "nc-client", "--set capabilities.events.namespacesDenylist={client-namespace}")
    ],
    ids=["watch_namespace", "namespacesDenylist"]
)
@pytest.mark.flaky(reruns=3)
def test_namespace_behavior(
        setup_cluster, install_agent, restart_deployment,
        watch_namespace, watch_deployment, un_watch_namespace, un_watch_deployment, additional_settings):
    start_time = int(time.time() * 1000)
    end_time = int(time.time() * 1000) + 120_000  # two minutes from now

    # Install agent
    install_agent(CLUSTER_NAME, additional_settings)

    # Restart deployments
    restart_deployment(watch_deployment, watch_namespace)
    restart_deployment(un_watch_deployment, un_watch_namespace)

    # Verify events from watched namespace
    response = query_events(watch_namespace, watch_deployment, start_time, end_time)
    assert response.status_code == 200, f"Failed to get configmap from resources api, response: {response}"
    assert len(response.json()['event_deploy']) > 0, f"Failed to get event_deploy from resources api, response: {response}"

    # Verify that we dont get events from unwatched namespace
    response = query_events(un_watch_namespace, un_watch_deployment, start_time, end_time)
    assert response.status_code == 200, f"Failed to get configmap from resources api, response: {response}"
    assert len(response.json()['event_deploy']) == 0, f"Found events for un-watched namespace {un_watch_namespace}, response: {response.json()}"


@pytest.mark.flaky(reruns=3)
def test_redact_workload_names(setup_cluster):
    start_time = int(time.time() * 1000)
    end_time = start_time + 120_000  # two minutes from now
    deployment = "nc-server"
    namespace = "server-namespace"

    output, exit_code = helm_agent_install(CLUSTER_NAME, additional_settings="--set capabilities.events.redact={TOP_SECRET}")
    assert exit_code == 0, f"Agent installation failed, output: {output}"

    rollout_restart_and_wait(deployment, namespace)

    kuid = create_komodor_uid("Deployment", deployment, namespace, CLUSTER_NAME)
    url = (f"{BE_BASE_URL}/resources/api/v1/deploys/events/search"
           f"?fromEpoch={start_time}"
           f"&toEpoch={end_time}"
           f"&limit=1"
           f"&order=DESC"
           f"&komodorUids={kuid}")

    response = query_backend(url)

    assert response.status_code == 200, f"Failed to get configmap from resources api, response: {response}"
    assert len(response.json()['data']) > 0, f"Failed to get configmap from resources api, response: {response}"
    try:
        spec = response.json()["data"][0]["newSpec"]
        data = json.loads(spec)["spec"]["template"]["spec"]["containers"][0]["env"][0]["value"]
        assert "REDACTED:" in data, f"Failed to redact workload env, response: {response}"
    except:
        assert False, f"Failed to find expected redacted value, response: {response.json()}"
