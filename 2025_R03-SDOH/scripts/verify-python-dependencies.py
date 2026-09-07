#!/usr/bin/env python3
"""Verify that an interpreter exactly matches the public Python lock."""

from __future__ import annotations

import argparse
import importlib.metadata
from pathlib import Path


def locked(path: Path) -> dict[str, str]:
    result = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if line and not line.startswith("#"):
            name, version = line.split("==", 1)
            result[name.lower()] = version
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lock", required=True, type=Path)
    args = parser.parse_args()
    expected = locked(args.lock)
    actual = {dist.metadata["Name"].lower(): dist.version for dist in importlib.metadata.distributions()}
    mismatches = [f"{name}: expected {version}, found {actual.get(name, 'missing')}"
                  for name, version in expected.items() if actual.get(name) != version]
    if mismatches:
        print("\n".join(mismatches))
        return 1
    print(f"Python dependency lock verified ({len(expected)} packages).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
