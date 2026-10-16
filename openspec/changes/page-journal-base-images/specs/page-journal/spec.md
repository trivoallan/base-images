# Spec Delta

## Purpose

Rendre lisibles, depuis une URL publique et sans le mainteneur, les décisions du journal de criblage et les reports `regis` qui les fondent.

## ADDED Requirements

### Requirement: Publication après chaque criblage
Le dépôt MUST être publié sur GitHub Pages après chaque run `screening` réussi sur `main` qui n'a pas été déclenché par une pull request, et à la demande. La publication SHALL inclure le journal, les reports, une liste des journaux publiés et la correspondance entre chaque `ruleset` et sa source, sans autre transformation du contenu du dépôt.

#### Scenario: Criblage réussi sur main
- **WHEN** un run `screening` déclenché par le planning ou à la demande se termine avec succès sur `main`
- **THEN** la page publiée montre les lignes de journal que ce run a commitées, sans action humaine

#### Scenario: Criblage d'une pull request
- **WHEN** un run `screening` se termine sur une pull request (mode `judge`)
- **THEN** rien n'est publié

#### Scenario: Publication à la demande
- **WHEN** le mainteneur lance la publication à la main
- **THEN** l'état courant de `main` est publié

### Requirement: Liste des décisions
La page MUST afficher toutes les lignes de tous les journaux publiés, une ligne par décision, triées par date décroissante. Chaque ligne SHALL montrer la date, l'image (`ref`), l'état, la raison, le `ruleset` abrégé et, s'il existe, l'arbitrage (auteur, date, motif).

#### Scenario: Aucune ligne perdue
- **WHEN** l'affichage « tout » est actif
- **THEN** le nombre de lignes affichées est égal au nombre total de lignes des journaux publiés

#### Scenario: Décision arbitrée
- **WHEN** une ligne du journal porte un `arbitration`
- **THEN** son auteur, sa date et son motif s'affichent sur la ligne de cette décision

### Requirement: Refus d'abord
Par défaut, la page MUST n'afficher que les lignes `quarantine` et `inconclusive`, et SHALL offrir une bascule qui affiche toutes les lignes. Une ligne dont l'état n'est pas connu de la page MUST rester visible par défaut.

#### Scenario: Ouverture de la page
- **WHEN** un lecteur ouvre la page sans rien toucher
- **THEN** seules les lignes `quarantine` et `inconclusive` sont visibles, et aucune autre ligne d'un état connu

#### Scenario: État inconnu
- **WHEN** le journal contient une ligne dont l'état est inconnu de la page
- **THEN** cette ligne est visible par défaut, avec son état tel qu'il est écrit

### Requirement: Recherche par image
La page MUST offrir un champ de recherche qui ne garde que les lignes dont l'image (`ref`) contient le texte saisi, sans tenir compte de la casse. La recherche SHALL se combiner avec le filtre par état, et les décomptes du filtre SHALL refléter la recherche.

#### Scenario: Recherche d'une image
- **WHEN** un lecteur saisit `redis` dans le champ de recherche
- **THEN** seules les lignes dont l'image contient `redis` restent visibles, dans le filtre par état choisi

#### Scenario: Recherche vidée
- **WHEN** le champ de recherche est vidé
- **THEN** toutes les lignes du filtre par état choisi réapparaissent

### Requirement: Lien vers les sources du ruleset
Le `ruleset` d'une ligne MUST mener au fichier playbook dont le contenu a produit ce `ruleset`, au commit où ce contenu existe dans le dépôt. Un `ruleset` qu'aucune version d'un playbook du dépôt ne produit MUST s'afficher sans lien.

#### Scenario: Ruleset connu
- **WHEN** un lecteur suit le lien du `ruleset` d'une décision
- **THEN** le playbook s'ouvre sur GitHub, dans la version dont le sha256 est ce `ruleset`

#### Scenario: Ruleset inconnu
- **WHEN** le `ruleset` d'une ligne ne correspond à aucune version d'un playbook du dépôt
- **THEN** il s'affiche abrégé, sans lien

### Requirement: Lien vers le report
Chaque ligne MUST mener au report de sa décision : le `report.html` publié de sa politique et de son `digest` s'il existe, sinon son report Markdown, sinon la mention « pas de report ». Une ligne MUST NOT mener à un lien mort.

#### Scenario: Refus avec report HTML
- **WHEN** un lecteur suit le lien d'une ligne `quarantine` dont le `report.html` est publié
- **THEN** le report s'ouvre rendu en HTML, et non comme du code source

#### Scenario: Décision sans report
- **WHEN** aucun report n'est publié pour une décision
- **THEN** la ligne affiche « pas de report » au lieu d'un lien

### Requirement: Contenu du journal traité comme du texte
La page MUST afficher le contenu du journal comme du texte, jamais l'interpréter comme du HTML, et MUST NOT charger de ressource hors du site publié.

#### Scenario: Motif d'arbitrage contenant du balisage
- **WHEN** le motif d'un arbitrage contient `<script>` ou du balisage HTML
- **THEN** il s'affiche littéralement et rien ne s'exécute

### Requirement: Lisible sur téléphone
La page MUST rester lisible à 375 px de large sans défilement horizontal de la page.

#### Scenario: Écran étroit
- **WHEN** la page est affichée à 375 px de large
- **THEN** la page ne défile pas horizontalement
