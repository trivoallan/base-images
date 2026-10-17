# Plan — onboarding

## Plan de documentation

| Chemin | Quadrant | Destinataire | Geste |
| --- | --- | --- | --- |
| `README.md` (section « Méthode ») | — | le mainteneur, ou qui clone le dépôt et lance `npm install` | modifiée |

## ADR

- Relus au frontmatter : `SDR-0000` à `SDR-0014` sous `docs/adr/` (pas de `SDR-0012`) ; seul `SDR-0001` est `accepted`, aucun n'en dépasse un autre.
- Relus au corps : `SDR-0001` (consigner les décisions d'architecture), parce qu'il dit quand une décision mérite un ADR.
- Créés : aucun — la forme de la dépendance à la méthode est tactique et datée (`design.md` dit quand y revenir), et aucune décision durable et transverse n'est introduite.

## 1. Vérifier la pose

- [x] 1.1 Lancer `npm ls surdesrails` dans base-images ; la dernière ligne attendue est `` `-- surdesrails@0.4.0 -> ./../../surdesrails ``.
- [x] 1.2 Lancer `openspec schemas` ; la sortie liste `spec-driven` et `surdesrails (project)`.
- [x] 1.3 Lancer `git check-ignore .nanopm` ; la sortie attendue est `.nanopm`. Lancer `git ls-files .nanopm CONTEXT.md` ; la sortie attendue est vide.
- [x] 1.4 Lancer `sh ../oci-pm/test_link.sh` ; la dernière ligne attendue est `OK`.

## 2. Documenter la méthode dans le README

- [x] 2.1 Dans `README.md`, avant `## Licence`, ajouter une section `## Méthode` de trois phrases : les changes `openspec/` suivent le schéma `surdesrails` (ou `spec-driven` pour ceux d'avant) ; `npm install` attend un clone de `surdesrails` à `../../surdesrails`, sans quoi le lien `openspec/schemas/surdesrails` pend ; la découverte du produit vit dans le dépôt privé `oci-pm`, pas ici.
- [x] 2.2 Relire la section au Google developer documentation style : phrases courtes, à la deuxième personne, sans futur.
- [x] 2.3 Commit : `git add README.md openspec/changes/onboarding && git commit -m "docs: dire comment la méthode surdesrails est posée"`.

## 3. Commiter la découverte dans oci-pm

- [x] 3.1 `git -C ../oci-pm add link.sh test_link.sh base-images` ; `git -C ../oci-pm status --short base-images` ne doit lister ni `raw/` ni `search.db`.
- [x] 3.2 `git -C ../oci-pm commit -m "feat: brancher base-images et sa découverte"`.

## 4. Fermer le change

- [x] 4.1 `openspec validate onboarding --type change --strict` ; la sortie attendue est `Change 'onboarding' is valid`.
- [x] 4.2 `openspec archive onboarding --yes`, puis `git add openspec && git commit -m "chore: archiver le change onboarding"`, dans la même branche `chore/surdesrails`.
