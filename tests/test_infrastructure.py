"""
Validation tests to ensure the testing infrastructure is working correctly.
"""
import os
import sys
from pathlib import Path

import pytest


class TestInfrastructure:
    """Test suite to validate the testing infrastructure setup."""
    
    def test_pytest_is_working(self):
        """Test that pytest is working correctly."""
        assert True
    
    def test_fixtures_are_available(self, temp_dir, sample_config):
        """Test that custom fixtures are working."""
        assert temp_dir.exists()
        assert temp_dir.is_dir()
        assert isinstance(sample_config, dict)
        assert "version" in sample_config
    
    def test_temp_file_fixture(self, temp_file):
        """Test the temp_file fixture."""
        assert temp_file.exists()
        assert temp_file.read_text() == "test content"
    
    def test_project_structure_fixtures(self, project_root, charts_dir, manifests_dir):
        """Test project structure fixtures."""
        assert project_root.exists()
        assert project_root.name in ["workspace", "helm-charts"]
        assert charts_dir.exists() or not charts_dir.parent.exists()
        assert manifests_dir.exists() or not manifests_dir.parent.exists()
    
    @pytest.mark.unit
    def test_unit_marker(self):
        """Test that unit marker works."""
        assert True
    
    @pytest.mark.integration
    def test_integration_marker(self):
        """Test that integration marker works."""
        assert True
    
    @pytest.mark.slow
    def test_slow_marker(self):
        """Test that slow marker works."""
        assert True
    
    def test_environment_variables(self, mock_env_vars):
        """Test environment variable mocking."""
        assert os.getenv("TEST_MODE") == "true"
        assert os.getenv("DEBUG") == "false"
        assert "TEST_MODE" in mock_env_vars
    
    def test_sample_data_fixtures(self, sample_yaml_content, sample_json_content):
        """Test sample data fixtures."""
        assert "apiVersion: v1" in sample_yaml_content
        assert "kind: ConfigMap" in sample_yaml_content
        assert '"test": true' in sample_json_content
        assert '"value": 42' in sample_json_content
    
    def test_python_version(self):
        """Test that Python version is compatible."""
        version_info = sys.version_info
        assert version_info.major == 3
        assert version_info.minor >= 8
    
    def test_coverage_will_work(self):
        """Test that coverage reporting will work by creating some code to cover."""
        def sample_function(x, y):
            if x > y:
                return x + y
            else:
                return x - y
        
        result = sample_function(5, 3)
        assert result == 8
        
        result = sample_function(2, 5)
        assert result == -3


class TestProjectStructure:
    """Test the project structure and files."""
    
    def test_pyproject_toml_exists(self, project_root):
        """Test that pyproject.toml exists."""
        pyproject_file = project_root / "pyproject.toml"
        assert pyproject_file.exists()
    
    def test_tests_directory_structure(self, project_root):
        """Test the tests directory structure."""
        tests_dir = project_root / "tests"
        assert tests_dir.exists()
        assert (tests_dir / "__init__.py").exists()
        assert (tests_dir / "conftest.py").exists()
        assert (tests_dir / "unit").exists()
        assert (tests_dir / "unit" / "__init__.py").exists()
        assert (tests_dir / "integration").exists()
        assert (tests_dir / "integration" / "__init__.py").exists()
    
    def test_gitignore_has_testing_entries(self, project_root):
        """Test that .gitignore includes testing-related entries."""
        gitignore_file = project_root / ".gitignore"
        if gitignore_file.exists():
            content = gitignore_file.read_text()
            assert ".coverage" in content
            assert "htmlcov/" in content
            assert "coverage.xml" in content
            assert ".claude/*" in content