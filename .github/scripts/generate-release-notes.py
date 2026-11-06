#!/usr/bin/env python3

import argparse
import re
import subprocess
from collections import defaultdict
from pathlib import Path

SECTIONS = {
    "feat": "New Features",
    "fix": "Bug Fixes",
    "perf": "Performance Improvements",
    "refactor": "Refactor",
    "style": "Styles",
    "test": "Tests",
    "ci": "CI/CD",
    "workflow": "Workflows",
    "chore": "Chores",
    "types": "Types",
    "wip": "Work in Progress",
    "revert": "Reverts",
}
COMMIT_PATTERN = re.compile(
    r"^(?:revert:\s*)?(?P<type>feat|fix|perf|refactor|style|test|ci|workflow|chore|types|wip|revert)"
    r"(?:\((?P<scope>[^)]+)\))?!?:\s*(?P<subject>.+)$",
    re.IGNORECASE,
)
PR_PATTERN = re.compile(r"\s*(?:\(#(?P<paren>\d+)\)|#(?P<plain>\d+))\s*$")


def uppercase_first(value):
    return value[:1].upper() + value[1:]


def parse_commit(subject):
    match = COMMIT_PATTERN.match(subject)
    if match:
        section = SECTIONS[match.group("type").lower()]
        scope = match.group("scope")
        description = match.group("subject").strip()
    else:
        section = "Other Changes"
        scope = None
        description = subject.strip()

    pr_match = PR_PATTERN.search(description)
    pr_number = None
    if pr_match:
        pr_number = pr_match.group("paren") or pr_match.group("plain")
        description = description[: pr_match.start()].rstrip()

    description = uppercase_first(description)
    if scope:
        description = f"{uppercase_first(scope.strip())} | {description}"
    if pr_number:
        description = f"{description} (#{pr_number})"

    return section, description


def render_notes(subjects):
    groups = defaultdict(list)
    for subject in subjects:
        section, description = parse_commit(subject)
        groups[section].append(description)

    if not groups:
        return "# Changes\n\nNo commits found for this release.\n"

    sections = list(SECTIONS.values()) + ["Other Changes"]
    blocks = []
    for section in sections:
        if section in groups:
            entries = "\n".join(f"{entry}  " for entry in groups[section])
            blocks.append(f"# {section}\n\n{entries}")

    return "\n\n".join(blocks) + "\n"


def commit_subjects(previous_ref, current_ref):
    revision_range = f"{previous_ref}..{current_ref}" if previous_ref else current_ref
    result = subprocess.run(
        ["git", "log", "--no-merges", "--format=%s", revision_range],
        check=True,
        capture_output=True,
        text=True,
    )
    return [line for line in result.stdout.splitlines() if line.strip()]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--from", dest="previous_ref")
    parser.add_argument("--to", dest="current_ref", default="HEAD")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    notes = render_notes(commit_subjects(args.previous_ref, args.current_ref))
    args.output.write_text(notes, encoding="utf-8")


if __name__ == "__main__":
    main()
