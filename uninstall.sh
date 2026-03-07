#!/bin/bash

SKILL_DIR="${HOME}/.agent-skills"
SKILL_FILE="agent-coordination.md"
GIT_SKILL_FILE="agent-git-workflow.md"
SYNC_GLOBAL_URL="https://raw.githubusercontent.com/dsspiegel/agent-coordination/main/sync-global-agent-instructions.sh"

AGENTS=(
  "Claude Code|${HOME}/.claude"
  "Gemini CLI|${HOME}/.gemini"
  "Codex CLI|${HOME}/.codex"
  "Aider|${HOME}/.aider"
  "Continue|${HOME}/.continue"
)

echo "Uninstalling Agent Coordination tools..."
echo "=========================================="
echo ""

REMOVED=0

# Remove symlinks from agent directories
for agent_info in "${AGENTS[@]}"; do
  IFS='|' read -r agent config_dir <<< "$agent_info"
  
  if [[ -L "${config_dir}/${SKILL_FILE}" ]]; then
    rm "${config_dir}/${SKILL_FILE}"
    echo "✓ Removed ${SKILL_FILE} from ${agent}"
    REMOVED=$((REMOVED + 1))
  fi

  if [[ -L "${config_dir}/${GIT_SKILL_FILE}" ]]; then
    rm "${config_dir}/${GIT_SKILL_FILE}"
    echo "✓ Removed ${GIT_SKILL_FILE} from ${agent}"
    REMOVED=$((REMOVED + 1))
  fi
done

echo ""

# Remove central skill files
if [[ -f "${SKILL_DIR}/${SKILL_FILE}" ]]; then
  rm "${SKILL_DIR}/${SKILL_FILE}"
  echo "✓ Removed core skill file from ${SKILL_DIR}"
fi

if [[ -f "${SKILL_DIR}/${GIT_SKILL_FILE}" ]]; then
  rm "${SKILL_DIR}/${GIT_SKILL_FILE}"
  echo "✓ Removed Git workflow profile from ${SKILL_DIR}"
fi

# Attempt to remove the skill directory if it's empty
if [[ -d "${SKILL_DIR}" ]]; then
  if rmdir "${SKILL_DIR}" 2>/dev/null; then
    echo "✓ Removed empty ${SKILL_DIR} directory"
  fi
fi

echo ""
echo "Removing managed global instruction blocks..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_SYNC_SCRIPT="${SCRIPT_DIR}/sync-global-agent-instructions.sh"

if [[ -f "${LOCAL_SYNC_SCRIPT}" ]]; then
  if ! bash "${LOCAL_SYNC_SCRIPT}" --remove; then
    echo "WARNING: Failed to remove managed global instruction blocks via local helper."
  fi
else
  if command -v curl &> /dev/null; then
    TMP_SYNC_SCRIPT="$(mktemp)"
    if curl -fsSL "${SYNC_GLOBAL_URL}" -o "${TMP_SYNC_SCRIPT}"; then
      if ! bash "${TMP_SYNC_SCRIPT}" --remove; then
        echo "WARNING: Failed to remove managed global instruction blocks via downloaded helper."
      fi
    else
      echo "WARNING: Could not download global instruction sync helper."
    fi
    rm -f "${TMP_SYNC_SCRIPT}"
  else
    echo "WARNING: curl is required to remove managed global instruction blocks in this mode."
  fi
fi

echo "=========================================="
if [[ $REMOVED -gt 0 ]]; then
  echo "Uninstall complete. Removed ${REMOVED} symlinks."
else
  echo "Uninstall complete. No active symlinks found."
fi
