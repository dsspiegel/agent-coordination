#!/bin/bash
set -e

SKILL_DIR="${HOME}/.agent-skills"
GIT_SKILL_FILE="agent-git-workflow.md"

echo "Agent Git Workflow Setup"
echo "========================="
echo "This script will help you define how AI agents interact with Git."
echo ""

# 1. PR vs Direct Push
echo "1) How should agents handle code changes?"
echo "   [a] Structured Workflow: Always create a new branch and open a Pull Request (Safest)"
echo "   [b] Direct Push: Push directly to the main/master branch (Fastest)"
read -p "Your choice [a/b]: " merge_pref

if [[ "$merge_pref" == "b" ]]; then
  MERGE_TEXT="You are permitted to push directly to the main or master branch for all changes. Numbered steps (branching/PRs) are not required unless specifically requested by the user."
else
  MERGE_TEXT="Always follow these numbered steps for code changes:
1. Create a descriptive local branch.
2. Commit your changes to that branch.
3. Push the branch to the remote repository.
4. Create a Pull Request (PR) for human review.
Do NOT push directly to the main or master branch."
fi

echo ""

# 2. Commit Message Style
echo "2) Which commit message style do you prefer?"
echo "   [a] Informal (e.g., 'Add login endpoint')"
echo "   [b] Structured / Conventional (e.g., 'feat(api): add login endpoint')"
read -p "Your choice [a/b]: " commit_pref

if [[ "$commit_pref" == "b" ]]; then
  COMMIT_TEXT="Use the Structured / Conventional Commits specification (e.g., feat:, fix:, docs:, chore:, refactor:) for all commit messages."
else
  COMMIT_TEXT="Use Informal, clear, imperative-style commit messages (e.g., 'Add feature X', 'Fix bug Y')."
fi

echo ""

# 3. Verification
echo "3) Should agents attempt to run tests/linting before committing?"
echo "   [y/n]"
read -p "Your choice [y/n]: " test_pref

if [[ "$test_pref" == "y" || "$test_pref" == "Y" ]]; then
  TEST_TEXT="Always attempt to run existing tests and linting commands (e.g., 'npm test', 'pytest', 'npm run lint') before committing. If they fail, fix the issues or report the blockers."
else
  TEST_TEXT="Running tests before commit is optional unless the user specifically asks."
fi

echo ""

# 4. Branch Cleanup
echo "4) Should agents periodically check if PRs have been merged and clean up local branches?"
echo "   [y/n]"
read -p "Your choice [y/n]: " cleanup_pref

if [[ "$cleanup_pref" == "y" || "$cleanup_pref" == "Y" ]]; then
  CLEANUP_TEXT="Periodically check if your previously opened Pull Requests have been merged. If they have, delete the corresponding local branches to keep the workspace clean."
else
  CLEANUP_TEXT="Do not automatically delete local branches unless the user explicitly requests a cleanup."
fi

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

## Accountability
Always include the branch name and, if applicable, the Pull Request URL in your \`agent-actions.md\` log entry.
EOF

echo ""
echo "✓ Git workflow profile created at ${SKILL_DIR}/${GIT_SKILL_FILE}"

# Sync to agents
# Reuse the detection logic from install.sh
declare -A AGENTS=(
  ["Claude Code"]="${HOME}/.claude"
  ["Gemini CLI"]="${HOME}/.gemini"
  ["Codex CLI"]="${HOME}/.codex"
  ["Aider"]="${HOME}/.aider"
  ["Continue"]="${HOME}/.continue"
)

LINKED=0
for agent in "${!AGENTS[@]}"; do
  config_dir="${AGENTS[$agent]}"
  if [[ -d "${config_dir}" ]]; then
    ln -sf "${SKILL_DIR}/${GIT_SKILL_FILE}" "${config_dir}/${GIT_SKILL_FILE}"
    echo "✓ Linked to ${agent} profile (${config_dir}/${GIT_SKILL_FILE})"
    ((LINKED++))
  fi
done

echo ""
echo "Done! Your Git workflow preferences are now active for ${LINKED} agent(s)."
