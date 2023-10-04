import yaml
from fixtures import setup_cluster, kube_client
from helpers.utils import cmd, get_filename_as_cluster_name
from deepdiff import DeepDiff
from config import API_KEY, API_KEY_B64, RELEASE_NAME, NAMESPACE, BE_BASE_URL
from helpers.helm_helper import (helm_agent_install, helm_agent_template, get_value_from_helm_template,
                                 validate_template_value_by_values_path)

CLUSTER_NAME = get_filename_as_cluster_name(__file__)


def test_override_deployment_pod_annotations():
    test_value = "test_value"
    set_path = "components.komodorAgent.podAnnotations.test"
    template_path = "spec.template.metadata.annotations.test"

    validate_template_value_by_values_path(test_value, set_path, "Deployment", f"{RELEASE_NAME}-k8s-watcher",
                                           template_path)


def test_override_deployment_tolerations():
    values_file = """
    components:
        komodorAgent:
          tolerations:
          - key: "gpu"
            operator: "Equal"
            value: "true"
            effect: "NoSchedule"
    """

    yaml_templates, exit_code = helm_agent_template("test", values_file=values_file)
    resp = get_value_from_helm_template(yaml_templates, "Deployment", f"{RELEASE_NAME}-k8s-watcher",
                                        "spec.template.spec.tolerations".split("."))
    response_yaml = yaml.safe_load(resp)
    values_dict = yaml.safe_load(values_file)
    validate_diff = DeepDiff(values_dict['components']['komodorAgent']['tolerations'], response_yaml)

    assert exit_code == 0, f"helm template failed, output: {yaml_templates}"
    assert validate_diff == {}, f"Expected affinity: {values_dict['components']['komodorAgent']['tolerations']} in values file {response_yaml}"


def test_override_deployment_node_selector():
    test_value = "test_node_selector"
    set_path = "components.komodorAgent.nodeSelector.test_node_selector"
    template_path = "spec.template.spec.nodeSelector.test_node_selector"

    validate_template_value_by_values_path(test_value, set_path, "Deployment", f"{RELEASE_NAME}-k8s-watcher",
                                           template_path)

def test_override_deployment_annotations():
    test_value = "test_value"
    set_path = "components.komodorAgent.annotations.test"
    template_path = "metadata.annotations.test"

    validate_template_value_by_values_path(test_value, set_path, "Deployment", f"{RELEASE_NAME}-k8s-watcher",
                                           template_path)

def test_override_deployment_affinity():
    values_file = """
    components:
        komodorAgent:
          affinity:
            nodeAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                - matchExpressions:
                  - key: kubernetes.io/e2e-az-name
                    operator: In
                    values:
                    - e2e-az1
                    - e2e-az2
    """

    yaml_templates, exit_code = helm_agent_template("test", values_file=values_file)
    resp = get_value_from_helm_template(yaml_templates, "Deployment", f"{RELEASE_NAME}-k8s-watcher",
                                                       "spec.template.spec.affinity".split("."))
    response_yaml = yaml.safe_load(resp)
    values_dict = yaml.safe_load(values_file)
    validate_diff = DeepDiff(values_dict['components']['komodorAgent']['affinity'], response_yaml)

    assert exit_code == 0, f"helm template failed, output: {yaml_templates}"
    assert validate_diff == {}, f"Expected affinity: {values_dict['components']['komodorAgent']['affinity']} in values file {response_yaml}"

