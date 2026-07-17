"""NovaCart ingestion application entry point."""

from __future__ import annotations

from ingestion.config.settings import settings


def create_required_directories() -> None:
    """Create local project directories when they do not exist."""

    required_directories = [
        settings.generated_directory,
        settings.rejected_directory,
        settings.archive_directory,
        settings.logs_directory,
    ]

    for directory in required_directories:
        directory.mkdir(parents=True, exist_ok=True)


def main() -> None:
    """Run the initial project setup check."""

    create_required_directories()

    print("NovaCart Customer 360 project initialized.")
    print(f"Environment: {settings.environment}")
    print(f"AWS region: {settings.aws_region}")
    print(f"Project root: {settings.generated_directory.parent.parent}")


if __name__ == "__main__":
    main()
