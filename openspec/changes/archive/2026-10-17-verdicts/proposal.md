# Proposition — rendre les verdicts des SDR hérités de surdesrails

## Why

La pose de la méthode a déposé treize SDR en `status: proposed`. Tant qu'ils ne sont pas tranchés, un agent qui les lit doit deviner, et la méthode les repropose à chaque change. La découverte est écrite (change `onboarding`) : on sait maintenant pour qui ce dépôt existe, et l'on peut statuer.

## What Changes

- Les treize SDR `proposed` de `docs/adr/` reçoivent leur verdict, selon les cinq gestes de leur bloc de prescription : valeurs sous `traits:` (ou bloc retiré si `rejected`), `status`, `date`, `authors`, quelques lignes sous *Consequences*, et le mode d'emploi remplacé par le motif et la provenance de chaque valeur.
- `SDR-0001`, déjà `accepted`, n'est pas touché.

| ADR | Thème | Décisions | Statut |
| --- | --- | --- | --- |
| [SDR-0000](../../../docs/adr/SDR-0000-socle-de-service.md) | Socle de service | pas d'identifiant ARESIS, dépôt personnel et public | rejected |
| [SDR-0002](../../../docs/adr/SDR-0002-localization.md) | Langue | `default: français`, `code: anglais` | accepted |
| [SDR-0003](../../../docs/adr/SDR-0003-architecture.md) | Architecture | pas d'application, seulement de la colle | rejected |
| [SDR-0004](../../../docs/adr/SDR-0004-languages.md) | Langage | pas de langage applicatif | rejected |
| [SDR-0005](../../../docs/adr/SDR-0005-validation.md) | Validation | `boundary: aucune`, `data_files: json-schema` | accepted |
| [SDR-0006](../../../docs/adr/SDR-0006-commits.md) | Commits | `tool: aucun`, `scopes: []` | accepted |
| [SDR-0007](../../../docs/adr/SDR-0007-tests.md) | Tests | pas de code à couvrir ; le screening `judge` en tient lieu | rejected |
| [SDR-0008](../../../docs/adr/SDR-0008-documentation.md) | Documentation | `tool: aucun`, `root: .`, `audience: public` | accepted |
| [SDR-0009](../../../docs/adr/SDR-0009-branching.md) | Branches | `github-flow`, `squash`, `[feat, fix, docs, chore]` | accepted |
| [SDR-0010](../../../docs/adr/SDR-0010-forge-and-ci.md) | Forge et CI | `vendor: github`, `gate: informative` | accepted |
| [SDR-0011](../../../docs/adr/SDR-0011-delivery.md) | Livraison | rien ne se déploie ; Pages et GHCR par les workflows | rejected |
| [SDR-0013](../../../docs/adr/SDR-0013-frontend.md) | Front | HTML/JS natif, sans framework | rejected |
| [SDR-0014](../../../docs/adr/SDR-0014-work-tracking.md) | Jira | pas de projet Jira | rejected |

Provenance : `SDR-0002`, `SDR-0009`, `SDR-0010` et `SDR-0013` sont **constatés** (valeurs fixées par `README.md`, `openspec/config.yaml`, `git log`, `.github/settings.json`, l'origine git et `index.html`), confirmés en un bloc ; les neuf autres sont **répondus** un par un. Chaque ADR dit la provenance de chacune de ses valeurs.

## Alternatives écartées

- **Ne rien faire** : les SDR resteraient `proposed`, `mdschema` les refuserait, et la méthode les reproposerait à chaque change.
- **Refuser la proposition des verdicts** : écartée, la découverte est faite et les réponses se lisent pour la plupart dans le dépôt.
- **Accepter les SDR inapplicables avec des valeurs forcées** (`SDR-0011` en `paas` pour GitHub Pages, `SDR-0007` à une cible `0`, `SDR-0003` en `monolithic`) : écartée, une valeur qui ne décrit pas le dépôt ferait agir un agent sur une fausse prémisse ; `rejected` dit ce qui en tient lieu.
- **`commits.tool: commitlint`**, la proposition de la méthode : écartée, ce dépôt n'engendre aucune version depuis ses messages.
- **`forge.gate: bloquante`**, la proposition de la méthode : écartée de ce change, le ruleset `main` n'exige aucun contrôle et le verdict décrit l'état réel ; rendre le screening bloquant est un autre change.

## Conception

Conception : aucune condition, pas de `design.md`.

## Revue

Revue : aucune, pas de `review.md`.

## Cadrage

- Cadrage, passe 1 sur 5 : proposition des verdicts acceptée ; tas constaté accepté en bloc (`SDR-0002`, `SDR-0009`, `SDR-0010`, `SDR-0013`) ; `SDR-0004` rejeté ; `SDR-0006` en `aucun`, `[]` (2026-10-17).
- Cadrage, passe 2 sur 5 : `SDR-0000`, `SDR-0003` et `SDR-0007` rejetés ; `SDR-0005` en `json-schema`, sans frontière (2026-10-17).
- Cadrage, passe 3 sur 5 : `SDR-0008` en `aucun`, `.`, `public` ; `SDR-0011` et `SDR-0014` rejetés (2026-10-17).

Objectif qualité : aucun déclaré (arc42 absent ou sans objectifs qualité)

## Questions ouvertes

- Le bot du screening commite en type `journal(<policy>)`, hors des onze types que `SDR-0006` impose. Passer à `chore(journal)` dans `screen.sh` (ou dans `after-record.sh` du change `uske-screen`) ?
- `SDR-0003` rejeté ne vaut pas `architecture.document: aucun` : la méthode proposera le document d'architecture au change suivant.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

Aucune. Le change tranche des décisions de méthode, sans comportement du dépôt qui change ; les specs sont sautées (`skip_specs: true`).

## Impact

- Fichiers modifiés : les treize `docs/adr/SDR-*.md` en `proposed`.
- Vérifié par `( cd docs/adr && npx @jackchuka/mdschema@0.15.1 check '*.md' )` : aucune violation.
