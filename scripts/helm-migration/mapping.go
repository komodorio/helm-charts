package main

var mapping = map[string]string{
	"metrics.enabled":          "capabilities.metrics.enabled",
	"watcher.actions.advanced": "capabilities.watcher.actions.advanced",
	"watcher.actions.basic":    "capabilities.watcher.actions.basic",
	"watcher.actions.podExec":  "",
	"watcher.clusterName":      "basic.clusterName",
}
