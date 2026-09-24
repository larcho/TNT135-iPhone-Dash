import sys
from pathlib import Path

# Pure modules under src/ are importable on CPython; hardware modules are not tested here.
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
