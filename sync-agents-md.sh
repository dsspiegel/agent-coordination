#!/bin/bash
set -euo pipefail

BEGIN_MARKER="<!-- BEGIN MANAGED: agent-coordination -->"
END_MARKER="<!-- END MANAGED: agent-coordination -->"

CHECK_MODE=0
REPO_DIR="$(pwd)"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--repo <path>] [--check]

Creates or updates a managed Agent Coordination block in AGENTS.md.

Options:
  --repo <path>  Repository root to update (default: current directory)
  --check        Do not write files; exit non-zero if AGENTS.md is missing or out of date
  -h, --help     Show this help text
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      if [[ $# -lt 2 ]]; then
        echo "error: --repo requires a path" >&2
        exit 2
      fi
      REPO_DIR="$2"
      shift 2
      ;;
    --check)
      CHECK_MODE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ! -d "$REPO_DIR" ]]; then
  echo "error: repo directory not found: $REPO_DIR" >&2
  exit 2
fi

SKILL_DIR="${AGENT_SKILLS_DIR:-$HOME/.agent-skills}"
COORD_SKILL_FILE="$SKILL_DIR/agent-coordination.md"
DEV_ENV_SKILL_FILE="$SKILL_DIR/agent-dev-env.md"
AGENTS_FILE="$REPO_DIR/AGENTS.md"

if [[ ! -f "$COORD_SKILL_FILE" ]]; then
  echo "error: required skill file missing: $COORD_SKILL_FILE" >&2
  exit 2
fi

generated_block_file="$(mktemp)"
updated_file="$(mktemp)"
trap 'rm -f "$generated_block_file" "$updated_file"' EXIT

render_managed_block() {
  {
    echo "$BEGIN_MARKER"
    echo "## Agent Coordination (Managed)"
    echo
    echo "This block is managed by \`sync-agents-md.sh\`."
    echo "Do not edit inside these markers; re-run the script instead."
    echo
    echo "### Required Workflow"
    echo "1. FIRST action in any session: read \`agent-actions.md\` in the repo root. If it does not exist, create it before doing anything else using the bootstrap pattern in \`$COORD_SKILL_FILE\`."
    echo "2. LAST action before finishing: append a log entry to \`agent-actions.md\` with summary, details, blockers, and next steps."
    echo "3. Do not silently undo another agent's approach; document reasoning for significant approach changes in the log first."
    echo
    echo "### Scope"
    echo "- Applies to all agents working in this repository."
    echo "- Treat this as the default behavior, not an opt-in workflow."
    echo
    echo "### Source Of Truth"
    echo "- \`$COORD_SKILL_FILE\`"

    if [[ -f "$DEV_ENV_SKILL_FILE" ]]; then
      echo "- \`$DEV_ENV_SKILL_FILE\`"
      echo
      echo "### Development Environment Profile (Managed Snapshot)"
      sed 's/^/> /' "$DEV_ENV_SKILL_FILE"
    fi

    echo "$END_MARKER"
  } > "$generated_block_file"
}

build_updated_content() {
  local input_file="$1"
  local output_file="$2"

  if [[ ! -f "$input_file" ]]; then
    {
      echo "# AGENTS"
      echo
      cat "$generated_block_file"
      echo
    } > "$output_file"
    return
  fi

  if grep -Fq "$BEGIN_MARKER" "$input_file" && ! grep -Fq "$END_MARKER" "$input_file"; then
    echo "error: found begin marker without matching end marker in $input_file" >&2
    exit 2
  fi

  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" -v replacement_file="$generated_block_file" '
    BEGIN {
      in_block = 0
      replaced = 0
      while ((getline line < replacement_file) > 0) {
        replacement = replacement line ORS
      }
      close(replacement_file)
    }
    {
      if ($0 == begin) {
        if (replaced == 1) {
          print "error: multiple managed blocks found" > "/dev/stderr"
          exit 2
        }
        printf "%s", replacement
        in_block = 1
        replaced = 1
        next
      }

      if (in_block == 1) {
        if ($0 == end) {
          in_block = 0
        }
        next
      }

      print
    }
    END {
      if (in_block == 1) {
        print "error: missing end marker" > "/dev/stderr"
        exit 2
      }
      if (replaced == 0) {
        print ""
        printf "%s", replacement
      }
    }
  ' "$input_file" > "$output_file"
}

render_managed_block
build_updated_content "$AGENTS_FILE" "$updated_file"

if [[ "$CHECK_MODE" -eq 1 ]]; then
  if [[ ! -f "$AGENTS_FILE" ]]; then
    echo "AGENTS.md is missing. Run ./sync-agents-md.sh --repo \"$REPO_DIR\""
    exit 1
  fi

  if ! cmp -s "$AGENTS_FILE" "$updated_file"; then
    echo "AGENTS.md is out of date. Run ./sync-agents-md.sh --repo \"$REPO_DIR\""
    exit 1
  fi

  echo "AGENTS.md is up to date."
  exit 0
fi

mv "$updated_file" "$AGENTS_FILE"
echo "Updated $AGENTS_FILE"
