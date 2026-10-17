# Proposition — poser la méthode surdesrails sur base-images, avec sa découverte

## Why

Les évolutions de base-images passent déjà par OpenSpec (`page-journal-base-images`, `uske-screen`), mais sans méthode commune ni découverte écrite du produit : personne n'a dit pour qui ce dépôt existe, ni ce qu'il ne sert pas. Ce change pose la méthode et écrit cette découverte avant le prochain change.

## What Changes

- La méthode surdesrails est une dépendance de développement (`package.json`, `package-lock.json`) ; son schéma est lié sous `openspec/schemas/surdesrails`, ses 27 skills sont déclarées dans `package.json`, et ses SDR hérités sont déposés sous `docs/adr/`, tous en `status: proposed` sauf `SDR-0000`.
- `openspec/config.yaml` garde `schema: spec-driven` : les changes en cours restent dans leur schéma, et ce change déclare `surdesrails`.
- La découverte est conduite, et ses pages vivent dans le dépôt privé `oci-pm`, pas dans ce dépôt public : `.nanopm` est un lien vers `oci-pm/base-images`, ignoré par `.gitignore`, et `oci-pm/link.sh` pose ce lien comme pour `regis`, `knock` et `uske`. **Écart à la méthode**, qui veut ces pages dans la merge request : la règle du workspace interdit les données nanopm dans les dépôts publics.
- `node_modules/` est ignoré.

## Alternatives écartées

- **Ne rien faire** : les changes suivants n'auraient ni découverte ni méthode commune, et chaque cadrage referait la question de l'usager.
- **Pages de découverte commitées ici** (ce que prescrit la méthode) : écartée, base-images est public, et la règle du workspace place tout `.nanopm` dans `oci-pm`.
- **Découverte par entretien** : écartée au profit de `/nanopm:pm-product` et `/nanopm:pm-personas`, qui lisent le code et ne posent que des questions de validation.
- **Rendre les verdicts des SDR dans ce change** : la détection s'arrête à la première proposition conduite, ici la découverte ; les verdicts se proposent au change suivant.
- **Ajouter une garde CI contre un `.nanopm` suivi**, comme dans `regis`, `knock` et `uske` : écartée de ce change, le `.gitignore` suffit pour l'instant.
- **Basculer `openspec/config.yaml` sur `surdesrails`** : écartée, `spec-driven` est un schéma intégré à OpenSpec et résout bien, contrairement à ce qu'annonce la commande de pose ; basculer changerait le schéma par défaut des changes en cours.

## Conception

Conception : due — dépendance externe nouvelle. La méthode est installée en `file:../../surdesrails`, qui ne s'installe que sur ce poste ; `design.md` pèse cette forme contre l'URL GitLab interne et contre l'absence de dépendance npm.

## Revue

Revue : aucune, pas de `review.md`.

## Découverte

Version de nanopm trouvée : 0.26.0 (`~/.claude/plugins/cache/nanopm/nanopm/0.26.0/VERSION`). Synchro cloud vérifiée absente le 2026-10-17 : ni `NANOPM_SUPABASE_URL` ni `NANOPM_SUPABASE_KEY` dans l'environnement ni dans `~/.nanopm/.env` ; un `.env` de projet ou une variable posée plus tard échappent à cette vérification.

- Découverte, passe 1 sur 5 : forme et lieu — nanopm, pages dans `oci-pm` (2026-10-17).
- Découverte, passe 2 sur 5 : consommation par les outils « pas encore livrée » ; usager principal : le mainteneur ; Alpine et Redis servent de banc de rebuilds (2026-10-17).
- Découverte, passe 3 sur 5 : pas de persona secondaire ; anti-persona : les équipes SNCF du pilote ; pari : les outils consommeront la porte (2026-10-17).

Pages écrites, hors du change et hors de ce dépôt : `oci-pm/base-images/wiki/docs/product.md` et `oci-pm/base-images/wiki/docs/personas.md`, lues ici par `.nanopm/wiki/docs/`.

## Cadrage

- Cadrage, passe 1 sur 5 : périmètre limité à la pose et à la découverte ; `design.md` court pour la forme de la dépendance (2026-10-17).

Objectif qualité : aucun déclaré (arc42 absent ou sans objectifs qualité)

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

Aucune. Le change pose un outillage et une découverte, sans comportement du dépôt qui change ; les specs sont sautées (`skip_specs: true`).

## Impact

- Fichiers ajoutés : `package.json`, `package-lock.json`, `docs/adr/` (15 fichiers), `openspec/schemas/surdesrails` (lien), `openspec/changes/onboarding/`.
- Fichiers modifiés : `.gitignore` (`node_modules/`, `.nanopm`).
- Hors de ce dépôt : `oci-pm/link.sh`, `oci-pm/test_link.sh`, `oci-pm/base-images/`, à commiter avec `git -C oci-pm`.
- Dépendance : `surdesrails` 0.4.0, en chemin local ; `npm install` échoue sur tout autre poste et en CI tant que `design.md` ne l'a pas tranché.
