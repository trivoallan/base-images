---
name: Journal des décisions
description: The public register of what the base-images gate refused or placed, image by image.
colors:
  paper: "#fbfbfa"
  sheet: "#ffffff"
  ink: "#1b1b1a"
  pencil: "#6b6a66"
  rule-line: "#e3e2de"
  link-blue: "#1d4ed8"
  refus-red: "#b42318"
  refus-wash: "#fdecea"
  doute-amber: "#9a5b00"
  doute-wash: "#fff4e0"
  transfo-yellow: "#766000"
  transfo-wash: "#fbf3cc"
  ok-green: "#1e6b37"
  ok-wash: "#e8f4ec"
  autre-graphite: "#3d3c39"
  autre-wash: "#ecebe8"
  paper-dark: "#161615"
  sheet-dark: "#1d1d1c"
  ink-dark: "#ecebe8"
  pencil-dark: "#9b9a95"
  rule-line-dark: "#2e2d2b"
  link-blue-dark: "#8fb3ff"
  refus-red-dark: "#ff8f84"
  refus-wash-dark: "#3a1714"
  doute-amber-dark: "#ffc266"
  doute-wash-dark: "#352610"
  transfo-yellow-dark: "#f2d14b"
  transfo-wash-dark: "#2e2a10"
  ok-green-dark: "#86d29b"
  ok-wash-dark: "#14301d"
  autre-graphite-dark: "#d6d4cf"
  autre-wash-dark: "#2a2928"
typography:
  headline:
    fontFamily: "system-ui, sans-serif"
    fontSize: "1.5rem"
    fontWeight: 700
    letterSpacing: "-0.01em"
  title:
    fontFamily: "system-ui, sans-serif"
    fontSize: "1.15rem"
    fontWeight: 650
  body:
    fontFamily: "system-ui, sans-serif"
    fontSize: "16px"
    lineHeight: 1.5
  meta:
    fontFamily: "system-ui, sans-serif"
    fontSize: "0.85rem"
  label:
    fontFamily: "system-ui, sans-serif"
    fontSize: "0.8rem"
    fontWeight: 600
rounded:
  card: "6px"
  pill: "999px"
spacing:
  xs: "0.25rem"
  sm: "0.5rem"
  md: "0.75rem"
  lg: "1rem"
  xl: "1.25rem"
components:
  button-report:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.paper}"
    rounded: "{rounded.card}"
    padding: "0 1rem"
    height: "44px"
  filter-pill:
    backgroundColor: "{colors.sheet}"
    textColor: "{colors.ink}"
    rounded: "{rounded.pill}"
    padding: "0 1rem"
    height: "44px"
  filter-pill-pressed:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.paper}"
  decision-card:
    backgroundColor: "{colors.sheet}"
    rounded: "{rounded.card}"
    padding: "1rem 1rem 0.75rem"
  status-pill-refus:
    backgroundColor: "{colors.refus-wash}"
    textColor: "{colors.refus-red}"
    rounded: "{rounded.pill}"
    padding: "0.1rem 0.55rem"
    typography: "{typography.label}"
---

# Design System: Journal des décisions

## Overview

**Creative North Star: "Le registre du greffe"**

The page is a court clerk's register of decisions. Each entry is a dated act that a third party can consult without anyone narrating it. The page is a neutral working tool. It is plain, legible and dense enough to scan, and it makes no visual claims of its own. Everything rests on one sheet of warm off-white paper, set in the platform's own sans. The only colour on the page is the colour of a verdict.

The interface stays out of the way of the record. Hierarchy comes from weight, position and one filled button per entry, not from decoration. Light and dark themes follow the reader's system and are full token sets, not inversions. The page is one static file under a strict CSP, so it uses no web fonts, images or external assets. The system works with what the browser already has.

**Key Characteristics:**
- One column, 52rem wide, read top to bottom.
- Flat sheets on paper. Depth comes from hairline rules, never from shadows.
- Colour carries state and nothing else: refusal, doubt, transformation, placement, other.
- The platform sans is used throughout, with weight steps rather than font changes.
- Controls are discreet and precise. The single filled control on a card is the report.

## Colors

A warm-neutral paper-and-ink palette with five state hues, each paired with a pale wash. Every value has a dark-theme twin.

### Primary
- **Ink** (`ink`): text, and the fill of the one primary action (the report button) and of a pressed filter. Ink is the accent: the page has no brand hue.

### Neutral
- **Paper** (`paper`): page background, and the text colour on ink fills.
- **Sheet** (`sheet`): card and control surfaces, one step lighter than paper.
- **Pencil** (`pencil`): secondary text, such as timestamps, references, history toggles, placeholders and empty states.
- **Rule Line** (`rule-line`): borders, dividers and card outlines.
- **Link Blue** (`link-blue`): inline links and focus rings.

### State
- **Refus Red / Refus Wash** (`refus-red`, `refus-wash`): a refused image (`quarantine`).
- **Doute Amber / Doute Wash** (`doute-amber`, `doute-wash`): `inconclusive`.
- **Transfo Yellow / Transfo Wash** (`transfo-yellow`, `transfo-wash`): `transformation-required`, meaning the image must be rebuilt before it is placed. It is a yellow ochre, kept distinct from the orange of doubt.
- **OK Green / OK Wash** (`ok-green`, `ok-wash`): `direct-placement`.
- **Autre Graphite / Autre Wash** (`autre-graphite`, `autre-wash`): any unknown or hand-written state.

### Named Rules
**The Verdict-Only Colour Rule.** A state hue appears only where it names a decision's state: the status pill and the card's state rule. No hue is used for emphasis, decoration or branding.

**The Twin Rule.** Every colour token has a dark twin (`*-dark`) tuned for contrast on `sheet-dark`. A new colour ships with both values or not at all.

## Typography

**Body Font:** system-ui (with sans-serif fallback)

**Character:** the platform's own sans at every level. It loads nothing and so stays within the CSP, and it reads as an instrument rather than a publication.

### Hierarchy
- **Headline** (700, 1.5rem, -0.01em): the page title, used once.
- **Title** (650, 1.15rem): an image's `name:tag` at the head of its card. It wraps anywhere, because tags are long.
- **Body** (400–500, 16px, 1.5): the reason and the deciding rule. The current reason is set at 500 weight; reasons in the history are set at 400.
- **Meta** (0.85rem, pencil): timestamps (with "UTC"), ruleset, image reference and the regis message.
- **Label** (600, 0.8rem): status pills.

### Named Rules
**The Code-Is-Data Rule.** Monospace (`code`) is used only for raw machine values, such as a reason code, a rule or a ruleset hash. A code whose meaning is known carries its French explanation in an explanation tip.

## Layout

There is a single centred column, max 52rem, with 1.5rem / 1rem / 3rem page padding. Cards stack in a grid with a 0.75rem gap. Card padding is 1rem 1rem 0.75rem, and lines inside a card are separated by 0.35rem. The filter bar wraps freely. From 40rem up it sticks to the top of the viewport; below that width it scrolls away so it does not take over a phone screen. Every interactive target is at least 44px tall. Long references wrap anywhere rather than scroll sideways.

## Elevation & Depth

The page is flat, with no shadows anywhere. Depth is a two-step tone change, from paper to sheet, plus a 1px rule-line outline. A card's history sits behind a hairline divider inside the same sheet, never on a nested card.

**The Flat Register Rule.** Surfaces never lift. Separation comes from a tone step and a hairline, as on a printed register.

## Shapes

Corners are slightly softened at 6px on cards and on the report button. Filter controls and status pills are fully rounded. Each card carries a 4px state rule on its left edge in the state hue, the one place where colour touches structure.

## Components

### Buttons
- **Report (primary):** an ink fill with paper text, 6px corners, 44px tall, 0 1rem padding, 600 weight. There is one per card, and it opens the report whose verdict caused the decision. It stays a button even when only the `.md` report exists.
- **Secondary links:** underlined link-blue text, such as "rapport de la source" and the history "rapport".

### Chips
- **Filter pills:** sheet background, rule-line border, ink text, 44px, fully rounded. When pressed (`aria-pressed="true"`) they invert to an ink fill with paper text. Each label carries a live count, as in "Refus et inconclusive (11)".
- **Status pills:** the state hue on its wash, 0.8rem at 600, fully rounded. Screen readers hear them prefixed with "Statut :".

### Cards / Containers
- **Decision card:** a sheet with a rule-line outline, 6px corners and the left state rule. The face says what and why:
  1. The `name:tag`, the status pill, then any proof badges ("Transformée", "Réparée").
  2. Why: "Bloqué par :" and the rule that still fails, for an image refused after a rebuild; otherwise "Raison :" and the reason code. Each code carries an explanation tip.
  3. The single report button.
  4. A "Détails et historique" disclosure: the rail (see below), then the meta line (time, policy link, ruleset link, reference). The source's report is reached from its point in the rail.

**The Two-Line Face Rule.** Below the title, a card face carries one line of why and one button. Everything else goes in "Détails et historique".

### Rail (decision history)
- A vertical 2px rule-line thread with one dot per decision, oldest first, in the state hue. A 3px sheet halo detaches each dot from the thread.
- Each entry names who was judged, in 600 weight: "Source jugée", "Reconstruction jugée" (line with `source`), "Source close" (line with `rebuilt`) or "Source rouverte". The time follows in pencil (« 16/10 17:46 UTC »), then the status pill. Below, in pencil 0.85rem: the reason code, the reference and a "rapport" link.
- A placement line (`placed`, uske 0.8.0) is a green "Placée" dot with no status pill: it records the digest written, not a verdict, and its state only copies the source's. The card's status comes from the last verdict, never from a placement line.
- At the same second, a rebuild's judgment comes before its source's closing line.
- "Reconstruite par knock" is a hollow dot with no time, just before the first rebuild, naming the policy and the transit. The journal implies this step but does not date it.

### Proof badges
- "Transformée" and "Réparée" sit after the status pill. They are outlined in rule-line with pencil text and no fill, so they never compete with the state colour.
- A badge appears only on journal evidence: a `source` or `rebuilt` line for Transformée; an `epoch` on a held image, or `uske/remediation-refused`, for Réparée.
- Hover, focus or tap opens an explanation tip listing the steps the policy declares, one per line (code, then its French reading).

### Explanation tip
- A 24px round "?" button with a rule-line outline and pencil text, next to a code. Its hit area extends 10px beyond the visible circle.
- On hover, keyboard focus or tap, it shows an ink bubble with paper text, 6px corners and 0.9rem type. The bubble holds the French explanation and, when there is one, the regis message.
- It is the only ink surface besides the report button, and it never holds an action.

### Inputs / Fields
- **Search:** shares the filter-pill shape. Its placeholder is set in pencil, and its focus is a 2px link-blue outline offset by 2px.

### Empty state
- Centred pencil text that says why the list is empty, followed by one pill button that resolves it: "Tout afficher (N)" or "Effacer la recherche".

## Do's and Don'ts

### Do:
- **Do** keep colour to state: a new state gets a hue, a wash and their dark twins.
- **Do** give every card exactly one ink-filled button.
- **Do** show raw machine values in `code`, with their French reading one hover, focus or tap away.
- **Do** keep targets at 44px or taller and the focus ring at 2px link-blue.

### Don't:
- **Don't** load fonts, images, icons or scripts from anywhere. The CSP is `default-src 'self'`.
- **Don't** add shadows or nest cards. Depth is a tone step and a hairline.
- **Don't** use a state hue for emphasis, headings or links.
