package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"strings"

	yaml "gopkg.in/yaml.v2"
)

type HelmRelease struct {
	Name      string `json:"name"`
	Namespace string `json:"namespace"`
}

var version = "dev"

func main() {
	var outputFile string
	var releaseName string
	var showVersion bool
	flag.BoolVar(&showVersion, "v", false, "Show the version and exit")
	flag.StringVar(&outputFile, "o", "komodor_watcher_values.yaml", "Output values file")
	flag.StringVar(&releaseName, "r", "k8s-watcher", "Release name")
	flag.Parse()

	showVersionAndExit(showVersion)

	namespace := getNamespace(releaseName)
	oldValues := getOldValues(namespace, releaseName)
	flatMap := flattenOldValues(oldValues)
	newValues := mapOldToNewValues(flatMap)

	err := writeNewValuesToFile(outputFile, newValues)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	printUpdateCommand(releaseName, outputFile, namespace)
}

func printUpdateCommand(releaseName string, outputFile string, namespace string) {
	updateCmd := fmt.Sprintf("helm upgrade %s komodorio/k8s-watcher -f %s -n %s\n", releaseName, outputFile, namespace)
	printHashMessage("Use the following command to upgrade the release:\n" + updateCmd)
}

func showVersionAndExit(showVersion bool) {
	if showVersion {
		fmt.Printf("Version: %s\n", version)
		os.Exit(0)
	}
}

func writeNewValuesToFile(filename string, newValues map[string]interface{}) error {
	newValuesYAML, err := yaml.Marshal(newValues)
	if err != nil {
		return err
	}
	return writeFile(filename, newValuesYAML)
}

func mapOldToNewValues(flatMap map[string]interface{}) map[string]interface{} {
	newValues := make(map[string]interface{})
	for oldKey, value := range flatMap {
		if newKey, exists := mapping[oldKey]; exists {
			if newKey == "" {
				fmt.Printf("- Skipping: %s: %s\n", oldKey, value)
				continue
			}
			setValueInMap(newValues, newKey, value)
			fmt.Printf("+ Converted: %s > %s\n", oldKey, newKey)
		} else {
			setValueInMap(newValues, oldKey, value)
			fmt.Printf("= Not Changeg: %s\n", oldKey)
		}
	}
	return newValues
}

func flattenOldValues(oldValues map[string]interface{}) map[string]interface{} {
	flatMap := make(map[string]interface{})
	flattenMap(oldValues, "", flatMap)
	return flatMap
}

func getOldValues(namespace string, releaseName string) map[string]interface{} {
	cmd := exec.Command("helm", "get", "values", releaseName, "-n", namespace)
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		fmt.Println("Error:", err)
		return nil
	}

	var oldValues map[string]interface{}
	err = yaml.Unmarshal(out.Bytes(), &oldValues)
	if err != nil {
		fmt.Println("Error:", err)
		return nil
	}
	return oldValues
}
func writeFile(filename string, data []byte) error {
	err := os.WriteFile(filename, data, os.ModePerm)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return err
	}
	return nil
}

func getNamespace(releaseName string) string {
	cmd := exec.Command("helm", "ls", "-A", "-o", "json")
	var helmOut bytes.Buffer
	cmd.Stdout = &helmOut
	err := cmd.Run()
	if err != nil {
		fmt.Println("Error:", err)
		return "default"
	}

	var helmReleases []HelmRelease
	err = json.Unmarshal(helmOut.Bytes(), &helmReleases)
	if err != nil {
		fmt.Println("Error:", err)
		return "default"
	}

	// Find the namespace for the release named 'k8s-watcher'
	var namespace string
	for _, release := range helmReleases {
		if release.Name == releaseName {
			namespace = release.Namespace
			break
		}
	}

	if namespace == "" {
		fmt.Printf("%s not found\n", releaseName)
		return "default"
	}

	return namespace
}

func flattenMap(data map[string]interface{}, parentKey string, flatMap map[string]interface{}) {
	for k, v := range data {
		newKey := k
		if parentKey != "" {
			newKey = parentKey + "." + k
		}

		switch value := v.(type) {
		case map[interface{}]interface{}:
			converted, ok := convertToMapStringInterface(value)
			if !ok {
				converted = make(map[string]interface{})
				for key, val := range value {
					strKey, ok := key.(string)
					if ok {
						converted[strKey] = val
					}
				}
			}
			flattenMap(converted, newKey, flatMap)
		case map[string]interface{}:
			flattenMap(value, newKey, flatMap)
		default:
			flatMap[newKey] = v
		}
	}
}

func convertToMapStringInterface(input interface{}) (map[string]interface{}, bool) {
	if input == nil {
		return nil, false
	}

	switch inputMap := input.(type) {
	case map[string]interface{}:
		return inputMap, true
	case map[interface{}]interface{}:
		strMap := make(map[string]interface{})
		for key, value := range inputMap {
			strKey, ok := key.(string)
			if !ok {
				return nil, false
			}
			strMap[strKey] = value
		}
		return strMap, true
	default:
		return nil, false
	}
}

func setValueInMap(m map[string]interface{}, key string, value interface{}) {
	keys := strings.Split(key, ".")
	lastKey := keys[len(keys)-1]
	var val interface{} = m
	for _, k := range keys[:len(keys)-1] {
		valMap, ok := val.(map[string]interface{})
		if !ok {
			valMap = make(map[string]interface{})
			val = valMap
		}
		if valMap[k] == nil {
			valMap[k] = make(map[string]interface{})
		}
		val = valMap[k]
	}
	valMap, ok := val.(map[string]interface{})
	if ok {
		valMap[lastKey] = value
	}
}

func printHashMessage(message string) {
	length := len(message)
	hashes := strings.Repeat("#", length+4)

	fmt.Printf("\n")
	fmt.Println(hashes)
	fmt.Printf(message)
	fmt.Println(hashes)
}
