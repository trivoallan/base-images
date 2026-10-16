.PHONY: settings pages

settings: ## Applique .github/settings.json au dépôt
	.github/apply-settings.sh

# ponytail: hors d'apply-settings.sh, qui est un fichier du socle identique dans regis, knock et uske.
pages: ## Active Pages, publié par le workflow pages (idempotent)
	@repo="$$(gh repo view --json nameWithOwner --jq .nameWithOwner)"; \
	if [ "$$(gh api "repos/$$repo/pages" --jq .build_type 2>/dev/null)" = workflow ]; then echo "= pages"; \
	else gh api -X POST "repos/$$repo/pages" -f build_type=workflow --silent 2>/dev/null \
	  || gh api -X PUT "repos/$$repo/pages" -f build_type=workflow --silent; echo "~ pages"; fi
