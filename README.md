# base-images

Les images de base Python de [`regis`](https://github.com/trivoallan/regis),
[`knock`](https://github.com/trivoallan/knock) et [`uske`](https://github.com/trivoallan/uske),
passées par la porte que ces trois outils forment. Sans ce dépôt, ils tireraient leur base de Docker
Hub sans aucun jugement : la porte ne protégerait pas ses propres images.

Un criblage `uske` place `python:3.1x-alpine3.24` dans `ghcr.io/sncfdevelopers/base/python`,
seulement après un verdict `regis`, et consigne chaque décision dans le journal de la policy.

```
policies/base/python.yaml        la policy knock (régime standard)
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

## Licence

Apache-2.0.
