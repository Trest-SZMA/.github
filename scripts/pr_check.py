"""Проверка PR по регламенту Trest-SZMA (раздел 6). Запускается из workflow pr-check.

Аргументы: --base <ветка, куда PR> --head <ветка PR> --base-sha <sha базы> [--max-mb 10].
Выход 1 — есть нарушения; каждое печатается строкой ::error для GitHub.
"""
import argparse
import json
import os
import subprocess
import sys

PROTECTED = ("main", "Development")
CONFLICT_PREFIXES = ("<<<<<<< ", ">>>>>>> ")
PBIP_JSON_SUFFIXES = (".json", ".pbir", ".pbism", ".platform")


def git(*args):
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True, encoding="utf-8").stdout


def check_direction(base, head):
    if base == "main" and head != "Development":
        return [f"PR в main допускается только из Development, а не из «{head}»."]
    if base == "Development" and head in PROTECTED:
        return [f"PR в Development — из ветки задачи, а не из «{head}»."]
    return []


def check_tree(max_mb):
    errors = []
    for path in git("ls-files", "-z").split("\0"):
        if not path:
            continue
        if path.lower().endswith(".pbix"):
            errors.append(f"{path}: файлы .pbix запрещены — сохраните модель как PBIP.")
        elif os.path.isfile(path) and os.path.getsize(path) > max_mb * 1024 * 1024:
            errors.append(f"{path}: файл больше {max_mb} МБ.")
    return errors


def changed_files(base_sha):
    out = git("diff", "--name-only", "--diff-filter=AMR", "-z", f"{base_sha}...HEAD")
    return [p for p in out.split("\0") if p and os.path.isfile(p)]


def read_text(path):
    try:
        with open(path, encoding="utf-8-sig") as f:
            return f.read()
    except (UnicodeDecodeError, OSError):
        return None  # двоичный файл — не проверяем


def check_conflicts(files):
    errors = []
    for path in files:
        text = read_text(path)
        if text is None:
            continue
        for n, line in enumerate(text.splitlines(), 1):
            if line.startswith(CONFLICT_PREFIXES) or line == "<<<<<<<" or line == ">>>>>>>":
                errors.append(f"{path}:{n}: неразрешённый конфликт.")
                break
    return errors


def in_pbip(path):
    return any(part.endswith((".SemanticModel", ".Report", ".Dataset")) for part in path.replace("\\", "/").split("/"))


def check_pbip(files):
    errors = []
    for path in files:
        if not in_pbip(path) and not path.endswith(".pbip"):
            continue
        if path.endswith(PBIP_JSON_SUFFIXES) or path.endswith(".pbip"):
            text = read_text(path)
            try:
                json.loads(text or "")
            except json.JSONDecodeError as e:
                errors.append(f"{path}:{e.lineno}: файл PBIP не читается как JSON — {e.msg}.")
        elif path.endswith(".tmdl"):
            text = read_text(path)
            if text is None or not text.strip():
                errors.append(f"{path}: файл TMDL пустой или не в UTF-8.")
    return errors


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument("--base", required=True)
    p.add_argument("--head", required=True)
    p.add_argument("--base-sha", required=True)
    p.add_argument("--max-mb", type=float, default=10)
    a = p.parse_args(argv)

    files = changed_files(a.base_sha)
    sections = [
        ("Направление PR", check_direction(a.base, a.head)),
        (".pbix и крупные файлы", check_tree(a.max_mb)),
        ("Конфликты", check_conflicts(files)),
        ("PBIP", check_pbip(files)),
    ]
    failed = False
    for title, errors in sections:
        print(f"{'✗' if errors else '✓'} {title}")
        for e in errors:
            print(f"::error::{e}")
        failed = failed or bool(errors)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
