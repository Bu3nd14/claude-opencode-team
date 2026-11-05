#!/usr/bin/env bash
# SessionStart hook: nei progetti con beads (.beads/) carica la skill opencode-delegate
# e lo stato dei task delegati a opencode. Altrove non fa nulla.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
cd "${CLAUDE_PROJECT_DIR:-$PWD}" 2>/dev/null || exit 0
command -v bd >/dev/null 2>&1 || exit 0
bd where >/dev/null 2>&1 || exit 0

skill="$HOME/.claude/skills/opencode-delegate/SKILL.md"
[[ -f $skill ]] || exit 0
body=$(awk 'f>=2{print} /^---$/{f++}' "$skill")   # senza frontmatter

status=$(oc-task status 2>/dev/null)
ready=$(bd ready --json 2>/dev/null | jq -r '.[] | "\(.id)\tP\(.priority)\t\(.title)"' 2>/dev/null | head -10)

ctx="Questo progetto usa beads ($(bd where 2>/dev/null | head -1)). Skill opencode-delegate precaricata:

${body}

## Stato all'avvio della sessione
Task delegati a opencode (oc-task status):
${status:-nessuno}

Lavoro pronto (bd ready, max 10):
${ready:-nessuno}"

jq -n --arg c "$ctx" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
