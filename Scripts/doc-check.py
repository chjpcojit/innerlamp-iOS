#!/usr/bin/env python3
"""Docs consistency check for Assumptions, Tech Debt and SRS acceptance criteria.

Pure standard library, no network, no token cost. Run from anywhere:

    python3 Scripts/doc-check.py              # check everything
    python3 Scripts/doc-check.py --changed    # only files changed in git (plus their feature)
    python3 Scripts/doc-check.py --strict     # warnings also fail the run

Exit code 1 when there is at least one ERROR (or any WARN with --strict).
Rules come from AGENTS.md section 10 and the ba-builder Gherkin convention.
"""
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LEVELS = {"Low", "Medium", "High", "Critical"}
STATUS = {
    "AS": {"Unvalidated", "Validated", "Invalidated"},
    "TD": {"Open", "In Progress", "Resolved", "Won't Fix"},
}
CLOSED = {"Validated", "Invalidated", "Resolved", "Won't Fix"}
COMMON_KEYS = ["id", "title", "title_vi", "feature", "level", "status", "created", "updated", "files"]
EXTRA_KEYS = {"AS": ["source", "owner"], "TD": []}
NAME_RE = re.compile(r"^(AS|TD)-([A-Za-z0-9]+)-(\d{3})-[a-z0-9-]+\.md$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
FR_RE = re.compile(r"^\*\*FR-\d+", re.M)

findings = []  # (level, path, message)


def report(level, path, msg):
    findings.append((level, str(path.relative_to(ROOT)), msg))


def parse_frontmatter(text):
    """Return (dict, body) or (None, text). Supports `key: value` and `key:` + `- item` lists."""
    if not text.startswith("---\n"):
        return None, text
    end = text.find("\n---", 4)
    if end == -1:
        return None, text
    data, key = {}, None
    for line in text[4:end].splitlines():
        if line.startswith("  - ") and key:
            data.setdefault(key, []).append(line[4:].strip())
        elif ":" in line and not line.startswith(" "):
            key, _, val = line.partition(":")
            key = key.strip()
            val = val.split("  #")[0].strip()
            data[key] = val if val else []
    return data, text[end + 4:]


def check_entry(path, kind):
    text = path.read_text(encoding="utf-8")
    fm, body = parse_frontmatter(text)
    m = NAME_RE.match(path.name)
    folder = path.parent.name
    if not m or m.group(1) != kind:
        report("WARN", path, f"file name should be {kind}-<Feature>-<NNN>-<slug>.md")
    elif m.group(2) != folder:
        report("WARN", path, f"feature in file name ({m.group(2)}) differs from folder ({folder})")
    if fm is None:
        report("ERROR", path, "missing YAML frontmatter")
        return None
    for key in COMMON_KEYS + EXTRA_KEYS[kind]:
        if key not in fm or fm[key] == "" or (key != "files" and fm[key] == []):
            report("ERROR", path, f"frontmatter key '{key}' missing or empty")
    if fm.get("level") and fm["level"] not in LEVELS:
        report("ERROR", path, f"level '{fm['level']}' not in {sorted(LEVELS)}")
    if fm.get("status") and fm["status"] not in STATUS[kind]:
        report("ERROR", path, f"status '{fm['status']}' not in {sorted(STATUS[kind])}")
    for key in ("created", "updated"):
        if fm.get(key) and not DATE_RE.match(str(fm[key])):
            report("ERROR", path, f"{key} must be YYYY-MM-DD")
    if m and fm.get("id") and fm["id"] != f"{m.group(1)}-{m.group(2)}-{m.group(3)}":
        report("ERROR", path, f"id '{fm['id']}' does not match file name")
    if fm.get("feature") and fm["feature"] != folder:
        report("WARN", path, f"feature '{fm['feature']}' differs from folder '{folder}'")
    en = len(re.findall(r"^EN:", body, re.M))
    vi = len(re.findall(r"^VI:", body, re.M))
    if en == 0 or en != vi:
        report("ERROR", path, f"bilingual blocks unbalanced (EN: {en}, VI: {vi})")
    status = fm.get("status")
    if status in CLOSED and "_(fill in" in body.split("## Outcome" if kind == "AS" else "## Resolution")[-1]:
        report("ERROR", path, f"status is {status} but Outcome/Resolution is still the placeholder")
    if status not in CLOSED:
        for ref in fm.get("files", []) or []:
            target = ref.split(":")[0]
            if target and not (ROOT / target).exists():
                report("WARN", path, f"files: '{target}' does not exist (code moved or renamed?)")
    return fm


def check_srs(path):
    text = path.read_text(encoding="utf-8")
    if "```gherkin" not in text:
        return "legacy"
    starts = [m.start() for m in FR_RE.finditer(text)]
    for i, s in enumerate(starts):
        e = starts[i + 1] if i + 1 < len(starts) else len(text)
        block = text[s:e]
        # an FR block also ends at the next heading or horizontal rule
        cut = re.search(r"^(#{2,4} |---$)", block, re.M)
        block = block[: cut.start()] if cut else block
        name = block.splitlines()[0].strip("* ")
        if not re.search(r"^\s*Scenario( Outline)?:", block, re.M):
            report("ERROR", path, f"{name}: no Gherkin scenario")
        if "@not-confirmed" in block and "Not confirmed" not in block.replace("@not-confirmed", ""):
            report("ERROR", path, f"{name}: @not-confirmed scenario without a '⚠️ Not confirmed' note")
    return "ok"


def changed_paths():
    out = subprocess.run(["git", "status", "--porcelain"], cwd=ROOT, capture_output=True, text=True).stdout
    return {ROOT / line[3:].strip().split(" -> ")[-1] for line in out.splitlines()}


def main():
    changed = changed_paths() if "--changed" in sys.argv else None
    wanted = lambda p: changed is None or any(c == p or p in c.parents or c in p.parents for c in changed)

    ids = defaultdict(list)
    for kind, base in (("AS", "Docs/Assumptions"), ("TD", "Docs/Tech-Debt")):
        for path in sorted((ROOT / base).glob("*/*.md")):
            fm = check_entry(path, kind) if wanted(path) else None
            if fm and fm.get("id"):
                ids[fm["id"]].append(path)
    for entry_id, paths in ids.items():
        if len(paths) > 1:
            for p in paths:
                report("ERROR", p, f"duplicate id {entry_id}")

    legacy = 0
    for srs in sorted((ROOT / "Docs/Specs").glob("*/SRS.md")):
        if wanted(srs) and check_srs(srs) == "legacy":
            legacy += 1

    # code written on top of an unconfirmed spec item must have an Assumption (AGENTS.md 10.3)
    for spec_dir in sorted(p for p in (ROOT / "Docs/Specs").iterdir() if p.is_dir()):
        if not wanted(spec_dir):
            continue
        marker = any("⚠️ Not confirmed" in f.read_text(encoding="utf-8")
                     for f in spec_dir.glob("*.md") if f.name != "changelog.md")
        tasks = spec_dir / "tasks.md"
        started = tasks.exists() and "[x]" in tasks.read_text(encoding="utf-8")
        has_assumption = any((ROOT / "Docs/Assumptions" / spec_dir.name).glob("*.md"))
        if marker and started and not has_assumption:
            report("WARN", spec_dir / "tasks.md",
                   "spec has '⚠️ Not confirmed' and ticked tasks but Docs/Assumptions/"
                   f"{spec_dir.name}/ has no entry")

    order = {"ERROR": 0, "WARN": 1}
    for level, path, msg in sorted(findings, key=lambda f: (order[f[0]], f[1])):
        print(f"{level:5} {path}: {msg}")
    errors = sum(1 for f in findings if f[0] == "ERROR")
    warns = len(findings) - errors
    print(f"\n{errors} error(s), {warns} warning(s); {legacy} SRS without Gherkin skipped (legacy).")
    sys.exit(1 if errors or (warns and "--strict" in sys.argv) else 0)


if __name__ == "__main__":
    main()
