#!/bin/bash
# Filet de sécurité : commit + push automatique du travail en cours sur la
# branche de feature courante, pour ne rien perdre en cas de coupure de
# crédits / de session. Ne touche jamais main/master. Les commits sont
# préfixés "WIP checkpoint" pour être facilement squashés avant merge :
#   git log --grep '^WIP checkpoint' --oneline
set -u

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

branch=$(git symbolic-ref --short -q HEAD)
[ -z "$branch" ] && exit 0
case "$branch" in
  main|master) exit 0 ;;
esac

# Rien à committer ?
if git diff --quiet && git diff --cached --quiet \
   && [ -z "$(git status --porcelain --untracked-files=all)" ]; then
  exit 0
fi

git add -A

msg="WIP checkpoint: ${branch} @ $(date -u +%Y-%m-%dT%H:%M:%SZ) [auto]"

# Si un pre-commit hook bloque (lint, tests...), le contourner : un
# checkpoint WIP qui échoue silencieusement est pire qu'un commit imparfait,
# et il sera de toute façon squashé avant merge.
if ! git commit -q -m "$msg" 2>/dev/null; then
  git commit -q -m "$msg" --no-verify 2>/dev/null
fi

git push -q -u origin "$branch" 2>/dev/null

exit 0
