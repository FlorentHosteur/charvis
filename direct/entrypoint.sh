#!/usr/bin/env bash
set -e

if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "WARNING: ANTHROPIC_API_KEY is not set. Claude Code will not work without it."
fi

if [ -z "$OPENCLAW_GATEWAY_TOKEN" ]; then
  echo "WARNING: OPENCLAW_GATEWAY_TOKEN is not set. Gateway access will be unauthenticated."
fi

# If no command specified, start the OpenClaw gateway
if [ $# -eq 0 ] || [ "$1" = "gateway" ]; then
  exec openclaw gateway --bind lan
else
  exec "$@"
fi
