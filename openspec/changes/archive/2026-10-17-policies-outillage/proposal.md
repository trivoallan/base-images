# Proposition — une policy pour chaque image que tirent regis, knock et uske

Proposition refusée : architecture (2026-10-17)

## Why

La porte ne juge que trois bases (`python`, `alpine`, `redis`), et encore de travers : knock et uske
tirent `python:3.13-alpine` quand la policy sert 3.14, knock tire `redis:7-alpine` quand elle sert
`7.2-alpine3.21`, et aucun outil ne tire `alpine` nue. Tout le reste — les images d'où viennent les
binaires copiés, les compagnons d'exécution, les trois outils eux-mêmes — arrive de Docker Hub, GHCR
ou Chainguard sans aucun jugement. uske 0.10.0 laisse enfin le dépôt de playbooks nommer ses
régimes (`<playbooks>/<régime>.yaml`, tiers par `id`, règles réparables taguées `curable`) : on peut
repartir à zéro sur des régimes faits pour ce dépôt.

## What Changes

- **BREAKING** — retrait des policies `policies/base/{python,alpine,redis}.yaml`, des journaux
  `results/*.jsonl`, de leurs rapports et de `playbooks/version/playbook.yaml`. La page publique
  repart vide.
- Trois playbooks, un par régime, au nom nu que lit uske ≥ 0.10.0. La version vit dans
  `app.kubernetes.io/version` ; ce qui a jugé une décision, c'est le `ruleset` (sha256 du playbook)
  que le journal porte déjà :
  - `playbooks/rebuild.yaml` : images à paquets (apk), réparables. Une faille critique
    corrigeable mène à `transformation-required` ; la règle `cve-critical` est taguée `curable`.
  - `playbooks/copy.yaml` : images copiées sans reconstruction (scratch, distroless, ko).
    Tiers `direct-placement` et `quarantine` seulement : rien n'y est réparable.
  - `playbooks/product.yaml` : regis, knock et uske. Même forme que `copy`, plus sévère : faille
    critique (même corrigeable), `root`, fraîcheur, et une signature keyless vérifiée par la CI de
    release de l'outil (`provenance/signed-by`) sont critiques. Les reconstruire casserait leur signature et leur provenance.
- Une policy knock par image, une seule mineure servie (D-01), étiquetée `admission-track:
  <régime>` :

  | régime    | images |
  |-----------|--------|
  | `rebuild` | python (alpine), curl, redis, postgres, buildkit-rootless, golang (alpine), alpine/git |
  | `copy`    | uv, regctl, cosign, syft, grype (anchore), git-sync, zot, rustfs, dependencytrack apiserver et frontend |
  | `product` | regis, knock, uske |

- Grype vient d'`anchore/grype` (tags versionnés, distroless) plutôt que de Chainguard, qui n'expose
  que `latest` et `latest-dev`. L'image `git` d'uske est `alpine/git`. Aucun miroir n'est ajouté :
  `alpine` suffit.
- `screening.yml` épingle uske ≥ 0.10.0, prérequis du routage par nom de fichier.
- Les binaires que le Dockerfile de regis télécharge en release GitHub (grype, syft, trufflehog,
  hadolint, dockle, regctl) sont nommés dans le README comme hors de portée d'une policy d'image.

## Alternatives écartées

- `ne rien faire` : les bases des outils restent jugées à moitié, et tout ce qu'ils copient ou
  déploient ne l'est pas du tout — la porte ne protège pas ses propres images.
- `bases seules (FROM)`, ou `bases + sources de COPY --from` : périmètres plus petits, mais les trois
  outils ne passeraient pas par leur propre porte.
- `garder policies et journaux, compléter` : les policies actuelles servent des versions que les
  outils ne tirent pas ; repartir à zéro coûte moins que les redresser une à une.
- `deux régimes (rebuild, copy)` : regis, knock et uske y seraient jugés comme une image tierce,
  alors que c'est nous qui corrigeons en amont ; ils méritent un seuil plus dur.
- `version dans le nom du régime` (`rebuild-v1.yaml`) : n'ajoute rien à la traçabilité — le
  `ruleset` de chaque ligne du journal est le hash exact du playbook — et oblige à dupliquer le
  fichier et réétiqueter chaque policy à chaque version. Un `-v2` ne naîtra que pour une règle à
  appliquer policy par policy.
- `product sans provenance en v1` : regis vérifie désormais l'identité et l'émetteur d'une signature,
  dans les deux formats de cosign (`provenance/signed-by`, fd58e1a1) ; attendre un régime suivant
  laisserait passer une image maison non signée.
- `labels source et revision critiques` : aucun critère regis ne teste un label, et une règle ne
  peut pas porter de condition libre ; la signature keyless prouve déjà le dépôt source.
- `plusieurs mineures par policy` : contredit D-01 et ferait juger deux images pour un même usage ;
  les outils s'alignent plutôt (python 3.14, cosign et buildkit d'une seule version), dans leurs
  propres dépôts.
- `grype Chainguard en rebuild, avec un miroir wolfi` : réparable, mais Chainguard gratuit n'a pas
  de tag versionné ; la policy servirait un tag mouvant, sans version lisible ni rollback par tag.
- `image git hors périmètre` : la seule image qui manie le jeton GitHub resterait sans jugement.

## Conception

`design.md` est dû : ambiguïté qu'une décision technique lève avant le code (zot publié une image
par architecture contre `platforms: [amd64, arm64]`, image `git` non résolue, miroir `wolfi`), et
décision `irréversible` (retrait des journaux publiés).

## Revue

`review.md` est due : décision `irréversible` (journaux et page publique remis à zéro) et livrable
face à un tiers (la page publique, les dépôts `ghcr.io/<propriétaire>/…` que des Dockerfiles tirent).

## Capabilities

### New Capabilities
- `regimes-admission` : les trois playbooks versionnés, leurs tiers, leurs règles critiques et
  réparables, et la règle qui range une image dans un régime.
- `couverture-images-outillage` : chaque image tirée par regis, knock ou uske a sa policy, une
  seule mineure servie, et ce qui reste hors de portée est nommé.

### Modified Capabilities

## Impact

- `policies/`, `playbooks/`, `results/` : réécrits ou vidés.
- `.github/workflows/screening.yml` : uske ≥ 0.10.0, regis ≥ la release qui suit 0.42.0 et porte
  `provenance/signed-by`.
- `README.md` : arborescence, régimes, ce qui reste hors de portée.
- Hors de ce dépôt, par des PR dans `knock` et `uske` : FROM en python 3.14, cosign et buildkit
  alignés, puis bascule de leurs FROM et COPY sur `ghcr.io/<propriétaire>/…`.
- Les tags déjà placés sous `ghcr.io/<propriétaire>/base/*` restent ; leur sort est à trancher en
  conception (`deletionMode: mark` ne marque que ce qu'une policy encore présente désélectionne).

Objectif qualité : aucun déclaré (arc42 absent ou sans objectifs qualité)

## Questions ouvertes

- Cadrage, passe 1 sur 5 (2026-10-17) : architecture refusée ; grype en `rebuild` avec miroir
  `wolfi` ; une mineure par policy, outils alignés ; démo kind, image `git` et binaires de regis
  dans le périmètre.
- Tranché en conception (2026-10-17) : `git` est `alpine/git` ; zot vient de son index multi-arch ;
  grype vient d'Anchore, en `copy`.
- Les images de démo kind (rustfs, golang, postgres, zot) suivent-elles le même rythme de
  screening que celles de production ?
