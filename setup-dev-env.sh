#!/bin/bash
set -e

SKILL_DIR="${HOME}/.agent-skills"
DEV_ENV_SKILL_FILE="agent-dev-env.md"
OLD_GIT_SKILL_FILE="agent-git-workflow.md"

echo "Agent Development Environment Setup"
echo "====================================="
echo "This script will help you define how AI agents interact with Git"
echo "and manage Python/JavaScript environments."
echo "Press [Enter] to accept the default values."
echo ""

# --- Migration: Remove old agent-git-workflow.md files ---
# Called after the new profile is successfully written to avoid leaving users
# with no profile if the script is interrupted during interactive input.
migrate_old_git_workflow() {
  local removed=0

  if [[ -f "${SKILL_DIR}/${OLD_GIT_SKILL_FILE}" || -L "${SKILL_DIR}/${OLD_GIT_SKILL_FILE}" ]]; then
    rm -f "${SKILL_DIR}/${OLD_GIT_SKILL_FILE}"
    echo "✓ Migrated: removed old ${SKILL_DIR}/${OLD_GIT_SKILL_FILE}"
    removed=$((removed + 1))
  fi

  local AGENTS=(
    "${HOME}/.claude"
    "${HOME}/.gemini"
    "${HOME}/.codex"
    "${HOME}/.aider"
    "${HOME}/.continue"
  )

  for config_dir in "${AGENTS[@]}"; do
    if [[ -L "${config_dir}/${OLD_GIT_SKILL_FILE}" || -f "${config_dir}/${OLD_GIT_SKILL_FILE}" ]]; then
      rm -f "${config_dir}/${OLD_GIT_SKILL_FILE}"
      echo "✓ Migrated: removed old ${config_dir}/${OLD_GIT_SKILL_FILE}"
      removed=$((removed + 1))
    fi
  done

  if [[ $removed -gt 0 ]]; then
    echo ""
  fi
}

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

echo ""

# 6. Python virtual environment (Default: a)
while true; do
  echo "6) Should agents use a Python virtual environment?"
  echo "   [a] Yes, always use venv"
  echo "   [b] No"
  read -p "Your choice [A/b]: " venv_pref || { echo -e "\nSetup aborted."; exit 1; }

  venv_pref=${venv_pref:-a}

  if [[ "$venv_pref" == "a" || "$venv_pref" == "A" ]]; then
    VENV_TEXT="Always create and activate a Python virtual environment (venv) before installing packages or running Python code. If a \`venv\`, \`.venv\`, or \`env\` directory already exists, use it."
    break
  elif [[ "$venv_pref" == "b" || "$venv_pref" == "B" ]]; then
    VENV_TEXT="Do not create virtual environments unless the user specifically requests it."
    break
  else
    echo "Invalid choice. Please enter 'a' or 'b' or press Enter for default."
    echo ""
  fi
done

echo ""

# 7. Python package manager (Default: a)
while true; do
  echo "7) Which Python package manager do you prefer?"
  echo "   [a] pip"
  echo "   [b] uv"
  echo "   [c] poetry"
  read -p "Your choice [A/b/c]: " pypm_pref || { echo -e "\nSetup aborted."; exit 1; }

  pypm_pref=${pypm_pref:-a}

  if [[ "$pypm_pref" == "a" || "$pypm_pref" == "A" ]]; then
    PYPM_TEXT="Use \`pip\` as the default Python package manager."
    break
  elif [[ "$pypm_pref" == "b" || "$pypm_pref" == "B" ]]; then
    PYPM_TEXT="Use \`uv\` as the default Python package manager."
    break
  elif [[ "$pypm_pref" == "c" || "$pypm_pref" == "C" ]]; then
    PYPM_TEXT="Use \`poetry\` as the default Python package manager."
    break
  else
    echo "Invalid choice. Please enter 'a', 'b', or 'c' or press Enter for default."
    echo ""
  fi
done

echo ""

# 8. JS local dependencies only (Default: a)
while true; do
  echo "8) Should agents install JS packages locally only (no global installs)?"
  echo "   [a] Yes, local node_modules only"
  echo "   [b] No, global installs acceptable"
  read -p "Your choice [A/b]: " jslocal_pref || { echo -e "\nSetup aborted."; exit 1; }

  jslocal_pref=${jslocal_pref:-a}

  if [[ "$jslocal_pref" == "a" || "$jslocal_pref" == "A" ]]; then
    JSLOCAL_TEXT="Always install packages locally into \`node_modules\`. Never use \`npm install -g\` or equivalent global installs unless the user explicitly requests it."
    break
  elif [[ "$jslocal_pref" == "b" || "$jslocal_pref" == "B" ]]; then
    JSLOCAL_TEXT="Global package installs are acceptable when appropriate."
    break
  else
    echo "Invalid choice. Please enter 'a' or 'b' or press Enter for default."
    echo ""
  fi
done

echo ""

# 9. JS package manager (Default: a)
while true; do
  echo "9) Which JavaScript package manager do you prefer?"
  echo "   [a] npm"
  echo "   [b] yarn"
  echo "   [c] pnpm"
  echo "   [d] bun"
  read -p "Your choice [A/b/c/d]: " jspm_pref || { echo -e "\nSetup aborted."; exit 1; }

  jspm_pref=${jspm_pref:-a}

  if [[ "$jspm_pref" == "a" || "$jspm_pref" == "A" ]]; then
    JSPM_TEXT="Use \`npm\` as the default JavaScript package manager."
    break
  elif [[ "$jspm_pref" == "b" || "$jspm_pref" == "B" ]]; then
    JSPM_TEXT="Use \`yarn\` as the default JavaScript package manager."
    break
  elif [[ "$jspm_pref" == "c" || "$jspm_pref" == "C" ]]; then
    JSPM_TEXT="Use \`pnpm\` as the default JavaScript package manager."
    break
  elif [[ "$jspm_pref" == "d" || "$jspm_pref" == "D" ]]; then
    JSPM_TEXT="Use \`bun\` as the default JavaScript package manager."
    break
  else
    echo "Invalid choice. Please enter 'a', 'b', 'c', or 'd' or press Enter for default."
    echo ""
  fi
done

echo ""

# 10. Implementer role (Default: 1)
while true; do
  echo "10) Which agent should be the primary Implementer (writes plans and code)?"
  echo "   [1] Claude Code"
  echo "   [2] Codex"
  echo "   [3] Gemini CLI"
  echo "   [4] Aider"
  echo "   [5] Unassigned"
  read -p "Your choice [1/2/3/4/5]: " impl_pref || { echo -e "\nSetup aborted."; exit 1; }

  impl_pref=${impl_pref:-1}

  case "$impl_pref" in
    1) IMPL_NAME="Claude Code"; break ;;
    2) IMPL_NAME="Codex"; break ;;
    3) IMPL_NAME="Gemini CLI"; break ;;
    4) IMPL_NAME="Aider"; break ;;
    5) IMPL_NAME="Unassigned"; break ;;
    *) echo "Invalid choice. Please enter 1-5 or press Enter for default."; echo "" ;;
  esac
done

echo ""

# 11. Reviewer role (Default: 1)
while true; do
  echo "11) Which agent should be the primary Reviewer (reviews code before merge)?"
  echo "   [1] Codex"
  echo "   [2] Claude Code"
  echo "   [3] Gemini CLI"
  echo "   [4] Unassigned"
  read -p "Your choice [1/2/3/4]: " rev_pref || { echo -e "\nSetup aborted."; exit 1; }

  rev_pref=${rev_pref:-1}

  case "$rev_pref" in
    1) REV_NAME="Codex"; break ;;
    2) REV_NAME="Claude Code"; break ;;
    3) REV_NAME="Gemini CLI"; break ;;
    4) REV_NAME="Unassigned"; break ;;
    *) echo "Invalid choice. Please enter 1-4 or press Enter for default."; echo "" ;;
  esac
done

# Build ROLES_TEXT
if [[ "$IMPL_NAME" == "Unassigned" ]]; then
  IMPL_LINE="- **Implementer: Unassigned** — Any agent may write plans and code. Coordinate in \`agent-actions.md\` to avoid conflicts."
else
  IMPL_LINE="- **Implementer: ${IMPL_NAME}** — Writes plans and code. Must NOT review own work; mark PRs as \`Ready for Reviewer\` when done."
fi

if [[ "$REV_NAME" == "Unassigned" ]]; then
  REV_LINE="- **Reviewer: Unassigned** — Any agent may review code. Document review findings in \`agent-actions.md\`."
else
  REV_LINE="- **Reviewer: ${REV_NAME}** — Reviews PRs and code changes. Provides feedback or approves before merge."
fi

ROLES_TEXT="${IMPL_LINE}
${REV_LINE}
- Other agents should not disrupt these roles. They may assist with research, debugging, or tasks that do not conflict with the Implementer/Reviewer workflow."

# Create the markdown file
mkdir -p "${SKILL_DIR}"

cat <<EOF > "${SKILL_DIR}/${DEV_ENV_SKILL_FILE}"
# Development Environment Preferences

This file defines development environment preferences for AI agents.

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

## Python Environment
- ${VENV_TEXT}
- ${PYPM_TEXT}
- If a \`conda\` environment or \`environment.yml\` file is present in the project, respect and use it instead of creating a new virtual environment.

## JavaScript / Node.js Environment
- ${JSLOCAL_TEXT}
- ${JSPM_TEXT}
- If a \`.nvmrc\` or \`.node-version\` file is present, use the specified Node.js version.
- Respect existing lockfiles: \`package-lock.json\` → npm, \`yarn.lock\` → yarn, \`pnpm-lock.yaml\` → pnpm, \`bun.lockb\` → bun.

## Agent Roles & Responsibilities
${ROLES_TEXT}
EOF

echo ""
echo "✓ Development environment profile created at ${SKILL_DIR}/${DEV_ENV_SKILL_FILE}"

# Now that the new profile is safely written, clean up old files
migrate_old_git_workflow

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
    ln -sf "${SKILL_DIR}/${DEV_ENV_SKILL_FILE}" "${config_dir}/${DEV_ENV_SKILL_FILE}"
    echo "✓ Linked to ${agent} profile (${config_dir}/${DEV_ENV_SKILL_FILE})"
    LINKED=$((LINKED + 1))
  fi
done

echo ""
echo "Done! Your development environment preferences are now active for ${LINKED} agent(s)."

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
