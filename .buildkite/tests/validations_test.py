import pytest
from config import API_KEY
from helpers.utils import get_filename_as_cluster_name
from helpers.helm_helper import helm_agent_template

CLUSTER_NAME = get_filename_as_cluster_name(__file__)


class TestSiteValidation:
    """Tests for site value validation"""

    @pytest.mark.parametrize(
        "invalid_site",
        ["il", "asia", "invalid", "EU", "US", ""]
    )
    def test_invalid_site_values(self, invalid_site):
        """Test that invalid site values are rejected"""
        settings = f"--set apiKey={API_KEY} --set clusterName={CLUSTER_NAME} --set site={invalid_site}"
        output, exit_code = helm_agent_template(settings=settings)

        assert exit_code != 0, f"helm template should fail with invalid site '{invalid_site}', output: {output}"
        assert "site is required and must be either 'eu' or 'us'" in output, \
            f"Expected site validation error message, got: {output}"

    @pytest.mark.parametrize(
        "valid_site",
        ["eu", "us"]
    )
    def test_valid_site_values(self, valid_site):
        """Test that valid site values are accepted"""
        settings = f"--set apiKey={API_KEY} --set clusterName={CLUSTER_NAME} --set site={valid_site}"
        output, exit_code = helm_agent_template(settings=settings)

        assert exit_code == 0, f"helm template should succeed with valid site '{valid_site}', output: {output}"


class TestClusterNameValidation:
    """Tests for clusterName validation"""

    def test_missing_cluster_name(self):
        """Test that missing clusterName is rejected"""
        settings = f"--set apiKey={API_KEY} --set site=us"
        output, exit_code = helm_agent_template(settings=settings)

        assert exit_code != 0, f"helm template should fail without clusterName, output: {output}"
        assert "clusterName is a required value!" in output, \
            f"Expected clusterName validation error message, got: {output}"

    def test_empty_cluster_name(self):
        """Test that empty clusterName is rejected"""
        settings = f"--set apiKey={API_KEY} --set site=us --set clusterName=''"
        output, exit_code = helm_agent_template(settings=settings)

        assert exit_code != 0, f"helm template should fail with empty clusterName, output: {output}"
        assert "clusterName is a required value!" in output, \
            f"Expected clusterName validation error message, got: {output}"


class TestApiKeyValidation:
    """Tests for apiKey validation"""

    def test_missing_api_key(self):
        """Test that missing apiKey is rejected when not using existing secret"""
        settings = f"--set clusterName={CLUSTER_NAME} --set site=us"
        output, exit_code = helm_agent_template(settings=settings)

        assert exit_code != 0, f"helm template should fail without apiKey, output: {output}"
        assert "apiKey is a required value!" in output, \
            f"Expected apiKey validation error message, got: {output}"

    def test_empty_api_key(self):
        """Test that empty apiKey is rejected"""
        settings = f"--set apiKey='' --set clusterName={CLUSTER_NAME} --set site=us"
        output, exit_code = helm_agent_template(settings=settings)

        assert exit_code != 0, f"helm template should fail with empty apiKey, output: {output}"
        assert "apiKey is a required value!" in output, \
            f"Expected apiKey validation error message, got: {output}"

    def test_api_key_secret_bypasses_validation(self):
        """Test that using apiKeySecret allows skipping apiKey"""
        settings = f"--set clusterName={CLUSTER_NAME} --set site=us --set apiKeySecret=my-secret"
        output, exit_code = helm_agent_template(settings=settings)

        assert exit_code == 0, f"helm template should succeed with apiKeySecret, output: {output}"


class TestServiceAccountValidation:
    """Tests for serviceAccount validation"""

    def test_missing_service_account_name_when_not_creating(self):
        """Test that serviceAccount.name is required when create is false"""
        settings = f"--set apiKey={API_KEY} --set clusterName={CLUSTER_NAME} --set site=us " \
                   f"--set serviceAccount.create=false"
        output, exit_code = helm_agent_template(settings=settings)

        assert exit_code != 0, f"helm template should fail without serviceAccount.name, output: {output}"
        assert "you must provide a serviceAccount.name when serviceAccount.create is not set to true" in output, \
            f"Expected serviceAccount validation error message, got: {output}"

    def test_service_account_name_provided_when_not_creating(self):
        """Test that providing serviceAccount.name when create is false works"""
        settings = f"--set apiKey={API_KEY} --set clusterName={CLUSTER_NAME} --set site=us " \
                   f"--set serviceAccount.create=false --set serviceAccount.name=my-sa"
        output, exit_code = helm_agent_template(settings=settings)

        assert exit_code == 0, f"helm template should succeed with serviceAccount.name, output: {output}"


class TestAdmissionControllerServiceAccountValidation:
    """Tests for admission controller serviceAccount validation"""

    def test_missing_admission_controller_sa_name_when_not_creating(self):
        """Test that admission controller serviceAccount.name is required when create is false"""
        settings = f"--set apiKey={API_KEY} --set clusterName={CLUSTER_NAME} --set site=us " \
                   f"--set components.admissionController.enabled=true " \
                   f"--set components.admissionController.serviceAccount.create=false"
        output, exit_code = helm_agent_template(settings=settings)

        assert exit_code != 0, \
            f"helm template should fail without admission controller serviceAccount.name, output: {output}"
        assert "you must provide a components.admissionController.serviceAccount.name" in output, \
            f"Expected admission controller serviceAccount validation error message, got: {output}"

    def test_admission_controller_sa_name_provided_when_not_creating(self):
        """Test that providing admission controller serviceAccount.name when create is false works"""
        settings = f"--set apiKey={API_KEY} --set clusterName={CLUSTER_NAME} --set site=us " \
                   f"--set components.admissionController.enabled=true " \
                   f"--set components.admissionController.serviceAccount.create=false " \
                   f"--set components.admissionController.serviceAccount.name=my-ac-sa"
        output, exit_code = helm_agent_template(settings=settings)

        assert exit_code == 0, \
            f"helm template should succeed with admission controller serviceAccount.name, output: {output}"

    def test_admission_controller_disabled_skips_validation(self):
        """Test that admission controller SA validation is skipped when disabled"""
        settings = f"--set apiKey={API_KEY} --set clusterName={CLUSTER_NAME} --set site=us " \
                   f"--set components.admissionController.enabled=false " \
                   f"--set components.admissionController.serviceAccount.create=false"
        output, exit_code = helm_agent_template(settings=settings)

        assert exit_code == 0, \
            f"helm template should succeed when admission controller is disabled, output: {output}"


class TestTagsValidation:
    """Tests for tags format validation"""

    def test_tags_as_map(self):
        """Test that tags work as a map"""
        settings = f"--set apiKey={API_KEY} --set clusterName={CLUSTER_NAME} --set site=us " \
                   f"--set tags.env=production --set tags.team=platform"
        output, exit_code = helm_agent_template(settings=settings)

        assert exit_code == 0, f"helm template should succeed with tags as map, output: {output}"

    def test_tags_as_string(self):
        """Test that tags work as a semicolon-separated string"""
        settings = f"--set apiKey={API_KEY} --set clusterName={CLUSTER_NAME} --set site=us " \
                   f"--set tags='env:production;team:platform'"
        output, exit_code = helm_agent_template(settings=settings)

        assert exit_code == 0, f"helm template should succeed with tags as string, output: {output}"

    def test_tags_as_invalid_type_using_values_file(self):
        """Test that tags with invalid type (array) are rejected"""
        values_content = """
apiKey: test-key
clusterName: test-cluster
site: us
tags:
  - invalid
  - array
"""
        output, exit_code = helm_agent_template(settings="", values_file=values_content)

        assert exit_code != 0, f"helm template should fail with tags as array, output: {output}"
        assert "Invalid type for .Values.tags. Expected map or string." in output, \
            f"Expected tags validation error message, got: {output}"


class TestCombinedValidations:
    """Tests for multiple validation failures"""

    def test_all_required_values_present(self):
        """Test that all required values work together"""
        settings = f"--set apiKey={API_KEY} --set clusterName={CLUSTER_NAME} --set site=us"
        output, exit_code = helm_agent_template(settings=settings)

        assert exit_code == 0, f"helm template should succeed with all required values, output: {output}"

    def test_multiple_missing_values(self):
        """Test that first validation error is shown when multiple values are missing"""
        settings = ""
        output, exit_code = helm_agent_template(settings=settings)

        assert exit_code != 0, f"helm template should fail with missing values, output: {output}"
        # Should fail on first validation (site)
        assert "site is required" in output or "clusterName is a required" in output or "apiKey is a required" in output, \
            f"Expected validation error message, got: {output}"
