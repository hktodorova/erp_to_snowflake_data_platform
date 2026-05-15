from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_local_data_quality_demo_passes() -> None:
    subprocess.run([sys.executable, "scripts/generate_sample_data.py"], cwd=ROOT, check=True)
    result = subprocess.run([sys.executable, "snowpark/data_quality_local_demo.py"], cwd=ROOT, text=True, capture_output=True, check=True)
    assert "FAIL" not in result.stdout
