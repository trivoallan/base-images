#!/usr/bin/env bash
# Un screening : les étapes du WorkflowTemplate `uske-screening` (uske/deploy/base), dans le même
# ordre, chacune dans le conteneur publié de son outil. Rien ici ne juge ni ne place : uske, regis
# et knock le font ; ce script ne fait que les enchaîner, comme Argo le fait ailleurs.
#
#   SCREEN_MODE=judge   plan et jugement seulement : rien n'est consigné, rien n'est placé (les PR)
#   SCREEN_MODE=apply   le screening complet ; le journal est commité AVANT tout placement
#
# Entrées : REGIS_IMAGE, KNOCK_IMAGE, USKE_IMAGE ; KNOCK_* pour knock ; REGISTRY_HOST,
# REGISTRY_USER, REGISTRY_PASSWORD pour que regis lise le transit ; TRANSIT, le nom de
# KNOCK_REGISTRIES où les images réparées attendent leur jugement ; GRYPE_CACHE, un dossier hôte.
set -euo pipefail

MODE="${SCREEN_MODE:-judge}"
REPO="$(cd "$(dirname "$0")" && pwd)"
RESULTS="$REPO/results"
W="$(mktemp -d)"
GRYPE_CACHE="${GRYPE_CACHE:-$W/grype}"
TRANSIT="${TRANSIT:-transit}"
# Le screening qui juge, nommé sur chaque ligne du journal (SDR-0018 d'uske) : l'URL du run GitHub
# Actions ; vide en local, et la ligne n'en porte pas.
RUN="${GITHUB_RUN_ID:+$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID}"
# L'epoch des ordres de réparation : le début du screening, en UTC. Écrit dans le RUN de la
# réparation, il empêche un screening de réutiliser la couche d'une mise à jour antérieure.
EPOCH="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$RESULTS" "$GRYPE_CACHE"
# Les trois images ne tournent pas sous l'utilisateur du runner.
chmod -R a+rwX "$W" "$RESULTS" "$GRYPE_CACHE"

mounts=(-v "$REPO:/repo:ro" -v "$W:/work" -v "$RESULTS:/results")

uske() { docker run --rm "${mounts[@]}" "$USKE_IMAGE" "$@"; }

knock() {
  # --plan-out, --staged-out et --applied-out ne créent pas leur dossier parent.
  mkdir -p "$W/plans" "$W/staged" "$W/applied" && chmod a+rwX "$W/plans" "$W/staged" "$W/applied"
  docker run --rm --network host "${mounts[@]}" \
    -v "$HOME/.docker:/tmp/.docker:ro" \
    -e KNOCK_REGISTRIES -e BUILDKIT_HOST -e KNOCK_TRANSFORM_PACKAGE_MIRRORS \
    -e KNOCK_SBOM_FORMATS -e KNOCK_ATTEST_SIGNER -e KNOCK_LOG_FORMAT=text \
    -e KNOCK_ATTEST_VERIFY_IDENTITY -e KNOCK_ATTEST_VERIFY_OIDC_ISSUER \
    -e ACTIONS_ID_TOKEN_REQUEST_URL -e ACTIONS_ID_TOKEN_REQUEST_TOKEN \
    "$KNOCK_IMAGE" "$@"
}

regis() {
  local auth=()
  [ -n "${REGISTRY_USER:-}" ] && auth=(--auth "$REGISTRY_HOST=$REGISTRY_USER:$REGISTRY_PASSWORD")
  docker run --rm "${mounts[@]}" -v "$GRYPE_CACHE:/cache/grype" -e GRYPE_DB_CACHE_DIR=/cache/grype \
    "$REGIS_IMAGE" "$@" "${auth[@]}"
}

# Le journal d'abord, le placement ensuite : une image n'est jamais placée sans sa décision écrite.
commit_journal() {
  [ "$MODE" = apply ] || return 0
  git -C "$REPO" add results
  git -C "$REPO" diff --cached --quiet && return 0
  git -C "$REPO" commit -q -m "$1"
  # main a pu avancer pendant le screening (une PR fusionnée) : seul ce script écrit results/.
  git -C "$REPO" pull -q --rebase
  git -C "$REPO" push -q
}

# evaluate POLICY PLAYBOOK LINES ITEM_JSON [TRACK] : un digest, jugé par regis, classé par uske.
# TRACK, le régime, marque un refus réparable à la première porte.
evaluate() {
  local name=$1 playbook=$2 lines=$3 item=$4 track=${5:-}
  local ref digest target key source_ref source_digest epoch rc=0
  ref=$(jq -r .ref <<<"$item"); digest=$(jq -r .digest <<<"$item")
  target=$(jq -r .target <<<"$item"); key=$(jq -r .key <<<"$item")
  source_ref=$(jq -r '.sourceRef // ""' <<<"$item"); source_digest=$(jq -r '.source // ""' <<<"$item")
  epoch=$(jq -r '.epoch // ""' <<<"$item")  # une image tenue : l'ordre sous lequel elle a été réparée
  mkdir -p "$W/$lines/$name" "$W/reports/$key" && chmod a+rwX "$W/$lines/$name" "$W/reports/$key"

  if [ "$playbook" = null ]; then  # régime inconnu : jamais envoyé à regis (D-21)
    uske classify --ref "$ref" --digest "$digest" --run "$RUN" >"$W/$lines/$name/$key.json"
    return
  fi
  echo "::group::regis $target"
  regis analyze "$target" --playbook "$playbook" \
    -D "/work/reports/$key" -o "report.{format}" --html --markdown || rc=$?  # inconclusive, pas perdu (D-23)
  echo "::endgroup::"
  # Le rapport survit au screening, à côté du journal, avant que la ligne qui le cite soit écrite.
  # Le Markdown se lit sur GitHub, et c'est lui que le journal cite ; le HTML garde le détail.
  mkdir -p "$RESULTS/reports/$name"
  for ext in md html; do
    if [ -f "$W/reports/$key/report.$ext" ]; then
      cp "$W/reports/$key/report.$ext" "$RESULTS/reports/$name/$digest.$ext"
    fi
  done
  uske classify --playbook "$playbook" --ref "$ref" --digest "$digest" \
    --report "/work/reports/$key/report.json" \
    --report-link "results/reports/$name/$digest.md" \
    --regis-exit "$rc" --source-ref "$source_ref" --source-digest "$source_digest" \
    --track "$track" --epoch "$epoch" --run "$RUN" \
    | tee "$W/$lines/$name/$key.json"
}

# compose_reports POLICY : chaque rapport Markdown de la policy devient les décisions de toute sa
# famille (`uske decisions` : la source, ses reconstructions, les deux portes) puis le détail de
# regis. Tous sont recomposés à chaque porte : une reconstruction change aussi le rapport de sa
# source et de ses sœurs. La partie regis se retrouve après le marqueur ; un rapport qui vient
# d'être copié n'en a pas encore et se prend en entier.
REGIS_MARK='<!-- regis -->'
compose_reports() {
  local name=$1 f digest end
  for f in "$RESULTS/reports/$name"/*.md; do
    [ -f "$f" ] || continue
    digest=$(basename "$f" .md)
    {
      uske decisions "$digest" --results /results --policy-name "$name" --format md
      printf '\n---\n\n%s\n' "$REGIS_MARK"
      # Sans marqueur : un rapport regis tout juste copié (il commence par « # »), ou un rapport
      # composé avant le marqueur, dont regis suit le premier « --- ».
      if grep -qxF "$REGIS_MARK" "$f"; then end="$REGIS_MARK"; else end='---'; fi
      awk -v end="$end" 'FNR == 1 { raw = ($0 !~ /^## /) } raw { print; next } $0 == end { raw = 1 }' "$f"
    } >"$f.new"
    mv "$f.new" "$f"
  done
}

failed=0
uske list --policies /repo/policies >"$W/list.json"
while read -r policy; do
  name=$(jq -r .name <<<"$policy"); path=$(jq -r .path <<<"$policy")
  echo "::group::$name : plan"
  uske prepare --policy "$path" --out "/work/policies/$name/policy.yaml"
  knock reconcile "/work/policies/$name" --plan-out "/work/plans/$name.json"
  uske pending --policy "$path" --plan "/work/plans/$name.json" --results /results >"$W/pending.json"
  resolved=$(uske resolve --policy "$path" --playbooks /repo/playbooks)
  playbook=$(jq -r .playbook <<<"$resolved"); track=$(jq -r '.track // ""' <<<"$resolved")
  echo "::endgroup::"
  echo "$name : $(jq length "$W/pending.json") digest(s) en attente de décision"

  while read -r item; do evaluate "$name" "$playbook" lines "$item" "$track"; done < <(jq -c '.[]' "$W/pending.json")
  [ "$MODE" = apply ] || continue

  uske record --policy "$path" --results /results --lines "/work/lines/$name"
  compose_reports "$name"
  commit_journal "journal($name): décisions du screening, première porte"

  # Une source à réparer revient avec un ordre ; sans transit, elle est consignée inconclusive.
  mkdir -p "$W/approve-lines" && chmod a+rwX "$W/approve-lines"
  decision=$(uske approve --policy "$path" --results /results --plan "/work/plans/$name.json" \
    --out "/work/plans/$name.approved.json" --transit "$TRANSIT" --epoch "$EPOCH" \
    --lines-out "/work/approve-lines/$name.json" --run "$RUN")
  uske record --policy "$path" --results /results --lines "/work/approve-lines/$name.json"
  approved=$(jq .approved <<<"$decision"); ordered=$(jq .ordered <<<"$decision")
  [ "$approved" -gt 0 ] || continue

  # Copies et transformations seules placées ; les images réparées tenues en transit, qui n'est
  # passé à knock que si le plan porte un ordre. Un build raté ne retient pas les autres.
  stage=()
  [ "$ordered" -gt 0 ] && stage=(--stage-to "$TRANSIT" --staged-out "/work/staged/$name.json")
  knock reconcile "/work/policies/$name" --apply-plan "/work/plans/$name.approved.json" \
    ${stage[@]+"${stage[@]}"} --applied-out "/work/applied/$name.json" || failed=1
  # Le lien source → digest placé, et les ordres que knock n'a pas pu honorer.
  uske record --policy "$path" --results /results --applied "/work/applied/$name.json" --run "$RUN"
  if [ "$ordered" -eq 0 ]; then
    compose_reports "$name"
    commit_journal "journal($name): placements du screening"
    continue
  fi

  # Seconde porte : juger ce que knock a construit, par son propre digest.
  uske pending --policy "$path" --staged "/work/staged/$name.json" --results /results >"$W/staged.json"
  while read -r item; do evaluate "$name" "$playbook" staged-lines "$item"; done < <(jq -c '.[]' "$W/staged.json")
  uske record --policy "$path" --results /results --lines "/work/staged-lines/$name"
  compose_reports "$name"
  commit_journal "journal($name): décisions du screening, seconde porte"

  promoted=$(uske approve --policy "$path" --results /results --staged "/work/staged/$name.json" \
    --out "/work/staged/$name.approved.json" | jq .approved)
  if [ "$promoted" -gt 0 ]; then
    knock promote "/work/policies/$name" --staged "/work/staged/$name.approved.json"
    # Le lien source → digest promu, une fois tout placé (le digest tenu est le digest promu).
    uske record --policy "$path" --results /results --promoted "/work/staged/$name.approved.json" --run "$RUN"
    compose_reports "$name"
    commit_journal "journal($name): promotions du screening"
  fi
done < <(jq -c '.[]' "$W/list.json")

[ "$failed" = 0 ] || { echo "::error::knock reconcile --apply-plan a échoué" >&2; exit 1; }
