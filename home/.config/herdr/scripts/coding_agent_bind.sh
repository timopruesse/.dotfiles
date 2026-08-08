#!/bin/sh
# Thin herdr [[keys.command]] adapter → coding_agent_herdr.sh
# Usage: coding_agent_bind.sh right|down|tab [resume|continue]
set -eu

scripts=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
exec "$scripts/coding_agent_herdr.sh" "$@"
