#!/usr/bin/env bash
# Load variables from backend/.env into the current shell.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
if [[ ! -f "$ENV_FILE" ]];
then
  echo "Env file not found at $ENV_FILE" >&2
  exit 1
fi
while IFS= read -r line || [[ -n "$line" ]];
do
  # Skip empty lines and comments
  [[ -z "$line" || "${line%%#*}" = "" ]] && continue
  export "$line"
done < "$ENV_FILE"
