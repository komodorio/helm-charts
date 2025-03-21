import pytest

from config import RELEASE_NAME
from helpers.helm_helper import get_yaml_from_helm_template
from helpers.utils import get_filename_as_cluster_name

CLUSTER_NAME = get_filename_as_cluster_name(__file__)


@pytest.mark.parametrize("component_name, deployment_name_suffix", [
    ("komodorAgent", ""),
    ("komodorMetrics", "-metrics")])
def test_override_deployment_pod_annotations(component_name, deployment_name_suffix):
    set_path = f"components.{component_name}.podAnnotations.test"
    value = "test_value"
    set_command = f"{set_path}={value}"

    deployment_name = f"{RELEASE_NAME}-komodor-agent{deployment_name_suffix}"
    pod_annotations = get_yaml_from_helm_template(set_command, "Deployment", deployment_name,
                                                  "spec.template.metadata.annotations.test")

    assert pod_annotations == value, f"Expected {value} in pod annotations {pod_annotations}"


def run_label_test(set_path, value, deployment_name, resource_type):
    set_command = f"{set_path}={value}"
    results = get_yaml_from_helm_template(set_command, resource_type, deployment_name,
                                          "spec.template.metadata.labels.test")
    assert results == value, f"Expected {value} in pod labels {results}"


@pytest.mark.parametrize("set_path, value, deployment_name, resource_type", [
    ("components.komodorAgent.labels.test", "test_value", f"{RELEASE_NAME}-komodor-agent", "Deployment"),
    ("components.komodorDaemon.labels.test", "test_value", f"{RELEASE_NAME}-komodor-agent-daemon", "DaemonSet"),
    ("components.komodorDaemonWindows.labels.test", "test_value", f"{RELEASE_NAME}-komodor-agent-daemon-windows",
     "DaemonSet"),
    ("components.komodorMetrics.labels.test", "test_value", f"{RELEASE_NAME}-komodor-agent-metrics", "Deployment")
])
def test_user_labels(set_path, value, deployment_name, resource_type):
    run_label_test(set_path, value, deployment_name, resource_type)


@pytest.mark.parametrize("component_name, deployment_name_suffix", [
    ("komodorAgent", ""),
    ("komodorMetrics", "-metrics")])
def test_override_deployment_tolerations(component_name, deployment_name_suffix):
    values_file = f"""
    components:
        {component_name}:
          tolerations:
          - key: "gpu"
            operator: "Equal"
            value: "true"
            effect: "NoSchedule"
    """

    deployment_name = f"{RELEASE_NAME}-komodor-agent{deployment_name_suffix}"
    deployment_tolerations = get_yaml_from_helm_template("test=test", "Deployment", deployment_name,
                                                         "spec.template.spec.tolerations", values_file=values_file)

    assert deployment_tolerations[0][
               "key"] == "gpu", f"Expected gpu in deployment tolerations {deployment_tolerations}"


@pytest.mark.parametrize("component_name, deployment_name_suffix", [
    ("komodorAgent", ""),
    ("komodorMetrics", "-metrics")])
def test_override_deployment_node_selector(component_name, deployment_name_suffix):
    set_path = f"components.{component_name}.nodeSelector.test_node_selector"
    value = "test_node_selector"
    set_command = f"{set_path}={value}"

    deployment_name = f"{RELEASE_NAME}-komodor-agent{deployment_name_suffix}"
    pod_annotations = get_yaml_from_helm_template(set_command, "Deployment", deployment_name,
                                                  "spec.template.spec.nodeSelector.test_node_selector")

    assert pod_annotations == value, f"Expected {value} in pod annotations {pod_annotations}"


@pytest.mark.parametrize("component_name, deployment_name_suffix", [
    ("komodorAgent", ""),
    ("komodorMetrics", "-metrics")])
def test_override_deployment_annotations(component_name, deployment_name_suffix):
    set_path = f"components.{component_name}.annotations.test"
    value = "test"
    set_command = f"{set_path}={value}"

    deployment_name = f"{RELEASE_NAME}-komodor-agent{deployment_name_suffix}"
    deployment_annotations = get_yaml_from_helm_template(set_command, "Deployment", deployment_name,
                                                         "metadata.annotations.test")

    assert deployment_annotations == value, f"Expected {value} in pod annotations {deployment_annotations}"


@pytest.mark.parametrize("component_name, deployment_name_suffix", [
    ("komodorAgent", ""),
    ("komodorMetrics", "-metrics")])
def test_override_deployment_affinity(component_name, deployment_name_suffix):
    values_file = f"""
    components:
        {component_name}:
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

    deployment_name = f"{RELEASE_NAME}-komodor-agent{deployment_name_suffix}"
    deployment_affinity = get_yaml_from_helm_template("test=test", "Deployment", deployment_name,
                                                      "spec.template.spec.affinity", values_file=values_file)

    assert deployment_affinity is not None, f"Expected affinity in deployment {deployment_affinity}"


@pytest.mark.parametrize(
    "component, location, container, container_index, deployment_name_suffix",
    [
        ("komodorAgent", "containers", "watcher", "0", ""),
        ("komodorAgent", "containers", "supervisor", "1", ""),
        ("komodorMetrics", "containers", "metrics", "0", "-metrics"),
        ("komodorMetrics", "initContainers", "metricsInit", "0", "-metrics")
    ]
)
def test_extra_env_vars(component, location, container, container_index, deployment_name_suffix):
    values_file = f"""
    components:
      {component}:
        {container}:
          extraEnvVars:
            - name: "TEST_ENV_VAR"
              value: "test"
    """

    deployment_name = f"{RELEASE_NAME}-komodor-agent{deployment_name_suffix}"
    deployment_env_vars = get_yaml_from_helm_template("test=test", "Deployment", deployment_name,
                                                      f"spec.template.spec.{location}.{container_index}.env",
                                                      values_file=values_file)

    assert deployment_env_vars[-1][
               "name"] == "TEST_ENV_VAR", f"Expected TEST_ENV_VAR in deployment env vars {deployment_env_vars}"


@pytest.mark.parametrize("component_name, deployment_name_suffix", [
    ("komodorAgent", ""),
    ("komodorMetrics", "-metrics"),
    ("komodorDaemon", "")])
def test_override_security_context(component_name, deployment_name_suffix):
    values_file = f"""
    components:
      {component_name}:
        securityContext:
          runAsUser: 1000
          runAsGroup: 3000
          fsGroup: 2000
    """

    deployment_name = f"{RELEASE_NAME}-komodor-agent{deployment_name_suffix}"
    deployment_affinity = get_yaml_from_helm_template("test=test", "Deployment", deployment_name,
                                                      "spec.template.spec.securityContext", values_file=values_file)

    assert deployment_affinity is not None, f"Expected securityContext in deployment {deployment_affinity}"


@pytest.mark.parametrize("component_name, deployment_name_suffix, strategy_key, resource_kind", [
    ("komodorAgent", "", "strategy", "Deployment"),
    ("komodorMetrics", "-metrics", "strategy", "Deployment"),
    ("komodorDaemon", "-daemon", "updateStrategy", "DaemonSet"),
    ("komodorDaemonWindows", "-daemon-windows", "updateStrategy", "DaemonSet")])
def test_override_update_strategy(component_name, deployment_name_suffix, strategy_key, resource_kind):
    values_file = f"""
    components:
        {component_name}:
          {strategy_key}:
            type: RollingUpdate
            rollingUpdate:
              maxUnavailable: 10
              maxSurge: 10

    """

    deployment_name = f"{RELEASE_NAME}-komodor-agent{deployment_name_suffix}"
    deployment_strategy = get_yaml_from_helm_template("test=test", resource_kind, deployment_name,
                                                      f"spec.{strategy_key}", values_file=values_file)

    assert deployment_strategy["type"] == "RollingUpdate", f"Expected rollingUpdate in deployment tolerations {deployment_strategy}"
