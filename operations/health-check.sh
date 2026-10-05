#!/usr/bin/env bash
set -euo pipefail
if curl --fail --silent --max-time 5 http://127.0.0.1:8090/health >/dev/null; then
  logger -t cedarfield-health -- 'health=ok'
else
  logger -p daemon.err -t cedarfield-health -- 'health=failed investigate cedarfield.service'
  exit 1
fi
