import os
import re

import pytest
import yaml

from config import API_KEY, CHART_PATH, RELEASE_NAME
from helpers.helm_helper import helm_agent_template

TEMPLATES_DIR = os.path.join(CHART_PATH, "templates")
# the agent ConfigMap is named after the chart, everything else after the release
CONFIG_MAP_NAME = "komodor-agent-config"
FULLNAME = f"{RELEASE_NAME}-komodor-agent"
AGENT_SERVICE_ACCOUNT = FULLNAME

# Every value path "--set profile=cost" writes, as it appears in installed-values.yaml.
# A path is listed here whether or not the profile's value differs from the chart default:
# the profile pins it either way, and test_cost_profile_turns_off_every_profiled_key asserts
# the rendered result rather than the delta.
PROFILED_CAPABILITY_PATHS = [
    "capabilities.actions",
    "capabilities.crActions",
    "capabilities.rbac",
    "capabilities.rbacTempTokens",
    "capabilities.helm.enabled",
    "capabilities.events.create",
    "capabilities.nodeEnricher",
    "capabilities.logs.enabled",
    "capabilities.resourceInfo.enabled",
    "capabilities.telemetry.enabled",
    "capabilities.telemetry.deployOtelCollector",
    "capabilities.tunnel.enabled",
    "capabilities.tunnel.kubeapiserver.enabled",
    "capabilities.kubectlProxy.enabled",
    "capabilities.klaudiaIntegrationSync.enabled",
    "components.komodorDaemonWindows.enabled",
]

ALLOWED_RESOURCES_OFF = [
    "allowReadAll",
    "replicaSet", "horizontalPodAutoscaler", "podDisruptionBudget", "priorityClass",
    "persistentVolume", "persistentVolumeClaim", "storageClass", "csiDriver", "csiNode",
    "csiStorageCapacity", "volumeAttachment",
    "limitRange", "resourceQuota", "event", "replicationController", "podTemplate",
    "controllerRevision", "runtimeClass", "lease", "certificateSigningRequest",
    "service", "endpoints", "endpointSlice", "ingress", "ingressClass", "networkPolicy",
    "secret", "configMap",
    "clusterRole", "clusterRoleBinding", "role", "roleBinding", "serviceAccount",
    "customResourceDefinition", "admissionRegistrationResources", "authorizationResources",
    "flowControlResources", "policyResources",
]

# Left at the chart default on purpose, so an operator can still shrink the install further.
ALLOWED_RESOURCES_ON = [
    "node", "metrics", "namespace", "pod",
    "deployment", "statefulSet", "daemonSet", "job", "cronjob",
    # Komodor requests rollouts.argoproj.io from every cluster whose CRD is installed. Without
    # the read the agent answers forbidden rather than "not supported", which is not tolerated
    # the same way, and the cluster's resource sync stops. Rollout is also a right-sizable
    # workload kind.
    "rollout",
]

# Same reason: workflows and cronworkflows are the other two CRD-backed kinds. The remaining two
# argo sub-keys are gated separately in the ClusterRole and nothing requests them.
ARGO_WORKFLOWS_ON = ["workflows", "cronWorkflows"]
ARGO_WORKFLOWS_OFF = ["workflowTemplates", "clusterWorkflowTemplates"]

# What the cost flows need and the profile must not touch.
COST_CAPABILITIES_ON = [
    "capabilities.metrics",
    "capabilities.admissionController.enabled",
    "capabilities.cost.hpa",
]

# Reads that oblige a template to include "applyProfile" first. Matched against template text
# with parentheses stripped, so "((.Values.capabilities).logs).enabled" matches too.
PROFILED_READS = [
    r"\.Values\.capabilities\.actions\b",
    r"\.Values\.capabilities\.crActions\b",
    r"\.Values\.capabilities\.helm\b",
    r"\.Values\.capabilities\.rbac\b",
    r"\.Values\.capabilities\.rbacTempTokens\b",
    r"\.Values\.capabilities\.nodeEnricher\b",
    r"\.Values\.capabilities\.logs\.enabled\b",
    r"\.Values\.capabilities\.events\.create\b",
    r"\.Values\.capabilities\.telemetry\.(enabled|deployOtelCollector)\b",
    r"\.Values\.capabilities\.tunnel\.(enabled|kubeapiserver)",
    r"\.Values\.capabilities\.kubectlProxy\.enabled\b",
    r"\.Values\.capabilities\.klaudiaIntegrationSync\.enabled\b",
    r"\.Values\.capabilities\.resourceInfo\b",
    r"\.Values\.components\.komodorDaemonWindows\.enabled\b",
    r"\.Values\.components\.komodorAgent\.watcher\.resources\b",
    r"\.Values\.allowedResources\b",
    # a whole profiled tree aliased into a variable or piped, e.g. {{- $caps := .Values.capabilities -}}
    r"\.Values\.(capabilities|components)\s*(-?\}\}|\|)",
]
PROFILED_READS_RE = re.compile("|".join(PROFILED_READS))
APPLY_PROFILE_RE = re.compile(r'include\s+"applyProfile"')


def render(extra=""):
    settings = f"--set apiKey={API_KEY} --set clusterName=profile-test --set site=us {extra}"
    output, exit_code = helm_agent_template(settings=settings)
    assert exit_code == 0, f"helm template failed, output: {output}"
    return manifests(output)


def manifests(output):
    """helm writes warnings to stdout, so keep only documents that look like manifests."""
    return [doc for doc in yaml.safe_load_all(output) if isinstance(doc, dict) and "kind" in doc]


def config_maps(docs):
    cm = next(
        d for d in docs
        if d["kind"] == "ConfigMap" and d["metadata"]["name"] == CONFIG_MAP_NAME
    )
    return (
        yaml.safe_load(cm["data"]["komodor-k8s-watcher.yaml"]),
        yaml.safe_load(cm["data"]["installed-values.yaml"]),
    )


def lookup(tree, dotted):
    for key in dotted.split("."):
        tree = tree[key]
    return tree


def null_paths(tree, prefix):
    found = []
    for key, value in (tree or {}).items():
        path = f"{prefix}.{key}"
        if value is None:
            found.append(path)
        elif isinstance(value, dict):
            found += null_paths(value, path)
    return found


@pytest.fixture(scope="module")
def cost_render():
    return render("--set profile=cost")


@pytest.fixture(scope="module")
def default_render():
    return render()


@pytest.fixture(scope="module")
def forced_on_render():
    """profile=cost with every key the profile writes explicitly set to true first."""
    forced = " ".join(f"--set {path}=true" for path in PROFILED_CAPABILITY_PATHS)
    # klaudiaIntegrationSync.enabled=true makes publicApiKey required, so supply one - the point
    # of this render is the profile's precedence, not the chart's validations
    return render(f"--set profile=cost --set publicApiKey={API_KEY} {forced}")


class TestProfileIsInertByDefault:
    def test_profiled_keys_keep_their_chart_defaults(self, default_render):
        _, installed = config_maps(default_render)
        assert lookup(installed, "capabilities.actions") is True
        assert lookup(installed, "capabilities.helm.enabled") is True
        assert lookup(installed, "allowedResources.allowReadAll") is True
        assert installed["profile"] == ""

    def test_resource_info_is_written_into_the_agent_config(self, default_render):
        """HC-4's key is a default in the agent config file, so remote config can still win."""
        agent_config, _ = config_maps(default_render)
        assert agent_config["resourceInfo"]["enabled"] is False
        agent_config, _ = config_maps(render("--set capabilities.resourceInfo.enabled=true"))
        assert agent_config["resourceInfo"]["enabled"] is True

    @pytest.mark.parametrize("value", [
        "nope",
        "Cost",   # the value is case sensitive
        "false",  # helm reads this as a bool; it is a profile name, not a way to disable one
        "true",
        "1",
    ])
    def test_an_unrecognised_profile_is_rejected(self, value):
        """
        The check lives in the helper, not in validations.yaml. Helm renders deepest-path-first,
        so validations.yaml is not the first template and a bad value would otherwise surface as
        a raw "incompatible types for comparison" from _profile.tpl. A falsy value silently
        installing a full agent is the failure that actually costs something.
        """
        output, exit_code = helm_agent_template(
            settings=f"--set apiKey={API_KEY} --set clusterName=c --set site=us --set profile={value}"
        )
        assert exit_code != 0, f"profile={value} rendered instead of failing"
        assert "profile must be" in output, output

    @pytest.mark.parametrize("extra", ["", '--set profile=""', "--set profile=null"])
    def test_an_empty_profile_is_the_default_install(self, extra):
        _, installed = config_maps(render(extra))
        assert installed["allowedResources"]["allowReadAll"] is True


class TestCostProfile:
    @pytest.mark.parametrize("path", PROFILED_CAPABILITY_PATHS)
    def test_cost_profile_turns_off_every_profiled_key(self, cost_render, path):
        _, installed = config_maps(cost_render)
        assert lookup(installed, path) is False

    @pytest.mark.parametrize("key", ALLOWED_RESOURCES_OFF)
    def test_cost_profile_turns_off_the_unused_resource_kinds(self, cost_render, key):
        agent_config, installed = config_maps(cost_render)
        assert installed["allowedResources"][key] is False
        # allowedResources is dumped verbatim into the agent's own config file
        assert agent_config["resources"][key] is False

    @pytest.mark.parametrize("key", ALLOWED_RESOURCES_ON)
    def test_cost_profile_keeps_the_resource_kinds_the_cost_flows_read(self, cost_render, key):
        _, installed = config_maps(cost_render)
        assert installed["allowedResources"][key] is True

    def test_cost_profile_keeps_the_argo_kinds_the_reconciler_requests(self, cost_render):
        _, installed = config_maps(cost_render)
        argo = installed["allowedResources"]["argoWorkflows"]
        for key in ARGO_WORKFLOWS_ON:
            assert argo[key] is True
        for key in ARGO_WORKFLOWS_OFF:
            assert argo[key] is False

    def test_cost_profile_grants_read_on_the_argo_kinds(self, cost_render):
        """
        The config key is not enough - the reconciler fails on a 403, so the ClusterRole has to
        carry the read as well.
        """
        rules = [
            rule
            for doc in cost_render
            if doc["kind"] == "ClusterRole" and doc["metadata"]["name"].endswith("-k8s-watcher")
            for rule in doc.get("rules") or []
            if "argoproj.io" in (rule.get("apiGroups") or [])
        ]
        granted = {resource for rule in rules for resource in rule.get("resources") or []}
        for resource in ("rollouts", "workflows", "cronworkflows"):
            assert resource in granted, f"profile=cost does not grant read on argoproj.io/{resource}"

    def test_cost_profile_turns_off_resource_info_in_the_agent_config(self, cost_render):
        agent_config, _ = config_maps(cost_render)
        assert agent_config["resourceInfo"]["enabled"] is False

    @pytest.mark.parametrize("path", COST_CAPABILITIES_ON)
    def test_cost_profile_keeps_the_cost_capabilities_on(self, cost_render, path):
        _, installed = config_maps(cost_render)
        assert lookup(installed, path) is True

    def test_cost_profile_leaves_custom_read_api_groups_to_the_operator(self):
        docs = render("--set profile=cost --set allowedResources.customReadAPIGroups={sparkoperator.k8s.io}")
        _, installed = config_maps(docs)
        assert installed["allowedResources"]["customReadAPIGroups"] == ["sparkoperator.k8s.io"]

    def test_cost_profile_can_still_be_shrunk_further(self):
        docs = render("--set profile=cost --set capabilities.metrics=false")
        _, installed = config_maps(docs)
        assert installed["capabilities"]["metrics"] is False

    def test_cost_profile_drops_the_workloads_it_disables(self, cost_render, default_render):
        gone = [
            ("DaemonSet", f"{FULLNAME}-daemon-windows"),
            ("ClusterRole", f"{FULLNAME}-node-enricher"),
            ("Service", f"{FULLNAME}-otel-collector"),
        ]
        default_names = {(d["kind"], d["metadata"]["name"]) for d in default_render}
        cost_names = {(d["kind"], d["metadata"]["name"]) for d in cost_render}
        for kind, name in gone:
            assert (kind, name) in default_names, \
                f"{kind}/{name} does not render by default either, so this asserted nothing"
            assert (kind, name) not in cost_names, f"{kind}/{name} still rendered under profile=cost"

    def test_cost_profile_leaves_workload_sizing_alone(self, cost_render, default_render):
        """
        Requests and limits are the operator's to set - utilities/memory-planning exists to tell
        them what to put there - so the profile does not write them. A cost install that wants a
        smaller watcher passes the value itself.
        """
        def containers(docs):
            deployment = next(
                d for d in docs
                if d["kind"] == "Deployment" and d["metadata"]["name"] == FULLNAME
            )
            return {c["name"]: c for c in deployment["spec"]["template"]["spec"]["containers"]}

        cost, default = containers(cost_render), containers(default_render)
        for name in ("k8s-watcher", "supervisor"):
            assert cost[name]["resources"] == default[name]["resources"], \
                f"profile=cost changed {name} resources"

        watcher = cost["k8s-watcher"]["resources"]
        assert watcher["limits"] == {"cpu": 2, "memory": "8Gi"}
        assert watcher["requests"] == {"cpu": 0.25, "memory": "256Mi"}

    def test_a_cost_install_can_still_lower_the_watcher_memory_limit(self):
        docs = render(
            "--set profile=cost "
            "--set components.komodorAgent.watcher.resources.limits.memory=2Gi"
        )
        deployment = next(
            d for d in docs if d["kind"] == "Deployment" and d["metadata"]["name"] == FULLNAME
        )
        watcher = next(
            c for c in deployment["spec"]["template"]["spec"]["containers"]
            if c["name"] == "k8s-watcher"
        )
        assert watcher["resources"]["limits"]["memory"] == "2Gi"
        go_mem_limit = next(e for e in watcher["env"] if e["name"] == "GOMEMLIMIT")["value"]
        assert go_mem_limit == "1843MiB", "GOMEMLIMIT no longer follows the configured limit"

    def test_cost_profile_wins_over_an_explicit_set(self):
        """The one place a profile differs from an equivalent values file."""
        docs = render("--set profile=cost --set capabilities.kubectlProxy.enabled=true")
        names = {(d["kind"], d["metadata"]["name"]) for d in docs}
        assert ("Deployment", f"{FULLNAME}-proxy") not in names
        _, installed = config_maps(docs)
        assert installed["capabilities"]["kubectlProxy"]["enabled"] is False

    @pytest.mark.parametrize("path", PROFILED_CAPABILITY_PATHS)
    def test_cost_profile_turns_a_key_off_even_when_it_was_set_on(self, forced_on_render, path):
        """
        Asserting `is False` against a key whose chart default is already false proves nothing.
        This renders with every profiled key forced true, so each assertion can only pass
        because the profile wrote it.
        """
        _, installed = config_maps(forced_on_render)
        assert lookup(installed, path) is False

    def test_cost_profile_keeps_the_cost_workloads(self, cost_render):
        kinds = {(d["kind"], d["metadata"]["name"]) for d in cost_render}
        assert ("Deployment", FULLNAME) in kinds
        assert ("Deployment", f"{FULLNAME}-metrics") in kinds
        assert ("Deployment", f"{FULLNAME}-admission-controller") in kinds

    def test_cost_profile_grants_no_wildcard_or_empty_rules(self, cost_render):
        bound = {
            d["roleRef"]["name"]
            for d in cost_render
            if d["kind"] == "ClusterRoleBinding"
            and any(
                s.get("kind") == "ServiceAccount" and s["name"] == AGENT_SERVICE_ACCOUNT
                for s in d.get("subjects") or []
            )
        }
        assert bound, "no ClusterRole is bound to the agent ServiceAccount, so this asserted nothing"
        for doc in cost_render:
            if doc["kind"] != "ClusterRole" or doc["metadata"]["name"] not in bound:
                continue
            for rule in doc.get("rules") or []:
                groups = rule.get("apiGroups") or []
                resources = rule.get("resources") or []
                assert not ("*" in groups and "*" in resources), \
                    f"{doc['metadata']['name']} still grants */*: {rule}"
                assert resources or rule.get("nonResourceURLs"), \
                    f"{doc['metadata']['name']} renders a rule with no resources: {rule}"


class TestProfileSurvivesAwkwardValues:
    """
    The helper writes through `set`, which needs a real map at every level, and rewrites
    capabilities.helm, which may still be a bare bool from before the map migration.
    """

    @pytest.mark.parametrize("extra", [
        # already fails to render without the profile too, so the helper's guard is what keeps
        # it working rather than a regression it has to avoid
        "--set allowedResources.argoWorkflows=null",
    ])
    def test_profile_renders(self, extra):
        output, exit_code = helm_agent_template(
            settings=f"--set apiKey={API_KEY} --set clusterName=c --set site=us --set profile=cost {extra}"
        )
        assert exit_code == 0, f"profile=cost failed to render with {extra}: {output}"

    def test_legacy_bool_helm_is_still_migrated_under_the_profile(self):
        """
        capabilities.helm was a bare bool before the map migration, and the helper writes to it
        with `set`, which needs a map - hence the migrateHelmValues call inside applyProfile.

        Helm 4 refuses to replace a declared table with a scalar and just warns, so on helm 4
        this asserts the value stays a concrete map. On helm 3, where the override does take
        effect, it is the migration inside the helper that keeps the render working.
        """
        output, exit_code = helm_agent_template(
            settings=f"--set apiKey={API_KEY} --set clusterName=c --set site=us --set profile=cost",
            values_file="capabilities:\n  helm: true\n",
        )
        assert exit_code == 0, f"profile=cost failed on a legacy bool capabilities.helm: {output}"
        _, installed = config_maps(manifests(output))
        assert installed["capabilities"]["helm"] == {"enabled": False, "readonly": False}


class TestInstalledValuesStayConcrete:
    """
    installed-values.yaml is sent to Komodor and type-asserted there. A null under capabilities
    reads as "capability on" and silently disables right-sizing, so a profile must set concrete
    values and never delete a key.
    """

    @pytest.mark.parametrize("extra", ["", "--set profile=cost"])
    @pytest.mark.parametrize("tree", ["capabilities", "allowedResources"])
    def test_no_nulls(self, extra, tree):
        _, installed = config_maps(render(extra))
        assert null_paths(installed[tree], tree) == []


class TestApplyProfileRunsFirstEverywhere:
    """
    Helm renders templates deepest-path-first and then reverse-alphabetically, so which
    template observes the profile first is an accident of directory naming: add
    templates/windows/foo.yaml and it sorts after templates/watcher/ and reads pre-profile
    values. Rather than track which templates read what, every rendered template runs the
    helper as its first action - then render order cannot matter at all.

    Partials are excluded because helm never renders a file whose basename starts with "_";
    an include there would be dead code.
    """

    @staticmethod
    def _rendered_templates():
        for root, _, names in os.walk(TEMPLATES_DIR):
            for name in names:
                if not name.startswith("_"):
                    yield os.path.join(root, name)

    @staticmethod
    def _first_action(text):
        """Offset of the first template action, skipping any leading template comments."""
        pos = 0
        while True:
            match = re.compile(r"\{\{").search(text, pos)
            if match is None:
                return None
            after = text[match.end():].lstrip("-").lstrip()
            if after.startswith("/*"):
                close = text.find("*/", match.end())
                if close == -1:
                    return match.start()
                pos = close
                continue
            return match.start()

    def test_every_rendered_template_starts_with_the_helper(self):
        problems = []
        checked = 0
        for path in self._rendered_templates():
            checked += 1
            text = open(path).read()
            rel = os.path.relpath(path, TEMPLATES_DIR)
            include = APPLY_PROFILE_RE.search(text)
            if include is None:
                problems.append(f"{rel}: never includes applyProfile")
                continue
            first = self._first_action(text)
            if first is not None and first < include.start() - len('{{- include "'):
                problems.append(f"{rel}: runs something before applyProfile")
        assert checked > 20, "template directory looks wrong, this asserted almost nothing"
        assert problems == [], (
            "every rendered template must run applyProfile first, or it can read a "
            f"pre-profile value: {problems}"
        )

    def test_partials_do_not_carry_a_dead_include(self):
        """
        helm skips files whose basename starts with "_", so an include at the top of a partial
        never runs. templates/watcher/_containers.tpl has exactly that for migrateHelmValues;
        this test keeps the profile helper from growing the same dead wiring.
        """
        for root, _, names in os.walk(TEMPLATES_DIR):
            for name in names:
                if not name.startswith("_"):
                    continue
                text = open(os.path.join(root, name)).read()
                for line in text.splitlines():
                    if 'include "applyProfile"' in line and "define" not in text[:text.index(line)][-200:]:
                        break
                else:
                    continue
        # a partial may legitimately include the helper *inside* a define; only a top-level
        # include is dead, and there are none today
        top_level = []
        for root, _, names in os.walk(TEMPLATES_DIR):
            for name in names:
                if not name.startswith("_"):
                    continue
                path = os.path.join(root, name)
                text = open(path).read()
                head = text.split('{{- define', 1)[0]
                if 'include "applyProfile"' in head:
                    top_level.append(os.path.relpath(path, TEMPLATES_DIR))
        assert top_level == [], f"dead top-level include in partials (helm never runs them): {top_level}"
