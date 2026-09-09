"""Check bundle consistency, compile Luau sources and run adapter lifecycle tests."""
from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path

from build import DIST, ROOT, SOURCES, build_bundle


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau-dir", type=Path, default=ROOT / ".tools" / "luau")
    args = parser.parse_args()
    if not DIST.is_file() or DIST.read_text(encoding="utf-8") != build_bundle():
        raise SystemExit("Bundle desatualizado. Execute python scripts/build.py.")

    def binary(name: str) -> str:
        for candidate in (args.luau_dir / f"{name}.exe", args.luau_dir / name):
            if candidate.is_file():
                return str(candidate.resolve())
        found = shutil.which(name)
        if found:
            return found
        raise SystemExit(f"{name} nao encontrado. Informe --luau-dir ou adicione ao PATH.")

    compiler, runtime = binary("luau-compile"), binary("luau")
    source_paths = [str(path.relative_to(ROOT)) for path in SOURCES.values()]
    subprocess.run([compiler, "--null", *source_paths, str(DIST.relative_to(ROOT))], cwd=ROOT, check=True)

    # Bundle the real module into the tests, matching distribution and avoiding
    # native require path-resolution issues in accented Windows directories.
    tests = (ROOT / "tests" / "sensory_esp.luau").read_text(encoding="utf-8")
    marker = 'local SensoryESP = require("../src/Integrations/SensoryESP")'
    assert tests.count(marker) == 1
    source = SOURCES["SensoryESP"].read_text(encoding="utf-8")
    test_bundle = tests.replace(marker, "local SensoryESP = (function()\n" + source + "\nend)()")
    target = ROOT / ".tools" / "sensory_esp_test_bundle.luau"
    target.parent.mkdir(exist_ok=True)
    target.write_text(test_bundle, encoding="utf-8", newline="\n")
    subprocess.run([runtime, str(target.relative_to(ROOT))], cwd=ROOT, check=True)
    print("OK: bundle, Luau compilation and adapter lifecycle tests.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
