import time

import pytest

from config import NAMESPACE, RELEASE_NAME
from fixtures import (
    setup_cluster,
    kube_client,
    cleanup_agent_from_cluster,
)  # noqa # pylint: disable=unused-import
from helpers.helm_helper import helm_agent_install, get_yaml_from_helm_template
from helpers.kubernetes_helper import (
    create_namespace,
    wait_for_pod_ready,
    read_file_from_pod,
)
from helpers.utils import cmd, get_filename_as_cluster_name

CLUSTER_NAME = get_filename_as_cluster_name(__file__)
PROXY_POD_NAME = "mitm"
PROXY_NAMESPACE = "proxy"
PROXY_URL = "http://mitm.proxy:8080"
KOMODOR_SERVICE_URLS = [
    "https://app.komodor.com/api/v1/agents",
    "https://app.komodor.com/api/v1/agents/remote-config",
    "https://app.komodor.com/k8s-events",
    "https://app.komodor.com/k8s-events/event",
    "https://app.komodor.com/metrics-collector",
    "https://app.komodor.com/agent-task-manager",
]


@pytest.mark.flaky(reruns=3)
def test_use_proxy_and_custom_ca(setup_cluster, kube_client):
    def extract_root_ca(pem_file_path, output_file_path):
        with open(pem_file_path, "r") as file:
            pem_data = file.read()

        certificates = pem_data.split("-----END RSA PRIVATE KEY-----")
        # Get the last certificate, ignoring any trailing whitespace or empty strings
        root_ca_certificate = next(
            (cert for cert in reversed(certificates) if cert.strip()), None
        )

        if root_ca_certificate:
            root_ca_certificate = root_ca_certificate.strip() + "\n"
            with open(output_file_path, "w") as file:
                file.write(root_ca_certificate)
            print(f"Root CA certificate extracted to {output_file_path}")
            return True

        print("No certificate found")
        return False

    #################
    # Starting here #
    #################
    proxy_ready = wait_for_pod_ready("mitm", "proxy")
    assert proxy_ready, "Failed to wait for mitmproxy pod to be ready"

    root_ca_pem = "/tmp/mitmproxy-ca.pem"
    output, exit_code = cmd(
        f"kubectl cp -n proxy  mitm:root/.mitmproxy/mitmproxy-ca.pem  {root_ca_pem}"
    )
    assert exit_code == 0, f"Failed to copy ca from mitmproxy pod, output: {output}"

    # Extract ca from pem file
    root_ca_path = root_ca_pem.replace(".pem", ".crt")
    ca_extracted = extract_root_ca(root_ca_pem, root_ca_path)
    assert ca_extracted, f"Failed to extract root ca from {root_ca_pem}"

    # create ns and secret
    create_namespace(kube_client)
    secret_name = "mitmproxysecret"
    cmd(
        f"kubectl create secret generic {secret_name}  --from-file={root_ca_path} -n {NAMESPACE}"
    )

    # TODO: Find a way to add networkpolicy to prevent the agent from reaching the internet directly.
    #  (at the moment it's not possible natively in kind)

    # install with proxy and custom ca
    output, exit_code = helm_agent_install(
        CLUSTER_NAME,
        additional_settings=f"--set proxy.enabled=true "
        f"--set proxy.http={PROXY_URL} "
        f"--set proxy.https={PROXY_URL} "
        f"--set customCa.enabled=true "
        f"--set customCa.secretName={secret_name} ",
    )

    assert exit_code == 0, f"Agent installation failed, output: {output}"

    verify_communication_through_proxy()


def verify_communication_through_proxy():
    attempts = 12
    success = False
    for attempt in range(attempts):
        try:
            mitm_access_log = read_file_from_pod(
                PROXY_POD_NAME, PROXY_NAMESPACE, "/tmp/accessed_urls.log"
            )
            if mitm_access_log:
                for url in KOMODOR_SERVICE_URLS:
                    assert (
                        url in mitm_access_log
                    ), f"Failed to find {url} in proxy access log"
                success = True
                break
        except AssertionError as e:
            print(f"Attempt {attempt + 1} failed: {e}")

        if attempt < attempts - 1:
            time.sleep(10)

    assert (
        success
    ), f"Failed to read mitmproxy access log or find URLs after {attempts} attempts"


@pytest.fixture(scope="module")
def proxy_values():
    return """
    proxy:
      enabled: true
      http: "http://mitm.proxy:8080"
      https: "https://mitm.proxy:8080"
    """


@pytest.mark.parametrize(
    "deployment_suffix, resource_kind, container_path",
    [
        ("-komodor-agent", "Deployment", "spec.template.spec.containers"),
        ("-komodor-agent-daemon", "DaemonSet", "spec.template.spec.containers"),
        ("-komodor-agent-daemon", "DaemonSet", "spec.template.spec.initContainers"),
    ],
)
def test_proxy_envroinment_vars_are_set(
    deployment_suffix, resource_kind, container_path, proxy_values
):
    deployment_name = f"{RELEASE_NAME}{deployment_suffix}"
    exclude_containers = ["network-mapper", "network-sniffer-test-template"]
    expected_env_vars = {
        "KOMOKW_HTTP_PROXY": "http://mitm.proxy:8080",
        "KOMOKW_HTTPS_PROXY": "https://mitm.proxy:8080",
    }

    result = get_yaml_from_helm_template(
        "test=test",
        resource_kind,
        deployment_name,
        container_path,
        values_file=proxy_values,
    )

    for container in result:
        if container["name"] in exclude_containers:
            continue

        env_vars = {
            env["name"]: env["value"]
            for env in container.get("env", [])
            if "value" in env
        }
        if container["name"] == "metrics":
            assert "KOMODOR_HTTP_PROXY" in env_vars
            continue
        
        for env_name, expected_value in expected_env_vars.items():

            assert (
                env_name in env_vars
            ), f"Expected {env_name} in container {container['name']}"
            assert (
                env_vars[env_name] == expected_value
            ), f"Expected {env_name} to be {expected_value} in container {container['name']}"
