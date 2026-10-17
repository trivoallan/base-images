# Plan — verdicts

## Plan de documentation

| Chemin | Quadrant | Destinataire | Geste |
| --- | --- | --- | --- |
| `docs/adr/SDR-0000-…` à `SDR-0014-…` (les treize en `proposed`) | — | l'agent qui lit les traits avant d'écrire, et le mainteneur qui relit une décision | modifiée |

## ADR

- Relus au frontmatter : `SDR-0000` à `SDR-0014` sous `docs/adr/` (pas de `SDR-0012`) ; aucun n'en dépasse un autre. Seul `SDR-0001` était `accepted`, et il n'est pas touché.
- Relus au corps : les treize SDR `proposed`, parce que ce change rend leur verdict selon leur bloc de prescription. Statuer un ADR `proposed` n'en modifie pas un ADR `accepted`.
- Créés : aucun — les verdicts tranchent les ADR existants, sans nouvelle décision durable.

## 1. Vérifier les verdicts

- [x] 1.1 Lancer `grep -l '^status: proposed' docs/adr/SDR-*.md` ; la sortie attendue est vide.
- [x] 1.2 Lancer `grep -l 'Tout ce qui suit disparaît quand vous statuez' docs/adr/*.md` ; la sortie attendue est vide (aucun mode d'emploi oublié).
- [x] 1.3 Lancer `( cd docs/adr && npx -y @jackchuka/mdschema@0.15.1 check '*.md' )` ; la sortie attendue est `✓ No violations found`.
- [x] 1.4 Relire le tableau de `proposal.md` contre le `status:` et les `traits:` de chaque SDR : six `accepted` (0002, 0005, 0006, 0008, 0009, 0010), sept `rejected` sans bloc `traits:` (0000, 0003, 0004, 0007, 0011, 0013, 0014).
- [x] 1.5 Commit : `git add docs/adr openspec/changes/verdicts && git commit -m "docs: rendre les verdicts des SDR hérités"`.

## 2. Fermer le change

- [ ] 2.1 `openspec validate verdicts --type change --strict` ; la sortie attendue est `Change 'verdicts' is valid`.
- [ ] 2.2 `openspec archive verdicts --yes`, puis `git add openspec && git commit -m "chore: archiver le change verdicts"`, dans la même branche `chore/surdesrails`.
