# base-images

Toutes les images que tirent [`regis`](https://github.com/trivoallan/regis),
[`knock`](https://github.com/trivoallan/knock) et [`uske`](https://github.com/trivoallan/uske) — leurs
bases, les images d'où ils copient un binaire, ce qu'ils déploient, et les trois outils eux-mêmes —
passées par la porte que ces trois outils forment. Sans ce dépôt, la porte ne protégerait pas ses
propres images.

Un screening `uske` place chaque image sous `ghcr.io/sncfdevelopers/oci/<nom>` seulement après un
verdict `regis`, et consigne chaque décision dans le journal de sa policy. Le playbook qui la juge
dépend de son régime, et une règle écrite range chaque image dans l'un des trois
([ADR 0015](docs/adr/0015-trois-regimes-admission.md)) :

| Régime | Images | Ce qu'il exige |
| --- | --- | --- |
| `rebuild` | python, redis, postgres, golang, curl, buildkit, git | une image à paquets apk ; une faille critique corrigeable mène à une reconstruction |
| `copy` | uv, regctl, cosign, syft, grype, git-sync, zot, rustfs, Dependency-Track | une image copiée telle quelle ; une faille critique la met en quarantaine |
| `product` | regis, knock, uske | un seuil plus dur (root, fraîcheur) et une signature keyless de la CI de release de l'outil |

```
policies/<régime>/<image>.yaml        une policy knock par image, étiquetée admission-track: <régime>
playbooks/{rebuild,copy,product}.yaml le playbook regis de chaque régime, là où uske le cherche
```

Une policy sert une seule mineure de sa source ; une policy `product` sert sa majeure entière, parce
que ces outils sortent une mineure presque chaque semaine.

Vérifier en local :

```bash
uv run --project ../uske uske list --policies policies
for p in rebuild copy product; do uv run --project ../regis regis playbook validate playbooks/$p.yaml; done
```

## Ce que la porte ne voit pas

- Les binaires que le Dockerfile de `regis` télécharge depuis les releases GitHub : grype, syft,
  trufflehog, hadolint, dockle et regctl. Ce ne sont pas des images OCI, et aucune policy ne les
  juge.
- Les dépôts `ghcr.io/sncfdevelopers/base/*` (python, alpine, redis), qu'un jeu de policies antérieur
  remplissait. Plus rien ne les juge ni ne les tire : ils sont abandonnés, et le propriétaire les passe en privé.

## Screening

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
screening `apply` réussi sur `main`, et à la demande. Il n'y ajoute que trois fichiers, qu'[`index.html`](index.html)
lit : `results/index.json`, la liste des journaux ; `results/rulesets.json`, la source de chaque
ruleset ; `results/policies.json`, le fichier de chaque policy et les étapes de reconstruction
qu'elle déclare. Pages s'active une fois avec `make pages`.

## Renovate

[`renovate`](.github/workflows/renovate.yml) suit les digests de `regis`, `knock` et `uske` épinglés
dans `screening.yml`. Une montée de version ouvre une PR, et c'est le screening en mode `judge` de
cette PR qui la valide. Renovate passe par l'app CI, et non par `GITHUB_TOKEN`, parce qu'une PR
ouverte avec `GITHUB_TOKEN` ne déclencherait aucun workflow. Le dépôt a donc besoin des secrets
`CI_APP_CLIENT_ID` et `CI_APP_PRIVATE_KEY`, et l'app doit y être installée.

## Méthode

Les changes d'`openspec/` suivent le schéma `surdesrails`, ou `spec-driven` pour ceux d'avant sa
pose. `npm install` attend un clone de `surdesrails` à `../../surdesrails` ; sans lui, le lien
`openspec/schemas/surdesrails` pend et seuls les changes `spec-driven` restent utilisables. La
découverte du produit vit dans le dépôt privé `oci-pm`, et `.nanopm` n'en est qu'un lien.

## Licence

Apache-2.0.
