# Agent Coordination

A shared protocol for coordinating multiple AI coding agents (Claude Code, Gemini CLI, Codex, Aider, etc.) working on the same project.

## The Problem

When you use multiple AI coding agents on a project — switching between them, or using one to review another's work — they don't share context. One agent doesn't know what the other tried, what failed, or why certain decisions were made.

## The Solution

A simple, tool-agnostic protocol where agents maintain a shared `agent-actions.md` log in your project root. Each agent documents what it did, what blocked it, and what comes next.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/dsspiegel/agent-coordination/main/install.sh | bash
```

The installer will:
1. Download the skill file to `~/.agent-skills/`
2. Detect which agents you have installed (Claude Code, Gemini CLI, Codex, Aider, Continue)
3. Symlink the skill file into each agent's config directory

## What Agents Will Do

Once installed, agents following this protocol will:

- **Read `agent-actions.md`** before starting work
- **Log significant actions** with context and reasoning
- **Document blockers** and failed approaches (so the next agent doesn't repeat them)
- **Write clean handoffs** when stopping mid-task
- **Note disagreements** before changing another agent's approach

## Example Log Entry

```markdown
## 2026-03-05 2:45 PM PST; Claude Code

### Summary
Implemented go-links redirect endpoint with access tracking.

### Details
- Added `/go/<slug>` route in `src/routes/links.py`
- Used Firestore transaction for atomic counter increment

### Blockers / Challenges
- Initially tried incrementing outside transaction; hit race condition under load
- Firestore's `increment()` field transform solved it

### Next Steps
- "My Links" dashboard view not yet started
- Need to add ownership check for edit/delete endpoints
```

## Supported Agents

| Agent | Config Directory | Detection |
|-------|------------------|-----------|
| Claude Code | `~/.claude/` | `claude` command |
| Gemini CLI | `~/.gemini/` | `gemini` command |
| Codex CLI | `~/.codex/` | `codex` command |
| Aider | `~/.aider/` | `aider` command |
| Continue | `~/.continue/` | `continue` command |

### Adding Another Agent

```bash
ln -s ~/.agent-skills/agent-coordination.md ~/.your-agent/
```

## Uninstall

```bash
rm ~/.agent-skills/agent-coordination.md
rm ~/.claude/agent-coordination.md
rm ~/.gemini/agent-coordination.md
# ... etc for any other agents
```

## Philosophy

- **Simple**: It's just a markdown file. No databases, no servers, no dependencies.
- **Tool-agnostic**: Works with any agent that can read instruction files.
- **Human-readable**: You can read and edit the log too.
- **Git-friendly**: The log is just a file in your repo — version it like anything else.

## Contributing

Found a way to improve the protocol? PRs welcome.

## License

MIT
