---
name: opencode-delegate
description: Delegate tasks to a mixed team — the user's opencode agents (orchestratore, architetto, architetto-avversariale, coder, tester) via the oc-task CLI and Claude Code's own subagents (architetto, architetto-avversariale, reviewer) — tracked with beads (bd), in any project. Use when the user asks to assign/delegate work ("fallo fare al tester", "assegna l'architettura al tuo architetto e lo sviluppo al coder di oc", "delega a opencode"), to follow up on or check delegated tasks ("a che punto sono i task?", "cosa ha risposto il coder?"), to activate beads in a project, to manage the bd task list, or asks how to use oc-task.
---

# Delegare task agli agenti opencode, tracciati con beads

Lo strumento è `oc-task` (`~/.local/bin/oc-task`): crea/legge il bead, lo prende in carico come
`opencode:<agente>`, lancia `opencode run --format json`, salva la risposta come commento del bead
e la sessione opencode nei metadati, poi stampa un JSON `{id, agent, session, exit, cost, response}`.

## Agenti disponibili (globali, `~/.config/opencode/agent/`)
- `orchestratore` (primary): pianifica e scompone in sotto-task; delega da solo agli altri.
- `architetto`: design, schemi, contratti, API.
- `architetto-avversariale`: review critica del design; risponde APPROVO/RESPINGO.
- `coder`: implementazione a partire dal design approvato.
- `tester`: test, build, analisi log, fix loop.

Il file `~/.config/opencode/AGENTS.md` dell'utente impone la doppia approvazione architetturale per
i cambiamenti non "fast track" (lo decide solo l'utente). Non mandare un cambiamento di codice
non banale direttamente al `coder`: passa da `architetto` + `architetto-avversariale`, oppure
delega l'intero flusso all'`orchestratore`.

## Team misto: chi fa cosa

Agenti Claude Code globali (`~/.claude/agents/`), lanciati con lo strumento Agent (`subagent_type`):
- `architetto` (Opus): design → `docs/design/<id>-<slug>.md`.
- `architetto-avversariale` (Opus): red team del design, chiude con `VERDETTO: APPROVO|RESPINGO`.
- `reviewer` (Sonnet): review del codice consegnato, chiude con `VERDETTO: ACCETTO|RIFIUTO`.

### Modalità per feature: label `team:oc` / `team:misto`
- Ogni epic (e i suoi figli, `bd label propagate <epic> team:<x>`) dichiara chi lo guida.
- `team:oc` → lo guida l'orchestratore di opencode in autonomia: **non toccarlo** (niente oc-task, claim,
  review) se l'utente non lo chiede esplicitamente; per entrarci, prima cambia la label in `team:misto`
  con il consenso dell'utente e avvisalo di dirlo all'orchestratore.
- `team:misto` → lo guido io con il flusso misto qui sotto. Ogni bead che creo per un team misto ha
  `-l team:misto` (`oc-task new` la aggiunge da sola).
- Una feature, un solo orchestratore: mai due che guidano lo stesso epic.

### Assegnazione (regola scelta dall'utente)
- "tuo / di Claude / Claude Code" → mio sottoagente. "di oc / di opencode / oc" → `oc-task -a <agente>`.
- Nessuna indicazione → default per ruolo, **annunciato all'utente prima di partire**:

  | Ruolo | Default |
  |---|---|
  | architettura / design | `architetto` Claude |
  | review avversariale | lato opposto a chi ha fatto il design (vedi sotto) |
  | implementazione | `coder` oc |
  | test / build / fix loop | `tester` oc |
  | review del codice | `reviewer` Claude |
  | pianificazione / scomposizione grande | `orchestratore` oc (solo se richiesto o se il lavoro è molto ampio) |

### Approvazione incrociata (obbligatoria per i cambiamenti non fast-track)
- Design di `claude:architetto` → review di `architetto-avversariale` **di opencode**.
- Design di `opencode:architetto` → review di `architetto-avversariale` **di Claude**.
- Il `coder` parte solo dopo un `APPROVO` registrato come commento sul bead del design. Su `RESPINGO`
  l'architetto che ha fatto il design risolve le obiezioni bloccanti/alte e si ripete; disaccordo
  persistente → fermati e chiedi all'utente. Il fast track lo decide solo l'utente.

### Tracciare i sottoagenti Claude (come opencode)
```bash
oc-task claim <id> --as claude:<agente>              # prima di lanciare il sottoagente
# ... Agent(subagent_type: "<agente>", prompt autosufficiente con id del bead e percorso del design)
oc-task report <id> --as claude:<agente> -f <file>   # o testo su stdin: salva la risposta, torna in review
```
Scrivi la risposta del sottoagente in un file temporaneo (`$CLAUDE_JOB_DIR/tmp` o la scratchpad) e passalo
con `-f`. Il bead torna all'utente con label `agent-review`, identico ai run opencode.

### Ricetta: "architettura al tuo architetto, sviluppo al coder di oc"
```bash
A=$(bd create "Design: <feature>" -t task -l agent:claude-architetto,team:misto -d "<requisiti>" --silent)
I=$(bd create "Implementazione: <feature>" -t feature -l agent:coder,team:misto -d "Implementa docs/design/$A-*.md" --deps blocked-by:$A --silent)
R=$(bd create "Review avversariale design $A" -t task -l agent:architetto-avversariale,team:misto --deps blocked-by:$A --silent)
```
1. `oc-task claim $A --as claude:architetto` → sottoagente `architetto` → `oc-task report $A ...`.
2. `oc-task run $R -a architetto-avversariale` (design di Claude ⇒ avversariale di oc). Il prompt deve
   indicare il file del design. Se RESPINGO: di nuovo `architetto` Claude con le obiezioni, poi
   `oc-task followup $R "design aggiornato, rivaluta"`.
3. Con APPROVO: `bd close $A $R`, poi `oc-task run $I -a coder` (meglio in un worktree con `-C`).
4. A fine run: `oc-task claim $I --as claude:reviewer` → sottoagente `reviewer` → `oc-task report`.
   RIFIUTO ⇒ `oc-task followup $I "<rilievi>"`; ACCETTO ⇒ verifica finale e `bd close $I`.
Lavori indipendenti (es. design di A mentre il tester di oc verifica B) vanno lanciati in parallelo:
sottoagente in background + `oc-task` con Bash `run_in_background`.

## Flusso (solo opencode)
1. **Una volta per progetto**: `oc-task init` dalla root del repo (beads in modalità stealth: niente
   file tracciati da git; idempotente).
2. **Delegare**:
   - nuovo: `oc-task new "titolo" -a <agente> -d "descrizione con criteri di accettazione"`
   - esistente: `oc-task run <id> [-a agente]` (senza `-a` usa la label `agent:<nome>` del bead)
   - lancialo con Bash `run_in_background: true` se dura più di qualche secondo; più task
     indipendenti = più comandi in background in parallelo.
   - per task che modificano file mentre lavori anche tu, crea un git worktree e passa `-C <path>`.
   - `--auto` solo se l'utente lo autorizza (auto-approva i permessi opencode).
3. **Raccogliere**: leggi `response` dal JSON (`exit != 0` → il bead torna `open`, leggi l'errore).
   La risposta termina con `ESITO / FILE / VERIFICHE`: controlla i file e le verifiche, non fidarti
   solo dell'esito dichiarato.
4. **Iterare**: `oc-task followup <id> "messaggio"` riprende la stessa sessione opencode.
5. **Chiudere**: a fine run il bead torna a chi ha delegato (`in_progress`, label `agent-review`).
   Solo dopo aver verificato: `bd close <id> --reason "..."`. Altrimenti lascialo aperto e
   riferisci all'utente. (Durante il run è assegnato a `opencode:<agente>` e beads rifiuta la
   chiusura senza `--force`: non forzarla mentre un agente ci lavora.)
6. **Panoramica**: `oc-task status` (`running` = agente al lavoro, `review` = da verificare), `bd ready` (lavoro sbloccato),
   `bd list`, `bd show <id>`, `bd comments <id>`.

## Riferimento `oc-task`

Va lanciato da dentro il progetto (qualsiasi sottocartella del repo con `.beads/`).

| Comando | Effetto |
|---|---|
| `oc-task init [prefisso]` | Attiva beads nel repo corrente (stealth, idempotente). Prefisso id default = nome cartella. |
| `oc-task new "titolo" [opz]` | Crea il bead e lo delega subito; stampa `oc-task: creato <id>` su stderr e il JSON su stdout. |
| `oc-task run <id> [opz]` | Delega un bead esistente (anche creato a mano con `bd create`). |
| `oc-task followup <id> "msg"` | Nuovo messaggio nella stessa sessione opencode (stesso agente e directory del run). |
| `oc-task status` | TSV: `id  running/review  agente  team  sessione  titolo` dei bead delegati non chiusi. |
| `oc-task --help` | Aiuto sintetico. |

Opzioni di `new`/`run` (e `-a`, `-m`, `-C`, `--auto` anche per `followup`):

| Opzione | Significato |
|---|---|
| `-a, --agent NOME` | Agente opencode. Default: label `agent:NOME` del bead, altrimenti il default di opencode (`orchestratore`). |
| `-d, --desc TESTO` | Descrizione del bead (solo `new`): è il corpo del prompt all'agente. |
| `-t, --type TIPO` | `task` (default), `bug`, `feature`, `chore`, `epic` (solo `new`). |
| `-p, --prio N` | Priorità 0 (critica) … 4 (backlog), default 2 (solo `new`). |
| `-m, --model P/M` | Modello opencode alternativo, `provider/model#variant`. |
| `-C, --dir PATH` | Directory in cui lavora opencode (es. un git worktree); il bead resta nel progetto. |
| `--auto` | Auto-approva i permessi opencode non negati. Solo con consenso dell'utente. |
| `--force-team` | Agisce anche su un bead `team:oc` (run/claim/followup lo rifiutano). Solo su richiesta esplicita dell'utente. |

Variabili: `OC_TASK_MAX_COMMENT` (default 12000 caratteri salvati nel commento),
`BEADS_ACTOR` (a chi torna il bead a fine run; default `git config user.name`).

Exit code: `0` ok; `≠0` errore opencode (il bead torna `open`, motivo in `response` e nei commenti).
I costi sono in dollari, sommati su tutti gli step del run.

### Esempi tipici
```bash
# domanda in sola lettura al tester
oc-task new "Quanti test ci sono in app/Tests?" -a tester -d "Solo lettura. Riporta il numero e il comando usato."

# feature non banale: passa dall'orchestratore (rispetta la doppia approvazione)
oc-task new "Aggiungere opzione --dry-run al CLI" -t feature -a orchestratore \
  -d "Contesto: ... Criteri di accettazione: 1) ... 2) ... Verifica: swift test."

# implementazione isolata in un worktree mentre Claude lavora nel checkout principale
git worktree add ../proj-sidecar-abc -b oc/sidecar-abc
oc-task run sidecar-abc -a coder -C ../proj-sidecar-abc

# ciclo di revisione
oc-task followup sidecar-abc "Il test X fallisce con: ... correggi e rilancia i test."
oc-task status
bd comments sidecar-abc          # storico risposte
bd close sidecar-abc --reason "verificato: swift test verde"
```

### Richieste dell'utente → azione
- "fallo fare al <agente>: …" → `oc-task new "…" -a <agente> -d "…"` (descrizione autosufficiente).
- "a che punto sono?" / "cosa è aperto?" → `oc-task status` + `bd ready` (o `bv --robot-triage -f json` per priorità e blocchi); riassumi in una tabella. L'utente guarda i task con `bv` (TUI beads_viewer).
- "cosa ha risposto?" → `bd comments <id>` (ultimo commento) o il JSON del run.
- "digli che…" → `oc-task followup <id> "…"`.
- "chiudilo" → verifica prima file/test citati in `VERIFICHE`, poi `bd close <id> --reason`.
- "attiva beads qui" → `oc-task init`.
- "come si usa oc-task?" → mostra la tabella sopra e un paio di esempi.

## Regole
- Scrivi descrizioni autosufficienti: l'agente opencode non vede questa conversazione.
- Dipendenze: `bd dep add <issue> <dipende-da>`; lavoro scoperto: `--deps discovered-from:<id>`.
- Riporta sempre all'utente id del bead, agente, esito e costo.
- Le sessioni opencode sono visibili anche nella TUI dell'utente (`opencode session list`,
  titolo `<id>: <titolo>`), così può subentrare.
