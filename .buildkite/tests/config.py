import os
import base64

API_KEY = os.environ.get("API_KEY", "92dc9cf8-dcf6-40c9-87e1-a0fd2835ef47")
API_KEY_B64 = base64.b64encode(API_KEY.encode()).decode()
CLUSTER_NAME = os.environ.get("CLUSTER_NAME", "helm-chart-test-mk")
RELEASE_NAME = os.environ.get("RELEASE_NAME", "helm-test")
CHART_PATH = os.environ.get("CHART_PATH", "../../charts/k8s-watcher")
VALUES_FILE_PATH = os.environ.get("VALUES_FILE_PATH", "")
NAMESPACE = os.environ.get("NAMESPACE", "komodor")
BE_BASE_URL = os.environ.get("BE_BASE_URL", "https://app.komodor.com")