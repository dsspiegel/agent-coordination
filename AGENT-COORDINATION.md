# Agent Coordination Protocol

This file defines how AI coding agents should coordinate when multiple agents work on the same project.

## Core Principles

1. **Leave a trail.** Every significant action gets logged so other agents (and humans) can understand what happened.
2. **Read before you write.** Check the log and recent changes before starting work.
3. **Document dead ends.** Failed approaches are as valuable as successful ones — they prevent repeated mistakes.
4. **Stay in your lane.** When picking up work another agent started, understand their approach before changing course.

---

## The Action Log

### Location
Every project should have an `agent-actions.md` file in the project root.

### Before Starting Work
1. Read the entire `agent-actions.md` file
2. Check the most recent entries for:
   - Work in progress that you should continue
   - Blockers or failed approaches to avoid
   - Context that affects your current task
3. Review recent commits/changes if the log references them

### When to Log
Log after:
- Completing a feature or significant component
- Hitting a blocker that took multiple attempts to resolve
- Making an architectural decision
- Abandoning an approach that didn't work
- Completing a code review of another agent's work
- Any action where context would help the next agent

### Log Entry Format

```markdown
## YYYY-MM-DD HH:MM AM/PM TZ; [Agent Name]

### Summary
One-line description of what was accomplished.

### Details
- What was done (be specific about files changed)
- Why this approach was chosen (if non-obvious)

### Blockers / Challenges (if any)
- What didn't work and why
- Key insight that unblocked progress

### Next Steps (if incomplete)
- What remains to be done
- Recommended approach
```

### Example Entry

```markdown
## 2026-03-05 2:45 PM PST; Claude Code

### Summary
Implemented go-links redirect endpoint with access tracking.

### Details
- Added `/go/<slug>` route in `main.py`
- Increment `access_count` and update `accessed_at` on each redirect
- Used Firestore transaction to avoid race conditions on counter

### Blockers / Challenges
- Initially tried incrementing outside a transaction; hit race condition under load
- Firestore's `increment()` field transform solved it without needing explicit transaction

### Next Steps
- "My Links" dashboard view not yet started
- Need to add ownership check for edit/delete endpoints
```

---

## Bootstrapping a New Project

If `agent-actions.md` doesn't exist, create it:

```markdown
# Agent Actions Log

This file tracks significant actions taken by AI coding agents on this project.
Human contributors are also welcome to log context here.

---

## YYYY-MM-DD HH:MM AM/PM TZ; [Agent Name]

### Summary
Initialized project / began work on [description].

### Details
- [What was set up]
- [Key decisions made]
```

---

## Code Review Protocol

When reviewing code written by another agent (or human):

1. **Read the log first** to understand intent and constraints
2. **Log your review** before making changes:

```markdown
## YYYY-MM-DD HH:MM AM/PM TZ; [Agent Name]

### Summary
Code review of [feature/PR/commit].

### Reviewed
- [Files or components reviewed]

### Feedback
- [Issues found, suggestions, questions]

### Changes Made
- [Any direct changes, or "none — feedback only"]
```

3. **Preserve intent** — if you disagree with an approach, note it in the log and discuss rather than silently rewriting

---

## Handoff Protocol

When you cannot complete a task (hitting context limits, user switching agents, etc.):

1. **Stop at a clean point** if possible (tests passing, no syntax errors)
2. **Log current state explicitly**:

```markdown
## YYYY-MM-DD HH:MM AM/PM TZ; [Agent Name]

### Summary
Handoff — [reason: context limit / switching agents / blocked].

### Current State
- [What's working]
- [What's broken or incomplete]
- [Files in uncertain state, if any]

### To Continue
1. [Specific next step]
2. [What to watch out for]

### Open Questions
- [Anything unresolved that needs human input]
```

---

## Conflict Resolution

If you disagree with a previous agent's approach:

1. **Don't silently undo their work**
2. **Log your reasoning**:

```markdown
### Approach Change
Previous agent used [X approach] because [their reasoning].
Switching to [Y approach] because [your reasoning].
```

3. If the change is significant, consider flagging for human review rather than proceeding

---

## File Conventions

| File | Purpose |
|------|---------|
| `agent-actions.md` | Action log (this protocol) |
| `REQUIREMENTS.md` | What we're building (human-authored, agents read) |
| `DECISIONS.md` | Architectural decisions with rationale (optional) |
| `TODO.md` | Current task list (optional, can use log instead) |

---

## Tips for Effective Logging

**Be specific about files:**
- ❌ "Updated the API"
- ✅ "Added `POST /api/links` endpoint in `src/routes/links.py`"

**Capture the "why":**
- ❌ "Used Firestore"
- ✅ "Used Firestore because other apps here use it — see `user-service/` for patterns"

**Document environment issues:**
- ✅ "Auth only works with `gcloud auth application-default login` — IAP headers not available in local dev"

**Link to resources:**
- ✅ "Followed Cloud Run deploy pattern from `go/deploy-docs` (internal) and https://cloud.google.com/run/docs/deploying"

---

## Agent-Specific Notes

### Claude Code
- You can reference this file from `~/.claude/CLAUDE.md` or `.claude/CLAUDE.md`
- If user says "coordinate" or "check the log", this protocol applies

### Gemini CLI
- You can reference this file from `~/.gemini/GEMINI.md` or `.gemini/GEMINI.md`
- Same triggers apply

### Other Agents
- Any agent capable of reading instruction files can follow this protocol
- The format is intentionally tool-agnostic
