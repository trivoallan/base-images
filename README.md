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

## État

Le criblage dans GitHub Actions n'est pas encore écrit : voir le change OpenSpec
`dogfood-base-images` à la racine du workspace `oci/`, groupe 2.

**À faire avant le premier criblage** : le journal est commité directement sur `main` par le bot
CI. La règle `main` de `.github/settings.json` doit autoriser l'app CI à contourner l'obligation
de PR (`bypass_actors`, `actor_type: Integration`). Son identifiant est à prendre après
l'installation de l'app sur `sncFdevelopers`.

## Licence

Apache-2.0.
