#!/bin/bash
set -euo pipefail

BEGIN_MARKER="<!-- BEGIN MANAGED: agent-coordination-global -->"
END_MARKER="<!-- END MANAGED: agent-coordination-global -->"

REMOVE_MODE=0
SKILL_DIR="${AGENT_SKILLS_DIR:-$HOME/.agent-skills}"
COORD_SKILL_FILE="$SKILL_DIR/agent-coordination.md"
DEV_ENV_SKILL_FILE="$SKILL_DIR/agent-dev-env.md"
TMP_FILES=()

cleanup_tmp_files() {
  local tmp_file
  for tmp_file in "${TMP_FILES[@]-}"; do
    if [[ -n "$tmp_file" ]]; then
      rm -f "$tmp_file"
    fi
  done
}

trap cleanup_tmp_files EXIT

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--remove]

Creates or updates managed instruction blocks in:
  - ~/.codex/AGENTS.md
  - ~/.claude/CLAUDE.md
  - ~/.gemini/GEMINI.md

Options:
  --remove      Remove managed blocks instead of updating them
  -h, --help    Show this help text
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remove)
      REMOVE_MODE=1
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

render_managed_block() {
  local output_file="$1"
  {
    echo "$BEGIN_MARKER"
    echo "## Agent Coordination (Managed)"
    echo
    echo "This block is managed by \`sync-global-agent-instructions.sh\`."
    echo "Do not edit inside these markers; re-run the installer/setup scripts instead."
    echo
    echo "### Required Workflow"
    echo "- ALWAYS read \`agent-actions.md\` in the project root before starting work."
    echo "- If \`agent-actions.md\` does not exist, ALWAYS create it using the bootstrap pattern — even in new or empty projects."
    echo "- After meaningful progress, blockers, reviews, or handoffs, append an entry to \`agent-actions.md\`."
    echo "- Do not silently undo another agent's approach; document reasoning first."
    echo "- For full protocol details, read the Source Of Truth files listed below."
    echo
    echo "### Source Of Truth"
    if [[ -f "$COORD_SKILL_FILE" ]]; then
      echo "- \`$COORD_SKILL_FILE\`"
    else
      echo "- \`$COORD_SKILL_FILE\` (missing)"
    fi
    if [[ -f "$DEV_ENV_SKILL_FILE" ]]; then
      echo "- \`$DEV_ENV_SKILL_FILE\`"
    fi
    echo

    echo "$END_MARKER"
  } > "$output_file"
}

default_header_for_file() {
  local basename_target
  basename_target="$(basename "$1")"
  case "$basename_target" in
    AGENTS.md) echo "# AGENTS" ;;
    CLAUDE.md) echo "# CLAUDE" ;;
    GEMINI.md) echo "# GEMINI" ;;
    *) echo "# Instructions" ;;
  esac
}

remove_managed_block() {
  local target_file="$1"
  local updated_file="$2"

  if [[ ! -f "$target_file" ]]; then
    return 1
  fi

  if ! grep -Fq "$BEGIN_MARKER" "$target_file"; then
    return 1
  fi

  if ! grep -Fq "$END_MARKER" "$target_file"; then
    echo "error: found begin marker without matching end marker in $target_file" >&2
    exit 2
  fi

  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
    BEGIN {
      in_block = 0
    }
    {
      if ($0 == begin) {
        in_block = 1
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
    }
  ' "$target_file" > "$updated_file"

  mv "$updated_file" "$target_file"
  return 0
}

upsert_managed_block() {
  local target_file="$1"
  local generated_block_file="$2"
  local updated_file="$3"

  if [[ ! -f "$target_file" ]]; then
    {
      default_header_for_file "$target_file"
      echo
      cat "$generated_block_file"
      echo
    } > "$target_file"
    return 0
  fi

  if grep -Fq "$BEGIN_MARKER" "$target_file" && ! grep -Fq "$END_MARKER" "$target_file"; then
    echo "error: found begin marker without matching end marker in $target_file" >&2
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
  ' "$target_file" > "$updated_file"

  mv "$updated_file" "$target_file"
}

TARGETS=(
  "Codex CLI|codex|$HOME/.codex|AGENTS.md"
  "Claude Code|claude|$HOME/.claude|CLAUDE.md"
  "Gemini CLI|gemini|$HOME/.gemini|GEMINI.md"
)

CHANGED=0
for entry in "${TARGETS[@]}"; do
  IFS='|' read -r agent cmd config_dir instruction_file <<< "$entry"
  if [[ -d "$config_dir" ]] || command -v "$cmd" >/dev/null 2>&1; then
    mkdir -p "$config_dir"
    target_file="${config_dir}/${instruction_file}"

    generated_block_file="$(mktemp)"
    updated_file="$(mktemp)"
    TMP_FILES+=("$generated_block_file" "$updated_file")

    if [[ "$REMOVE_MODE" -eq 1 ]]; then
      if remove_managed_block "$target_file" "$updated_file"; then
        echo "Removed managed block from ${target_file} (${agent})"
        CHANGED=$((CHANGED + 1))
      fi
    else
      render_managed_block "$generated_block_file"
      upsert_managed_block "$target_file" "$generated_block_file" "$updated_file"
      echo "Updated managed instructions in ${target_file} (${agent})"
      CHANGED=$((CHANGED + 1))
    fi

    rm -f "$generated_block_file" "$updated_file"
  fi
done

if [[ "$REMOVE_MODE" -eq 1 ]]; then
  if [[ "$CHANGED" -eq 0 ]]; then
    echo "No managed global instruction blocks found."
  fi
else
  if [[ "$CHANGED" -eq 0 ]]; then
    echo "No supported agent environments detected for global instruction sync."
  fi
fi
