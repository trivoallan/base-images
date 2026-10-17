# Tasks

## 1. Prérequis en amont

- [ ] 1.1 Attendre la publication d'`uske` 0.9.0 (uske #43), puis relever le SHA du commit du tag `v0.9.0`. Vérification : `uvx --from "git+https://github.com/trivoallan/uske@<sha>" uske screen --help` affiche l'aide de `screen`, et `USKE_AFTER_RECORD` y figure.
- [ ] 1.2 Ouvrir dans `uske` deux demandes, l'une pour `USKE_STEP` dans l'environnement du hook, l'autre pour un nom de rapport court qui distingue chaque tentative (D4, Risks). Elles ne bloquent pas ce change. Vérification : chaque issue a son lien dans la PR de ce change.

## 2. Le hook

- [ ] 2.1 Écrire `after-record.sh`. Il reprend `compose_reports` et `commit_journal` de `screen.sh` (D3), avec ces différences :
  - il lit `USKE_POLICY` et `USKE_RESULTS` ;
  - il appelle `uske decisions` par la même commande `uvx` que le workflow ;
  - il écrit le message `journal(<policy>): screening <run>` (D4).

  Vérification : sur une copie du dépôt, avec `USKE_POLICY=base-alpine-3`, deux exécutions de suite donnent les mêmes rapports (idempotence), et `git status` ne montre que les rapports de cette policy.
- [ ] 2.2 Vérifier que le hook sort en non-zéro quand `git push` échoue, pour que la policy s'arrête avant tout placement. Vérification : avec un remote injoignable, le hook sort en code non nul.

## 3. Le workflow

- [ ] 3.1 Dans `screening.yml` :
  - remplacer `USKE_IMAGE` par l'installation `astral-sh/setup-uv` ;
  - remplacer `./screen.sh` par `uske screen --policies "$PWD/policies" --playbooks "$PWD/playbooks" --results "$PWD/results" --work "$RUNNER_TEMP/screen" --transit transit --run "$RUN"` ;
  - ajouter `--judge-only` quand l'événement est une PR (D1).

  Vérification : `actionlint` passe.
- [ ] 3.2 Construire `USKE_REGIS_CMD` et `USKE_KNOCK_CMD` dans le pas `Screen` (D2) :
  - montages au même chemin ;
  - `--user "$(id -u):$(id -g)"` ;
  - cache grype ;
  - `REGIS_AUTH_GHCR_IO_*` ;
  - les variables `KNOCK_*` et `ACTIONS_ID_TOKEN_*` ;
  - `--network host` pour knock.

  Vérification : la PR (task 5.1) juge les trois policies sans aucun `inconclusive` dû à un chemin ou à l'authentification.
- [ ] 3.3 Ne définir `USKE_AFTER_RECORD=./after-record.sh` qu'en mode `apply` (D3). Vérification : le log du screening de la PR ne contient aucun `git push`.
- [ ] 3.4 Supprimer `screen.sh`. Vérification : `git grep -n screen.sh` ne renvoie plus que l'historique (CHANGELOG, change archivé), plus aucun fichier vivant.

## 4. Renovate et documentation

- [ ] 4.1 Dans `.github/renovate.json5`, ajouter un gestionnaire regex pour la ligne `uske@<sha> # v<version>` du workflow, avec `datasourceTemplate: "github-tags"`, et le ranger dans le groupe « outils de la porte » (`automerge: false`). Vérification : `npx --yes --package renovate -- renovate-config-validator` passe, et le dry-run local de Renovate détecte `trivoallan/uske`.
- [ ] 4.2 Réécrire la section « Screening » du README : `uske screen`, le hook, le mode `--judge-only` sur une PR. Retirer toute mention de `screen.sh`. Vérification : relecture de la section, et les liens résolvent sur GitHub.

## 5. Recette et bascule

- [ ] 5.1 Ouvrir la PR. Son screening `--judge-only` doit donner, pour chaque digest encore à juger, le même état que le dernier screening de `screen.sh`. Vérification : comparaison des lignes affichées avec `results/*.jsonl` sur `main`.
- [ ] 5.2 Après fusion, lancer un screening `apply` par `workflow_dispatch`. Vérification :
  - un commit `journal(...)` sur `main` par étape qui écrit ;
  - les rapports nouveaux commencent par les décisions de leur famille ;
  - le workflow `pages` publie, et la page affiche les nouvelles lignes.
