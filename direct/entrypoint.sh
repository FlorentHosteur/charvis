#!/usr/bin/env bash
set -e

if [ -z "$OPENCLAW_GATEWAY_TOKEN" ]; then
  echo "WARNING: OPENCLAW_GATEWAY_TOKEN is not set. Gateway access will be unauthenticated."
fi

# If no command specified, start the OpenClaw gateway
if [ $# -eq 0 ] || [ "$1" = "gateway" ]; then
  exec node /app/dist/index.js gateway --bind lan --port 18789
else
  exec "$@"
fi
