# Plan — policies-outillage

> **Pour les agents :** exécuter avec `/opsx:apply`, tâche par tâche, en cochant chaque case.
> Commandes lancées depuis la racine de `base-images`, avec les clones voisins `../regis`,
> `../knock` et `../uske`.

**But :** une policy knock pour chaque image que tirent regis, knock et uske, jugée par l'un des
trois playbooks `rebuild`, `copy` et `product`, à partir d'un journal vide.

**Approche :** retirer l'ancien jeu (policies `base-*`, journaux, playbook `version/`), écrire les
trois playbooks au format d'uske 0.10.0, une policy par image rangée dans un répertoire par régime,
puis monter le screening sur uske ≥ 0.10.0 et regis ≥ la release qui porte `provenance/signed-by`.

**Outils :** YAML (playbooks regis `v1alpha1`, policies knock `v1alpha1`), GitHub Actions, `uv`,
`crane`, `cosign`.

## Plan de documentation

| Chemin | Quadrant | Destinataire | Geste |
| --- | --- | --- | --- |
| `README.md` | — | Mainteneur du dépôt et lecteur de la page publique : ce que la porte juge, avec quel régime, et ce qui lui échappe | modifié |
| `docs/adr/0015-trois-regimes-admission.md` | — | Mainteneur qui ajoute une image ou un régime | créé (à l'écriture de ce plan) |

Le terme « régime `rebuild` / `copy` / `product` » est nouveau. Le glossaire de référence vit dans le
dépôt `docs`, hors de ce change : la skill `glossary` n'est pas installée ici, et l'entrée est listée
en suivi (S8).

## ADR

- Relus au frontmatter : SDR-0000 à SDR-0014. Aucun n'est dépassé.
- Relus au corps : SDR-0005 (les fichiers de données sont validés par schéma, d'où les tâches 3.4 et
  4.5) ; SDR-0002 (prose en français) ; SDR-0010 (CI GitHub, d'où le groupe 5).
- Créés : [`docs/adr/0015-trois-regimes-admission.md`](../../../docs/adr/0015-trois-regimes-admission.md),
  les trois régimes et la règle qui y range une image. Vérifié par
  `cd docs/adr && npx @jackchuka/mdschema@0.15.1 check '*.md'` → `✓ No violations found`.

## 1. Prérequis hors de ce dépôt

- [ ] 1.1 Attendre la release de regis qui suit 0.42.0 et contient fd58e1a1 (`provenance/signed-by`).
  Vérifier : `crane ls ghcr.io/trivoallan/regis | grep -E '^0\.4[3-9]\.[0-9]+-full$'` imprime au
  moins une ligne. Noter la version `<R>` et son digest :
  `crane digest ghcr.io/trivoallan/regis:<R>-full`.
- [x] 1.2 Relever l'identité de signature de chaque outil. Pour `t` dans `regis knock uske`, avec la
  dernière version publiée `<V>` :
  `cosign verify ghcr.io/trivoallan/$t:<V> --certificate-identity https://github.com/trivoallan/$t/.github/workflows/release.yml@refs/heads/main --certificate-oidc-issuer https://token.actions.githubusercontent.com > /dev/null && echo ok`
  imprime `ok`. Si une commande échoue, relire l'identité réelle avec
  `--certificate-identity-regexp '.*'` et la reporter à la tâche 3.3.
- [ ] 1.3 Créer un jeton Docker Hub en lecture seule (geste du propriétaire, dans Docker Hub), puis
  `gh secret set DOCKERHUB_USERNAME` et `gh secret set DOCKERHUB_TOKEN`.
  Vérifier : `gh secret list` liste les deux noms.

## 2. Remise à zéro

- [ ] 2.1 Créer la branche : `git switch -c feat/policies-outillage`.
- [ ] 2.2 Retirer l'ancien jeu :
  `git rm -r policies/base playbooks/version results/base-alpine-3.jsonl results/base-python-3.jsonl results/base-redis-7.jsonl results/reports`.
  Vérifier : `ls policies playbooks results 2>&1` n'affiche plus aucun de ces chemins.
- [ ] 2.3 Commit : `git commit -m "feat: repartir de zéro sur les policies de la porte"`, avec en
  pied `BREAKING CHANGE: journaux, policies base-* et playbook version/ retirés`.

## 3. Les trois playbooks

- [ ] 3.1 Écrire `playbooks/rebuild.yaml` :

```yaml
# yaml-language-server: $schema=https://trivoallan.github.io/regis/schemas/playbook/v1alpha1/playbook.schema.json
#
# Régime `rebuild` : une image à paquets, que knock sait reconstruire depuis un miroir déclaré.
# Une faille critique corrigeable mène à la transformation ; `cve-critical` est `curable`.
apiVersion: regis.io/v1alpha1
kind: Playbook
metadata:
  name: rebuild
  title: Image reconstructible
  labels:
    app.kubernetes.io/version: "1.0.0"
spec:
  # Premier tier vrai l'emporte. `cve-fixable` se lit à l'envers de son nom : la règle
  # `fix-available` PASSE quand aucune faille n'a de correctif, ÉCHOUE quand il en existe.
  tiers:
    - id: direct-placement
      name: Placement direct
      condition:
        and:
          - { var: rules.no-secret.passed }
          - { var: rules.no-licence-toxique.passed }
          - { var: rules.cve-critical.passed }
    - id: transformation-required
      name: Transformation requise puis placement
      condition:
        and:
          - { var: rules.no-secret.passed }
          - { var: rules.no-licence-toxique.passed }
          - { "!": [{ var: rules.cve-fixable.passed }] }
    - id: quarantine
      name: Quarantaine
      condition: true
  rules:
    - provider: secrets
      criterion: verified-secrets
      slug: no-secret
      level: critical
      tags: [redhibitoire]
    - provider: sbom
      criterion: license-blocklist
      slug: no-licence-toxique
      level: critical
      tags: [redhibitoire]
      options:
        blocklist: [AGPL-3.0-only, AGPL-3.0-or-later, SSPL-1.0]
    - provider: cve
      criterion: cve-count
      slug: cve-critical
      level: critical
      tags: [curable]
      options: { level: critical, max_count: 0 }
    - provider: cve
      criterion: fix-available
      slug: cve-fixable
      level: warning
      tags: [discriminant]
    - provider: oci
      criterion: user-blacklist
      slug: no-root
      level: warning
      tags: [informatif]
    - provider: freshness
      criterion: age
      slug: freshness
      level: warning
      tags: [informatif]
      options: { max_days: 90 }
    - provider: cve
      criterion: cve-count
      slug: cve-high
      level: warning
      tags: [informatif]
      options: { level: high, max_count: 10 }
```

- [ ] 3.2 Écrire `playbooks/copy.yaml`. Il reprend `rebuild.yaml` avec trois écarts : `name: copy`,
  `title: Image copiée`, et le commentaire d'en-tête « Régime `copy` : une image sans gestionnaire
  de paquets, copiée telle quelle. Rien n'y est réparable. ». Il supprime aussi le tier
  `transformation-required` et la règle `cve-fixable`, et passe `cve-critical` à `tags: [redhibitoire]`.
  Le tier `quarantine` garde `condition: true`.
- [ ] 3.3 Écrire `playbooks/product.yaml`. Il reprend `copy.yaml` avec ces écarts : `name: product`,
  `title: Outil maison`, et le commentaire d'en-tête « Régime `product` : regis, knock et uske. Seuil
  plus dur, signature de la CI de release exigée. ». `no-root` et `freshness` passent à
  `level: critical` (`freshness` : `max_days: 30`, le rythme des releases). Le tier
  `direct-placement` exige en plus `{ var: rules.no-root.passed }`, `{ var: rules.freshness.passed }`
  et `{ var: rules.signed-by.passed }`. Ajouter la règle (identités relevées en 1.2) :

```yaml
    - provider: provenance
      criterion: signed-by
      slug: signed-by
      level: critical
      tags: [redhibitoire]
      options:
        signers:
          - identity: https://github.com/trivoallan/regis/.github/workflows/release.yml@refs/heads/main
            issuer: https://token.actions.githubusercontent.com
          - identity: https://github.com/trivoallan/knock/.github/workflows/release.yml@refs/heads/main
            issuer: https://token.actions.githubusercontent.com
          - identity: https://github.com/trivoallan/uske/.github/workflows/release.yml@refs/heads/main
            issuer: https://token.actions.githubusercontent.com
```

- [ ] 3.4 Valider chaque playbook avec regis à la version `<R>` de 1.1 :
  `for p in rebuild copy product; do uv run --project ../regis regis playbook validate playbooks/$p.yaml; done`
  Attendu : trois validations sans erreur, code de sortie 0. Si `../regis` n'est pas sur `<R>`,
  faire d'abord `git -C ../regis checkout v<R>`.
- [ ] 3.5 Commit : `git add playbooks && git commit -m "feat: trois playbooks, rebuild, copy et product"`.

## 4. Les policies

Chaque policy suit ce modèle, ici `policies/rebuild/python.yaml`. Seuls changent les valeurs du
tableau ci-dessous et, pour `copy` et `product`, la ligne `transform`/`remediate`, qui disparaît.

```yaml
# Python 3 sur Alpine, base de regis, knock et uske. Régime rebuild : apk, miroir `alpine`.
apiVersion: knock.io/v1alpha1
kind: MirrorPolicy
metadata:
  name: python-3
  labels:
    admission-track: rebuild           # → playbooks/rebuild.yaml
    major: "3"
    cao: oci-maintainers
spec:
  artifactType: image
  # GHCR refuse la suppression par l'API : un tag sorti de la sélection est marqué, jamais effacé.
  deletionMode: mark
  source:
    registry: docker.io
    repository: library/python
  imports:
    - name: main
      owners: [group:default/oci-maintainers]
      tags:
        includeRegex: "^3\\.14\\.\\d+-alpine3\\.24$"
        semverOnly: false
        aliases: ["{major}.{minor}-alpine"]
      platforms: [linux/amd64, linux/arm64]
      transform:
        - rewritePackageSources: { mirror: alpine }
      remediate:
        - upgradePackages: {}
      destinations:
        - registry: ghcr
          project: oci
          repository: python
```

Valeurs relevées le 2026-10-17. La mineure servie est la plus haute publiée ce jour-là.

| Fichier | `metadata.name` | `source.registry` / `repository` | `includeRegex` | `semverOnly` | Alias | Destination |
| --- | --- | --- | --- | --- | --- | --- |
| `rebuild/python.yaml` | `python-3` | `docker.io` / `library/python` | `^3\.14\.\d+-alpine3\.24$` | false | `{major}.{minor}-alpine` | `python` |
| `rebuild/redis.yaml` | `redis-7` | `docker.io` / `library/redis` | `^7\.4\.\d+-alpine3\.21$` | false | `{major}.{minor}-alpine` | `redis` |
| `rebuild/postgres.yaml` | `postgres-17` | `docker.io` / `library/postgres` | `^17\.\d+-alpine3\.24$` | false | `{major}-alpine` | `postgres` |
| `rebuild/golang.yaml` | `golang-1` | `docker.io` / `library/golang` | `^1\.25\.\d+-alpine3\.24$` | false | `{major}.{minor}-alpine` | `golang` |
| `rebuild/curl.yaml` | `curl-8` | `docker.io` / `curlimages/curl` | `^8\.23\.\d+$` | true | `{major}.{minor}` | `curl` |
| `rebuild/buildkit.yaml` | `buildkit-0` | `docker.io` / `moby/buildkit` | `^v0\.34\.\d+-rootless$` | false | `v{major}.{minor}-rootless` | `buildkit` |
| `rebuild/git.yaml` | `git-2` | `docker.io` / `alpine/git` | `^v2\.54\.\d+$` | true | `v{major}.{minor}` | `git` |
| `copy/uv.yaml` | `uv-0` | `ghcr.io` / `astral-sh/uv` | `^0\.13\.\d+$` | true | `{major}.{minor}` | `uv` |
| `copy/regctl.yaml` | `regctl-0` | `docker.io` / `regclient/regctl` | `^v0\.11\.\d+$` | true | `v{major}.{minor}` | `regctl` |
| `copy/cosign.yaml` | `cosign-3` | `ghcr.io` / `sigstore/cosign/cosign` | `^v3\.1\.\d+$` | true | `v{major}.{minor}` | `cosign` |
| `copy/syft.yaml` | `syft-1` | `docker.io` / `anchore/syft` | `^v1\.54\.\d+$` | true | `v{major}.{minor}` | `syft` |
| `copy/grype.yaml` | `grype-0` | `docker.io` / `anchore/grype` | `^v0\.120\.\d+$` | true | `v{major}.{minor}` | `grype` |
| `copy/git-sync.yaml` | `git-sync-4` | `registry.k8s.io` / `git-sync/git-sync` | `^v4\.7\.\d+$` | true | `v{major}.{minor}` | `git-sync` |
| `copy/zot.yaml` | `zot-2` | `ghcr.io` / `project-zot/zot` | `^v2\.1\.\d+$` | true | `v{major}.{minor}` | `zot` |
| `copy/rustfs.yaml` | `rustfs-1` | `docker.io` / `rustfs/rustfs` | `^1\.0\.\d+$` | true | `{major}.{minor}` | `rustfs` |
| `copy/dependencytrack-apiserver.yaml` | `dependencytrack-apiserver-4` | `docker.io` / `dependencytrack/apiserver` | `^4\.14\.\d+$` | true | `{major}.{minor}` | `dependencytrack-apiserver` |
| `copy/dependencytrack-frontend.yaml` | `dependencytrack-frontend-4` | `docker.io` / `dependencytrack/frontend` | `^4\.14\.\d+$` | true | `{major}.{minor}` | `dependencytrack-frontend` |
| `product/regis.yaml` | `regis-0` | `ghcr.io` / `trivoallan/regis` | deux imports : `slim` `^0\.\d+\.\d+$`, `full` `^0\.\d+\.\d+-full$` | true / false | `{major}.{minor}` / `{major}.{minor}-full` | `regis-slim`, `regis-full` |
| `product/knock.yaml` | `knock-0` | `ghcr.io` / `trivoallan/knock` | `^0\.\d+\.\d+$` | true | `{major}.{minor}` | `knock` |
| `product/uske.yaml` | `uske-0` | `ghcr.io` / `trivoallan/uske` | `^0\.\d+\.\d+$` | true | `{major}.{minor}` | `uske` |

- [ ] 4.1 Vérifier qu'aucune source ne manque de plateforme. Pour chaque ligne :
  `crane manifest <registry>/<repository>:<tag le plus haut> | jq -r '[.manifests[].platform | "\(.os)/\(.architecture)"] | map(select(. == "linux/amd64" or . == "linux/arm64")) | unique | length'`
  doit imprimer `2`. Une source qui imprime moins quitte le tableau, et le README la nomme (tâche 6.2).
- [ ] 4.2 Écrire les sept fichiers de `policies/rebuild/`, d'après le modèle et le tableau.
- [ ] 4.3 Écrire les dix fichiers de `policies/copy/`, sans `transform` ni `remediate`.
- [ ] 4.4 Écrire les trois fichiers de `policies/product/`, sans `transform` ni `remediate`.
  `regis.yaml` porte deux entrées sous `imports` (`slim`, `full`), chacune vers sa destination.
- [ ] 4.5 Vérifier qu'uske lit et route chaque policy :
  `uv run --project ../uske uske list --policies policies`. Attendu : 20 policies listées, sans
  erreur. Vérifier aussi l'accord entre répertoire et label :
  `for f in policies/*/*.yaml; do d=$(basename $(dirname $f)); grep -q "admission-track: $d" $f || echo "ÉCART $f"; done`
  n'imprime rien.
- [ ] 4.6 Commit : `git add policies && git commit -m "feat: une policy par image de l'outillage, rangée par régime"`.

## 5. Le screening

- [ ] 5.1 Dans `.github/workflows/screening.yml`, épingler `USKE_IMAGE` sur la dernière version
  ≥ 0.10.0 et `REGIS_IMAGE` sur `<R>-full`, chacune avec son digest :
  `crane digest ghcr.io/trivoallan/uske:<U>` et `crane digest ghcr.io/trivoallan/regis:<R>-full`.
- [ ] 5.2 Ajouter, avant l'étape `Screen`, la connexion à Docker Hub :

```yaml
      - name: Log in to Docker Hub
        # Les runners partagent leurs IP : en anonyme, la limite de Docker Hub rend des
        # `inconclusive` en série.
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
```

  Vérifier que `screen.sh` transmet bien ces identifiants à knock et regis :
  `grep -n 'docker/config.json\|DOCKER_CONFIG' screen.sh`. Si rien ne s'imprime, monter
  `$HOME/.docker/config.json` en lecture seule dans chaque `docker run` de `screen.sh`.
- [ ] 5.3 Remplacer, dans le commentaire de `permissions.packages`, `base/ et base-transit/` par
  `oci/ et base-transit/`. Le dépôt de transit garde son nom.
- [ ] 5.4 Commit : `git add .github/workflows/screening.yml screen.sh && git commit -m "build: screener avec uske ≥ 0.10.0, regis <R> et Docker Hub authentifié"`.

## 6. Le README

- [ ] 6.1 Réécrire l'introduction et le bloc d'arborescence de `README.md` : `playbooks/{rebuild,copy,product}.yaml`,
  `policies/<régime>/*.yaml`, la destination `ghcr.io/<propriétaire>/oci/<nom>`, et le renvoi à
  l'ADR 0015 pour la règle de régime.
- [ ] 6.2 Ajouter une section « Ce que la porte ne voit pas » : les binaires que le Dockerfile de
  regis télécharge en release GitHub (grype, syft, trufflehog, hadolint, dockle, regctl), et toute
  source retirée par la tâche 4.1.
- [ ] 6.3 Ajouter une phrase sur les dépôts `ghcr.io/<propriétaire>/base/*` : abandonnés, passés en
  privé, plus jugés.
- [ ] 6.4 Mettre à jour le bloc « Vérifier en local » :
  `uv run --project ../uske uske list --policies policies` et la boucle `regis playbook validate` de 3.4.
- [ ] 6.5 Commit : `git add README.md && git commit -m "docs: dire ce que la porte juge, par régime, et ce qui lui échappe"`.

## 7. Validation par le screening de PR

- [ ] 7.1 `openspec validate policies-outillage --type change --strict` imprime
  `Change 'policies-outillage' is valid`.
- [ ] 7.2 Pousser et ouvrir la PR : `git push -u origin feat/policies-outillage`, puis `gh pr create`.
  Le titre est le premier commit.
- [ ] 7.3 Lire le screening `judge` de la PR : `gh run watch` sur le run `screening`. Attendu : 20
  policies planifiées, un verdict par digest, aucune erreur technique (code 0). Une
  `quarantine` est un résultat, pas une faute. Un `inconclusive` en série sur Docker Hub signale
  que 5.2 n'a pas pris.
- [ ] 7.4 Vérifier que les trois outils passent `signed-by` : dans les rapports regis de la PR, la
  règle `signed-by` de `regis-0`, `knock-0` et `uske-0` est `passed`. Sinon, corriger l'identité
  en 3.3 et relancer.

## 8. Clôture

- [ ] 8.1 `openspec archive policies-outillage --yes`, dans la branche de la PR, avant sa fusion.
  Puis `git add openspec && git commit -m "chore: archiver le change policies-outillage"`.

## Suivi après la fusion (hors des cases : l'archivage les précède)

### Dans ce dépôt

- S1 Laisser tourner le premier screening `apply` sur `main`, puis vérifier :
  `ls results/*.jsonl` liste les nouvelles policies et aucune `base-*`.
- S2 Passer en privé les paquets GHCR `base/python`, `base/alpine` et `base/redis`. C'est un
  geste du propriétaire, dans les réglages de chaque paquet.
- S3 Vérifier la page publique : elle ne liste que des policies `rebuild`, `copy` ou `product`.

### Dans les autres dépôts

- S4 knock : `FROM python:3.14-alpine`, cosign v3.1.x, buildkit v0.34.x, `anchore/grype` à la
  place de `cgr.dev/chainguard/grype:latest-dev`, et `redis` en 7.4-alpine. Une PR dans `knock`.
- S5 uske : `FROM python:3.14-alpine`, cosign v3.1.x, zot multi-arch, et `alpine/git` épinglé dans
  l'overlay kind. Une PR dans `uske`.
- S6 regis : uv 0.13.x et curl 8.23.x dans le Dockerfile. Une PR dans `regis`.
- S7 Basculer les `FROM` et `COPY --from` des trois outils sur `ghcr.io/<propriétaire>/oci/…`,
  une fois les images placées.
- S8 Ajouter « régime d'admission » (`rebuild`, `copy`, `product`) au glossaire du dépôt `docs`.
