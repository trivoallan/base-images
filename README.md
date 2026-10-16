# base-images

Les images de base, Python, Alpine et Redis, de [`regis`](https://github.com/trivoallan/regis),
[`knock`](https://github.com/trivoallan/knock) et [`uske`](https://github.com/trivoallan/uske),
passées par la porte que ces trois outils forment. Sans ce dépôt, ils tireraient leur base de Docker
Hub sans aucun jugement : la porte ne protégerait pas ses propres images.

Un criblage `uske` place `python:3.14-alpine3.24` dans `ghcr.io/sncfdevelopers/base/python` et
`alpine:3.24` dans `ghcr.io/sncfdevelopers/base/alpine`, et `redis:7.2-alpine3.21` dans
`ghcr.io/sncfdevelopers/base/redis`, seulement après un verdict `regis`, et consigne chaque
décision dans le journal de sa policy.

```
policies/base/python.yaml        la policy knock de Python 3 (régime standard)
policies/base/alpine.yaml        la policy knock d'Alpine 3 (régime standard)
policies/base/redis.yaml         la policy knock de Redis 7 (régime standard)
playbooks/version/playbook.yaml  le playbook regis de ce régime, là où uske le cherche
```

Vérifier en local :

```bash
uv run --project ../uske uske list --policies policies
uv run --project ../regis regis playbook validate playbooks/version/playbook.yaml
```

## Criblage

[`screen.sh`](screen.sh) enchaîne les étapes du `WorkflowTemplate` Argo de `uske`, dans le même
ordre, chacune dans le conteneur publié de son outil. [`screening`](.github/workflows/screening.yml)
le lance chaque lundi et à la demande, en mode `apply`. Sur une PR, il tourne en mode `judge` :
plan et verdicts seulement, sans journal ni placement.

Le journal (`results/<policy>.jsonl`) et les rapports HTML sont commités sur `main` par
`github-actions[bot]`, avant tout placement. Les rulesets d'un dépôt personnel ne savent pas
exempter GitHub Actions. La règle `main` n'impose donc pas de PR : elle interdit seulement la
suppression, le force-push et l'historique non linéaire.

Pour rouvrir une source mise en quarantaine, ajoute au journal une ligne `uske/reopened` (voir le
README d'`uske`) et ouvre une PR.

## Page

[`https://trivoallan.github.io/base-images/`](https://trivoallan.github.io/base-images/) montre le
journal de toutes les politiques, la décision la plus récente en premier : d'abord les refus et les
`inconclusive`, et tout le reste d'un clic. Chaque ligne mène au rapport `regis` de sa décision, rendu
en HTML, qui dit quelle règle l'a tranchée.

Il n'y a pas de build. [`pages`](.github/workflows/pages.yml) publie le dépôt tel quel après chaque
criblage `apply` réussi sur `main`, et à la demande. Il n'y ajoute que `results/index.json`, la liste
des journaux, qu'[`index.html`](index.html) lit. Pages s'active une fois avec `make pages`.

## Renovate

[`renovate`](.github/workflows/renovate.yml) suit les digests de `regis`, `knock` et `uske` épinglés
dans `screening.yml`. Une montée de version ouvre une PR, et c'est le criblage en mode `judge` de
cette PR qui la valide. Renovate passe par l'app CI, et non par `GITHUB_TOKEN`, parce qu'une PR
ouverte avec `GITHUB_TOKEN` ne déclencherait aucun workflow. Le dépôt a donc besoin des secrets
`CI_APP_CLIENT_ID` et `CI_APP_PRIVATE_KEY`, et l'app doit y être installée.

## Licence

Apache-2.0.
