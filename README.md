# claude-opencode-team

Ambiente per far lavorare insieme **Claude Code** e gli agenti di **opencode** su qualsiasi progetto,
con i task tracciati in **beads** (`bd`) e visibili con **beads_viewer** (`bv`). Puoi usare un
**team misto** (Claude + opencode) oppure **solo opencode**, una feature alla volta.

## Installazione su un nuovo Mac

```bash
git clone git@github.com:Bu3nd14/claude-opencode-team.git ~/claude-opencode-team
cd ~/claude-opencode-team
./install.sh            # --dry-run per vedere cosa fa, --no-brew per saltare Homebrew
opencode auth login     # credenziali dei provider (non sono nel repo)
```

Prerequisiti: macOS con [Homebrew](https://brew.sh) e [Claude Code](https://claude.com/claude-code).
`install.sh` installa `jq`, `beads`, `beads_viewer` e `opencode` (Brewfile), poi **collega** i file di
configurazione a questo repo con dei symlink: sui file già presenti fa un backup `*.bak-<data>`.
Infine aggiunge l'hook di avvio a `~/.claude/settings.json`, unendolo a quello che c'è, senza
sovrascrivere. Puoi rilanciarlo senza problemi.

Per aggiornare una macchina: `git pull` (i link puntano al repo, non serve reinstallare).
Per modificare la configurazione: modifica i file qui, poi commit e push.

## Come si parte in un progetto nuovo

1. Apri la cartella (con Claude Code o con opencode).
2. Una volta sola: `git init` e `oc-task init`: attiva beads in modalità stealth (niente file
   tracciati da git) e l'export per `bv`. Puoi chiederlo a Claude Code o farlo a mano.
3. Poi scegli per ogni feature:
   - **solo opencode**: lavori in opencode; il suo orchestratore etichetta l'epic `team:oc` e usa la
     doppia approvazione interna (`architetto` + `architetto-avversariale`);
   - **team misto**: lo chiedi in Claude Code, per esempio *"per la feature X lavoriamo in team misto:
     design al tuo architetto, codice al coder di oc"*. L'epic viene etichettato `team:misto` e il
     flusso usa la review incrociata.
4. Per vedere a che punto sei: `bv` nella cartella del progetto, oppure chiedilo a Claude.

## Chi fa cosa

| Lato | Agenti | Dove sono definiti |
|---|---|---|
| Claude Code | `architetto` (Opus), `architetto-avversariale` (Opus), `reviewer` (Sonnet) | `claude/agents/` |
| opencode | `orchestratore`, `architetto`, `architetto-avversariale`, `coder`, `tester` | `opencode/agent/` |

Regole principali (dettagli in `claude/skills/opencode-delegate/SKILL.md` e `opencode/AGENTS.md`):

- **Assegnazione**: "tuo / di Claude" → sottoagente Claude; "di oc / di opencode" → `oc-task`.
  Senza indicazione: design → architetto Claude, codice e test → coder/tester di oc, review del
  codice → reviewer Claude. Claude annuncia la scelta prima di partire.
- **Approvazione incrociata** (team misto, cambiamenti non fast-track): design di Claude → review
  dell'avversariale di opencode, e viceversa. Il coder parte solo con un `VERDETTO: APPROVO`
  registrato come commento sul bead del design. Il fast track lo decide solo l'utente.
- **Una feature, un solo orchestratore**: l'epic `team:oc` non viene toccato da Claude (e `oc-task`
  lo rifiuta) se non su richiesta esplicita.
- **Identità**: gli agenti opencode sono sempre `opencode:<nome>`, quelli Claude `claude:<nome>`.
  opencode non usa `oc-task` (lo script si rifiuta di partire dentro opencode) e firma i comandi
  `bd` con `--actor opencode:<agente>`.

## `oc-task` in breve

Lo strumento con cui Claude Code delega a opencode e traccia tutto in beads.

| Comando | Effetto |
|---|---|
| `oc-task init [prefisso]` | Attiva beads nel repo corrente (stealth + export per `bv`). |
| `oc-task new "titolo" -a <agente> -d "…"` | Crea un bead `team:misto` e lo delega a un agente opencode. |
| `oc-task run <id> [-a agente] [-C worktree]` | Delega un bead esistente. |
| `oc-task followup <id> "msg"` | Continua la stessa sessione opencode del bead. |
| `oc-task claim/report <id> --as claude:<agente>` | Traccia il lavoro di un sottoagente Claude. |
| `oc-task status` | Bead in corso (`running`) o da verificare (`review`), con agente e modalità `team:*`. |

A fine lavoro il bead torna all'utente con la label `agent-review`: si verifica e si chiude con
`bd close <id> --reason "…"`.

## Vedere i task

- `bv`: interfaccia TUI di beads_viewer (priorità sul grafo, percorso critico, salute del progetto).
- `bd ready`, `bd list`, `bd show <id>`, `bd comments <id>`, `bd graph <epic>`, `bd status`.
- `oc-task status`: chi sta lavorando su cosa.

## Cosa contiene il repo

```
bin/oc-task                               → ~/.local/bin/oc-task
claude/skills/opencode-delegate/SKILL.md  → ~/.claude/skills/opencode-delegate/SKILL.md
claude/agents/*.md                        → ~/.claude/agents/
claude/hooks/beads-session-start.sh       → ~/.claude/hooks/   (+ voce in ~/.claude/settings.json)
opencode/AGENTS.md, opencode.jsonc        → ~/.config/opencode/
opencode/agent/*.md                       → ~/.config/opencode/agent/
Brewfile, install.sh
```

L'hook di avvio carica in Claude Code la skill e lo stato dei task **solo** nei progetti con
`.beads/`; altrove non fa nulla.

**Non** sono nel repo: credenziali di opencode (`~/.local/share/opencode/auth.json`), stato locale
(`service.json`), i database beads dei progetti (stanno in `.beads/` dentro ogni progetto, esclusi da
git) e la memoria per progetto di Claude Code.

## Ancora aperto (facoltativo)

- **Primo collaudo del team misto** su una feature reale e piccola: i singoli pezzi sono provati,
  il giro completo (architetto Claude → avversariale oc → coder oc → reviewer Claude) non ancora.
- **Metriche anonime di beads** attive per default: `bd metrics off` per disattivarle.
- **`git init` automatico** in `oc-task init` quando il repo manca.
