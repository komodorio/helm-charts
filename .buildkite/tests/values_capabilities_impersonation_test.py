import yaml
from helpers.helm_helper import helm_agent_template
from config import RELEASE_NAME, NAMESPACE

IMPERSONATION_CR_NAME = f"{RELEASE_NAME}-komodor-agent-impersonation"
K8S_WATCHER_CRB_GROUP_NAME = f"{RELEASE_NAME}-komodor-agent-k8s-watcher-group"
K8S_WATCHER_CR_NAME = f"{RELEASE_NAME}-komodor-agent-k8s-watcher"
IMPERSONATION_GROUP = "komodor:agent-actions"


def _get_all_docs(additional_settings=""):
    output, exit_code = helm_agent_template(additional_settings=additional_settings)
    assert exit_code == 0, f"helm template failed: {output}"
    return [d for d in yaml.safe_load_all(output) if d]


def _get_resource(docs, kind, name):
    return next(
        (d for d in docs if d.get("kind") == kind and d.get("metadata", {}).get("name") == name),
        None,
    )


def test_impersonation_disabled_by_default():
    docs = _get_all_docs()
    assert _get_resource(docs, "ClusterRole", IMPERSONATION_CR_NAME) is None, \
        f"ClusterRole {IMPERSONATION_CR_NAME} must not render when disabled"
    assert _get_resource(docs, "ClusterRoleBinding", IMPERSONATION_CR_NAME) is None, \
        f"ClusterRoleBinding {IMPERSONATION_CR_NAME} must not render when disabled"
    assert _get_resource(docs, "ClusterRoleBinding", K8S_WATCHER_CRB_GROUP_NAME) is None, \
        f"ClusterRoleBinding {K8S_WATCHER_CRB_GROUP_NAME} must not render when disabled"


def test_impersonation_enabled_clusterrole_rules():
    docs = _get_all_docs("--set capabilities.impersonation.enabled=true")
    cr = _get_resource(docs, "ClusterRole", IMPERSONATION_CR_NAME)
    assert cr is not None, f"ClusterRole {IMPERSONATION_CR_NAME} not found"

    rules = cr["rules"]

    users_rule = next((r for r in rules if "users" in r.get("resources", [])), None)
    assert users_rule is not None, "Missing users impersonation rule"
    assert "impersonate" in users_rule["verbs"], "users rule must include impersonate verb"
    assert "resourceNames" not in users_rule, "users rule must not restrict via resourceNames"

    groups_rule = next((r for r in rules if "groups" in r.get("resources", [])), None)
    assert groups_rule is not None, "Missing groups impersonation rule"
    assert "impersonate" in groups_rule["verbs"], "groups rule must include impersonate verb"
    assert groups_rule.get("resourceNames") == [IMPERSONATION_GROUP], \
        f"groups rule must be pinned to {IMPERSONATION_GROUP}"


def test_impersonation_enabled_crb_sa():
    docs = _get_all_docs("--set capabilities.impersonation.enabled=true")
    crb = _get_resource(docs, "ClusterRoleBinding", IMPERSONATION_CR_NAME)
    assert crb is not None, f"ClusterRoleBinding {IMPERSONATION_CR_NAME} not found"
    assert crb["roleRef"]["kind"] == "ClusterRole"
    assert crb["roleRef"]["name"] == IMPERSONATION_CR_NAME
    subjects = crb["subjects"]
    assert len(subjects) == 1, "Expected exactly one subject"
    assert subjects[0]["kind"] == "ServiceAccount"
    assert subjects[0]["namespace"] == NAMESPACE


def test_impersonation_enabled_crb_group():
    docs = _get_all_docs("--set capabilities.impersonation.enabled=true")
    crb = _get_resource(docs, "ClusterRoleBinding", K8S_WATCHER_CRB_GROUP_NAME)
    assert crb is not None, f"ClusterRoleBinding {K8S_WATCHER_CRB_GROUP_NAME} not found"
    assert crb["roleRef"]["kind"] == "ClusterRole"
    assert crb["roleRef"]["name"] == K8S_WATCHER_CR_NAME
    subjects = crb["subjects"]
    assert len(subjects) == 1, "Expected exactly one subject"
    assert subjects[0]["kind"] == "Group"
    assert subjects[0]["name"] == IMPERSONATION_GROUP
    assert subjects[0]["apiGroup"] == "rbac.authorization.k8s.io"
