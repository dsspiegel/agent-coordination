#!/bin/bash

# Function to sync global agent instructions
# Pass additional arguments (e.g., --remove) which are forwarded to sync-global-agent-instructions.sh
sync_global_agent_instructions() {
  local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local LOCAL_SYNC_SCRIPT="${SCRIPT_DIR}/sync-global-agent-instructions.sh"
  local SYNC_GLOBAL_URL="https://raw.githubusercontent.com/dsspiegel/agent-coordination/main/sync-global-agent-instructions.sh"

  if [[ -f "${LOCAL_SYNC_SCRIPT}" ]]; then
    if ! bash "${LOCAL_SYNC_SCRIPT}" "$@"; then
      echo "WARNING: Failed to sync global instruction files via local helper."
    fi
  else
    if command -v curl &> /dev/null; then
      local TMP_SYNC_SCRIPT="$(mktemp)"
      if curl -fsSL "${SYNC_GLOBAL_URL}" -o "${TMP_SYNC_SCRIPT}"; then
        if ! bash "${TMP_SYNC_SCRIPT}" "$@"; then
          echo "WARNING: Failed to sync global instruction files via downloaded helper."
        fi
      else
        echo "WARNING: Could not download global instruction sync helper."
      fi
      rm -f "${TMP_SYNC_SCRIPT}"
    else
      echo "WARNING: curl is required to sync global instruction files in this mode."
    fi
  fi
}
