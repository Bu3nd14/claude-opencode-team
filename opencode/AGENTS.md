# Regole generali del team agentico

## Doppia approvazione architetturale

Un cambiamento **NON "fast track"** richiede l'accordo di **entrambi** gli architetti:

- `architetto` — propone e valida il design.
- `architetto-avversariale` — red team; mette in dubbio le decisioni e deve emettere un verdetto `APPROVO`.

Sono **"fast track"** (esenti da doppia approvazione) SOLO i cambiamenti banali e locali che non
alterano comportamento, architettura, contratti pubblici, schemi dati o confini tra moduli:
refusi, commenti, formattazione, documentazione, rinomine senza effetto sul comportamento, valori
di configurazione non strutturali. **Nel dubbio, un cambiamento NON è "fast track".**

La decisione di trattare un cambiamento come fast-track spetta **esclusivamente all'utente**
(vedi la sezione "Fast track"): nessun agente può attribuirsi questa classificazione.

Flusso obbligatorio:

1. Per un cambiamento non fast-track, l'`architetto` produce il design.
2. L'`architetto-avversariale` lo sottopone a review e risponde `APPROVO` o `RESPINGO`.
3. Il `coder` può implementare solo dopo che **entrambi** hanno dato l'accordo.
4. Se `architetto-avversariale` risponde `RESPINGO`, l'`architetto` risolve ogni obiezione
   bloccante o, se non è d'accordo, motiva il rigetto; in caso di disaccordo persistente
   l'`orchestratore` **blocca il task e lo escala all'utente**. Nessuna implementazione finché il
   disaccordo non è risolto.

L'`orchestratore` è responsabile di far rispettare questa regola e di non passare il task al
`coder` prima della doppia approvazione.

## Fast track

La classificazione **"fast track" è decisa esclusivamente dall'utente**. Nessun agente
(`orchestratore`, `architetto` o altri) può dichiarare un cambiamento fast-track di propria
iniziativa: può solo *proporre* all'utente di trattarlo come tale, motivando perché rientra nei
casi ammessi, e attendere la sua conferma esplicita.

Finché l'utente non ha dichiarato esplicitamente un cambiamento fast-track, quel cambiamento è
trattato come **non fast-track** e richiede la doppia approvazione architetturale.

Un cambiamento dichiarato fast-track dall'utente può procedere direttamente con
`coder`/`tester` senza il giro di approvazione. In assenza di risposta, l'`orchestratore` non
assume il fast-track: applica il flusso ordinario oppure attende.

## Leggibilità dell'output e checkpoint di sintesi

L'umano che legge ha un budget di attenzione diverso da un LLM: legge una volta, non rilegge e paga
ogni riga in tempo. Queste regole valgono per **ogni agente**, sempre, qualunque sia il task.

**Policy R1–R7.**

- **R1 — Prima riga = la risposta (BLUF).** Nessun preambolo: la prima frase dice cosa è successo,
  cosa serve o cosa si decide.
- **R2 — Budget.** ≤150 parole per una risposta conversazionale, ≤800 per un deliverable; oltre
  serve un motivo dichiarato.
- **R3 — Vietati:** ripetere la domanda, "Certo!", "Ottima domanda", "è importante notare che",
  riassunto finale che ricopia.
- **R4 — Max 4 blocchi per risposta**; una idea per paragrafo; liste per le enumerazioni; tabelle
  solo per confronti multi-attributo.
- **R5 — Ogni frase aggiunge informazione.** Nessun aggettivo di riempimento.
- **R6 — Il dettaglio va in un file o in appendice**, non nel corpo.
- **R7 — Non toccare mai numeri, identificatori, nomi di file e decisioni** per abbreviare.

Le regole non si applicano a codice, JSON, log e artefatti macchina-macchina.

**I due checkpoint.**

- **A — requisiti.** L'`orchestratore` invoca l'`analista` quando orchestratore e utente sono
  maturi, prima che parta l'`architetto`. L'`analista` scrive `docs/requirements/<epic>.md`;
  l'utente approva il file o si cicla. Senza approvazione l'`architetto` non parte.
- **B — design.** Dopo il design dell'`architetto` e il verdetto dell'`architetto-avversariale`,
  l'utente approva `docs/design/<id>-*.md` o si cicla. Senza approvazione il `coder` non parte.

**Chi scrive la sintesi.** La sintesi è una sezione del documento, non un testo a parte: la scrive
chi scrive il documento — l'`analista` per i requisiti, l'`architetto` per il design — e la
mette nel file **prima** che venga mostrata. L'`orchestratore` la copia letteralmente in chat: non la
riformula e non aggiunge nulla. Se l'autore non l'ha prodotta, la scrive l'`orchestratore` e lo
annota nella cronologia del file. Quello che l'utente legge è quindi quello che approva, e si
verifica confrontando i due testi.

**Forma della sintesi** (entrambi i checkpoint): 100-150 parole di prosa continua, niente elenchi,
grassetti, conteggi o identificatori interni (`RF-n`, `CA-n`, `R1–R7`, `Q-n`). Dice cosa decidiamo,
cosa costruiamo, cosa resta fuori, cosa resta aperto, e descrive il documento intero, non le
modifiche di questa versione.

**Chi fa cosa.** L'`orchestratore` raccoglie e presenta: è l'unica voce verso l'utente. L'`analista`
formalizza i requisiti e ne scrive la sintesi; l'`architetto` scrive il design e la
sua sintesi; l'`orchestratore` presenta copiando. `architetto`, `coder` e `tester` leggono **solo i
file approvati**, mai la chat. Dopo l'ok dell'utente ai checkpoint l'`orchestratore` registra
l'approvazione nel file (`stato: approvato`) e solo allora delega a valle; un file con
`stato: bozza` non si legge come input.

**Invarianti.** `chat ⊆ file`: la sintesi non contiene nulla che il file non abbia. Nessuna
invenzione: ciò che non è tracciabile alla conversazione è marcato `[DA CONFERMARE]`. Dal ciclo 2 in
poi si mostra solo il delta.

**Chiusura.** Dopo il checkpoint B non esistono altre sintesi formali: vale solo la policy R1–R7.

## Percorsi di lavoro consentiti (obbligatorio per tutti gli agenti)

Ogni agente deve usare **esclusivamente** questi percorsi per file, comandi, scratch e artefatti:

- **Cartella di progetto**: la working directory in cui opencode è stato avviato (la root del progetto corrente).
- **Area temporanea**: `/tmp` (su macOS `/private/tmp`).

Regole:
1. Ogni file temporaneo, di scratch, di test o intermedio va creato **in `/tmp`** (es. `/tmp/<nome-descrittivo>-<id>`) oppure **dentro la cartella di progetto**. Preferisci `/tmp` per gli effimeri.
2. È **vietato** leggere o scrivere fuori da questi due percorsi (es. `~`, `/var`, `/Users/roberto/...` diversi dal progetto, `/etc`, `/opt`). L'unico percorso esterno autorizzato dai permessi è `/tmp`.
3. Non usare la home (`~`) come area di lavoro: niente file di appoggio in `~/`, nemmeno per debug.
4. Pulisci i temporanei in `/tmp` a fine task; non lasciare residui.
5. Se un task richiede davvero un percorso esterno diverso, **fermati e chiedi all'utente** prima di procedere.
6. Vale anche per gli script generati (script di test, smoke test, log di debug): scrivono in `/tmp` o nel progetto, mai altrove.

## Task tracciati con beads (`bd`)

Se il progetto ha una cartella `.beads/` (verifica con `bd where`), il lavoro è tracciato con beads.

- Un messaggio che inizia con `[beads <id>]` è un task delegato: leggi i dettagli con `bd show <id>`.
- Lavoro extra scoperto durante il task: **non** allargare il task, crea un nuovo bead con
  `bd create "titolo" -d "descrizione" --deps discovered-from:<id>`.
- Note intermedie utili a chi verifica: `bd comment <id> "..."`.
- **Firma sempre** i comandi `bd` che scrivono (create, comment, update, close, dep) con
  `--actor opencode:<tuo-nome-agente>` (es. `--actor opencode:orchestratore`), così in beads si distingue
  il lavoro degli agenti da quello dell'utente.
- **Non chiudere** il bead delegato (`bd close`): lo chiude chi ha delegato dopo la verifica.
- Chiudi sempre la risposta finale con:
  `ESITO: FATTO | PARZIALE | BLOCCATO`, `FILE: ...`, `VERIFICHE: ...`.
- L'`orchestratore`, quando scompone un task in sotto-task, crea un bead figlio per ciascuno
  (`bd create ... --parent <id>`) prima di delegarlo, così l'avanzamento resta visibile.

## Team misto con Claude Code (approvazione incrociata)

**Chi sei.** Tu e i tuoi sottoagenti (`orchestratore`, `architetto`, `architetto-avversariale`, `coder`,
`tester`) siete **sempre opencode**, anche quando lavorate a un bead. Un lavoro è "di Claude" solo se nei
bead l'assegnatario o l'autore è letteralmente `claude:<nome>`. Non attribuire mai a Claude un design o
una review fatti da un agente opencode e non usare le etichette `claude:*` per te stesso.

**Strumenti di Claude Code, non tuoi:** `oc-task` e i file in `~/.claude/` (skill, agenti) servono a
Claude Code per delegare a te. Non usarli: i tuoi sottoagenti li invochi con il tuo strumento di
delega (task/subagent), mai con `oc-task` o `opencode run`.

**Modalità esplicita con label `team:*` (ha la precedenza sugli indizi sotto).** Guarda le label del bead e
del suo epic padre (`bd show <id>`):
- `team:oc` → lavora **solo opencode**: doppia approvazione interna, nessun coinvolgimento di Claude, anche
  se trovi tracce `claude:*`. Quando crei un epic in autonomia, mettigli `team:oc` (e ai figli:
  `bd label propagate <epic> team:oc`).
- `team:misto` → team misto: valgono le regole incrociate di questa sezione.
- nessuna label `team:*` → usa le condizioni qui sotto.

**opencode deve poter lavorare anche da solo.** Questa sezione vale SOLO per il lavoro di un team misto,
cioè quando almeno una di queste condizioni è vera:
- il messaggio che ricevi inizia con `[beads <id>]` (task delegato da Claude Code tramite `oc-task`);
- il bead su cui lavori, o il suo design, ha assegnatari o autori `claude:*`
  (`claude:architetto`, `claude:architetto-avversariale`, `claude:reviewer`).

**In tutti gli altri casi** (sessione avviata dall'utente in opencode, nessun `claude:*` coinvolto) vale
la regola standard della sezione "Doppia approvazione architetturale": `architetto` +
`architetto-avversariale` di opencode. Non attendere, non richiedere e non simulare agenti Claude: non
puoi invocarli e la loro assenza non è un motivo per bloccarti.

Nel team misto la review avversariale è **incrociata**:
- design di `claude:architetto` → review dell'`architetto-avversariale` **di opencode**;
- design dell'`architetto` di opencode **dentro un task delegato da Claude Code** → la review di
  `claude:architetto-avversariale` la organizza Claude Code: consegna il design e fermati
  (`ESITO: FATTO`), senza passare al `coder` e senza aspettare.

L'approvazione vale solo se registrata come commento sul bead con verdetto esplicito (`APPROVO` /
`VERDETTO: APPROVO`). Il `coder` non implementa un design non approvato, da qualunque lato provenga.
I design di Claude stanno in `docs/design/<bead-id>-*.md`: leggili da lì.
Quando fai review avversariale di un design di Claude, verifica le sue affermazioni sul codice reale.
