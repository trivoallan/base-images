# Proposal

## Why

Aujourd'hui, `screen.sh` recopie en Bash, sur environ 190 lignes, les étapes du `WorkflowTemplate` d'`uske` : plan, jugement, consignation, approbation, placement, seconde porte, promotion. Chaque changement de cette séquence dans `uske` doit donc être reporté ici à la main, et ce dépôt est le seul endroit où cette copie tourne en vrai. Depuis uske #53, `uske screen` joue la même séquence en une commande, avec les décisions d'`uske` lui-même. Le hook `USKE_AFTER_RECORD` garde la règle de ce dépôt : le journal est commité avant tout placement.

## What Changes

- Le workflow `screening` appelle `uske screen` à la place de `./screen.sh`. Le mode `judge` d'une PR devient `--judge-only`.
- `uske` tourne sur le runner, et non plus dans son image : il lui faut `docker` pour lancer `regis` et `knock`, et `git` pour le hook. `regis` et `knock` restent dans leurs images publiées, épinglées par digest, et sont lancés par les préfixes `USKE_REGIS_CMD` et `USKE_KNOCK_CMD`.
- `screen.sh` disparaît. Il en reste un hook, `after-record.sh`, qui recompose les rapports Markdown de la policy (`uske decisions` puis le détail `regis`), puis commite le journal, rebase sur `main` et pousse.
- Renovate suit la version d'`uske` sous sa nouvelle forme d'installation, et non plus le digest de son image.
- Le README remplace sa section « Screening » : il ne décrit plus l'enchaînement, il le délègue à `uske screen`.
- Ce qui change à la marge :
  - les commits du journal ne précisent plus la porte qui les produit, sauf si `uske` expose l'étape au hook ;
  - les nouveaux rapports prennent le nom qu'`uske` donne au run, et non plus `<run_id>-<tentative>`. Les rapports existants restent en place, cités par le journal.

## Capabilities

### New Capabilities

### Modified Capabilities

Aucune. Le screening garde son comportement : mêmes étapes, mêmes décisions, même journal, et le journal commité avant tout placement. Le change ne remplace que l'outil qui les enchaîne. Les specs sont sautées (`skip_specs: true`).

## Impact

- Fichiers supprimés : `screen.sh`.
- Fichiers ajoutés : `after-record.sh`.
- Fichiers modifiés : `.github/workflows/screening.yml`, `.github/renovate.json5`, `README.md`.
- Dépendances en amont :
  - **bloquant** : une version publiée d'`uske` qui contient `uske screen`, au moins la 0.9.1. Ce dépôt ne tourne que sur des versions publiées ;
  - livré par la 0.9.1 (uske #56) : `USKE_STEP` dans l'environnement du hook, pour garder un message de commit par porte, et un rapport nommé d'après l'epoch, jamais réécrit (`<epoch>.md`, puis `<epoch>-2.md`…).
- Risque : une erreur de montage, quand un chemin n'est pas vu à l'identique dans un conteneur, donne `inconclusive` côté `regis` et un échec côté `knock`, jamais un placement (README d'`uske`). La PR de ce change le montre en mode `--judge-only` avant tout `apply`.
