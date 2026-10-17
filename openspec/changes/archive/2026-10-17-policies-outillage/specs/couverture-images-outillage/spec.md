## ADDED Requirements

### Requirement: Chaque image tirée par l'outillage a sa policy

Toute image qu'un Dockerfile, un manifeste de déploiement ou un overlay kind de regis, knock ou uske
tire — en `FROM`, en `COPY --from` ou en `image:` — SHALL avoir sa policy knock sous `policies/`,
étiquetée d'un régime qui a son playbook. Les images de démo kind en font partie.

#### Scenario: une image copiée par COPY --from

- **GIVEN** le Dockerfile de knock copie `/syft` depuis `anchore/syft`
- **WHEN** on cherche la policy de `anchore/syft`
- **THEN** elle existe, et porte `admission-track: copy`

#### Scenario: un compagnon d'exécution

- **GIVEN** le composant `scan-pipeline` de knock déploie `redis`
- **WHEN** on cherche la policy de `redis`
- **THEN** elle existe, et porte `admission-track: rebuild`

#### Scenario: les outils eux-mêmes

- **WHEN** on cherche les policies de `ghcr.io/trivoallan/regis`, `knock` et `uske`
- **THEN** chacune existe, et porte `admission-track: product`

### Requirement: Une policy sert une seule mineure, sauf product qui sert sa majeure

Chaque policy SHALL sélectionner les patchs d'une seule mineure de sa source (D-01), sauf une policy
du régime `product`, qui SHALL sélectionner toutes les versions de sa majeure et servir la plus
haute mineure sous son alias. Chaque policy MUST exiger
`linux/amd64` et `linux/arm64`. Quand deux outils tirent deux mineures d'une même image, c'est
l'outil en retard qui s'aligne, dans son dépôt ; la policy n'en sert pas deux.

#### Scenario: divergence entre outils

- **GIVEN** regis tire `python:3.14-alpine` et uske `python:3.13-alpine`
- **WHEN** la policy python est écrite
- **THEN** elle ne sert que 3.14, et l'alignement d'uske est une tâche hors de ce dépôt

#### Scenario: un outil maison sort une mineure

- **GIVEN** la policy `product` de knock sert la majeure 0, et knock publie 0.17.0
- **WHEN** le screening suivant tourne
- **THEN** 0.17.0 est jugée sans que la policy soit modifiée

#### Scenario: tag source incomplet

- **GIVEN** un tag source publié pour `linux/amd64` seulement
- **WHEN** knock établit le plan
- **THEN** ce tag est refusé au plan, et rien n'est placé

### Requirement: Une policy place sans jamais effacer

Chaque policy SHALL déclarer `deletionMode: mark` et une destination sous
`ghcr.io/<propriétaire>/`, que le workflow déclare dans `KNOCK_REGISTRIES` et jamais la policy.

#### Scenario: un tag sort de la sélection

- **GIVEN** un tag placé que la sélection de sa policy n'inclut plus
- **WHEN** le screening applique le plan
- **THEN** le tag reste tirable, marqué `pending-deletion`

### Requirement: Ce qui échappe aux policies est nommé

Le README SHALL nommer chaque artefact que l'outillage tire sans passer par une image OCI — les
binaires que le Dockerfile de regis télécharge en release GitHub — comme hors de portée d'une
policy, et toute image du périmètre encore sans policy avec la raison de son absence.

#### Scenario: un binaire téléchargé

- **WHEN** on lit le README
- **THEN** grype, syft, trufflehog, hadolint, dockle et regctl y figurent comme téléchargés par regis
  hors de la porte

### Requirement: Le journal repart de zéro

Les policies `base-python-3`, `base-alpine-3` et `base-redis-7`, leurs journaux et leurs rapports
SHALL être retirés du dépôt dans le même change que l'arrivée des nouvelles policies, et la page
publique MUST ne montrer que les décisions rendues sous les nouveaux régimes.

#### Scenario: premier screening après le change

- **GIVEN** le change fusionné
- **WHEN** le premier screening `apply` tourne et que la page est publiée
- **THEN** la page ne liste que des policies de régime `rebuild`, `copy` ou `product`, et aucune
  ligne antérieure au change
