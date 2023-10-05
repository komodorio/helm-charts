import os
import base64

API_KEY = os.environ.get("API_KEY", "512ecd36-aa72-4d37-af48-8ecdc817c822")
API_KEY_B64 = base64.b64encode(API_KEY.encode()).decode()
RELEASE_NAME = os.environ.get("RELEASE_NAME", "helm-test")
CHART_PATH = os.environ.get("CHART_PATH", "../../charts/komodor-agent")
VALUES_FILE_PATH = os.environ.get("VALUES_FILE_PATH", "")
NAMESPACE = os.environ.get("NAMESPACE", "test-chart")
BE_BASE_URL = os.environ.get("BE_BASE_URL", "https://app.komodor.com")