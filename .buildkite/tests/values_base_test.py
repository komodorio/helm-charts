from config import API_KEY_B64, NAMESPACE, RELEASE_NAME
from helpers.utils import cmd, get_filename_as_cluster_name
from helpers.helm_helper import helm_agent_install,  get_yaml_from_helm_template
from helpers.kubernetes_helper import create_namespace, create_secret, create_service_account
from fixtures import setup_cluster, kube_client, cleanup_agent_from_cluster

CLUSTER_NAME = get_filename_as_cluster_name(__file__)


def test_override_image_tag():
    set_path = "components.komodorAgent.networkMapper.image.tag"
    value = "13"
    set_command = f"{set_path}={value}"

    deployment_name = f"{RELEASE_NAME}-komodor-agent"
    deployment_containers = get_yaml_from_helm_template(set_command, "Deployment", deployment_name, "spec.template.spec.containers")

    for container in deployment_containers:
        if container["name"] == "network-mapper":
            assert value in container["image"], f"Expected {value} in image {container['image']}"


def test_override_image_name():
    set_path = "components.komodorAgent.watcher.image.name"
    value = "other-image-name"
    set_command = f"{set_path}={value}"

    deployment_name = f"{RELEASE_NAME}-komodor-agent"
    deployment_containers = get_yaml_from_helm_template(set_command, "Deployment", deployment_name, "spec.template.spec.containers")

    for container in deployment_containers:
        if container["name"] == "k8s-watcher":
            assert value in container["image"], f"Expected {value} in image {container['image']}"




def test_api_key_from_secret(setup_cluster, kube_client):
    cmd(f"kubectl delete namespace {NAMESPACE}")
    create_namespace(kube_client, NAMESPACE)
    create_secret(kube_client, NAMESPACE, "api-secret", {"apiKey": API_KEY_B64})
    output, exit_code = helm_agent_install(None, f"--set apiKeySecret=api-secret --set clusterName={CLUSTER_NAME}")
    assert exit_code == 0, f"helm install failed, output: {output}"



def test_use_existing_service_account(setup_cluster, kube_client):
    create_namespace(kube_client, NAMESPACE)
    service_account_name = "test-service-account"
    create_service_account(service_account_name, NAMESPACE)

    output, exit_code = helm_agent_install(CLUSTER_NAME, additional_settings=f"--set serviceAccount.create=false "
                                                                             f"--set serviceAccount.name={service_account_name}")
    assert exit_code == 0, f"Agent installation failed, output: {output}"


def test_override_image_default_pull_policy():
    set_command = "pullPolicy=Always"

    deployment_name = f"{RELEASE_NAME}-komodor-agent"
    daemonset_name = f"{RELEASE_NAME}-komodor-agent-daemon"

    deployment_containers = get_yaml_from_helm_template(set_command, "Deployment", deployment_name, "spec.template.spec.containers")
    daemonset_containers = get_yaml_from_helm_template(set_command, "DaemonSet", daemonset_name, "spec.template.spec.containers")

    for container in deployment_containers:
        assert container[
                   "imagePullPolicy"] == "Always", f"imagePullPolicy is not set to: Always in deployment {deployment_name}"

    for container in daemonset_containers:
        assert container[
                   "imagePullPolicy"] == "Always", f"imagePullPolicy is not set to: Always in daemonset {daemonset_name}"


def test_image_pull_secret_for_service_account():
    set_path = "imagePullSecret"
    value = "other-image-name"
    set_command = f"{set_path}={value}"

    service_account_name = f'{RELEASE_NAME}-komodor-agent'
    image_pull_secret = get_yaml_from_helm_template(set_command, "ServiceAccount", service_account_name, "imagePullSecrets")

    assert image_pull_secret[0]["name"] == value, f"Expected {value} in imagePullSecrets {image_pull_secret[0]['name']}"