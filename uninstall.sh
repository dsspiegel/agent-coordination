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

echo "=========================================="
if [[ $REMOVED -gt 0 ]]; then
  echo "Uninstall complete. Removed ${REMOVED} symlinks."
else
  echo "Uninstall complete. No active symlinks found."
fi
