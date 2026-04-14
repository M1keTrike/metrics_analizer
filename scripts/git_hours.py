#!/usr/bin/env python3
"""
Implementación simple de la heurística tipo git-hours.

Reglas:
- Se usa: git log --all --format="%an|%at"
  donde %at es timestamp unix (segundos) y %an es autor (nombre).

- Se agrupa por autor y se ordena por timestamp.
- Para commits consecutivos del mismo autor:
  * si diff < 2h -> suma diff real
  * si diff >= 2h -> suma 2h (nueva sesión)
- Al primer commit de cada autor se le suman +2h.
- Total final = suma de todos los autores.

Salida:
- Imprime el total de horas como entero (floor).
- Sin dependencias externas.
"""

from __future__ import annotations

import os
import subprocess
import sys
from collections import defaultdict


TWO_HOURS = 2 * 60 * 60


def run_git(repo_path: str, args: list[str]) -> str:
    return subprocess.check_output(
        ["git", "-C", repo_path] + args,
        stderr=subprocess.DEVNULL,
        text=True,
    )


def compute_git_hours(repo_path: str) -> int:
    # Formato: "Autor|timestamp"
    out = run_git(repo_path, ["log", "--all", "--format=%an|%at"])
    lines = [ln.strip() for ln in out.splitlines() if ln.strip()]

    by_author: dict[str, list[int]] = defaultdict(list)

    for ln in lines:
        if "|" not in ln:
            continue
        author, ts = ln.rsplit("|", 1)
        author = author.strip()
        ts = ts.strip()
        if not author or not ts:
            continue
        try:
            by_author[author].append(int(ts))
        except ValueError:
            continue

    total_seconds = 0

    for _author, timestamps in by_author.items():
        if not timestamps:
            continue
        timestamps.sort()

        # +2h al primer commit del autor
        total_seconds += TWO_HOURS

        prev = timestamps[0]
        for cur in timestamps[1:]:
            diff = cur - prev
            if diff < 0:
                diff = 0

            if diff < TWO_HOURS:
                total_seconds += diff
            else:
                total_seconds += TWO_HOURS

            prev = cur

    return total_seconds // 3600


def main() -> int:
    repo_path = sys.argv[1] if len(sys.argv) > 1 else ""

    if not repo_path:
        print("Uso: git_hours.py /ruta/al/repo", file=sys.stderr)
        return 2

    if not os.path.isdir(repo_path):
        print(f"Ruta no existe: {repo_path}", file=sys.stderr)
        return 2

    if not os.path.isdir(os.path.join(repo_path, ".git")):
        print("La ruta debe apuntar a un repositorio git con .git", file=sys.stderr)
        return 2

    try:
        hours = compute_git_hours(repo_path)
    except subprocess.CalledProcessError:
        # Si git falla (p.ej. repo sin commits), devolver 0
        hours = 0

    print(str(hours))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())