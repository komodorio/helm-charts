from config import API_KEY_B64, NAMESPACE, RELEASE_NAME
from helpers.utils import cmd, get_filename_as_cluster_name
from helpers.helm_helper import helm_agent_install, validate_template_value_by_values_path
from helpers.kubernetes_helper import create_namespace, create_secret, create_service_account
from fixtures import setup_cluster, kube_client, cleanup_agent_from_cluster

CLUSTER_NAME = get_filename_as_cluster_name(__file__)


def test_override_image_tag():
    test_value = "13"
    set_path = "components.komodorAgent.networkMapper.image.tag"
    template_path = "spec.template.spec.containers.1.image"

    validate_template_value_by_values_path(test_value, set_path, "Deployment",
                                           f"{RELEASE_NAME}-komodor-agent", template_path)


def test_override_image_name():
    test_value = "other-image-name"
    set_path = "components.komodorAgent.watcher.image.name"
    template_path = "spec.template.spec.containers.2.image"

    validate_template_value_by_values_path(test_value, set_path, "Deployment",
                                           f"{RELEASE_NAME}-komodor-agent", template_path)


# apiKeysecret as apikey
def test_api_key_secret_as_api_key(setup_cluster, kube_client):
    cmd(f"kubectl delete namespace {NAMESPACE}")
    create_namespace(kube_client, NAMESPACE)
    create_secret(kube_client, NAMESPACE, "api-secret", {"apiKey": API_KEY_B64})
    output, exit_code = helm_agent_install(None, f"--set apiKeySecret=api-secret --set clusterName={CLUSTER_NAME}")
    assert exit_code == 0, f"helm install failed, output: {output}"


# use an existing service_account with annotations
def test_use_existing_service_account(setup_cluster, kube_client):
    create_namespace(kube_client, NAMESPACE)
    service_account_name = "test-service-account"
    create_service_account(service_account_name, NAMESPACE)

    output, exit_code = helm_agent_install(CLUSTER_NAME, additional_settings=f"--set serviceAccount.create=false "
                                                               f"--set serviceAccount.name={service_account_name}")
    assert exit_code == 0, f"Agent installation failed, output: {output}"
