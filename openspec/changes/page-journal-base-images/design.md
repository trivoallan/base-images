# Design

## Context

`screen.sh` commite sur `main`, avec `GITHUB_TOKEN`, le journal (`results/<policy>.jsonl`) et les reports (`results/reports/<policy>/<digest>.{html,md}`). Un push fait avec `GITHUB_TOKEN` ne déclenche aucun workflow `push`. Le champ `report` du journal n'est pas homogène : certaines lignes pointent vers le `.md`, d'autres vers `/results/…` (chemin du volume `uske`), d'autres n'en ont pas. Au 2026-10-16, les 12 lignes `quarantine` ont toutes un `.html` à `results/reports/<policy>/<digest>.html`.

## Goals / Non-Goals

**Goals:**
- Un seul fichier de page et un seul workflow, sans étape de build ni dépendance.
- Une page indépendante de Pages : elle marche servie depuis n'importe quel sous-chemin.

**Non-Goals:**
- Corriger le champ `report` du journal dans `uske` : la page s'adapte au journal.
- Recopier le rendu d'`uske decisions` : la page regroupe par image, mais avec sa propre règle de tête (voir Decisions).

## Decisions

- **Déclenchement par `workflow_run` sur `screening`**, filtré sur `main`, la conclusion `success` et un événement autre que `pull_request`, plus `workflow_dispatch`. *Alternative écartée :* `on: push`, qui ne se déclenche pas sur les commits de `GITHUB_TOKEN`. *Écartée aussi :* publier depuis le job `screening`, qui mélangerait screening et publication et élargirait ses permissions (`pages: write`).
- **Publication par artefact** (`actions/upload-pages-artifact` puis `actions/deploy-pages`), pas « deploy from branch ». Le mode branche passe par Jekyll, qui transformerait les `.md` et pourrait ignorer des fichiers. L'artefact publie le dépôt tel quel, sans `.git` ni `.github`.
- **`results/index.json` généré au moment de la publication** (`ls results/*.jsonl` → tableau JSON de noms de politiques). Une page statique ne sait pas lister un répertoire. *Alternative écartée :* l'API GitHub `contents`, limitée en débit et liée à github.com. Le fichier n'est pas commité.
- **Lien du report dérivé de la politique et du `digest`**, pas du champ `report` : `results/reports/<policy>/<digest>.html`. Le repli vers le `.md`, puis « pas de report », est vérifié par une requête `HEAD` au chargement. *Alternative écartée :* réécrire le champ `report`, ce qui mélangerait trois conventions.
- **Rendu par `textContent` et `createElement`**, jamais `innerHTML` avec des données du journal. Une politique CSP en `<meta>` interdit les ressources externes (`default-src 'self'`, script et style inline autorisés pour le seul fichier).
- **Une carte par image, clé `nom:tag`** (dernier segment du `ref`) : la source `docker.io/…/redis:7.2.9…` et sa reconstruction `ghcr.io/…/base-transit/…/redis:7.2.9…` racontent une seule histoire (transformation requise, reconstruction, refus). Choix de l'option B du PRD, revenu sur l'option A après la mise en ligne. *Alternative écartée :* une ligne par décision, où les refus se perdaient parmi des lignes de même poids.
- **Décision de tête = la plus récente, puis la plus grave à égalité de date.** `uske` écrit le refus d'une source (`uske/rebuild-refused`) à la même seconde que le jugement de sa reconstruction (`transformation-required`). Avec la seule date, aucune image n'était en tête en refus le 2026-10-16 (0 sur 19) ; avec la gravité, 11 le sont, ce qui couvre les 12 refus.
- **Pas de Pretext ni de framework** : une liste de données s'enroule en CSS. Le fichier reste unique, sous la même CSP.
- **Chemins relatifs uniquement**, sans `baseUrl` : la page reste servable hors de Pages (copie vers le cluster SNCF, plus tard).

## Risks / Trade-offs

- [Une requête `HEAD` par ligne affichée] → 13 lignes par défaut aujourd'hui (58 en « tout »), et seulement les lignes visibles. Au-delà de ~200 lignes, publier la liste des reports dans `index.json`.
- [Un échec de `screening` ne republie rien] → c'est voulu : la page montre le dernier état réussi, et `workflow_dispatch` reste là.
- [L'URL change au transfert vers `sncFdevelopers` (≤ 30/10)] → chemins relatifs. Seul `homepage` dans `settings.json` est à mettre à jour.
- [Pages doit être activé une fois, en source « GitHub Actions »] → c'est fait par `make pages`, idempotent. Ce n'est pas dans `apply-settings.sh`, un fichier du socle commun à regis, knock et uske.
- [Sur téléphone, la colonne du rapport sortirait de l'écran] → sous 40 rem, chaque décision devient une carte.
