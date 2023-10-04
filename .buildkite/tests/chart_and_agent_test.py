import pytest
import yaml
import time
from fixtures import setup_cluster, kube_client
from helpers.utils import cmd
from deepdiff import DeepDiff
from config import API_KEY, API_KEY_B64, RELEASE_NAME, NAMESPACE, BE_BASE_URL
from helpers.kubernetes_helper import check_pods_running, create_namespace, create_secret, create_service_account, wait_for_pod_ready, find_pod_name_by_deployment
from helpers.helm_helper import helm_agent_install, helm_agent_template, get_value_from_helm_template, validate_template_value_by_values_path
from helpers.komodor_helper import create_komodor_uid, query_backend

# tags and policies
# ToDo: Check with Mick


# changing image repository -t

# changing pull policy - t

# providing an image pull secret for the service account -t

# disable installation capabilities (mapper, metrics) -t





# Event redaction - validate that workload is redacted in komodor

# disable logs

# log deny list

# log allow list

# log redact regex

# disable allowedResources.allowReadAll and dont allow clusterrole, validate that we are not getting clusterroles

# debug Allow collection of api metrics and validate that it sends metrics to collector

# change kubernetes Agent settings (affinity, annotations, nodeSelector, tolerations, podAnnotations)


