#!/bin/bash

SKILL_DIR="${HOME}/.agent-skills"
SKILL_FILE="agent-coordination.md"
GIT_SKILL_FILE="agent-git-workflow.md"

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
SYNC_HELPER_URL="https://raw.githubusercontent.com/dsspiegel/agent-coordination/main/sync-helper.sh"

if [[ -f "${SCRIPT_DIR}/sync-helper.sh" ]]; then
  source "${SCRIPT_DIR}/sync-helper.sh"
elif command -v curl &> /dev/null; then
  TMP_HELPER="$(mktemp)"
  if curl -fsSL "${SYNC_HELPER_URL}" -o "${TMP_HELPER}"; then
    source "${TMP_HELPER}"
  else
    echo "WARNING: Could not download sync helper."
  fi
  rm -f "${TMP_HELPER}"
else
  echo "WARNING: curl is required to remove managed global instruction blocks in this mode."
fi

if command -v sync_global_agent_instructions &> /dev/null; then
  sync_global_agent_instructions "--remove"
fi

echo "=========================================="
if [[ $REMOVED -gt 0 ]]; then
  echo "Uninstall complete. Removed ${REMOVED} symlinks."
else
  echo "Uninstall complete. No active symlinks found."
fi
