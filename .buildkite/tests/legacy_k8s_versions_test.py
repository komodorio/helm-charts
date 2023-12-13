import pytest
import json
from config import API_KEY_B64, NAMESPACE, RELEASE_NAME
from helpers.utils import cmd, get_filename_as_cluster_name
from helpers.helm_helper import helm_agent_install,  get_yaml_from_helm_template
from helpers.kubernetes_helper import get_pod_logs, find_pod_name_by_deployment, look_for_errors_in_pod_log
from fixtures import setup_cluster, kube_client, cleanup_agent_from_cluster

CLUSTER_NAME = get_filename_as_cluster_name(__file__)


@pytest.mark.parametrize("setup_cluster", ["1.25.11", "1.23.17"], indirect=True)
def test_agent_on_legacy_k8s_versions(setup_cluster, kube_client):
    output, exit_code = helm_agent_install(CLUSTER_NAME)
    assert exit_code == 0, "helm install failed, output: {}".format(output)

    deployment_name = f"{RELEASE_NAME}-komodor-agent"
    pod_name = find_pod_name_by_deployment(deployment_name, NAMESPACE)

    look_for_errors_in_pod_log(pod_name, "k8s-watcher")




