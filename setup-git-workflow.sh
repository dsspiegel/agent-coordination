#!/bin/bash
set -e

SKILL_DIR="${HOME}/.agent-skills"
GIT_SKILL_FILE="agent-git-workflow.md"
SYNC_GLOBAL_URL="https://raw.githubusercontent.com/dsspiegel/agent-coordination/main/sync-global-agent-instructions.sh"

echo "Agent Git Workflow Setup"
echo "========================="
echo "This script will help you define how AI agents interact with Git."
echo "Press [Enter] to accept the default values."
echo ""

# 1. PR vs Direct Push (Default: a)
while true; do
  echo "1) How should agents handle code changes?"
  echo "   [a] Structured Workflow: Always create a new branch and open a Pull Request (Safest)"
  echo "   [b] Direct Push: Push directly to the main/master branch (Fastest)"
  read -p "Your choice [A/b]: " merge_pref || { echo -e "\nSetup aborted."; exit 1; }

  merge_pref=${merge_pref:-a} # Default to 'a' if empty

  if [[ "$merge_pref" == "a" || "$merge_pref" == "A" ]]; then
    MERGE_TEXT="Always follow these numbered steps for code changes:
1. Create a descriptive local branch.
2. Commit your changes to that branch.
3. Push the branch to the remote repository.
4. Create a Pull Request (PR) for human review.
Do NOT push directly to the main or master branch."
    break
  elif [[ "$merge_pref" == "b" || "$merge_pref" == "B" ]]; then
    MERGE_TEXT="You are permitted to push directly to the main or master branch for all changes. Numbered steps (branching/PRs) are not required unless specifically requested by the user."
    break
  else
    echo "Invalid choice. Please enter 'a' or 'b' or press Enter for default."
    echo ""
  fi
done

echo ""

# 2. Commit Message Style (Default: a)
while true; do
  echo "2) Which commit message style do you prefer?"
  echo "   [a] Structured / Conventional (e.g., 'feat(api): add login endpoint')"
  echo "   [b] Informal (e.g., 'Add login endpoint')"
  read -p "Your choice [A/b]: " commit_pref || { echo -e "\nSetup aborted."; exit 1; }

  commit_pref=${commit_pref:-a} # Default to 'a' if empty

  if [[ "$commit_pref" == "a" || "$commit_pref" == "A" ]]; then
    COMMIT_TEXT="Use the Structured / Conventional Commits specification (e.g., feat:, fix:, docs:, chore:, refactor:) for all commit messages."
    break
  elif [[ "$commit_pref" == "b" || "$commit_pref" == "B" ]]; then
    COMMIT_TEXT="Use Informal, clear, imperative-style commit messages (e.g., 'Add feature X', 'Fix bug Y')."
    break
  else
    echo "Invalid choice. Please enter 'a' or 'b' or press Enter for default."
    echo ""
  fi
done

echo ""

# 3. Verification (Default: y)
while true; do
  echo "3) Should agents attempt to run tests/linting before committing?"
  echo "   [y/n]"
  read -p "Your choice [Y/n]: " test_pref || { echo -e "\nSetup aborted."; exit 1; }

  test_pref=${test_pref:-y} # Default to 'y' if empty

  if [[ "$test_pref" == "y" || "$test_pref" == "Y" ]]; then
    TEST_TEXT="Always attempt to run existing tests and linting commands (e.g., 'npm test', 'pytest', 'npm run lint') before committing. If they fail, fix the issues or report the blockers."
    break
  elif [[ "$test_pref" == "n" || "$test_pref" == "N" ]]; then
    TEST_TEXT="Running tests before commit is optional unless the user specifically asks."
    break
  else
    echo "Invalid choice. Please enter 'y' or 'n' or press Enter for default."
    echo ""
  fi
done

echo ""

# 4. Branch Cleanup (Default: y)
while true; do
  echo "4) Should agents periodically check if PRs have been merged and clean up local branches?"
  echo "   [y/n]"
  read -p "Your choice [Y/n]: " cleanup_pref || { echo -e "\nSetup aborted."; exit 1; }

  cleanup_pref=${cleanup_pref:-y} # Default to 'y' if empty

  if [[ "$cleanup_pref" == "y" || "$cleanup_pref" == "Y" ]]; then
    CLEANUP_TEXT="At the beginning of each session, check for any of your local branches where the corresponding Pull Request has been merged. Delete these branches to keep the workspace clean."
    break
  elif [[ "$cleanup_pref" == "n" || "$cleanup_pref" == "N" ]]; then
    CLEANUP_TEXT="Do not automatically delete local branches unless the user explicitly requests a cleanup."
    break
  else
    echo "Invalid choice. Please enter 'y' or 'n' or press Enter for default."
    echo ""
  fi
done

echo ""

# 5. Git Tracking (Default: y)
while true; do
  echo "5) Should the agent-actions.md log be tracked in Git?"
  echo "   [y] Yes: Commits the log so collaborators/other machines share context"
  echo "   [n] No: Adds it to .gitignore so it remains local-only"
  read -p "Your choice [Y/n]: " tracking_pref || { echo -e "\nSetup aborted."; exit 1; }

  tracking_pref=${tracking_pref:-y} # Default to 'y' if empty

  if [[ "$tracking_pref" == "y" || "$tracking_pref" == "Y" ]]; then
    TRACKING_TEXT="The \`agent-actions.md\` log should be tracked and committed to Git like a normal file."
    
    # Optional: try to remove from global gitignore if it was previously ignored
    GLOBAL_IGNORE=$(git config --global core.excludesfile || echo "")
    XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    DEFAULT_GLOBAL_IGNORE="${XDG_CONFIG_HOME}/git/ignore"
    
    for ignore_file in "$GLOBAL_IGNORE" "$DEFAULT_GLOBAL_IGNORE"; do
      if [[ -n "$ignore_file" && -f "$ignore_file" ]] && grep -q "agent-actions.md" "$ignore_file"; then
        sed -i.bak '/agent-actions.md/d' "$ignore_file" && rm -f "${ignore_file}.bak" || true
        echo "✓ Removed agent-actions.md from global gitignore ($ignore_file)"
      fi
    done
    break
  elif [[ "$tracking_pref" == "n" || "$tracking_pref" == "N" ]]; then
    TRACKING_TEXT="The \`agent-actions.md\` log is local-only. Never stage or commit it."
    
    # Add to global gitignore
    GLOBAL_IGNORE=$(git config --global core.excludesfile || echo "")
    XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    DEFAULT_GLOBAL_IGNORE="${XDG_CONFIG_HOME}/git/ignore"
    
    if [[ -z "$GLOBAL_IGNORE" ]]; then
      if [[ -f "$DEFAULT_GLOBAL_IGNORE" ]]; then
        GLOBAL_IGNORE="$DEFAULT_GLOBAL_IGNORE"
      else
        GLOBAL_IGNORE="${HOME}/.gitignore_global"
        git config --global core.excludesfile "$GLOBAL_IGNORE"
      fi
    fi

    if [[ ! -f "$GLOBAL_IGNORE" ]] || ! grep -q "agent-actions.md" "$GLOBAL_IGNORE"; then
      mkdir -p "$(dirname "$GLOBAL_IGNORE")"
      echo "agent-actions.md" >> "$GLOBAL_IGNORE"
      echo "✓ Added agent-actions.md to global gitignore ($GLOBAL_IGNORE)"
    fi
    break
  else
    echo "Invalid choice. Please enter 'y' or 'n' or press Enter for default."
    echo ""
  fi
done

# Create the markdown file
mkdir -p "${SKILL_DIR}"

cat <<EOF > "${SKILL_DIR}/${GIT_SKILL_FILE}"
# Git Workflow Instructions

This file defines the "Rules of Engagement" for how AI agents should interact with Git in this environment.

## Merging & Branching
${MERGE_TEXT}

## Commit Messages
${COMMIT_TEXT}

## Verification
${TEST_TEXT}

## Workspace Cleanup
${CLEANUP_TEXT}

## Log Tracking
${TRACKING_TEXT}

## Accountability
Always include the branch name and, if applicable, the Pull Request URL in your \`agent-actions.md\` log entry.
EOF

echo ""
echo "✓ Git workflow profile created at ${SKILL_DIR}/${GIT_SKILL_FILE}"

# Sync to agents
AGENTS=(
  "Claude Code|${HOME}/.claude"
  "Gemini CLI|${HOME}/.gemini"
  "Codex CLI|${HOME}/.codex"
  "Aider|${HOME}/.aider"
  "Continue|${HOME}/.continue"
)

LINKED=0
for agent_info in "${AGENTS[@]}"; do
  IFS='|' read -r agent config_dir <<< "$agent_info"
  if [[ -d "${config_dir}" ]]; then
    ln -sf "${SKILL_DIR}/${GIT_SKILL_FILE}" "${config_dir}/${GIT_SKILL_FILE}"
    echo "✓ Linked to ${agent} profile (${config_dir}/${GIT_SKILL_FILE})"
    LINKED=$((LINKED + 1))
  fi
done

echo ""
echo "Done! Your Git workflow preferences are now active for ${LINKED} agent(s)."

echo ""
echo "Syncing global instruction entry points..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_SYNC_SCRIPT="${SCRIPT_DIR}/sync-global-agent-instructions.sh"

if [[ -f "${LOCAL_SYNC_SCRIPT}" ]]; then
  if ! bash "${LOCAL_SYNC_SCRIPT}"; then
    echo "WARNING: Failed to sync global instruction files via local helper."
  fi
else
  if command -v curl &> /dev/null; then
    TMP_SYNC_SCRIPT="$(mktemp)"
    if curl -fsSL "${SYNC_GLOBAL_URL}" -o "${TMP_SYNC_SCRIPT}"; then
      if ! bash "${TMP_SYNC_SCRIPT}"; then
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
