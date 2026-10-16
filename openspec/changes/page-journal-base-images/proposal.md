# Proposal

## Why

Le criblage de ce dépôt commite déjà le journal (`results/*.jsonl`) et les reports `regis` (`results/reports/<policy>/<digest>.html`), mais rien ne se lit sans le mainteneur. Sur github.com, le journal reste un JSONL brut et un `report.html` s'affiche comme du code source. Le 2026-10-23, un refus réel doit pouvoir être ouvert depuis une URL publique par Thomas Comtet, le commanditaire, sans que le mainteneur le raconte (roadmap du pilote, item 1 ; O2, « un refus s'explique sans le mainteneur »).

## What Changes

- Le dépôt est publié tel quel sur GitHub Pages après chaque criblage `apply` réussi sur `main`, et à la demande. Il n'y a pas de build : le workflow ajoute seulement `results/index.json`, la liste des journaux.
- Une page `index.html` à la racine lit les journaux et affiche une table des décisions, par date décroissante. Elle montre d'abord les refus (`quarantine`) et les `inconclusive`, avec une bascule « tout ». Chaque ligne mène au `report.html` de sa décision.
- Le README gagne une section « Page ».
- Rien ne change dans `regis`, `knock` ou `uske`, ni dans le format du journal : la page s'adapte au journal tel qu'il est.

## Capabilities

### New Capabilities
- `page-journal` : la publication du journal et des reports sur Pages, et la page qui les rend lisibles (liste, filtre par état, lien vers le report, arbitrage).

### Modified Capabilities

## Impact

- Fichiers ajoutés : `index.html`, `.github/workflows/pages.yml`.
- Fichiers modifiés : `README.md`, `.github/settings.json` (`homepage`), `Makefile` (cible `pages` : activation de Pages, source GitHub Actions).
- Exposition : le journal et les reports deviennent consultables sur `https://trivoallan.github.io/base-images/`. Ils étaient déjà publics dans le dépôt, et ne concernent que des images publiques. L'URL changera au transfert vers `sncFdevelopers`.
- Aucune dépendance ajoutée : HTML, CSS et JS natifs, actions GitHub officielles (`upload-pages-artifact`, `deploy-pages`).
