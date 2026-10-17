Sections arc42 touchées : aucune (pas de `docs/architecture/arc42.md`, et aucun bloc ne se déplace).

## Context

La pose a installé la méthode comme dépendance de développement en chemin local : `"surdesrails": "file:../../surdesrails"`. Ce chemin suppose un clone de `surdesrails` deux niveaux au-dessus de base-images ; il n'existe que sur le poste du mainteneur. Trois choses en dépendent : le lien `openspec/schemas/surdesrails` (vers `node_modules/surdesrails/...`), les ADR hérités, que la méthode compare à leur copie sous `node_modules` pour proposer une nouvelle révision, et les skills déclarées dans `package.json`.

Faits qui bornent la décision :

- Aucun workflow de base-images n'exécute `npm` : `screening`, `pages` et `renovate` n'en ont pas besoin. Une dépendance npm qui ne s'installe pas ailleurs ne casse donc aucune CI.
- Le dépôt `surdesrails` est privé, sur la forge GitLab de la SNCF, joignable seulement par le VPN. Les runners GitHub ne le joignent pas.
- base-images est public, et le seul usager retenu par la découverte est le mainteneur (`personas.md`).
- ADR en vigueur : seul `SDR-0001` (consigner les décisions d'architecture) est `accepted` ; les autres SDR hérités sont `proposed` et ne contraignent pas encore ce change.

## Goals / Non-Goals

**Goals:**
- Trancher la forme de la dépendance à la méthode, avec ce qui fera revenir sur ce choix.

**Non-Goals:**
- Rendre le dépôt installable par un tiers.
- Rendre les verdicts des SDR hérités (change suivant).
- Publier `surdesrails` sur un registre npm public.

## Decisions

**Garder `file:../../surdesrails`.** C'est la seule forme qui s'installe sur le poste du seul usager sans exposer d'adresse interne, et rien d'autre n'exécute `npm` sur ce dépôt.

Alternatives pesées :

- **`git+https://gitlab-repo-gpf.apps.eul.sncf.fr/…/surdesrails.git#semver:^0`**, la forme du README de la méthode : épinglée par version, reproductible pour qui a le VPN. Écartée : elle publie l'adresse d'une forge interne dans un dépôt public, et ne s'installe pas mieux ailleurs que le chemin local, puisque ni un runner GitHub ni un tiers ne joignent cette forge.
- **Aucune dépendance npm** : copier le schéma sous `openspec/schemas/surdesrails/` et retirer `package.json`. Le dépôt resterait utilisable par tous. Écartée : la méthode suit ses montées de version par la copie sous `node_modules` (révision des ADR, skills) ; sans elle, chaque montée devient une recopie à la main, et la commande de pose ne peut plus vérifier ce qu'elle a déjà posé.

## Risks / Trade-offs

- [Un clone frais, ou un autre poste, échoue à `npm install` et voit le lien `openspec/schemas/surdesrails` pendre] → Le README le dit ; un change en schéma `spec-driven` reste possible sans la méthode.
- [Le clone local de `surdesrails` avance sans que base-images le sache : `file:` n'épingle aucune version] → `package-lock.json` garde la version installée (0.4.0) ; une montée se fait par `npm install` volontaire, et la révision des ADR hérités la rend visible au change suivant.
- [Le chemin relatif suppose la disposition actuelle du workspace (`ttc/surdesrails` et `ttc/oci/base-images`)] → Le chemin est écrit une fois, dans `package.json`, et se corrige en une ligne.

## Migration Plan

Rien à migrer : la pose est faite et commitée (`d8b1182`). Retour arrière : supprimer `package.json`, `package-lock.json`, `node_modules/`, `openspec/schemas/surdesrails` et `docs/adr/`, et retirer le change.

À reprendre quand :
- base-images passe sous `sncfdevelopers` et gagne un second contributeur ;
- ou `surdesrails` devient joignable sans VPN (registre npm public, ou forge publique).

## Open Questions

- La méthode n'a pas encore de version publiée hors de la forge interne : quand en aura-t-elle une ?
