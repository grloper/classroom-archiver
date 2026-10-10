#!/usr/bin/env bash
# Verification gate: classroom-archiver (Node CLI/web): eslint, syntax checks, node:test
#
# NOT CHECKED (do not claim these from a green run): real Google Classroom crawls/auth, packaged standalone exe, npm audit/compliance/sanitize release checks.
#
# Usage: scripts/verify.sh   (exit 0 = pass). Non-blocking steps print "WARN" and never fail the run.
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n== %s\n' "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "verify: required tool '$1' not found" >&2; exit 2; }; }
# warn_step "name" cmd...: run a check that fails today for pre-existing reasons; report but do not block.
warn_step() { local n="$1"; shift; step "$n (non-blocking)"; if ! "$@"; then echo "WARN: '$n' failed (pre-existing, non-blocking)"; fi; }
need git; need bash

step "shell syntax"
for f in scripts/*.sh; do bash -n "$f"; done

step "workflow lint (actionlint)"
if command -v actionlint >/dev/null 2>&1; then actionlint
elif command -v pipx >/dev/null 2>&1; then pipx run --spec actionlint-py==1.7.12.25 actionlint
else echo "verify: actionlint (or pipx) required" >&2; exit 2; fi

need node; need npm
step "npm ci"
npm ci --no-audit --no-fund
step "eslint"
npx --yes eslint@10.12.0 .
step "syntax and web module check"
npm run check
step "tests (node --test)"
npm test

printf '\nPASS: npm ci + eslint + syntax check + node --test + actionlint + shell syntax.\n'
printf 'NOT CHECKED: real Google Classroom crawls/auth, packaged standalone exe, npm audit/compliance/sanitize release checks.\n'
