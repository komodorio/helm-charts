"""
Shared pytest fixtures and configuration for the test suite.
"""
import os
import tempfile
import shutil
from pathlib import Path
from typing import Generator, Dict, Any

import pytest


@pytest.fixture
def temp_dir() -> Generator[Path, None, None]:
    """Create a temporary directory for test files."""
    temp_path = Path(tempfile.mkdtemp())
    try:
        yield temp_path
    finally:
        shutil.rmtree(temp_path, ignore_errors=True)


@pytest.fixture
def temp_file(temp_dir: Path) -> Path:
    """Create a temporary file in the temp directory."""
    temp_file_path = temp_dir / "test_file.txt"
    temp_file_path.write_text("test content")
    return temp_file_path


@pytest.fixture
def mock_env_vars() -> Generator[Dict[str, str], None, None]:
    """Mock environment variables with cleanup."""
    original_env = dict(os.environ)
    test_env = {
        "TEST_MODE": "true",
        "DEBUG": "false",
        "LOG_LEVEL": "INFO"
    }
    os.environ.update(test_env)
    try:
        yield test_env
    finally:
        os.environ.clear()
        os.environ.update(original_env)


@pytest.fixture
def sample_config() -> Dict[str, Any]:
    """Sample configuration data for tests."""
    return {
        "version": "1.0.0",
        "debug": False,
        "database": {
            "host": "localhost",
            "port": 5432,
            "name": "test_db"
        },
        "features": {
            "feature_a": True,
            "feature_b": False
        }
    }


@pytest.fixture
def sample_yaml_content() -> str:
    """Sample YAML content for testing."""
    return """
apiVersion: v1
kind: ConfigMap
metadata:
  name: test-config
  namespace: default
data:
  config.yaml: |
    test: true
    value: 42
"""


@pytest.fixture
def sample_json_content() -> str:
    """Sample JSON content for testing."""
    return '{"test": true, "value": 42, "items": [1, 2, 3]}'


@pytest.fixture(autouse=True)
def reset_working_directory():
    """Ensure tests start with a clean working directory state."""
    original_cwd = os.getcwd()
    yield
    os.chdir(original_cwd)


@pytest.fixture(scope="session")
def project_root() -> Path:
    """Get the project root directory."""
    return Path(__file__).parent.parent


@pytest.fixture
def charts_dir(project_root: Path) -> Path:
    """Get the charts directory."""
    return project_root / "charts"


@pytest.fixture
def manifests_dir(project_root: Path) -> Path:
    """Get the manifests directory."""
    return project_root / "manifests"