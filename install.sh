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
    LINKED=$((LINKED + 1))
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
    LINKED=$((LINKED + 1))
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

echo ""
echo "Syncing global instruction entry points..."

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
  echo "WARNING: curl is required to sync global instruction files in this mode."
fi

if command -v sync_global_agent_instructions &> /dev/null; then
  sync_global_agent_instructions
fi

# Offer to configure development environment preferences (interactive only)
if [[ -t 0 ]]; then
  echo ""
  echo "Would you like to configure how agents handle Git, Python, and JavaScript in your projects?"
  echo "(Recommended for first-time setup)"
  if ! read -p "[Y/n]: " setup_pref; then
    echo ""
    setup_pref="n"
  fi

  setup_pref=${setup_pref:-y}

  if [[ "$setup_pref" =~ ^[Yy] ]]; then
    SETUP_DEV_ENV_URL="${SETUP_DEV_ENV_URL:-https://raw.githubusercontent.com/dsspiegel/agent-coordination/main/setup-dev-env.sh}"

    if [[ -f "${SCRIPT_DIR}/setup-dev-env.sh" ]]; then
      bash "${SCRIPT_DIR}/setup-dev-env.sh"
    elif command -v curl &> /dev/null; then
      TMP_SETUP="$(mktemp)"
      trap 'rm -f "${TMP_SETUP}"' EXIT INT TERM
      if curl -fsSL "${SETUP_DEV_ENV_URL}" -o "${TMP_SETUP}"; then
        bash "${TMP_SETUP}"
      else
        echo "WARNING: Could not download setup-dev-env.sh."
      fi
      rm -f "${TMP_SETUP}"
      trap - EXIT INT TERM
    else
      echo "WARNING: curl is required to download setup-dev-env.sh."
    fi
  fi
fi
