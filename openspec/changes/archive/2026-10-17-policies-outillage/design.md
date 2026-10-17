# Conception — une policy pour chaque image que tirent regis, knock et uske

Sections arc42 touchées : aucune (`docs/architecture/arc42.md` absent, proposition refusée le
2026-10-17).

## Context

La motivation et le périmètre sont dans `proposal.md` ; les exigences, dans
`specs/regimes-admission` et `specs/couverture-images-outillage`.

Aujourd'hui, trois policies `base-*` routées par `admission-track: standard` vers
`playbooks/version/playbook.yaml`, l'emplacement qu'imposait la table codée en dur d'uske < 0.10.0.
uske 0.10.0 (ee418dc) lit `<playbooks>/<régime>.yaml`, exige un `id` parmi `direct-placement`,
`transformation-required` et `quarantine` sur chaque tier, et ne répare que les règles taguées
`curable`. uske refuse un répertoire de playbooks mal formé (`playbooks.check()`) avant tout jugement.

Faits relevés le 2026-10-17, qui fixent les décisions ci-dessous :

| image | constat |
|---|---|
| `cgr.dev/chainguard/grype` | n'expose que `latest` et `latest-dev` : aucun tag versionné |
| `anchore/grype` | tags `v0.99.x`, amd64 + arm64, distroless (`/grype`, aucun shell) |
| `ghcr.io/project-zot/zot` | index multi-arch (linux amd64 + arm64) ; les dépôts `zot-linux-<arch>` sont superflus |
| `alpine/git` | tags `v2.x.y`, multi-arch, apk |
| `dependencytrack/*`, `rustfs`, `git-sync`, `buildkit-rootless`, `curl` | amd64 + arm64 présents |
| `ghcr.io/<propriétaire>/base/*` | tiré par aucun Dockerfile ni manifeste de regis, knock ou uske |

knock réécrit les sources apk par substitution d'hôte dans `/etc/apk/repositories`
(`knock/domain/transforms/steps.py`) : toute image `rebuild` doit avoir un shell, `sed` et `apk`.

ADR en vigueur : SDR-0001, 0002 (le français), 0005 (fichiers de données validés par JSON Schema),
0006, 0008, 0009, 0010. Les décisions ci-dessous s'y conforment ; SDR-0005 impose que la CI valide
chaque policy et chaque playbook contre leur schéma.

## Goals / Non-Goals

**Goals:**
- Une policy par image du périmètre D, rangée par la règle écrite de `regimes-admission`.
- Trois playbooks qu'uske accepte, et dont les tiers rendent les issues des specs.
- Un premier screening `apply` qui part d'un journal vide.

**Non-Goals:**
- Faire tirer aux outils leurs images depuis `ghcr.io/<propriétaire>/…` : ce sont des PR dans
  regis, knock et uske, après ce change.
- Vérifier une attestation SLSA ou un SBOM signé : seule la signature de l'image est exigée.
- Juger les binaires que regis télécharge : ils sont nommés, pas couverts.

## Decisions

### D1 — Grype vient d'Anchore, en `copy`

`anchore/grype` remplace `cgr.dev/chainguard/grype:latest-dev`. Chainguard gratuit n'a pas de tag
versionné : la policy servirait un tag mouvant, et la règle « une seule mineure » ne tiendrait pas.
Anchore est distroless, donc `copy`. Conséquence : **pas de miroir `wolfi`**. knock passe ses manifestes sur `anchore/grype` (PR dans knock).
*Écarté* : Chainguard `latest-dev` en `rebuild` — réparable, mais chaque screening jugerait le digest
du moment, sans version lisible ni rollback par tag.

### D2 — L'image `git` d'uske est `alpine/git`, en `rebuild`

Le WorkflowTemplate d'uske nomme `git` sans qu'aucun overlay ne l'épingle. On sert `alpine/git`,
multi-arch et apk : réparable par le miroir `alpine` déjà déclaré. L'overlay kind d'uske l'épinglera
(PR dans uske). *Écarté* : hors périmètre — la seule image qui touche au jeton GitHub resterait
sans jugement.

### D3 — zot vient de son index multi-arch

Une seule policy sur `ghcr.io/project-zot/zot`, `platforms: [linux/amd64, linux/arm64]`.
*Écarté* : deux imports `zot-linux-amd64` et `zot-linux-arm64`, qui doubleraient le jugement d'un
même binaire et casseraient la règle d'une import par dépôt de destination.

### D4 — Une destination neuve, `ghcr.io/<propriétaire>/oci/<nom>`

Toutes les policies placent sous un projet `oci`, au nom court de l'image (`python`, `cosign`,
`dependencytrack-apiserver`…, tous distincts). Les dépôts `base/*` existants sont **gelés** : plus
aucune policy ne les vise, rien ne les tire, et GHCR refuse la suppression par l'API de registre ;
le README les déclare abandonnés, et leur suppression reste un geste du propriétaire dans l'interface
GHCR. *Écarté* : réutiliser `base/` — le nom ment pour `cosign` ou `zot`, et `deletionMode: mark` n'y
marquerait que les restes de python et redis, pas ceux d'alpine.

### D5 — Les tiers des trois playbooks

| tier (`id`) | `rebuild` | `copy` | `product` |
|---|---|---|---|
| `direct-placement` | aucune faute critique | aucune faute critique | aucune faute critique |
| `transformation-required` | seule faute : faille critique corrigeable | — | — |
| `quarantine` | sinon | sinon | sinon |

Règles critiques communes : `no-secret`, `no-licence-toxique`. `rebuild` et `copy` ajoutent
`cve-critical` ; seul `rebuild` la tague `curable`. `product` ajoute `cve-critical`, `no-root`,
`freshness` et `signed-by` (critère `provenance/signed-by` de regis, non publié à ce jour : il suit
0.42.0), tous critiques. `signed-by` liste trois paires `{identity, issuer}`, une par outil :
`https://github.com/trivoallan/<outil>/.github/workflows/release.yml@<ref>` et
`https://token.actions.githubusercontent.com`. Le playbook étant commun, une image maison signée par
la CI d'un autre outil maison passe : accepté, ces trois CI sont tenues par la même personne. Les
autres règles restent `warning`, informatives. Chaque playbook part en `1.0.0`.

Le playbook `rebuild` reprend la logique inversée de `cve-fixable` (la règle `fix-available`
échoue quand un correctif existe) que documentait `playbooks/version/playbook.yaml` ; le commentaire
voyage avec elle.

### D6 — Une policy par fichier, un répertoire par régime

`policies/rebuild/*.yaml`, `policies/copy/*.yaml`, `policies/product/*.yaml`. Le régime se lit au
chemin comme au label, et `uske list --policies policies` les parcourt tous. Nom de policy :
`<nom>-<majeure>` (D-01), par exemple `python-3`, `cosign-3`, `regis-0`. Le chemin et le label
disent la même chose : une vérification CI refuse un écart.

### D7 — `product` sert la majeure 0, pas une mineure

regis, knock et uske sont en 0.x et sortent une mineure presque chaque semaine : servir une seule
mineure imposerait d'éditer la policy à chaque release. Les policies `product` sélectionnent les
tags `^0\.\d+\.\d+$` (et `-full` / `-slim` pour regis, en deux imports vers deux destinations
`regis-full`, `regis-slim`), avec l'alias `{major}.{minor}` sur la plus haute. La spec
`couverture-images-outillage` porte cette exception.

### D8 — Ce qui change dans le screening

`screening.yml` épingle uske ≥ 0.10.0 et regis ≥ la release qui porte `provenance/signed-by`. Il n'ajoute aucune étape de vérification : uske appelle
`playbooks.check()` lui-même avant tout jugement, et un playbook mal formé fait échouer le
screening sans rien placer. Le screening s'authentifie auprès de Docker Hub par un secret de dépôt
en lecture seule, avant le plan. Aucun miroir n'est ajouté (D1). La CI de PR valide chaque policy contre le schéma knock et chaque playbook
par `regis playbook validate` (SDR-0005).

## Risks / Trade-offs

- [Docker Hub limite les tirages anonymes, et les runners GitHub partagent leurs IP : une dizaine
  d'images tirées par le plan knock puis par chaque analyse regis rendraient des `inconclusive` en
  série] → le screening s'authentifie auprès de Docker Hub (D8) ; un `inconclusive` est retenté au
  screening suivant.
- [Le premier screening juge ~20 images d'un coup, et une quarantaine massive vide la page] →
  attendu ; le journal le dit, et une réouverture `uske/reopened` se fait image par image.
- [`product` met regis en quarantaine, et le screening qui tourne avec ce regis continue] → le
  screening épingle un digest de regis par Renovate, indépendant de ce que la porte place ; la
  quarantaine signale, elle ne casse pas l'outillage.
- [Une image `rebuild` sans shell (variante distroless publiée plus tard)] → knock échoue au rebuild
  en erreur technique, retentée puis visible ; la règle de régime la renvoie en `copy`.
- [Les tags `base/*` gelés vieillissent avec leurs failles] → rien ne les tire ; le README le dit et
  nomme le geste de suppression.
- [Alignement des versions hors de ce dépôt] → tant que knock et uske tirent python 3.13, ils ne
  tirent pas ce que la porte place ; c'est déjà le cas aujourd'hui, et les PR d'alignement sont
  listées dans `tasks.md`.

## Migration Plan

1. Une seule PR : retrait de `policies/base/`, `playbooks/version/`, `results/*.jsonl` et
   `results/reports/` ; ajout des trois playbooks et des policies ; `screening.yml` sur uske ≥ 0.10.0.
2. Le screening `judge` de la PR montre le plan et les verdicts sans rien placer.
3. Fusion, puis premier screening `apply` : placements sous `oci/`, journaux neufs, page republiée.
4. Après coup, PR dans knock et uske : python 3.14, cosign et buildkit alignés, `anchore/grype`,
   `zot` multi-arch, `alpine/git` épinglé.

Rollback : **avant le premier screening `apply`** seulement, `git revert` de la PR rétablit
policies, journaux et playbook. Après, `github-actions[bot]` a commité des lignes neuves dans
`results/`, et le revert entre en conflit : on corrige en avant, par une PR qui modifie policies ou
playbooks. Ce qui a été placé sous `oci/` reste, inerte, puisque rien ne le tire encore.

## Open Questions

- Les images de démo kind sont-elles screenées au même rythme hebdomadaire que les autres ?
- Aucun ADR en vigueur n'est à remplacer.
