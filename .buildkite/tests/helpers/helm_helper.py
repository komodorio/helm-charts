import yaml
import os
from config import API_KEY, NAMESPACE, RELEASE_NAME, CHART_PATH
from helpers.utils import cmd


def helm_agent_install(cluster_name, settings=None, additional_settings=""):
    if settings is None:
        settings = f'--set apiKey={API_KEY} --set clusterName={cluster_name} --create-namespace'
    output, exit_code = cmd(
        f"helm install {RELEASE_NAME} {CHART_PATH} {settings} {additional_settings} --namespace={NAMESPACE} --wait")
    return output, exit_code


def helm_agent_template(settings=None, additional_settings="", values_file=False):
    if settings is None:
        settings = f'--set apiKey={API_KEY} --set clusterName=test-template --create-namespace'
    if values_file:
        temp_path = os.path.join(os.path.dirname(__file__), "temp-values.yaml")
        print(f"Using values file: {temp_path}, content: {values_file}")
        if os.path.exists(temp_path):
            os.remove(temp_path)
        with open(temp_path, "w") as f:
            f.write(values_file)
        additional_settings += f" -f {temp_path}"

    output, exit_code = cmd(
        f"helm template {RELEASE_NAME} {CHART_PATH} {settings} {additional_settings} --namespace={NAMESPACE}",
        silent=True)
    return output, exit_code


def helm_agent_uninstall():
    output, exit_code = cmd(f"helm uninstall {RELEASE_NAME} {CHART_PATH} --namespace={NAMESPACE} --wait")
    return output, exit_code


def get_yaml_from_helm_template(set_command, resource_kind, resource_name, field_path_array, values_file=False):
    yaml_templates, exit_code = helm_agent_template(additional_settings=f"--set {set_command}", values_file=values_file)
    assert exit_code == 0, f"helm template failed, output: {yaml_templates}"

    if not isinstance(field_path_array, list):
        field_path_array = field_path_array.split(".")

    documents = list(yaml.safe_load_all(yaml_templates))
    for doc in documents:
        if doc.get("kind") == resource_kind and doc.get("metadata", {}).get("name") == resource_name:
            temp = doc
            for key in field_path_array:
                if key.isdigit():
                    temp = temp[int(key)]
                else:
                    temp = temp[key]
            return temp
    raise ValueError(f"Resource of kind {resource_kind} and name {resource_name} not found in helm output.")
