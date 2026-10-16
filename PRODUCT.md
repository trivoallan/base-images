# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Primary: Thomas Comtet, sponsor of the pilot, and readers in the same position. They open a public URL to a refused image and must understand why it was refused without the maintainer explaining it (objective O2, « un refus s'explique sans le mainteneur »). First real use: 2026-10-23.

Secondary: the maintainer, following screening outcomes.

## Product Purpose

`base-images` runs the base images of `regis`, `knock` and `uske` (Python, Alpine, Redis) through the gate those three tools form, so the gate does not take its own bases from Docker Hub unjudged. The public page (`index.html`, served on GitHub Pages) makes the decision journal and the `regis` reports readable: success is a refusal that explains itself to someone who was not in the room.

## Positioning

The page shows the gate judging its own tooling's images, with every decision traceable to the `regis` report and the rule that settled it. It reads the committed journal as-is; nothing is summarized or rewritten upstream.

## Operating Context

- A weekly `screening` workflow (and on demand) runs `screen.sh`; it commits `results/<policy>.jsonl` and `results/reports/<policy>/<digest>.{html,md}` to `main`, then `pages` publishes the repo as-is plus a generated `results/index.json`.
- One card per image (key `name:tag`); the head decision is the most recent, then the most severe at equal date. Refusals (`quarantine`) and `inconclusive` come first; everything else is one click away. Filter by image; link to a ruleset's source.
- The journal's `report` field is inconsistent; the page derives report links from policy + digest, falling back to `.md`, then "no report".
- URL moves when the repo transfers to `sncfdevelopers` (by 2026-10-30).

## Capabilities and Constraints

- Single `index.html`, no build, no dependencies: native HTML/CSS/JS.
- Strict CSP (`default-src 'self'`; inline script and style for this file only): no external fonts, CDNs, or resources.
- Relative paths only, so the page can be served outside Pages (later copy to the SNCF cluster).
- French only, no i18n.
- Journal data is rendered with `textContent`/`createElement`, never `innerHTML`.
- The page adapts to the journal format; it never requires changes in `regis`, `knock` or `uske`.

## Brand Commitments

None. Neutral tool page, no SNCF identity, even after the transfer to `sncfdevelopers`. Voice: plain French, as in the README.

## Evidence on Hand

Real journal lines in `results/*.jsonl` and real `regis` reports in `results/reports/`. No testimonials or usage figures exist; do not invent any.

## Product Principles

1. A refusal must explain itself: the why and the deciding rule are reachable from the first screen.
2. Show the journal as it is; adapt the page, never the data.
3. Nothing to build, nothing to fetch from elsewhere.
4. Refusals and doubts lead; the rest stays one click away.
