#!/usr/bin/env bash
# install.sh — installa l'ambiente Claude Code + opencode + beads su questa macchina.
#
#   ./install.sh            installa dipendenze (Homebrew) e collega i file di configurazione
#   ./install.sh --no-brew  salta Homebrew, collega solo i file
#   ./install.sh --dry-run  mostra cosa farebbe, senza toccare nulla
#
# I file vengono COLLEGATI (symlink) a questo repo, non copiati: modifichi qui, committi, e su
# ogni macchina basta `git pull`. Un file già presente al posto di un link viene spostato in
# <file>.bak-<data> prima di essere sostituito. Rilanciarlo è sicuro (idempotente).
set -euo pipefail

REPO=$(cd "$(dirname "$0")" && pwd)
STAMP=$(date +%Y%m%d-%H%M%S)
DRY=0 BREW=1
for a in "$@"; do
  case $a in
    --dry-run) DRY=1;;
    --no-brew) BREW=0;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "opzione sconosciuta: $a" >&2; exit 1;;
  esac
done

run() { if [[ $DRY -eq 1 ]]; then echo "  [dry-run] $*"; else "$@"; fi; }
say() { printf '\n==> %s\n' "$*"; }

link() { # link <file nel repo> <destinazione>
  local src="$REPO/$1" dst=$2
  [[ -e $src ]] || { echo "  manca nel repo: $1" >&2; return 1; }
  if [[ -L $dst && $(readlink "$dst") == "$src" ]]; then echo "  ok      $dst"; return; fi
  run mkdir -p "$(dirname "$dst")"
  if [[ -e $dst || -L $dst ]]; then
    echo "  backup  $dst -> $dst.bak-$STAMP"
    run mv "$dst" "$dst.bak-$STAMP"
  fi
  run ln -s "$src" "$dst"
  echo "  link    $dst -> $src"
}

# --- 1. dipendenze ---------------------------------------------------------------
if [[ $BREW -eq 1 ]]; then
  say "Dipendenze Homebrew (Brewfile)"
  command -v brew >/dev/null || { echo "Homebrew non trovato: installalo da https://brew.sh" >&2; exit 1; }
  run brew bundle --file "$REPO/Brewfile"
fi
for c in jq bd bv opencode; do
  command -v "$c" >/dev/null || echo "  attenzione: '$c' non è nel PATH"
done
command -v claude >/dev/null || echo "  attenzione: Claude Code ('claude') non trovato: https://claude.com/claude-code"

# --- 2. file di configurazione -----------------------------------------------------
say "Claude Code (~/.claude)"
link claude/skills/opencode-delegate/SKILL.md "$HOME/.claude/skills/opencode-delegate/SKILL.md"
for f in "$REPO"/claude/agents/*.md; do link "claude/agents/$(basename "$f")" "$HOME/.claude/agents/$(basename "$f")"; done
link claude/hooks/beads-session-start.sh "$HOME/.claude/hooks/beads-session-start.sh"

say "opencode (~/.config/opencode)"
link opencode/AGENTS.md "$HOME/.config/opencode/AGENTS.md"
link opencode/opencode.jsonc "$HOME/.config/opencode/opencode.jsonc"
for f in "$REPO"/opencode/agent/*.md; do link "opencode/agent/$(basename "$f")" "$HOME/.config/opencode/agent/$(basename "$f")"; done

say "oc-task (~/.local/bin)"
link bin/oc-task "$HOME/.local/bin/oc-task"
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo "  attenzione: aggiungi ~/.local/bin al PATH (es. in ~/.zshrc)";; esac

# --- 3. hook SessionStart in ~/.claude/settings.json (merge, non sovrascrive) -----------
say "Hook di avvio Claude Code (~/.claude/settings.json)"
S="$HOME/.claude/settings.json"
HOOK_CMD="bash ~/.claude/hooks/beads-session-start.sh"
if [[ -f $S ]] && jq -e --arg c "$HOOK_CMD" '[.hooks.SessionStart[]?.hooks[]?.command] | index($c)' "$S" >/dev/null 2>&1; then
  echo "  ok      hook già registrato"
else
  [[ -f $S ]] || { run mkdir -p "$HOME/.claude"; [[ $DRY -eq 1 ]] || echo '{}' > "$S"; }
  run cp "$S" "$S.bak-$STAMP"
  if [[ $DRY -eq 0 ]]; then
    tmp=$(mktemp)
    jq --arg c "$HOOK_CMD" '.hooks.SessionStart += [{"matcher":"startup|resume|clear|compact","hooks":[{"type":"command","command":$c,"timeout":15}]}]' "$S" > "$tmp"
    mv "$tmp" "$S"
  fi
  echo "  aggiunto hook SessionStart (backup: $S.bak-$STAMP)"
fi

say "Fatto"
cat <<'EOF'
Prossimi passi:
  - autentica opencode con i tuoi provider:        opencode auth login
  - (facoltativo) metriche anonime di beads off:    bd metrics off
  - in ogni progetto, una volta:                     git init && oc-task init
  - riavvia Claude Code per caricare agenti, skill e hook.
EOF
