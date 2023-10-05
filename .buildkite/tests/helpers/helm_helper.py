import yaml
import os
from config import API_KEY, NAMESPACE, RELEASE_NAME, CHART_PATH
from helpers.utils import cmd


def helm_agent_install(cluster_name, settings=None, additional_settings=""):
    if settings is None:
        settings=f'--set apiKey={API_KEY} --set clusterName={cluster_name} --create-namespace'
    output, exit_code = cmd(
        f"helm install {RELEASE_NAME} {CHART_PATH} {settings} {additional_settings} --namespace={NAMESPACE} --wait")
    return output, exit_code


def helm_agent_template(settings=None,additional_settings="", values_file=False):
    if settings is None:
        settings=f'--set apiKey={API_KEY} --set clusterName=test-template --create-namespace'
    if values_file:
        temp_path = os.path.join(os.path.dirname(__file__), "temp-values.yaml")
        print(f"Using values file: {temp_path}, content: {values_file}")
        if os.path.exists(temp_path):
            os.remove(temp_path)
        with open(temp_path, "w") as f:
            f.write(values_file)
        additional_settings += f" -f {temp_path}"

    output, exit_code = cmd(
        f"helm template {RELEASE_NAME} {CHART_PATH} {settings} {additional_settings} --namespace={NAMESPACE}", silent=True)
    return output, exit_code


def helm_agent_uninstall():
    output, exit_code = cmd(f"helm uninstall {RELEASE_NAME} {CHART_PATH} --namespace={NAMESPACE} --wait")
    return output, exit_code


def get_value_from_helm_template(helm_output, resource_kind, resource_name, field_path_array):
    documents = list(yaml.safe_load_all(helm_output))
    for doc in documents:
        if doc.get("kind") == resource_kind and doc.get("metadata", {}).get("name") == resource_name:
            temp = doc
            for key in field_path_array:
                if key.isdigit():
                    temp = temp[int(key)]
                else:
                    temp = temp[key]
            return yaml.dump(temp)
    raise ValueError(f"Resource of kind {resource_kind} and name {resource_name} not found in helm output.")


def validate_template_value_by_values_path(test_value, values_path, resource_type, resource_name, yaml_path):
    if not isinstance(yaml_path, list):
        yaml_path = yaml_path.split(".")
    yaml_templates, exit_code = helm_agent_template(additional_settings=f"--set {values_path}={test_value}")
    actual_value = get_value_from_helm_template(yaml_templates, resource_type, resource_name, yaml_path)

    assert exit_code == 0, f"helm template failed, output: {yaml_templates}"
    assert test_value in actual_value, f"Expected {test_value} in value {actual_value}"
