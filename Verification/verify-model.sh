#!/bin/sh
set -eu
PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CHECK_FILE=$(mktemp /tmp/tea-model-check.XXXXXX.swift)
trap 'rm -f "$CHECK_FILE"' EXIT
cat "$PROJECT_DIR/iosHW6/Models/TeaOrder.swift" "$PROJECT_DIR/Verification/ModelChecks.swift" > "$CHECK_FILE"
swift -module-cache-path /tmp/tea-module-cache "$CHECK_FILE"
