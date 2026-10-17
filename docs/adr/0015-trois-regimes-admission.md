---
adr: "0015"
slug: trois-regimes-admission
title: Trois régimes d'admission, rebuild, copy et product
status: accepted
date: 2026-10-17
authors: [Tristan Rivoallan]
supersedes: []
---

# Trois régimes d'admission, rebuild, copy et product

## Context and Problem Statement

Ce dépôt fait passer par la porte de regis, knock et uske toutes les images que ces trois outils
tirent : des bases à paquets, des images sans shell d'où l'on copie un binaire, et les trois outils
eux-mêmes. Un seul playbook les jugeait toutes de la même façon, alors qu'une image sans gestionnaire
de paquets ne peut pas être réparée par knock, et qu'une image maison se répare en amont, dans son
dépôt. Depuis uske 0.10.0, le dépôt nomme lui-même ses régimes : `<playbooks>/<régime>.yaml`.

## Considered Options

- Un seul régime pour toutes les images.
- Deux régimes : `rebuild` (réparable) et `copy` (copié tel quel).
- Trois régimes : `rebuild`, `copy` et `product`.

## Decision Outcome

Trois régimes, chacun dans un playbook au nom nu (`rebuild.yaml`, `copy.yaml`, `product.yaml`),
versionné par `app.kubernetes.io/version`. Une image va en `product` si et seulement si regis, knock
ou uske la publie ; sinon en `rebuild` si elle a un gestionnaire de paquets pour lequel le screening
déclare un miroir ; sinon en `copy`. `product` exige en plus une signature keyless vérifiée de la CI
de release de l'outil.

### Consequences

- Une nouvelle image se range par la règle, sans débat ; changer de régime, c'est changer son
  `admission-track`.
- Déclarer un miroir (par exemple `apt`) fait passer des images de `copy` à `rebuild` : c'est une
  évolution de régime, à porter par un change.
- Le journal rattache chaque décision au `ruleset` exact qui l'a rendue ; un `-v2` dans le nom d'un
  régime n'existe que pour une règle à appliquer policy par policy.
- Le change `policies-outillage` porte le détail : `openspec/changes/policies-outillage/design.md`.

## Pros and Cons of the Options

- Un seul régime : simple, mais il répare ce qui ne se répare pas, ou ne répare rien.
- Deux régimes : juge les outils maison comme une image tierce, sans exiger leur signature.
- Trois régimes : un playbook de plus à tenir, contre un seuil juste pour chaque origine.
