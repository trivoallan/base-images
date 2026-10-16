# Tasks

## 1. Publication sur Pages

- [x] 1.1 Ajouter `.github/workflows/pages.yml` : `workflow_run` sur `screening` (`main`, conclusion `success`, événement autre que `pull_request`) et `workflow_dispatch`. Il génère `results/index.json`, la liste des noms de politiques tirée de `results/*.jsonl`, puis appelle `upload-pages-artifact` et `deploy-pages`, avec les permissions `pages: write` et `id-token: write`. Vérification : `actionlint` passe sur le fichier.
- [x] 1.2 Activer Pages (source GitHub Actions) par une cible `make pages` idempotente (pas dans `.github/apply-settings.sh`, qui est un fichier du socle identique dans regis, knock et uske), et renseigner `homepage` dans `.github/settings.json`. Vérification : relancer `make pages` deux fois de suite n'échoue pas, et `gh api repos/trivoallan/base-images/pages` renvoie `build_type: workflow`.
- [x] 1.3 Lancer `pages.yml` à la main. Vérification : `https://trivoallan.github.io/base-images/results/index.json` liste les 3 politiques.

## 2. Page du journal

- [x] 2.1 Écrire `index.html` à la racine (HTML, CSS et JS natifs, CSP en `<meta>`). La page lit `results/index.json` puis chaque journal, et affiche la table triée par date décroissante (date, `ref`, état, raison, `ruleset` abrégé, arbitrage), le tout en `textContent`. Vérification : servie en local avec `python3 -m http.server`, la page affiche 58 lignes en mode « tout » (total au 2026-10-16).
- [x] 2.2 Ajouter le filtre : `quarantine` et `inconclusive` par défaut, une bascule « tout », et un état inconnu toujours visible. Vérification : en local, 13 lignes par défaut, 58 en « tout », et une ligne de test à l'état inventé reste visible par défaut.
- [x] 2.3 Ajouter le lien du report : `results/reports/<policy>/<digest>.html`, avec repli vers le `.md` puis « pas de report », vérifié par `HEAD`. Vérification : en local, les 12 `quarantine` ont un lien `.html` qui répond 200, et la ligne `uske/reopened` affiche « pas de report ».
- [x] 2.4 Vérifier le traitement en texte et la largeur. Vérification : un motif d'arbitrage `<script>alert(1)</script>` injecté dans une copie locale du journal s'affiche littéralement, et à 375 px la page ne défile pas horizontalement.
- [x] 2.5 Ajouter une section « Page » au README (URL, ce que la page montre, publication sans build, déclenchement). Vérification : la section existe et l'URL du README est celle de `homepage`.

## 3. Recherche et sources du ruleset

- [x] 3.1 Dans `pages.yml`, récupérer tout l'historique et générer `results/rulesets.json` : pour chaque version de chaque `playbooks/**/playbook.yaml`, son sha256 vers l'URL GitHub du fichier à ce commit. Vérification : en local, le script donne `sha256:589dd893…` vers `playbooks/version/playbook.yaml`.
- [x] 3.2 Ajouter le champ de recherche sur l'image, combiné au filtre par état, avec des décomptes qui en tiennent compte. Vérification : en local, `redis` ne garde que des lignes Redis, et vider le champ rend toutes les lignes.
- [x] 3.3 Rendre le `ruleset` cliquable quand `rulesets.json` le connaît, sans lien sinon. Vérification : en local, les 57 lignes dont le `ruleset` est un hash ont un lien vers `playbooks/version/playbook.yaml` (la ligne `uske/reopened` porte `none`), et un `ruleset` inventé reste sans lien.

## 4. Regroupement par image

- [x] 4.1 Réécrire la page en une carte par image (`nom:tag`) : décision de tête (la plus récente, puis la plus grave), pastille d'état, raison, métadonnées discrètes, bouton « Ouvrir le rapport » de 44 px, et historique repliable. Vérification : en local, 12 images par défaut (11 refus plus une ligne piège), 20 en « tout », 59 décisions rendues, `redis:7.2.9` en tête « Refusée », sans défilement horizontal à 375 px, en thème clair comme sombre.

## 5. Vérification publiée

- [ ] 5.1 Après publication, sur `https://trivoallan.github.io/base-images/` : ouvrir la page sans session GitHub, cliquer sur chacun des 12 refus (12/12 `report.html` rendus, aucune 404), et vérifier que le criblage suivant sur `main` republie la page sans action humaine. Vérification : la note est ajoutée sur la PR avant le 2026-10-22.
