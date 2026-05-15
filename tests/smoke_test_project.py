from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = [
    "README.md",
    "requirements.txt",
    ".github/workflows/ci.yml",
    "docs/diagrams/architecture.svg",
    "dbt/dbt_project.yml",
    "dbt/profiles.yml",
    "dbt/packages.yml",
    "terraform/main.tf",
    "snowpark/data_quality_local_demo.py",
]

FORBIDDEN = [
    "dbt/logs",
    "dbt/target",
    "dbt/dbt_packages",
    "logs",
    ".vscode",
    ".terraform",
    ".pytest_cache",
    "__pycache__",
    "tests/__pycache__",
]


def test_required_files_exist() -> None:
    missing = [p for p in REQUIRED if not (ROOT / p).exists()]
    assert not missing, f"Missing required files: {missing}"


def test_forbidden_directories_absent() -> None:
    present = [p for p in FORBIDDEN if (ROOT / p).exists()]
    assert not present, f"Forbidden directories present: {present}"


if __name__ == "__main__":
    test_required_files_exist()
    test_forbidden_directories_absent()
    print("Smoke test passed: required files exist and forbidden directories are absent.")
