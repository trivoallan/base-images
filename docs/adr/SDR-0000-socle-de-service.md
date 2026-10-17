---
adr: SDR-0000
slug: socle-de-service
title: Socle de service
status: rejected
revision: 1
date: 2026-10-17
authors: [Tristan Rivoallan]
supersedes: []
---

# Socle de service

> **Qu'est-ce que ce fichier ?** Un ADR — *Architecture Decision Record* — est une décision consignée : son contexte, les options pesées, ce qui a été retenu, et ce que ça coûte. **Tant qu'il porte `status: proposed`, il s'écrit et se corrige librement.**
>
> **La ligne `revision:` de l'en-tête date la question, pas le fichier.** Elle n'avance que si la question posée ici change — jamais pour une reformulation, une coquille ou un lien réparé. Vous ne la remplissez pas : elle arrive avec le fichier, et votre verdict lui reste attaché. Elle existe pour qu'on reconnaisse, plus tard, un verdict rendu contre une question qui a depuis bougé.
>
> **`rejected` est une réponse pleine, pas un abandon.** Quand la question ne se pose pas dans ce dépôt, l'ADR reçoit le verdict `rejected` avec son motif, et le bloc `traits:` disparaît en entier — une clé sans objet ne se laisse pas vide. Le motif dit alors **ce qui en tient lieu**, pour qu'un agent qui le lit sache à quoi s'en tenir. **Un ADR `rejected` sans bloc `traits:` passe la vérification** — c'est mesuré, pas supposé.

## Context and Problem Statement

**Ce fichier suppose un receveur interne à e.SNCF** : un dépôt qui a accès au référentiel Aresis, et dont les processus s'insèrent dans ceux de l'entité. C'est pourquoi les principes ci-dessous renvoient à l'entité, à Aresis, au PI planning et aux processus ITIL comme à des choses qui existent déjà autour du dépôt : les gloses qui les accompagnent disent ce que les mots veulent dire, elles ne donnent pas accès à ce qu'ils nomment. **Un dépôt hors de ce périmètre n'a pas de réponse à la question posée** — ni identifiant à écrire, ni route `rejected` qui le décrive, puisque celle-ci dit « ce dépôt ne produit aucune métrique FinOps » et non « ce dépôt n'est rattachable à rien ». Ce n'est pas un oubli qu'on réparera : c'est une limite de ce fichier, écrite ici pour qu'elle se reconnaisse tout de suite plutôt qu'au moment de statuer.

**Concrètement, ce que statuer change.** Tant que la clé `socle.aresis` est vide, les métriques FinOps — celles qui rapportent une consommation d'infrastructure à ce qu'elle coûte, et à qui la consomme — que ce dépôt expose ne sont rattachées à rien. Elles s'affichent, personne ne les facture, et le principe 3 ci-dessous — « Ce qui ne se mesure pas ne se pilote pas et ne se facture pas. » — reste lettre morte dans ce dépôt précisément.

**Les huit principes qui suivent ne sont pas la question.** Ils sont prescrits, ils ne se négocient pas, et un verdict `rejected` les laisse entiers : ce qu'un tel verdict refuse est la question du rattachement, jamais le socle. Ils viennent du cadrage stratégique du service conteneurisation e.SNCF, document que vous ne recevez pas — c'est pourquoi ils sont écrits ici en toutes lettres plutôt que cités.

1. **Autonomie client d'abord.** Chaque service est conçu pour être consommé en self-service. Le ratio humain/namespace — un namespace étant l'espace cloisonné qu'un client occupe dans un cluster Kubernetes — baisse à chaque release. Un client n'a jamais besoin de l'équipe pour une opération courante.
2. **CNCF graduated ou rien.** La CNCF est la Cloud Native Computing Foundation, qui classe les projets qu'elle héberge par maturité croissante : sandbox, puis incubating, puis graduated. Un projet CNCF graduated ou incubating passe avant tout développement spécifique. Le spécifique ne s'écrit que là où aucun projet open-source ne couvre le besoin, et son motif s'écrit. Un besoin non couvert par un projet retenu se traite en contribution amont, jamais en fork.
3. **Observable, auditable, facturable.** Tout composant expose des métriques Prometheus, des logs structurés, des traces OpenTelemetry **et** des métriques FinOps. Les quatre, pas trois. Ce qui ne se mesure pas ne se pilote pas et ne se facture pas.
4. **Le run commande le build.** Le run est l'exploitation de ce qui tourne ; le build, le développement de ce qu'on y met. Chaque décision de conception s'évalue à son impact sur l'exploitabilité. Une fonctionnalité qui dégrade le run ne passe pas, même demandée. L'IA-SRE — l'IA appliquée au diagnostic d'exploitation — est un accélérateur, pas un pansement.
5. **Compatible ITIL sans rupture.** ITIL est le référentiel de gestion des services informatiques. Les processus s'insèrent dans ceux de l'entité e.SNCF — changements, incidents, problèmes — sans rupture de séquence. Un processus spécifique est documenté, interopérable, et connu du PI planning — la cérémonie où les équipes techniques planifient leur incrément.
6. **Edge-ready par design.** Aucune dépendance dure à un control plane centralisé pour le runtime — le control plane étant la couche qui pilote et orchestre les charges, par opposition à celle qui les exécute. Toute architecture supporte un fonctionnement dégradé hors datacenter et hors cloud.
7. **Conduite du changement intégrée.** Les clients late majority — ceux qui n'adoptent une technologie qu'une fois qu'elle est éprouvée par d'autres — n'adoptent pas par curiosité. Chaque évolution technique est accompagnée — documentation, chemin de migration, valeur démontrée — **avant** de couper l'ancien.
8. **IA comme levier transverse.** L'IA assiste le diagnostic (run), le développement (build) et la maintenance (MCO, le maintien en condition opérationnelle). C'est un levier sous chaque axe, pas un projet à part. Elle propose, analyse et accélère ; la décision et la responsabilité restent humaines. Un outil d'IA s'accompagne avant de se déployer : former, expliquer, laisser le droit à l'essai et à l'erreur. Chaque outil d'IA employé sur ce dépôt est nommé par écrit, avec ce qu'on lui confie, dans son README ou là où ce dépôt consigne ses outils — à commencer par l'agent qui conduit le cycle de cette méthode. Son usage est sobre. Quand elle tourne dans le service, sa consommation et son coût se mesurent comme ceux de tout composant (principe 3) ; quand elle assiste le développement, aucun de ces instruments ne les mesure. Son empreinte environnementale compte aussi, et aucun des quatre instruments du principe 3 ne la mesure encore.

**Ce qui vous revient est le rattachement, et lui seul.** Aresis est le référentiel qui porte la facturation. Un dépôt qui expose des métriques FinOps y est rattaché par un identifiant, et la méthode ne peut pas le connaître : il dépend de votre produit, de votre périmètre et de votre centre de coût.

**Un dépôt qui ne facture rien rend `rejected`** — avec son motif, et en disant ce qui en tient lieu. Une clé laissée vide n'est pas une réponse ; `rejected` en est une.

## Considered Options

* **Écrire l'identifiant de rattachement Aresis** — les métriques exposées sont facturables, et le principe 3 est tenu de bout en bout.
* **Exposer les métriques sans les rattacher** — elles s'observent, elles ne se facturent pas. C'est un `accepted` à moitié tenu : une clé laissée vide, le contrôle décrit plus bas l'attrape ; une clé remplie d'un identifiant faux ou périmé, non — rien ne confronte la valeur au référentiel.
* **`rejected`** — ce dépôt ne produit aucune métrique FinOps parce qu'il ne sert aucun client facturable. Réponse pleine, à condition d'écrire ce qui en tient lieu.

## Decision Outcome

**La réponse que la méthode propose, et ses motifs.**

| Clé | Valeur proposée | Motif |
| --- | --- | --- |
| `socle.aresis` | *l'identifiant de rattachement de ce dépôt* | la méthode ne peut pas le connaître. Elle sait seulement qu'un dépôt qui expose des métriques FinOps en a un, et qu'une métrique rattachée à rien n'est facturable par personne |

**Où le trouver — et ce que ce fichier ne sait pas.** La méthode ne connaît ni l'équipe qui attribue les identifiants Aresis, ni le canal pour le demander, ni la forme d'un identifiant valide : elle ne transporte ni annuaire, ni convention de nommage. **C'est une limite assumée, pas un oubli** : la route change d'une entité à l'autre, et une route écrite ici serait fausse ailleurs sans que rien ne le dise. Demandez l'identifiant à la personne qui tient le périmètre de ce dépôt — celle qui sait à quel centre de coût il est rattaché —, et écrivez ce qu'elle vous donne, tel quel.

**Statué `rejected`** (répondue le 2026-10-17). base-images est un dépôt personnel et public, qui n'expose aucune métrique FinOps : il n'a pas d'identifiant ARESIS, et rien n'en tient lieu.

### Consequences

Aucun rattachement n'est exigé de ce dépôt, et aucune métrique ne lui sera imputée. Si le dépôt passe sous une organisation qui facture, la question se repose dans un nouvel ADR.

## More Information

`socle.aresis` est une chaîne libre : l'identifiant de rattachement de ce dépôt dans Aresis. La méthode ne ferme pas d'ensemble de valeurs, parce qu'elle ne connaît pas le référentiel.

**Une clé laissée vide n'est pas une réponse** — celle-ci est exigée. Vous n'avez pas à le vérifier à l'œil. Depuis la racine de votre dépôt :

```bash
( cd docs/adr && npx @jackchuka/mdschema@0.15.1 check '*.md' )
```

**Si votre dépôt n'a ni Node ni `npm`, cette ligne ne vous sert à rien**, et le dire vaut mieux que le supposer. **Elle peut aussi échouer alors que Node est là.** Mesuré le 2026-09-20 sur macOS arm64, avec `npm` 10.9.8 puis 11.6.0 : `npx` rend `sh: mdschema: command not found`, parce que `npm` n'installe pas le lien du binaire — sur un répertoire neuf, avec `bin-links` à `true` et `ignore-scripts` à `false`. Le paquet est pourtant posé, sa dépendance de plateforme aussi, et son point d'entrée existe.

Dans les deux cas, `mdschema` est un binaire autonome : prenez-le dans les *releases* de [son dépôt](https://github.com/jackchuka/mdschema) et lancez `mdschema check '*.md'` depuis ce répertoire. **C'est le chemin sûr**, et non un repli de second choix. La ligne ci-dessus n'est qu'un raccourci, qui évite d'installer quoi que ce soit — quand il fonctionne.

Le schéma qu'elle applique est le `.mdschema.yml` de ce même répertoire, posé par la méthode. Elle nomme, fichier par fichier : une clé restée vide, une valeur hors de l'ensemble admis, un `status:` resté `proposed`, une `date:` absente, et le mode d'emploi qu'on aurait oublié de supprimer. **Elle reconnaît ce dernier à sa première phrase**, pas au tableau : le tableau a le droit de rester, et le garder ne déclenche rien. Elle ne juge pas votre décision — seulement qu'elle est prise.
