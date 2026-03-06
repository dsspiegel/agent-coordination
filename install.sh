#!/bin/bash
set -e

SKILL_DIR="${HOME}/.agent-skills"
SKILL_FILE="agent-coordination.md"
SKILL_URL="https://raw.githubusercontent.com/dsspiegel/agent-coordination/main/AGENT-COORDINATION.md"

# Agent configurations: "Name|Command|ConfigDir"
# Note: 'Continue' doesn't use a command check because 'continue' is a Bash keyword.
AGENTS=(
  "Claude Code|claude|${HOME}/.claude"
  "Gemini CLI|gemini|${HOME}/.gemini"
  "Codex CLI|codex|${HOME}/.codex"
  "Aider|aider|${HOME}/.aider"
  "Continue||${HOME}/.continue"
)

echo "Agent Coordination Skill Installer"
echo "==================================="
echo ""

# Create shared skill directory and download
mkdir -p "${SKILL_DIR}"
echo "Downloading skill file..."
curl -fsSL "${SKILL_URL}" -o "${SKILL_DIR}/${SKILL_FILE}"
echo "✓ Saved to ${SKILL_DIR}/${SKILL_FILE}"
echo ""

# Detect and link for each agent
LINKED=0
echo "Detecting installed agents..."
echo ""

for agent_info in "${AGENTS[@]}"; do
  IFS='|' read -r agent cmd config_dir <<< "$agent_info"
  
  if [[ -n "$cmd" ]] && command -v "$cmd" &> /dev/null; then
    echo "✓ Found: ${agent}"
    mkdir -p "${config_dir}"
    ln -sf "${SKILL_DIR}/${SKILL_FILE}" "${config_dir}/${SKILL_FILE}"
    echo "  Linked: ${config_dir}/${SKILL_FILE}"
    ((LINKED++))
  else
    if [[ -n "$cmd" ]]; then
      echo "· Not found: ${agent}"
    fi
  fi
done

echo ""

# Also check for config dirs that exist even if command isn't in PATH
# (some agents might be installed but not in PATH, or use different binary names like Continue)
for agent_info in "${AGENTS[@]}"; do
  IFS='|' read -r agent cmd config_dir <<< "$agent_info"
  
  if [[ -d "${config_dir}" ]] && [[ ! -L "${config_dir}/${SKILL_FILE}" ]]; then
    echo "✓ Found config dir: ${config_dir} (${agent})"
    ln -sf "${SKILL_DIR}/${SKILL_FILE}" "${config_dir}/${SKILL_FILE}"
    echo "  Linked: ${config_dir}/${SKILL_FILE}"
    ((LINKED++))
  fi
done

echo "==================================="
if [[ $LINKED -gt 0 ]]; then
  echo "✓ Installed for ${LINKED} agent(s)"
else
  echo "⚠ No agents detected."
  echo ""
  echo "The skill file has been downloaded to:"
  echo "  ${SKILL_DIR}/${SKILL_FILE}"
  echo ""
  echo "Manually link it to your agent's config directory:"
  echo "  ln -s ${SKILL_DIR}/${SKILL_FILE} ~/.your-agent/"
fi

echo ""
echo "To add support for a new agent, just run:"
echo "  ln -s ${SKILL_DIR}/${SKILL_FILE} ~/.new-agent/"
