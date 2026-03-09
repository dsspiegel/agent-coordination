# Agent Coordination

A shared protocol for coordinating multiple AI coding agents (Claude Code, Gemini CLI, Codex, Aider, etc.) working on the same project.

## The Problem

When you use multiple AI coding agents on a project — switching between them, or using one to review another's work — they don't share context. One agent doesn't know what the other tried, what failed, or why certain decisions were made.

## The Solution

A simple, tool-agnostic protocol where agents maintain a shared `agent-actions.md` log in your project root. Each agent documents what it did, what blocked it, and what comes next.

## Install

From a local clone:

```bash
./install.sh
```

Or run it directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/dsspiegel/agent-coordination/main/install.sh | bash
```

The installer will:
1. Download the skill file to `~/.agent-skills/`
2. Detect which agents you have installed (Claude Code, Gemini CLI, Codex, Aider, Continue)
3. Symlink the skill file into each agent's config directory
4. Create or update managed instruction blocks in:
   - `~/.codex/AGENTS.md`
   - `~/.claude/CLAUDE.md`
   - `~/.gemini/GEMINI.md`

## What Agents Will Do

Once installed, agents following this protocol will:

- **Read `agent-actions.md`** before starting work
- **Log significant actions** with context and reasoning
- **Document blockers** and failed approaches (so the next agent doesn't repeat them)
- **Write clean handoffs** when stopping mid-task
- **Note disagreements** before changing another agent's approach

## Example Log Entry

```markdown
## 2026-03-05 10:15 AM PST; Gemini CLI (Gemini 2.5 Pro)

### Summary
Initialized Express backend and added React frontend.

### Details
- Scaffolded Node server in `/backend` and React app in `/frontend`.
- Added `POST /api/login` endpoint.

### Blockers / Challenges
- Frontend fetch to `/api/login` is failing due to CORS. 
- Added basic `cors()` middleware but it's rejecting the request because the frontend is sending credentials (cookies).
- Handoff due to hitting session limits.

### Next Steps
- Need to properly configure CORS to accept credentials without using a wildcard `*` origin.

---

## 2026-03-05 11:30 AM PST; Claude Code (Claude 3.7 Sonnet -> Opus 4.6)

### Summary
Fixed CORS authentication error between frontend and backend.

### Details
- Updated `backend/server.js` to dynamically reflect the `req.header('Origin')` instead of using `Access-Control-Allow-Origin: *`.

### Blockers / Challenges
- Initially, using the Sonnet model, I struggled to generate the correct dynamic origin function required by the `cors` package when `credentials: true` is set.
- The user switched me to the **Opus 4.6** model, which correctly identified the specific Express configuration needed to make this work.

### Next Steps
- Implement the "Dashboard" view now that login works.
```

## Supported Agents

| Agent | Config Directory | Detection |
|-------|------------------|-----------|
| Claude Code | `~/.claude/` | `claude` command |
| Gemini CLI | `~/.gemini/` | `gemini` command |
| Codex CLI | `~/.codex/` | `codex` command |
| Aider | `~/.aider/` | `aider` command |
| Continue | `~/.continue/` | `~/.continue/` dir |

### Adding Another Agent

```bash
ln -s ~/.agent-skills/agent-coordination.md ~/.your-agent/
```

## Uninstall

You can quickly remove the coordination protocol and the optional git workflow files by running the uninstall script:

```bash
curl -fsSL https://raw.githubusercontent.com/dsspiegel/agent-coordination/main/uninstall.sh | bash
```

The uninstall script also removes the managed instruction blocks previously added to Codex/Claude/Gemini instruction files.

## Optional: Configure Development Environment

AI agents often make assumptions about your Git workflow, Python setup, and JavaScript tooling. This script lets you define consistent preferences across all your CLI agents.

Run the interactive setup script:
```bash
./setup-dev-env.sh
```

This script gathers your preferences on:
- **Git workflow** — PRs vs. direct push, commit message style, test/lint before commit, branch cleanup, log tracking
- **Python** — virtual environment policy, package manager (pip, uv, or poetry)
- **JavaScript / Node.js** — local vs. global installs, package manager (npm, yarn, pnpm, or bun)

Preferences are stored in `~/.agent-skills/agent-dev-env.md` and symlinked into each agent's config directory.
It also refreshes the managed instruction blocks in `~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md`, and `~/.gemini/GEMINI.md` so the latest profile is included.

## Optional: Sync `AGENTS.md` In A Repo

To enforce coordination rules at the repository level, generate or update a managed block inside `AGENTS.md`:

```bash
./sync-agents-md.sh --repo /path/to/your/repo
```

What it does:
- Creates `AGENTS.md` if missing
- Inserts or updates a managed coordination block
- Pulls in your local `~/.agent-skills/agent-dev-env.md` profile when available
- Preserves any manual content outside the managed markers

For CI enforcement, run check mode:

```bash
./sync-agents-md.sh --repo /path/to/your/repo --check
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
