#!/usr/bin/env bash
# Un criblage : les étapes du WorkflowTemplate `uske-screening` (uske/deploy/base), dans le même
# ordre, chacune dans le conteneur publié de son outil. Rien ici ne juge ni ne place : uske, regis
# et knock le font ; ce script ne fait que les enchaîner, comme Argo le fait ailleurs.
#
#   SCREEN_MODE=judge   plan et jugement seulement : rien n'est consigné, rien n'est placé (les PR)
#   SCREEN_MODE=apply   le criblage complet ; le journal est commité AVANT tout placement
#
# Entrées : REGIS_IMAGE, KNOCK_IMAGE, USKE_IMAGE ; KNOCK_* pour knock ; REGISTRY_HOST,
# REGISTRY_USER, REGISTRY_PASSWORD pour que regis lise le transit ; TRANSIT, le nom de
# KNOCK_REGISTRIES où les rebuilds attendent leur jugement ; GRYPE_CACHE, un dossier hôte.
set -euo pipefail

MODE="${SCREEN_MODE:-judge}"
REPO="$(cd "$(dirname "$0")" && pwd)"
RESULTS="$REPO/results"
W="$(mktemp -d)"
GRYPE_CACHE="${GRYPE_CACHE:-$W/grype}"
TRANSIT="${TRANSIT:-transit}"
mkdir -p "$RESULTS" "$GRYPE_CACHE"
# Les trois images ne tournent pas sous l'utilisateur du runner.
chmod -R a+rwX "$W" "$RESULTS" "$GRYPE_CACHE"

mounts=(-v "$REPO:/repo:ro" -v "$W:/work" -v "$RESULTS:/results")

uske() { docker run --rm "${mounts[@]}" "$USKE_IMAGE" "$@"; }

knock() {
  # --plan-out et --staged-out ne créent pas leur dossier parent.
  mkdir -p "$W/plans" "$W/staged" && chmod a+rwX "$W/plans" "$W/staged"
  docker run --rm --network host "${mounts[@]}" \
    -v "$HOME/.docker:/tmp/.docker:ro" \
    -e KNOCK_REGISTRIES -e BUILDKIT_HOST -e KNOCK_TRANSFORM_PACKAGE_MIRRORS \
    -e KNOCK_SBOM_FORMATS -e KNOCK_ATTEST_SIGNER -e KNOCK_LOG_FORMAT=text \
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
  # main a pu avancer pendant le criblage (une PR fusionnée) : seul ce script écrit results/.
  git -C "$REPO" pull -q --rebase
  git -C "$REPO" push -q
}

# evaluate POLICY PLAYBOOK LINES ITEM_JSON : un digest, jugé par regis, classé par uske.
evaluate() {
  local name=$1 playbook=$2 lines=$3 item=$4
  local ref digest target key source_ref source_digest rc=0
  ref=$(jq -r .ref <<<"$item"); digest=$(jq -r .digest <<<"$item")
  target=$(jq -r .target <<<"$item"); key=$(jq -r .key <<<"$item")
  source_ref=$(jq -r '.sourceRef // ""' <<<"$item"); source_digest=$(jq -r '.source // ""' <<<"$item")
  mkdir -p "$W/$lines/$name" "$W/reports/$key" && chmod a+rwX "$W/$lines/$name" "$W/reports/$key"

  if [ "$playbook" = null ]; then  # régime inconnu : jamais envoyé à regis (D-21)
    uske classify --ref "$ref" --digest "$digest" >"$W/$lines/$name/$key.json"
    return
  fi
  echo "::group::regis $target"
  regis analyze "$target" --playbook "$playbook" \
    -D "/work/reports/$key" -o "report.{format}" --html --markdown || rc=$?  # inconclusive, pas perdu (D-23)
  echo "::endgroup::"
  # Le rapport survit au criblage, à côté du journal, avant que la ligne qui le cite soit écrite.
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
    | tee "$W/$lines/$name/$key.json"
}

failed=0
uske list --policies /repo/policies >"$W/list.json"
while read -r policy; do
  name=$(jq -r .name <<<"$policy"); path=$(jq -r .path <<<"$policy")
  echo "::group::$name : plan"
  uske prepare --policy "$path" --out "/work/policies/$name/policy.yaml"
  knock reconcile "/work/policies/$name" --plan-out "/work/plans/$name.json"
  uske pending --policy "$path" --plan "/work/plans/$name.json" --results /results >"$W/pending.json"
  playbook=$(uske resolve --policy "$path" --playbooks /repo/playbooks | jq -r .playbook)
  echo "::endgroup::"
  echo "$name : $(jq length "$W/pending.json") digest(s) en attente de décision"

  while read -r item; do evaluate "$name" "$playbook" lines "$item"; done < <(jq -c '.[]' "$W/pending.json")
  [ "$MODE" = apply ] || continue

  uske record --policy "$path" --results /results --lines "/work/lines/$name"
  commit_journal "journal($name): décisions du criblage, première porte"

  approved=$(uske approve --policy "$path" --results /results --plan "/work/plans/$name.json" \
    --out "/work/plans/$name.approved.json" --transit "$TRANSIT" | jq .approved)
  [ "$approved" -gt 0 ] || continue

  # Les copies sont placées, les rebuilds tenus en transit. Un build raté ne retient pas les autres.
  knock reconcile "/work/policies/$name" --apply-plan "/work/plans/$name.approved.json" \
    --stage-to "$TRANSIT" --staged-out "/work/staged/$name.json" || failed=1

  # Seconde porte : juger ce que knock a construit, par son propre digest.
  uske pending --policy "$path" --staged "/work/staged/$name.json" --results /results >"$W/staged.json"
  while read -r item; do evaluate "$name" "$playbook" staged-lines "$item"; done < <(jq -c '.[]' "$W/staged.json")
  uske record --policy "$path" --results /results --lines "/work/staged-lines/$name"
  commit_journal "journal($name): décisions du criblage, seconde porte"

  promoted=$(uske approve --policy "$path" --results /results --staged "/work/staged/$name.json" \
    --out "/work/staged/$name.approved.json" | jq .approved)
  if [ "$promoted" -gt 0 ]; then
    knock promote "/work/policies/$name" --staged "/work/staged/$name.approved.json"
  fi
done < <(jq -c '.[]' "$W/list.json")

[ "$failed" = 0 ] || { echo "::error::knock reconcile --apply-plan a échoué" >&2; exit 1; }
