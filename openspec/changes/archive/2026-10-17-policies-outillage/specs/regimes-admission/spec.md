## ADDED Requirements

### Requirement: Trois régimes, un playbook chacun

Le dépôt SHALL porter exactement trois playbooks regis sous `playbooks/`, au nom nu du régime
qu'ils servent : `rebuild.yaml`, `copy.yaml` et `product.yaml`. Chacun MUST porter sa version dans
`metadata.labels["app.kubernetes.io/version"]`, et chacun de ses tiers MUST porter un `id` parmi
`direct-placement`, `transformation-required` et `quarantine`.

#### Scenario: uske route chaque policy vers son playbook

- **GIVEN** une policy étiquetée `admission-track: copy`
- **WHEN** uske ≥ 0.10.0 prépare son screening
- **THEN** l'image est jugée avec `playbooks/copy.yaml`

#### Scenario: un playbook mal formé arrête le screening avant tout jugement

- **GIVEN** un playbook dont un tier n'a pas d'`id` reconnu
- **WHEN** uske vérifie le répertoire des playbooks
- **THEN** le screening échoue en erreur technique, et aucune image n'est jugée ni placée

#### Scenario: une policy sans playbook n'est jamais jugée

- **GIVEN** une policy étiquetée d'un régime qui n'a pas de fichier sous `playbooks/`
- **WHEN** le screening tourne
- **THEN** aucune de ses images n'est placée

### Requirement: Le régime rebuild répare ce qu'un paquet corrige

`playbooks/rebuild.yaml` SHALL mener à `transformation-required` une image dont la seule faute est
une faille critique pour laquelle un correctif existe, et SHALL taguer `curable` la règle
`cve-critical`. Un secret vérifié ou une licence de la liste noire MUST mener à `quarantine`.

#### Scenario: faille critique corrigeable

- **GIVEN** une image `rebuild` sans secret ni licence toxique, avec une faille critique corrigeable
- **WHEN** regis la juge
- **THEN** le tier retenu est `transformation-required`, et uske peut ordonner sa réparation

#### Scenario: faille critique sans correctif

- **GIVEN** une image `rebuild` avec une faille critique sans aucun correctif
- **WHEN** regis la juge
- **THEN** le tier retenu est `quarantine`

### Requirement: Le régime copy ne répare rien

`playbooks/copy.yaml` SHALL n'avoir que les tiers `direct-placement` et `quarantine`, et MUST ne
taguer aucune règle `curable`.

#### Scenario: faille critique sur une image copiée

- **GIVEN** une image `copy` avec une faille critique, corrigeable ou non
- **WHEN** regis la juge
- **THEN** le tier retenu est `quarantine`, et uske n'émet aucun ordre de réparation

### Requirement: Le régime product est plus sévère que copy

`playbooks/product.yaml` SHALL n'avoir que les tiers `direct-placement` et `quarantine`, ne taguer
aucune règle `curable`, et MUST tenir pour critiques : la faille critique, l'utilisateur `root`, la
fraîcheur, et une signature keyless vérifiée par la CI de release de regis, knock ou uske
(`provenance/signed-by`).

#### Scenario: un outil maison non signé

- **GIVEN** une image `product` sans signature, ou signée par une identité hors de la liste
- **WHEN** regis la juge
- **THEN** le tier retenu est `quarantine`, et la règle qui l'a tranchée est `signed-by`

#### Scenario: vérification impossible

- **GIVEN** une image `product` dont la signature ne peut être vérifiée (registre ou racine de
  confiance Sigstore injoignable)
- **WHEN** regis la juge
- **THEN** la décision est `inconclusive`, et l'image n'est pas placée

#### Scenario: un outil maison qui tourne en root

- **GIVEN** une image `product` dont l'utilisateur est `root`
- **WHEN** regis la juge
- **THEN** le tier retenu est `quarantine`

### Requirement: Le régime d'une image se choisit par une règle écrite

Une image SHALL être rangée en `product` si et seulement si elle est publiée par regis, knock ou
uske ; sinon en `rebuild` si elle a un gestionnaire de paquets pour lequel la configuration knock du
screening déclare un miroir ; sinon en `copy`.

#### Scenario: image distroless tierce

- **GIVEN** une image tierce sans gestionnaire de paquets
- **WHEN** sa policy est écrite
- **THEN** elle porte `admission-track: copy`

#### Scenario: image apk sans miroir déclaré

- **GIVEN** une image tierce à paquets apk Wolfi, et aucun miroir `wolfi` déclaré au screening
- **WHEN** sa policy est écrite
- **THEN** elle porte `admission-track: copy`

### Requirement: La version d'un régime ne change pas sa traçabilité

Toute modification d'un playbook SHALL monter sa version `app.kubernetes.io/version`. Le journal
MUST continuer de rattacher chaque décision au `ruleset` exact qui l'a rendue.

#### Scenario: une règle durcie

- **GIVEN** `copy.yaml` en version 1.0.0, puis durci et passé en 1.1.0
- **WHEN** le screening suivant juge une image `copy`
- **THEN** sa ligne de journal porte un `ruleset` différent de celui des décisions antérieures, et
  chaque ruleset reste lisible sur la page
