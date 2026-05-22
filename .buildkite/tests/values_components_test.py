import pytest
from pathlib import Path

from config import RELEASE_NAME
from helpers.helm_helper import get_yaml_from_helm_template
from helpers.utils import get_filename_as_cluster_name

CLUSTER_NAME = get_filename_as_cluster_name(__file__)
HARDENED_VALUES = Path(__file__).parents[2] / "charts" / "komodor-agent" / "examples" / "hardened-values.yaml"


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


def run_label_test(set_path, value, deployment_name, resource_type, capability_to_enable = None):
    set_command = f"{set_path}={value}"
    if capability_to_enable:
        set_command += f" --set capabilities.{capability_to_enable}=true"
    results = get_yaml_from_helm_template(set_command, resource_type, deployment_name,
                                          "spec.template.metadata.labels.test")
    assert results == value, f"Expected {value} in pod labels {results}"


@pytest.mark.parametrize("set_path, value, deployment_name, resource_type, capability_to_enable", [
    ("components.komodorAgent.labels.test", "test_value", f"{RELEASE_NAME}-komodor-agent", "Deployment", None),
    ("components.komodorDaemon.labels.test", "test_value", f"{RELEASE_NAME}-komodor-agent-daemon", "DaemonSet", None),
    ("components.komodorDaemonWindows.labels.test", "test_value", f"{RELEASE_NAME}-komodor-agent-daemon-windows",
     "DaemonSet", None),
    ("components.komodorMetrics.labels.test", "test_value", f"{RELEASE_NAME}-komodor-agent-metrics", "Deployment", None),
    ("components.komodorKubectlProxy.labels.test", "test_value", f"{RELEASE_NAME}-komodor-agent-proxy", "Deployment", "kubectlProxy.enabled")
])
def test_user_labels(set_path, value, deployment_name, resource_type, capability_to_enable):
    run_label_test(set_path, value, deployment_name, resource_type, capability_to_enable)


@pytest.mark.parametrize("component_name, deployment_name_suffix, capability_to_enable", [
    ("komodorAgent", "", None),
    ("komodorMetrics", "-metrics", None),
    ("komodorKubectlProxy", "-proxy", "kubectlProxy.enabled")
])
def test_override_deployment_tolerations(component_name, deployment_name_suffix, capability_to_enable):
    values_file = f"""
    components:
        {component_name}:
          tolerations:
          - key: "gpu"
            operator: "Equal"
            value: "true"
            effect: "NoSchedule"
    """
    set_command = "test=test"
    if capability_to_enable:
        set_command += f" --set capabilities.{capability_to_enable}=true"

    deployment_name = f"{RELEASE_NAME}-komodor-agent{deployment_name_suffix}"
    deployment_tolerations = get_yaml_from_helm_template(set_command, "Deployment", deployment_name,
                                                         "spec.template.spec.tolerations", values_file=values_file)

    assert deployment_tolerations[0][
               "key"] == "gpu", f"Expected gpu in deployment tolerations {deployment_tolerations}"


@pytest.mark.parametrize("component_name, deployment_name_suffix, capability_to_enable", [
    ("komodorAgent", "", None),
    ("komodorMetrics", "-metrics", None),
    ("komodorKubectlProxy", "-proxy", "kubectlProxy.enabled")
])
def test_override_deployment_node_selector(component_name, deployment_name_suffix, capability_to_enable):
    set_path = f"components.{component_name}.nodeSelector.test_node_selector"
    value = "test_node_selector"
    set_command = f"{set_path}={value}"
    if capability_to_enable:
        set_command += f" --set capabilities.{capability_to_enable}=true"

    deployment_name = f"{RELEASE_NAME}-komodor-agent{deployment_name_suffix}"
    pod_annotations = get_yaml_from_helm_template(set_command, "Deployment", deployment_name,
                                                  "spec.template.spec.nodeSelector.test_node_selector")

    assert pod_annotations == value, f"Expected {value} in pod annotations {pod_annotations}"


@pytest.mark.parametrize("component_name, deployment_name_suffix, capability_to_enable", [
    ("komodorAgent", "", None),
    ("komodorMetrics", "-metrics", None),
    ("komodorKubectlProxy", "-proxy", "kubectlProxy.enabled")
])
def test_override_deployment_annotations(component_name, deployment_name_suffix, capability_to_enable):
    set_path = f"components.{component_name}.annotations.test"
    value = "test"
    set_command = f"{set_path}={value}"
    if capability_to_enable:
        set_command += f" --set capabilities.{capability_to_enable}=true"

    deployment_name = f"{RELEASE_NAME}-komodor-agent{deployment_name_suffix}"
    deployment_annotations = get_yaml_from_helm_template(set_command, "Deployment", deployment_name,
                                                         "metadata.annotations.test")

    assert deployment_annotations == value, f"Expected {value} in pod annotations {deployment_annotations}"


@pytest.mark.parametrize("component_name, deployment_name_suffix, capability_to_enable", [
    ("komodorAgent", "", None),
    ("komodorMetrics", "-metrics", None),
    ("komodorKubectlProxy", "-proxy", "kubectlProxy.enabled")
])
def test_override_deployment_affinity(component_name, deployment_name_suffix, capability_to_enable):
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
    set_command = "test=test"
    if capability_to_enable:
        set_command += f" --set capabilities.{capability_to_enable}=true"

    deployment_name = f"{RELEASE_NAME}-komodor-agent{deployment_name_suffix}"
    deployment_affinity = get_yaml_from_helm_template(set_command, "Deployment", deployment_name,
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

    assert  any(env_var["name"] == "TEST_ENV_VAR" for env_var in deployment_env_vars), f"Expected TEST_ENV_VAR in deployment env vars {deployment_env_vars}"

@pytest.mark.parametrize("component_name, resource_kind, deployment_name_suffix", [
    ("admissionController",       "Deployment", "-admission-controller")
])
def test_extra_volumes(component_name, resource_kind, deployment_name_suffix):
    values_file = f"""
    components:
      {component_name}:
        enabled: true
        extraVolumes:
          - volume:
              name: extra-volume
              emptyDir: {{}}
            volumeMount:
              name: extra-volume
              mountPath: /extra
    """
    set_command = "test=test"
    resource_name = f"{RELEASE_NAME}-komodor-agent{deployment_name_suffix}"
    volume_mounts = get_yaml_from_helm_template(set_command, resource_kind, resource_name,
                                                "spec.template.spec.containers.0.volumeMounts", values_file=values_file)
    volumes = get_yaml_from_helm_template(set_command, resource_kind, resource_name,
                                          "spec.template.spec.volumes", values_file=values_file)

    assert any(vm["name"] == "extra-volume" and vm["mountPath"] == "/extra" for vm in volume_mounts), \
        f"Expected extra-volume mount in container volumeMounts {volume_mounts}"

    assert any(v["name"] == "extra-volume" and "emptyDir" in v for v in volumes), \
        f"Expected extra-volume in pod volumes {volumes}"

@pytest.mark.parametrize("component_name, resource_kind, deployment_name_suffix, capability_to_enable", [
    ("komodorAgent",       "Deployment", "",       None),
    ("komodorMetrics",     "Deployment", "-metrics", None),
    ("komodorDaemon",      "DaemonSet",  "-daemon", None),
    ("admissionController","Deployment", "-admission-controller", "admissionController.enabled"),
    ("komodorKubectlProxy","Deployment", "-proxy",  "kubectlProxy.enabled")
])
def test_override_security_context(component_name, resource_kind, deployment_name_suffix, capability_to_enable):
    """Tests the deprecated securityContext field still works as a pod-level fallback."""
    values_file = f"""
    components:
      {component_name}:
        securityContext:
          runAsUser: 1000
          runAsGroup: 3000
          fsGroup: 2000
    """
    set_command = "test=test"
    if capability_to_enable:
        set_command += f" --set capabilities.{capability_to_enable}=true"

    resource_name = f"{RELEASE_NAME}-komodor-agent{deployment_name_suffix}"
    pod_security_context = get_yaml_from_helm_template(set_command, resource_kind, resource_name,
                                                       "spec.template.spec.securityContext", values_file=values_file)

    assert pod_security_context is not None, f"Expected securityContext in {resource_kind} {resource_name}"


@pytest.mark.parametrize("component_name, resource_kind, resource_name_suffix, capability_to_enable", [
    ("komodorAgent",       "Deployment", "",        None),
    ("komodorMetrics",     "Deployment", "-metrics", None),
    ("komodorDaemon",      "DaemonSet",  "-daemon",  None),
    ("admissionController","Deployment", "-admission-controller", "admissionController.enabled"),
    ("komodorKubectlProxy","Deployment", "-proxy",   "kubectlProxy.enabled")
])
def test_override_pod_security_context(component_name, resource_kind, resource_name_suffix, capability_to_enable):
    """Tests that podSecurityContext is applied at pod level and takes precedence over the deprecated securityContext."""
    values_file = f"""
    components:
      {component_name}:
        podSecurityContext:
          runAsUser: 2000
          runAsGroup: 4000
          fsGroup: 3000
          runAsNonRoot: true
        securityContext:
          runAsUser: 9999
    """
    set_command = "test=test"
    if capability_to_enable:
        set_command += f" --set capabilities.{capability_to_enable}=true"

    resource_name = f"{RELEASE_NAME}-komodor-agent{resource_name_suffix}"
    pod_security_context = get_yaml_from_helm_template(set_command, resource_kind, resource_name,
                                                       "spec.template.spec.securityContext", values_file=values_file)

    assert pod_security_context is not None, f"Expected podSecurityContext in {resource_kind} {resource_name}"
    assert pod_security_context.get("runAsUser") == 2000, \
        f"Expected podSecurityContext.runAsUser=2000 (not deprecated securityContext value 9999), got {pod_security_context}"
    assert pod_security_context.get("fsGroup") == 3000, \
        f"Expected podSecurityContext.fsGroup=3000 in pod spec, got {pod_security_context}"


@pytest.mark.parametrize("resource_kind, resource_name_suffix, capability_to_enable", [
    ("Deployment", "", None),
    ("Deployment", "-metrics", None),
    ("Deployment", "-admission-controller", "admissionController.enabled"),
    ("Deployment", "-proxy", "kubectlProxy.enabled"),
    ("DaemonSet", "-daemon-windows", None),
    ("DaemonSet", "-gpu-host-access", None),
])
def test_global_pod_security_context(resource_kind, resource_name_suffix, capability_to_enable):
    values_file = """
    global:
      podSecurityContext:
        runAsUser: 2000
        runAsGroup: 4000
        fsGroup: 3000
        runAsNonRoot: true
    components:
      gpuAccess:
        enabled: true
    """
    set_command = "test=test"
    if capability_to_enable:
        set_command += f" --set capabilities.{capability_to_enable}=true"

    resource_name = f"{RELEASE_NAME}-komodor-agent{resource_name_suffix}"
    pod_security_context = get_yaml_from_helm_template(set_command, resource_kind, resource_name,
                                                       "spec.template.spec.securityContext", values_file=values_file)

    assert pod_security_context is not None, f"Expected global podSecurityContext in {resource_kind} {resource_name}"
    assert pod_security_context.get("runAsUser") == 2000, \
        f"Expected global podSecurityContext.runAsUser=2000, got {pod_security_context}"
    assert pod_security_context.get("fsGroup") == 3000, \
        f"Expected global podSecurityContext.fsGroup=3000, got {pod_security_context}"


@pytest.mark.parametrize("resource_kind, resource_name_suffix, container_path", [
    ("Deployment", "", "spec.template.spec.initContainers.0.securityContext"),
    ("Deployment", "", "spec.template.spec.containers.0.securityContext"),
    ("Deployment", "", "spec.template.spec.containers.1.securityContext"),
    ("Deployment", "-metrics", "spec.template.spec.initContainers.0.securityContext"),
    ("Deployment", "-metrics", "spec.template.spec.initContainers.1.securityContext"),
    ("Deployment", "-metrics", "spec.template.spec.containers.0.securityContext"),
    ("Deployment", "-metrics", "spec.template.spec.containers.1.securityContext"),
    ("Deployment", "-admission-controller", "spec.template.spec.containers.0.securityContext"),
    ("Deployment", "-proxy", "spec.template.spec.containers.0.securityContext"),
    ("DaemonSet", "-daemon", "spec.template.spec.initContainers.0.securityContext"),
    ("DaemonSet", "-daemon", "spec.template.spec.initContainers.1.securityContext"),
    ("DaemonSet", "-daemon", "spec.template.spec.initContainers.2.securityContext"),
    ("DaemonSet", "-daemon", "spec.template.spec.containers.0.securityContext"),
    ("DaemonSet", "-daemon", "spec.template.spec.containers.1.securityContext"),
    ("DaemonSet", "-daemon", "spec.template.spec.containers.2.securityContext"),
    ("DaemonSet", "-daemon", "spec.template.spec.containers.3.securityContext"),
    ("DaemonSet", "-daemon", "spec.template.spec.containers.4.securityContext"),
    ("DaemonSet", "-daemon-windows", "spec.template.spec.initContainers.0.securityContext"),
    ("DaemonSet", "-daemon-windows", "spec.template.spec.containers.0.securityContext"),
    ("DaemonSet", "-daemon-windows", "spec.template.spec.containers.1.securityContext"),
    ("DaemonSet", "-gpu-host-access", "spec.template.spec.containers.0.securityContext"),
])
def test_security_context_rendered_for_every_container_when_global_is_set(resource_kind, resource_name_suffix, container_path):
    values_file = """
    capabilities:
      kubectlProxy:
        enabled: true
    global:
      securityContext:
        allowPrivilegeEscalation: false
        runAsNonRoot: true
      podSecurityContext:
        runAsNonRoot: true
    customCa:
      enabled: true
      secretName: test-custom-ca
    components:
      gpuAccess:
        enabled: true
    """
    resource_name = f"{RELEASE_NAME}-komodor-agent{resource_name_suffix}"
    security_context = get_yaml_from_helm_template("test=test", resource_kind, resource_name,
                                                   container_path, values_file=values_file)

    assert security_context is not None, \
        f"Expected container securityContext at {container_path} in {resource_kind} {resource_name}"


@pytest.mark.parametrize("resource_kind, resource_name_suffix, container_path, expected_defaults", [
    ("Deployment", "", "spec.template.spec.containers.0.securityContext", {
        "allowPrivilegeEscalation": False,
        "readOnlyRootFilesystem": True,
        "runAsUser": 1000,
        "runAsGroup": 1000,
    }),
    ("Deployment", "", "spec.template.spec.containers.1.securityContext", {
        "allowPrivilegeEscalation": False,
        "readOnlyRootFilesystem": True,
        "runAsUser": 1000,
        "runAsGroup": 1000,
    }),
    ("DaemonSet", "-gpu-host-access", "spec.template.spec.containers.0.securityContext", {
        "privileged": True,
    }),
])
def test_global_container_security_context_preserves_chart_defaults(resource_kind, resource_name_suffix, container_path,
                                                                    expected_defaults):
    values_file = """
    global:
      securityContext:
        runAsNonRoot: true
    components:
      gpuAccess:
        enabled: true
    """
    resource_name = f"{RELEASE_NAME}-komodor-agent{resource_name_suffix}"
    security_context = get_yaml_from_helm_template("test=test", resource_kind, resource_name,
                                                   container_path, values_file=values_file)

    assert security_context.get("runAsNonRoot") is True, \
        f"Expected global securityContext.runAsNonRoot=true in {security_context}"
    for key, value in expected_defaults.items():
        assert security_context.get(key) == value, \
            f"Expected chart default {key}={value} to be preserved in {security_context}"


@pytest.mark.parametrize("container_path, expect_capability_add", [
    ("spec.template.spec.containers.0.securityContext", True),
    ("spec.template.spec.containers.1.securityContext", False),
])
def test_container_security_context_nested_overrides_do_not_leak(container_path, expect_capability_add):
    values_file = """
    global:
      securityContext:
        capabilities:
          drop:
            - ALL
    components:
      komodorAgent:
        watcher:
          securityContext:
            capabilities:
              add:
                - NET_BIND_SERVICE
    """
    resource_name = f"{RELEASE_NAME}-komodor-agent"
    security_context = get_yaml_from_helm_template("test=test", "Deployment", resource_name,
                                                   container_path, values_file=values_file)

    capabilities = security_context.get("capabilities", {})
    assert "ALL" in capabilities.get("drop", []), \
        f"Expected global capabilities.drop=[ALL], got {security_context}"
    if expect_capability_add:
        assert "NET_BIND_SERVICE" in capabilities.get("add", []), \
            f"Expected watcher-specific capabilities.add=[NET_BIND_SERVICE], got {security_context}"
    else:
        assert "add" not in capabilities, \
            f"Expected watcher-specific capabilities.add not to leak into supervisor, got {security_context}"


@pytest.mark.parametrize("container_path", [
    "spec.template.spec.initContainers.1.securityContext",
    "spec.template.spec.containers.4.securityContext",
])
def test_otel_init_container_security_context(container_path):
    values_file = """
    components:
      komodorDaemon:
        opentelemetry:
          otelInit:
            securityContext:
              allowPrivilegeEscalation: false
              runAsUser: 1500
              capabilities:
                drop:
                  - ALL
    """
    resource_name = f"{RELEASE_NAME}-komodor-agent-daemon"
    security_context = get_yaml_from_helm_template("test=test", "DaemonSet", resource_name,
                                                   container_path, values_file=values_file)

    assert security_context is not None, f"Expected securityContext at {container_path}"
    assert security_context.get("runAsUser") == 1500, \
        f"Expected otelInit.securityContext.runAsUser=1500, got {security_context}"
    assert security_context.get("allowPrivilegeEscalation") is False, \
        f"Expected otelInit.securityContext.allowPrivilegeEscalation=false, got {security_context}"
    assert "ALL" in security_context.get("capabilities", {}).get("drop", []), \
        f"Expected otelInit.securityContext.capabilities.drop=[ALL], got {security_context}"


@pytest.mark.parametrize("resource_kind, resource_name_suffix, container_path", [
    ("Deployment", "-metrics", "spec.template.spec.initContainers.0.securityContext"),
    ("Deployment", "-metrics", "spec.template.spec.containers.0.securityContext"),
    ("Deployment", "-metrics", "spec.template.spec.containers.1.securityContext"),
    ("DaemonSet", "-daemon", "spec.template.spec.initContainers.0.securityContext"),
    ("DaemonSet", "-daemon", "spec.template.spec.initContainers.1.securityContext"),
    ("DaemonSet", "-daemon", "spec.template.spec.containers.0.securityContext"),
    ("DaemonSet", "-daemon", "spec.template.spec.containers.1.securityContext"),
    ("DaemonSet", "-daemon", "spec.template.spec.containers.2.securityContext"),
    ("DaemonSet", "-daemon", "spec.template.spec.containers.3.securityContext"),
    ("DaemonSet", "-daemon", "spec.template.spec.containers.4.securityContext"),
])
def test_hardened_values_linux_container_security_contexts(resource_kind, resource_name_suffix, container_path):
    resource_name = f"{RELEASE_NAME}-komodor-agent{resource_name_suffix}"
    security_context = get_yaml_from_helm_template("test=test", resource_kind, resource_name,
                                                   container_path, values_file=HARDENED_VALUES.read_text())

    assert security_context is not None, f"Expected securityContext at {container_path}"
    assert security_context.get("runAsUser") != 0, \
        f"Expected non-root runAsUser at {container_path}, got {security_context}"
    assert security_context.get("runAsGroup") != 0, \
        f"Expected non-root runAsGroup at {container_path}, got {security_context}"
    assert security_context.get("readOnlyRootFilesystem") is True, \
        f"Expected readOnlyRootFilesystem=true at {container_path}, got {security_context}"


@pytest.mark.parametrize("volume_name, mount_path", [
    ("opentelemetry-varlogpods", "/var/log/pods"),
    ("opentelemetry-varlib-docker-containers", "/var/lib/docker/containers"),
])
def test_hardened_values_do_not_mount_otel_host_log_paths(volume_name, mount_path):
    resource_name = f"{RELEASE_NAME}-komodor-agent-daemon"
    values_file = HARDENED_VALUES.read_text()
    pod_volumes = get_yaml_from_helm_template("test=test", "DaemonSet", resource_name,
                                              "spec.template.spec.volumes", values_file=values_file)
    containers = get_yaml_from_helm_template("test=test", "DaemonSet", resource_name,
                                             "spec.template.spec.containers", values_file=values_file)
    otel_collector = next(container for container in containers if container["name"] == "otel-collector")

    assert volume_name not in [volume["name"] for volume in pod_volumes], \
        f"Expected hardened values not to render hostPath volume {volume_name}"
    assert mount_path not in [mount["mountPath"] for mount in otel_collector.get("volumeMounts", [])], \
        f"Expected hardened values not to mount host path {mount_path} into otel-collector"


@pytest.mark.parametrize("resource_kind, resource_name_suffix, capability_to_enable, values_override, container_path", [
    # komodorAgent — watcher (container 0) and supervisor (container 1)
    ("Deployment", "", None,
     """
     components:
       komodorAgent:
         watcher:
           securityContext:
             allowPrivilegeEscalation: false
             runAsUser: 1500
             capabilities:
               drop:
                 - ALL
         supervisor:
           securityContext:
             allowPrivilegeEscalation: false
             runAsUser: 1600
             capabilities:
               drop:
                 - ALL
     """,
     "spec.template.spec.containers.0.securityContext"),
    ("Deployment", "", None,
     """
     components:
       komodorAgent:
         watcher:
           securityContext:
             allowPrivilegeEscalation: false
             runAsUser: 1500
             capabilities:
               drop:
                 - ALL
         supervisor:
           securityContext:
             allowPrivilegeEscalation: false
             runAsUser: 1600
             capabilities:
               drop:
                 - ALL
     """,
     "spec.template.spec.containers.1.securityContext"),
    # admissionController
    ("Deployment", "-admission-controller", "admissionController.enabled",
     """
     components:
       admissionController:
         containerSecurityContext:
           allowPrivilegeEscalation: false
           runAsUser: 1500
           capabilities:
             drop:
               - ALL
     """,
     "spec.template.spec.containers.0.securityContext"),
    # komodorKubectlProxy
    ("Deployment", "-proxy", "kubectlProxy.enabled",
     """
     components:
       komodorKubectlProxy:
         containerSecurityContext:
           allowPrivilegeEscalation: false
           runAsUser: 1500
           capabilities:
             drop:
               - ALL
     """,
     "spec.template.spec.containers.0.securityContext"),
    # komodorMetrics — main telegraf container (container 0)
    ("Deployment", "-metrics", None,
     """
     components:
       komodorMetrics:
         metrics:
           securityContext:
             allowPrivilegeEscalation: false
             runAsUser: 1500
             capabilities:
               drop:
                 - ALL
     """,
     "spec.template.spec.containers.0.securityContext"),
    # komodorDaemon — main metrics/telegraf container (container 0)
    ("DaemonSet", "-daemon", None,
     """
     components:
       komodorDaemon:
         metrics:
           securityContext:
             allowPrivilegeEscalation: false
             runAsNonRoot: true
             capabilities:
               drop:
                 - ALL
     """,
     "spec.template.spec.containers.0.securityContext"),
    # komodorDaemon OpenTelemetry initContainer
    ("DaemonSet", "-daemon", None,
     """
     components:
       komodorDaemon:
         opentelemetry:
           otelInit:
             securityContext:
               allowPrivilegeEscalation: false
               runAsUser: 1500
               capabilities:
                 drop:
                   - ALL
     """,
     "spec.template.spec.initContainers.1.securityContext"),
    # komodorDaemon OpenTelemetry init sidecar
    ("DaemonSet", "-daemon", None,
     """
     components:
       komodorDaemon:
         opentelemetry:
           otelInit:
             securityContext:
               allowPrivilegeEscalation: false
               runAsUser: 1500
               capabilities:
                 drop:
                   - ALL
     """,
     "spec.template.spec.containers.4.securityContext"),
])
def test_override_container_security_context(resource_kind, resource_name_suffix, capability_to_enable,
                                             values_override, container_path):
    """Tests that per-container securityContext is applied at container level only."""
    set_command = "test=test"
    if capability_to_enable:
        set_command += f" --set capabilities.{capability_to_enable}=true"

    resource_name = f"{RELEASE_NAME}-komodor-agent{resource_name_suffix}"
    container_sc = get_yaml_from_helm_template(set_command, resource_kind, resource_name,
                                               container_path, values_file=values_override)

    assert container_sc is not None, f"Expected container securityContext at {container_path} in {resource_kind} {resource_name}"
    assert container_sc.get("allowPrivilegeEscalation") is False, \
        f"Expected allowPrivilegeEscalation=false in container securityContext, got {container_sc}"
    assert "ALL" in container_sc.get("capabilities", {}).get("drop", []), \
        f"Expected capabilities.drop=[ALL] in container securityContext, got {container_sc}"


@pytest.mark.parametrize("component_name, deployment_name_suffix, strategy_key, resource_kind, capability_to_enable", [
    ("komodorAgent", "", "strategy", "Deployment", None),
    ("komodorMetrics", "-metrics", "strategy", "Deployment", None),
    ("komodorDaemon", "-daemon", "updateStrategy", "DaemonSet", None),
    ("komodorDaemonWindows", "-daemon-windows", "updateStrategy", "DaemonSet", None),
    ("komodorKubectlProxy", "-proxy", "strategy", "Deployment", "kubectlProxy.enabled")
])
def test_override_update_strategy(component_name, deployment_name_suffix, strategy_key, resource_kind, capability_to_enable):
    values_file = f"""
    components:
        {component_name}:
          {strategy_key}:
            type: RollingUpdate
            rollingUpdate:
              maxUnavailable: 10
              maxSurge: 10

    """
    set_command = "test=test"
    if capability_to_enable:
        set_command += f" --set capabilities.{capability_to_enable}=true"

    deployment_name = f"{RELEASE_NAME}-komodor-agent{deployment_name_suffix}"
    deployment_strategy = get_yaml_from_helm_template(set_command, resource_kind, deployment_name,
                                                      f"spec.{strategy_key}", values_file=values_file)

    assert deployment_strategy["type"] == "RollingUpdate", f"Expected rollingUpdate in deployment tolerations {deployment_strategy}"
