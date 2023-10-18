import pytest
from kubernetes import client, config
from helpers.utils import cmd
from helpers.helm_helper import helm_agent_uninstall
from config import NAMESPACE


@pytest.fixture(scope='module')
def setup_cluster(request):
    cluster_name = "test"

    node = ""
    if hasattr(request, 'param'):
        node = f"--image=kindest/node:v{request.param}"

    cmd(f"kind create cluster --name {cluster_name} {node} --wait 5m")
    config.load_kube_config(context=f"kind-{cluster_name}")
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
    cmd(f"kubectl delete namespace {NAMESPACE}")
