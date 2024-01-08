import pytest

from config import RELEASE_NAME
from helpers.helm_helper import get_yaml_from_helm_template
from helpers.utils import get_filename_as_cluster_name

CLUSTER_NAME = get_filename_as_cluster_name(__file__)


def test_override_deployment_pod_annotations():
    set_path = "components.komodorAgent.podAnnotations.test"
    value = "test_value"
    set_command = f"{set_path}={value}"

    deployment_name = f"{RELEASE_NAME}-komodor-agent"
    pod_annotations = get_yaml_from_helm_template(set_command, "Deployment", deployment_name,
                                                  "spec.template.metadata.annotations.test")

    assert pod_annotations == value, f"Expected {value} in pod annotations {pod_annotations}"


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

    deployment_name = f"{RELEASE_NAME}-komodor-agent"
    deployment_tolerations = get_yaml_from_helm_template("test=test", "Deployment", deployment_name,
                                                         "spec.template.spec.tolerations", values_file=values_file)

    assert deployment_tolerations[0][
               "key"] == "gpu", f"Expected gpu in deployment tolerations {deployment_tolerations}"


def test_override_deployment_node_selector():
    set_path = "components.komodorAgent.nodeSelector.test_node_selector"
    value = "test_node_selector"
    set_command = f"{set_path}={value}"

    deployment_name = f"{RELEASE_NAME}-komodor-agent"
    pod_annotations = get_yaml_from_helm_template(set_command, "Deployment", deployment_name,
                                                  "spec.template.spec.nodeSelector.test_node_selector")

    assert pod_annotations == value, f"Expected {value} in pod annotations {pod_annotations}"


def test_override_deployment_annotations():
    set_path = "components.komodorAgent.annotations.test"
    value = "test"
    set_command = f"{set_path}={value}"

    deployment_name = f"{RELEASE_NAME}-komodor-agent"
    deployment_annotations = get_yaml_from_helm_template(set_command, "Deployment", deployment_name,
                                                         "metadata.annotations.test")

    assert deployment_annotations == value, f"Expected {value} in pod annotations {deployment_annotations}"


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

    deployment_name = f"{RELEASE_NAME}-komodor-agent"
    deployment_affinity = get_yaml_from_helm_template("test=test", "Deployment", deployment_name,
                                                      "spec.template.spec.affinity", values_file=values_file)

    assert deployment_affinity is not None, f"Expected affinity in deployment {deployment_affinity}"


@pytest.mark.parametrize(
    "component, container_index",
    [
        ("watcher", "1"),
        ("supervisor", "2"),
    ]
)
def test_extra_env_vars(component, container_index):
    values_file = f"""
    components:
      komodorAgent:
        {component}:
          extraEnvVars:
            - name: "TEST_ENV_VAR"
              value: "test"
    """

    deployment_name = f"{RELEASE_NAME}-komodor-agent"
    deployment_env_vars = get_yaml_from_helm_template("test=test", "Deployment", deployment_name,
                                                      f"spec.template.spec.containers.{container_index}.env",
                                                      values_file=values_file)

    assert deployment_env_vars[-1][
               "name"] == "TEST_ENV_VAR", f"Expected TEST_ENV_VAR in deployment env vars {deployment_env_vars}"
