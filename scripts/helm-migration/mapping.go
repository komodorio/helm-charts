package main

var mapping = map[string]string{
	"watcher.clusterName":                       "clusterName",
	"watcher.enableAgentTaskExecution":          "",
	"watcher.enableAgentTaskExecutionV2":        "",
	"watcher.enableHelm":                        "",
	"watcher.daemon.varsConfigMapName":          "",
	"watcher.servers.healthCheck":               "",
	"watcher.collectHistory":                    "",
	"watcher.watchNamespace":                    "events.watchNamespace",
	"watcher.namespacesDenylist":                "events.namespacesDenylist",
	"watcher.logsNamespacesDenylist":            "logs.logsNamespacesDenylist",
	"watcher.logsNamespacesAllowlist":           "logs.logsNamespacesAllowlist",
	"watcher.nameDenylist":                      "logs.nameDenylist",
	"watcher.redact":                            "events.redact",
	"watcher.redactLogs":                        "logs.redactLogs",
	"watcher.actions.basic":                     "capabilities.actions.basic",
	"watcher.actions.advanced":                  "capabilities.actions.advanced",
	"watcher.actions.podExec":                   "",
	"watcher.actions.portforward":               "",
	"watcher.telemetry.enable":                  "",
	"watcher.telemetry.collectApiServerMetrics": "debug.collectApiServerMetrics",
	"watcher.memoryThresholdSafetyCheck.enable": "",
	"watcher.networkMapper.enable":              "capabilities.networkMapper",
	"watcher.monitoringFQDN":                    "",
	"watcher.allowReadingPodLogs":               "capabilities.logs.enabled",
	"metrics.enabled":                           "capabilities.metrics",
	"helm.enableActions":                        "",
}
