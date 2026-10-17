# Design

## Context

`screen.sh` lance les trois outils par `docker run`, chacun depuis son image épinglée dans `screening.yml`. Il monte le dépôt en `/repo`, l'espace de travail en `/work` et le journal en `/results`. `uske screen` (uske #53) ne lance aucun conteneur : il exécute `regis` et `knock` par un préfixe de commande (`USKE_REGIS_CMD`, `USKE_KNOCK_CMD`), sans shell, et leur passe les chemins tels qu'il les voit. Après chaque étape qui écrit le journal, et avant l'étape suivante, il lance `USKE_AFTER_RECORD` par `sh -c`, avec `USKE_POLICY` et `USKE_RESULTS`. Si ce hook échoue, la policy s'arrête et rien d'autre n'est placé.

Deux traitements de `screen.sh` n'ont pas d'équivalent dans `uske screen` : `compose_reports`, qui place en tête de chaque rapport les décisions de toute la famille du digest, et `commit_journal`, qui commite, rebase et pousse.

## Goals / Non-Goals

**Goals:**
- Ne garder dans ce dépôt que ce qui lui est propre : où vivent le journal et les rapports (git, la page), et comment on y écrit (le commit avant le placement).
- Ne rien changer au format du journal, ni aux rapports déjà commités.

**Non-Goals:**
- Changer ce que décide le screening, ou l'ordre des portes.
- Faire tourner ce dépôt sur Argo : il reste sur GitHub Actions.
- Faire des ajouts en amont. Ceux que ce change souhaitait, `USKE_STEP` et un nom de rapport qui ne réécrit rien, sont livrés par `uske` 0.9.1 (uske #56).

## Decisions

### D1. `uske` s'installe sur le runner, depuis le tag de sa release, épinglé par commit

`uvx --from "git+https://github.com/trivoallan/uske@<sha>" uske screen …`, avec `astral-sh/setup-uv`. Le commentaire `# v0.9.1` sert à Renovate.

Il faut que le processus `uske` ait sous la main `docker`, pour ses préfixes, et `git`, pour le hook. L'image d'`uske` n'a ni l'un ni l'autre, et c'est voulu : elle est faite pour Argo, où chaque outil a son pod.

Alternatives écartées :
- **Ajouter docker et git à l'image `uske`.** L'image grossit pour un seul consommateur, et le hook demanderait le socket docker de l'hôte.
- **Extraire `/app/uske` de l'image épinglée** (`docker create` puis `docker cp`) et l'exécuter avec le Python du runner. Cette voie garde l'épinglage par digest et la règle Renovate telle quelle, et le code qui tourne serait exactement celui qu'Argo déploie. Elle est écartée parce qu'elle détourne l'image de son usage. Si l'écart entre le tag et l'image devient un problème, c'est la première alternative à reprendre.
- **Un paquet PyPI.** `uske` n'en publie pas.

Conséquence : Renovate suit `uske` par la source `github-tags`, avec le digest du commit. La règle « outils de la porte » s'applique toujours : pas de fusion automatique, et une PR en mode `--judge-only`.

### D2. Les préfixes portent ce que portaient les fonctions `regis()` et `knock()`

Chaque préfixe monte au même chemin le répertoire de travail (`$RUNNER_TEMP/screen`) et le dépôt (`$GITHUB_WORKSPACE`), qui contient `results/`, `policies/` et `playbooks/` :

```
USKE_REGIS_CMD = docker run --rm --user <uid:gid> -v $W:$W -v $REPO:$REPO
                 -v $GRYPE_CACHE:/cache/grype -e GRYPE_DB_CACHE_DIR=/cache/grype
                 -e REGIS_AUTH_GHCR_IO_USERNAME -e REGIS_AUTH_GHCR_IO_PASSWORD  $REGIS_IMAGE
USKE_KNOCK_CMD = docker run --rm --network host --user <uid:gid> -v $W:$W -v $REPO:$REPO
                 -v $HOME/.docker:/tmp/.docker:ro  -e KNOCK_* -e ACTIONS_ID_TOKEN_*  $KNOCK_IMAGE
```

- `--playbooks`, `--results` et `--work` sont passés **en absolu**. `playbooks.resolve` renvoie le chemin sous la forme où il l'a reçu, et un chemin relatif se résoudrait dans le répertoire courant du conteneur.
- `--user` remplace les `chmod a+rwX` de `screen.sh`. Les fichiers écrits appartiennent au runner, et le hook peut les commiter.
- L'authentification de `regis` passe par ses variables `REGIS_AUTH_<HOTE>_*`. Le flag `--auth` ne peut plus être ajouté après les arguments : le préfixe vient avant.
- Le préfixe est découpé à la manière d'un shell POSIX (`shlex`) : les variables y sont développées par le workflow avant l'appel, et non par `uske`.

### D3. Le hook `after-record.sh` reprend `compose_reports` puis `commit_journal`, sans y toucher

Le hook reçoit `USKE_POLICY` et `USKE_RESULTS`. Il recompose tous les rapports Markdown de la policy, comme `screen.sh` le fait à chaque porte, puis il commite, fait `pull --rebase` (le journal se fusionne par union, grâce à `.gitattributes`) et pousse.

Le moment d'appel ne change pas : après l'écriture du journal, avant le placement qui suit. `uske` appelle simplement le hook plus souvent que `screen.sh` ne composait les rapports, une fois par étape qui écrit. Ce n'est pas un problème : la composition est idempotente, et un commit sans changement est sauté.

En `--judge-only`, `uske` n'écrit pas le journal et n'appelle donc pas le hook. Le workflow ne définit `USKE_AFTER_RECORD` qu'en mode `apply`, pour qu'aucun push ne puisse partir d'une PR.

### D4. Le message de commit est `journal(<policy>): <étape> <run>`

`uske` passe au hook l'étape qui vient d'écrire le journal, dans `USKE_STEP` : `record`, `record-approve`, `record-applied`, `record-held` ou `record-promoted` (uske 0.9.1). Le message garde donc dans `git log` la distinction « première porte / placements / seconde porte / promotions ». Le hook n'est appelé qu'après une étape qui a écrit au moins une ligne : un screening en montre deux ou trois, rarement les cinq.

## Risks / Trade-offs

- [Un chemin mal monté] → `regis` rend `inconclusive` et `knock` échoue (exit 1), jamais de placement. La PR de ce change tourne en `--judge-only` sur les trois policies, et ses verdicts doivent être les mêmes que ceux du dernier screening.
- [Les noms de rapports changent] → Les nouveaux rapports s'appellent `<epoch>.md`, et non plus `<run_id>-<tentative>.md`. Quand une deuxième tentative rejuge un digest sous le même epoch, `uske` prend `<epoch>-2.md` : un rapport cité n'est jamais réécrit. Le run reste dans la ligne, en `run`. Les lignes existantes citent leur fichier par chemin et ne sont pas touchées.
- [Le code de sortie] → `uske screen` sort en 1 si une seule policy échoue, quelle qu'en soit la raison (hook, `--apply-plan`, `promote`), après avoir traité les autres. `screen.sh` ne sortait en erreur que sur `--apply-plan`. Le workflow `pages`, qui part d'un screening réussi, part donc moins souvent après une panne partielle. C'est voulu.
- [`uvx` récupère `uske` à chaque run] → Il clone une petite dépendance pure Python et installe `pyyaml`, en quelques secondes. Pas de cache.

## Migration Plan

1. Attendre la publication d'`uske` 0.9.1 (uske #56) : c'est fait.
2. Ouvrir la PR : `screen.sh` supprimé, `after-record.sh` ajouté, workflow et Renovate modifiés. Son screening `--judge-only` sert de recette.
3. Après fusion, lancer un screening `apply` par `workflow_dispatch`. Vérifier les commits du journal, les rapports composés et la page.
4. Retour arrière : revert de la PR. Le journal et les rapports écrits par `uske screen` restent lisibles par `screen.sh`, parce que leur format et leurs chemins (`<digest>/<nom>.md`) sont ceux qu'il sait déjà composer.
