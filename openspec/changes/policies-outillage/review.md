# Review

Revue due (ligne « Revue » de `proposal.md`) : décision `irréversible` — journaux et page publique
remis à zéro — et livrable face à des tiers — la page publique et les dépôts
`ghcr.io/<propriétaire>/…`. Relue sur `proposal.md`, les deux specs et `design.md`, et confrontée
au code d'uske 0.10.0, de knock et de `screening.yml` le 2026-10-17. Écrite à la main :
`/plan-eng-review` n'a pas été lancé.

## Grilles retenues

- **Contrôle** : le livrable est une porte, il refuse. On relit ce qu'elle laisse passer, ce
  qu'elle bloque à tort, et ce qu'elle ne voit pas.
- **Ingénierie** : une décision `irréversible`, et un plan qui déborde sur deux autres dépôts.
- *DevEx* et *Design* écartées : rien ne se consomme comme une API, et la page n'est pas modifiée,
  seulement vidée.

## Findings et traitement

| # | Grille · dimension | Finding | Sévérité | Traitement |
| --- | --- | --- | --- | --- |
| 1 | Ingénierie · faisabilité | D8 fait lancer `uske check` : uske 0.10.0 n'a pas cette sous-commande. Il appelle `playbooks.check()` lui-même avant tout jugement (`cli.py`). | haute | Corriger D8 : l'appel existe déjà dans uske, `screening.yml` n'ajoute rien. La CI de PR valide les playbooks par `regis playbook validate`. |
| 2 | Contrôle · disponibilité | Le screening tire une dizaine d'images Docker Hub sans `docker login`. Plan knock et analyses regis (grype, syft, trufflehog, dockle) les tirent chacun. Les runners GitHub partagent leurs IP, et la limite anonyme de Docker Hub rendra des `inconclusive` en série au premier screening. | haute | Tâche : authentifier le screening auprès de Docker Hub par un secret de dépôt en lecture seule, avant la fusion. Le risque est écrit dans `design.md`. |
| 3 | Contrôle · tiers | Les dépôts gelés `ghcr.io/<propriétaire>/base/*` restent publics et tirables par des tiers, avec des failles qui s'accumulent et sans journal pour le dire. | moyenne | Tâche : les passer en privé dans GHCR après la fusion, geste du propriétaire. Le README dit pourquoi. |
| 4 | Ingénierie · irréversibilité | Les liens partagés vers une image ou un rapport de la page (#26) cassent à la remise à zéro. Le rollback de `design.md` (`git revert`) entre en conflit dès qu'un screening a commité de nouvelles lignes. | moyenne | Accepté : le dépôt est jeune, les journaux restent dans l'historique git. Corriger le plan de migration : le rollback se fait avant le premier screening `apply`, après il se fait en avant. |
| 5 | Contrôle · faux refus | `product` tient `freshness` pour critique. Une release de regis vieille de plus de N jours passerait en quarantaine même saine, alors que Renovate épingle volontairement une version. | moyenne | Le seuil de `freshness` dans `product.yaml` suit le rythme des releases. Un scénario de spec le vérifie à l'écriture des tâches. |
| 6 | Contrôle · angle mort | La règle de régime range en `copy` les images à `apt` (dependencytrack, base Ubuntu) parce qu'aucun miroir `apt` n'est déclaré. C'est juste, mais une faille critique corrigeable y mène en quarantaine, alors qu'un `rebuild` la réparerait. | basse | Accepté pour ce change. Déclarer un miroir `apt` est une évolution de régime, qui passera par un change à part. |
| 7 | Ingénierie · dépendances | L'alignement de knock et d'uske (python 3.14, cosign, buildkit, `anchore/grype`, zot multi-arch, `alpine/git`) vit hors du dépôt. Tant qu'il n'est pas fait, la porte juge des images que les outils ne tirent pas. | basse | Listé en tâches de suivi, avec une PR par dépôt. Ce change n'en dépend pas pour fusionner. |
| 8 | Contrôle · couverture | `no-root` critique en `product` : vérifié, uske (`65532`), knock (`65532:65532`) et regis (`regis`) tournent sans root. | — | Aucun. |

## Critère d'achèvement

La revue est close quand :
- `design.md` porte la correction de D8 (finding 1), le risque Docker Hub (finding 2) et le plan de
  rollback corrigé (finding 4) ;
- `tasks.md` porte l'authentification Docker Hub, le passage en privé de `base/*`, le seuil de
  `freshness` de `product` avec son scénario, et une tâche de suivi par dépôt à aligner ;
- aucun finding de sévérité haute n'est laissé sans traitement.
