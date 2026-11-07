#!/usr/bin/env bash
# dry-run-apply-external-commit.sh - runs apply-external-commit.sh with --dry-run:
# verifies the package and the target and shows the plan, commits and pushes nothing.
# Extra arguments are passed on (for example --remote URL).
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/apply-external-commit.sh" --dry-run "$@"
