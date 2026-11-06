---
versione: 10
stato: approvato
---

# Requisiti — agente `sintetizzatore`

## Sintesi per approvazione

Stiamo decidendo se aggiungere al team un agente che, nei due momenti in cui devi approvare qualcosa, ti metta in condizione di farlo senza leggere un documento intero: prima che l'architetto progetti e prima che si scriva codice. In quei momenti scrive un documento completo e te ne mostra una spiegazione breve, in prosa. Tu approvi il documento: la spiegazione serve a decidere, non a sostituirlo. Se dici no si corregge e si ripete, e dal secondo giro vedi solo cosa è cambiato. Dopo il design non c'è altro: resta solo lo stile breve in tutti gli agenti. Restano aperti tre punti: dove tenere le regole di stile, come dichiarare la provenienza di ogni requisito, e quando l'agente deve fermarsi invece di tirare a indovinare.

## Obiettivo/problema

Gli LLM producono "wall of text"; l'umano smette di leggere e approva senza capire. Il costo sono decisioni prese male. Serve un confine testo→umano che produca un artefatto approvabile e una sintesi leggibile, così che l'umano approvi il file (non un riassunto) con cognizione di causa.

## Utenti e contesto d'uso

- **Target:** l'umano che deve decidere. A lui è destinata la sintesi per l'utente (sezione del documento, con copia letterale in chat).
- **Non target:** gli altri agenti (architetto, architetto-avversariale, coder, tester). A loro serve il file completo, non la sintesi. Un riassunto per un agente è un danno.
- L'agente opera dentro il team agentico, invocato dall'orchestratore, e parla solo all'orchestratore.

## Requisiti funzionali

- `RF-1` — Il sistema deve introdurre un unico nuovo agente, `sintetizzatore`, con due modalità di funzionamento: `requisiti` e `design`. (fonte: chat, decisione)
- `RF-2` — Il sistema deve prevedere due checkpoint formali con approvazione dell'utente: **A requisiti** (dopo la maturazione utente⇄orchestratore, prima dell'`architetto`) e **B design** (dopo il design dell'`architetto` e il verdetto dell'`architetto-avversariale`, prima del `coder`). (fonte: chat, decisione)
- `RF-3` — Il sistema deve ciclare sul checkpoint in caso di rifiuto dell'utente (non si avanza a valle finché non c'è approvazione). (fonte: chat, decisione)
- `RF-4` — Il sistema non deve produrre alcuna sintesi formale dopo il checkpoint B: nessun gate su consegna, report o log. Dopo B resta solo la policy R1–R7, valida per tutti gli agenti, sempre. (fonte: chat, decisione)
- `RF-5` — Il sistema deve far sì che il `sintetizzatore` parli solo all'orchestratore e mai direttamente all'utente. (fonte: chat, decisione)
- `RF-6` — Il sistema deve invocare il `sintetizzatore` con trigger manuale, quando orchestratore e utente sono maturi; nessuna soglia automatica di invocazione. (fonte: chat, decisione)
- `RF-7` — Il sistema deve fornire in input al `sintetizzatore` la sessione se disponibile, altrimenti le note strutturate dell'orchestratore. (fonte: chat, decisione)
- `RF-8` — Il sistema deve far scrivere il `sintetizzatore` solo in `docs/requirements/` e `docs/design/`; non tocca codice, configurazione o log. (fonte: chat, decisione)
- `RF-9` — In modalità `requisiti`, il sistema deve produrre `docs/requirements/<epic>.md` che apre con la sezione `## Sintesi per approvazione` (prima sezione dopo il titolo) e prosegue con le sezioni fisse nell'ordine: obiettivo, utenti e contesto, `RF-n`, `RNF-n` (con soglia numerica), vincoli, fuori scope, `CA-n` (uno per RF), domande aperte (con chi decide e cosa cambia), metriche di successo, cronologia modifiche. (fonte: chat, decisione)
- `RF-10` — In modalità `design`, il sistema deve aggiungere o riscrivere la sezione `## Sintesi per approvazione` in coda al file di design esistente, senza toccare il resto del file. (fonte: chat, decisione)
- `RF-11` — Il sistema deve produrre la sezione `## Sintesi per approvazione` in prosa continua che dica cosa decidiamo, cosa costruiamo, cosa resta fuori e cosa resta aperto; senza elenchi, identificatori interni o conteggi; descrivendo il documento intero, non le modifiche della versione corrente; in chat va la sua copia letterale. (fonte: chat, decisione)
- `RF-12` — Il sistema deve rispettare quattro invarianti: `chat ⊆ file`; a valle si legge solo il file; nessuna invenzione (il non tracciabile va marcato `[DA CONFERMARE]`); dal ciclo 2 in poi solo il delta. (fonte: chat, decisione)
- `RF-13` — Il sistema deve marcare ogni requisito/decisione non tracciabile con `[DA CONFERMARE]` e aggiungerlo alle domande aperte. (fonte: chat, decisione)
- `RF-14` — Il sistema deve persistere l'approvazione con `versione` e `stato: bozza|approvato|respinto`; il `sintetizzatore` non scrive mai `stato: approvato` (lo registra l'orchestratore dopo l'ok dell'utente). (fonte: chat, decisione)
- `RF-15` — Il sistema deve associare a ogni `RF-n`/`RNF-n` un campo `fonte:` che lo lega a ciò che è stato detto in conversazione. (fonte: chat, decisione)
- `RF-16` — Se il verdetto dell'`architetto-avversariale` è `RESPINGO`, il sistema non deve produrre la sintesi e deve rispondere `STATO: ERRORE`. (fonte: chat, decisione)
- `RF-17` — Il sistema deve rispondere all'orchestratore con un contratto di output deterministico con i campi `STATO`, `MODALITA`, `FILE`, `VERSIONE`, `SINTESI`, `DELTA`. `[DA CONFERMARE]` (fonte: assente in conversazione — presente solo nel prompt dell'agente)
- `RF-18` — Se un file esiste già, il sistema deve incrementare `versione` e registrare la modifica in `## Cronologia modifiche`. (fonte: chat, deducibile da "versione" persistita + sezione "cronologia modifiche")

## Requisiti non funzionali

- `RNF-1` — Lunghezza della sezione `## Sintesi per approvazione`: 100-150 parole. (fonte: chat, decisione)
- `RNF-2` — Costo atteso: 2 invocazioni per epic. (fonte: chat, decisione)
- `RNF-3` — Determinismo: temperatura 0.0 sul modello dell'agente. (fonte: chat, decisione)

## Vincoli

- Modello dell'agente: `deepseek/deepseek-v4-pro` (temperatura 0.0). (fonte: chat, decisione)
- Piattaforma: opencode non supporta la path-restriction per agente; il vincolo "scrivi solo in `docs/`" è applicato via prompt, non dal layer dei permessi. (fonte: chat, vincolo di piattaforma)
- Il `sintetizzatore` comunica solo con l'orchestratore (mai con l'utente). (fonte: chat, decisione)

## Fuori scope (esplicito)

- Un layer o agente separato `analista` per i requisiti: discusso e non adottato, resta una sola figura (`sintetizzatore`). (fonte: chat, discusso e non adottato)
- Soglia automatica di invocazione: sostituita dal trigger manuale. (fonte: chat, discusso e non adottato)
- Gate sulla consegna finale e sui report del tester: esclusi. (fonte: chat, discusso e non adottato)
- Riscrittura automatica dei design da parte del `sintetizzatore`: esclusa; l'agente segnala, l'autore corregge. (fonte: chat, discusso e non adottato)
- Qualsiasi sintesi formale dopo il checkpoint B (nessun gate su consegna/report/log). (fonte: chat, decisione)

## Criteri di accettazione

- `CA-1` — Esiste un unico agente `sintetizzatore` che accetta esattamente due modalità (`requisiti`, `design`); nessun agente `analista` o layer separato è introdotto.
- `CA-2` — Ogni epic passa per i checkpoint A e B nell'ordine definito: A precede l'`architetto`; B precede il `coder` e richiede il verdetto dell'`architetto-avversariale`.
- `CA-3` — In caso di rifiuto al checkpoint, il flusso riparte dal checkpoint stesso (nessun avanzamento a valle).
- `CA-4` — Dopo il checkpoint B non è prodotta alcuna sintesi/approvazione formale su consegna, report o log (0 gate post-B).
- `CA-5` — Ogni comunicazione del `sintetizzatore` è diretta esclusivamente all'orchestratore (0 messaggi diretti all'utente).
- `CA-6` — Il `sintetizzatore` si attiva solo su invocazione esplicita dell'orchestratore (0 attivazioni automatiche).
- `CA-7` — A ogni invocazione l'agente riceve la sessione o, in assenza, le note strutturate dell'orchestratore (mai input vuoto non segnalato).
- `CA-8` — L'agente scrive esclusivamente in `docs/requirements/` e `docs/design/` (0 scritture su codice/config/log).
- `CA-9` — In modalità `requisiti` è prodotto `docs/requirements/<epic>.md` che apre con `## Sintesi per approvazione` (prima sezione dopo il titolo) e contiene tutte le sezioni fisse elencate, nell'ordine previsto.
- `CA-10` — In modalità `design`, il file esistente è modificato solo aggiungendo o riscrivendo `## Sintesi per approvazione` in coda; il resto del contenuto preesistente resta invariato.
- `CA-11` — La sezione `## Sintesi per approvazione` è in prosa continua e dice cosa decidiamo, cosa costruiamo, cosa resta fuori e cosa resta aperto; senza elenchi, identificatori interni o conteggi; descrive il documento intero (non le modifiche della versione corrente); in chat ne è presente la copia letterale (0 elenchi, 0 identificatori interni citati, 0 conteggi, sempre presenti i quattro contenuti).
- `CA-12` — Per ogni sintesi valgono i quattro invarianti: nessun contenuto in chat assente dal file; a valle si legge solo il file; dal ciclo 2 solo il delta.
- `CA-13` — Ogni requisito non tracciabile è marcato `[DA CONFERMARE]` e compare nelle domande aperte (0 requisiti inventati non marcati).
- `CA-14` — Il frontmatter contiene `versione` e `stato`; `stato: approvato` è impostato solo dall'orchestratore, mai dall'agente.
- `CA-15` — Ogni `RF-n`/`RNF-n` ha un campo `fonte:` valorizzato (0 requisiti senza fonte).
- `CA-16` — Con verdetto `RESPINGO`, l'agente risponde `STATO: ERRORE` e non produce sintesi.
- `CA-17` — La risposta dell'agente contiene esattamente i campi del contratto (`STATO`, `MODALITA`, `FILE`, `VERSIONE`, `SINTESI`, `DELTA`). `[DA CONFERMARE]`
- `CA-18` — Se il file esiste già, `versione` è incrementata e la modifica è tracciata in `## Cronologia modifiche` (0 sovrascritture silenziose).

## Domande aperte/assunzioni

- `Q-1` — Contenuto della policy `R1–R7` citata in RF-4 come vincolo persistente per tutti gli agenti: non definita in questo contesto. `[DA CONFERMARE]` — chi decide: orchestratore (con l'utente); cosa cambia: il testo di RF-4 da riferimento generico a riferimento puntuale alla policy.
- `Q-2` — Tassonomia dei valori ammessi per `fonte:`: il formato è esemplificato ma l'elenco dei tipi/qualificatori ammessi non è formalizzato. `[DA CONFERMARE]` — chi decide: orchestratore; cosa cambia: il campo `fonte:` di tutti gli RF/RNF (da esempio libero a valori ammessi).
- `Q-5` — Casi di errore oltre `RESPINGO`: il contesto fissa solo `RESPINGO` → `STATO: ERRORE`; requisiti contraddittori, task fast-track e contenuto insufficiente non sono menzionati. `[DA CONFERMARE]` — chi decide: orchestratore; cosa cambia: estensione o esclusione dei casi di errore in RF-16.
- `Q-6` — Casi limite operativi (conversazione troppo lunga → note strutturate; `docs/` assente → creazione): non presenti nel contesto. `[DA CONFERMARE]` — chi decide: orchestratore; cosa cambia: aggiunta di un RF o esclusione.
- `Q-7` — Contratto di output dell'agente verso l'orchestratore: i campi `STATO`, `MODALITA`, `FILE`, `VERSIONE`, `SINTESI`, `DELTA` (e `METRICHE`) sono presenti nel prompt dell'agente ma non in conversazione. `[DA CONFERMARE]` — chi decide: orchestratore; cosa cambia: RF-17 e CA-17 (conferma con fonte corretta o rimozione).

## Metriche di successo

- 0 requisiti inventati/non tracciabili non marcati.
- 100% degli `RF-n`/`RNF-n` con campo `fonte:` valorizzato.
- Lunghezza della sezione `## Sintesi per approvazione` entro budget: 100-150 parole.
- Sintesi in prosa continua: 0 elenchi, 0 identificatori interni citati e 0 conteggi nella sintesi.
- Sintesi dichiara sempre cosa decidiamo, cosa costruiamo, cosa resta fuori e cosa resta aperto (0 sintesi senza i quattro contenuti).
- La sintesi descrive il documento intero, non le modifiche della versione corrente (0 sintesi limitate al solo delta).
- La sintesi in chat è copia letterale della sezione di sintesi del documento (0 discrepanze chat↔sezione).
- Il file requisiti apre con `## Sintesi per approvazione` come prima sezione dopo il titolo (0 file senza la sezione in testa).
- 0 violazioni dei quattro invarianti.
- Costo atteso rispettato: 2 invocazioni per epic.

## Cronologia modifiche

- `v1` — bozza iniziale dei requisiti (formalizzazione della conversazione utente⇄orchestratore).
- `v2` — aggiunti RF-19..RF-22 (formato fisso della sintesi in chat, contenuto della sezione `## Sintesi per approvazione`, casi di errore oltre `RESPINGO`, casi limite operativi) e relativi CA-19..CA-22; risolta Q-2 (formato della sintesi); raffinata Q-3 (esempio di `fonte:`).
- `v3` — riallineamento alla traccia della conversazione: limite sintesi unico ≤ 250 parole (rimosso il ≤ 200 requisiti non tracciabile); sintesi in linguaggio naturale senza conteggio dei requisiti (rimosso il formato "N funzionali, M non funzionali" contraddittorio); contratto di output senza campo `METRICHE` (non previsto dal contesto); rimossi RF-19..RF-22 non tracciabili e spostati i relativi contenuti nelle domande aperte Q-3..Q-6 come `[DA CONFERMARE]`; formato domande aperte allineato a "chi decide e cosa cambia" (non "entro quando"); CA riportate a 18 (una per RF).
- `v4` — ri-verifica della traccia contro la conversazione (stessa fonte della v3): riesaminati tutti i `fonte:` di RF-1..RF-18, RNF-1..RNF-3, CA-1..CA-18, vincoli e fuori scope. Confermata la tracciabilità integrale: ogni voce è riconducibile al contesto o deducibile in modo univoco (RF-18 resta marcata `deducibile`). Nessun requisito non tracciabile residuo da marcare o rimuovere; nessuna variazione di contenuto.
- `v5` — ri-verifica della traccia contro la nuova conversazione (nuova "unica fonte ammessa"). Aggiunto a RF-11 e CA-11 il vincolo "non citare identificatori interni" (nuovo elemento in conversazione). Marcati `[DA CONFERMARE]` RF-17/CA-17 (contratto di output: campi assenti in conversazione, presenti solo nel prompt dell'agente) e RNF-1 (soglia ≤ 250 parole assente in conversazione), con nuove domande Q-7 e Q-8. Metrica della lunghezza riportata a soglia da confermare; Q-4 aggiornata per includere "nessun identificatore interno".
- `v6` — ri-verifica della traccia contro il CONTESTO (unica fonte ammessa). Allineati RF-11, CA-11, la metrica della sintesi e Q-4 al termine esatto della conversazione: "prosa continua" sostituisce "linguaggio naturale (senza contarli)" (qualificatore non presente in conversazione, derivato dal prompt dell'agente). Confermata la tracciabilità di tutti gli altri `fonte:`; restano `[DA CONFERMARE]` RF-17/CA-17 (contratto di output) e RNF-1 (soglia ≤ 250 parole), come da v5. Nessun'altra variazione di contenuto.
- `v7` — ri-verifica della traccia contro il CONTESTO (unica fonte ammessa). Risolta Q-8: la conversazione fissa la lunghezza della sintesi in chat a "100-150 parole". RNF-1 aggiornato da "≤ 250 parole `[DA CONFERMARE]`" a "100-150 parole (fonte: chat, decisione)"; aggiornata la relativa metrica. Rimossa Q-8 dalle domande aperte. Nessun'altra variazione di contenuto; restano `[DA CONFERMARE]` RF-17/CA-17 (contratto di output).
- `v8` — ri-verifica della traccia contro il CONTESTO (unica fonte ammessa). Aggiunto il vincolo "dire cosa resta aperto" alla sintesi in chat: aggiornati RF-11, CA-11, la relativa metrica e l'enumerazione dei vincoli fissi in Q-4. Nessun altro requisito non tracciabile residuo; restano `[DA CONFERMARE]` RF-17/CA-17 (contratto di output).
- `v9` — ri-verifica della traccia contro il CONTESTO (unica fonte ammessa). Aggiornata la definizione della sintesi per l'utente: è una sezione del documento, in prosa continua, senza identificatori interni né conteggi, che dice cosa resta aperto, e in chat ne va la copia letterale; aggiornati RF-11, CA-11, RNF-1, la sezione "Utenti e contesto d'uso" e le relative metriche (aggiunti "0 conteggi" e "copia letterale"). Riformulata Q-4: il vincolo "prosa continua" risolve la questione delle righe fisse; resta aperta la collocazione della sezione di sintesi nel file requisiti (assente tra le sezioni fisse di RF-9). Restano `[DA CONFERMARE]` RF-17/CA-17 (contratto di output).
- `v10` — ri-verifica della traccia contro il CONTESTO (unica fonte ammessa). Risolte Q-3 e Q-4: il CONTESTO fissa la collocazione della sezione `## Sintesi per approvazione` nel file requisiti (prima sezione dopo il titolo) e il suo contenuto (cosa decidiamo, cosa costruiamo, cosa resta fuori, cosa resta aperto; niente elenchi, identificatori interni o conteggi; descrive il documento intero, non le modifiche della versione corrente). Aggiornati RF-9, RF-10 (aggiunge *o riscrive* la sezione in coda, senza toccare il resto), RF-11, CA-9, CA-10, CA-11, RNF-1 e le metriche. Rimosse Q-3 e Q-4 dalle domande aperte. Restano `[DA CONFERMARE]` RF-17/CA-17 (contratto di output).

- v10 — aggiunta la sezione «Sintesi per approvazione» dall'orchestratore (l'agente non la produceva).
