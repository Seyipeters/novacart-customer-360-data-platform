"""Tests for the NovaCart project configuration."""

from ingestion.config.settings import settings
from ingestion.main import create_required_directories


def test_project_name_is_configured() -> None:
    """Verify that the project has a valid name."""

    assert settings.project_name == "novacart-customer-360"


def test_required_directories_are_created() -> None:
    """Verify that required local directories exist."""

    create_required_directories()

    assert settings.generated_directory.exists()
    assert settings.rejected_directory.exists()
    assert settings.archive_directory.exists()
    assert settings.logs_directory.exists()
