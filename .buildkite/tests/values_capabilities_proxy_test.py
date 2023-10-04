from config import NAMESPACE
from fixtures import setup_cluster, kube_client, cleanup_agent_from_cluster
from helpers.utils import cmd
from helpers.helm_helper import helm_agent_install
from helpers.kubernetes_helper import create_namespace,wait_for_pod_ready


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
