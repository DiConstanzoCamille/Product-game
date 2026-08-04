#!/bin/bash
# Filet de sécurité : commit + push automatique du travail en cours sur la
# branche de feature courante, pour ne rien perdre en cas de coupure de
# crédits / de session. Ne touche jamais main/master. Les commits sont
# préfixés "WIP checkpoint" pour être facilement squashés avant merge :
#   git log --grep '^WIP checkpoint' --oneline
#
# Deux garde-fous, le repo étant public :
#  1. Fichiers à noms sensibles (.env, clés privées...) jamais stagés, et un
#     scan du contenu stagé bloque le commit si un secret (clé AWS, token
#     GitHub/Slack, "api_key = ...") apparaît, même dans un fichier au nom
#     anodin.
#  2. Si la branche a été supprimée côté remote (typiquement après un merge),
#     on arrête de pousser dessus pour ne pas la ressusciter ; le commit
#     reste local. Si le push est rejeté (divergence), on tente un merge
#     propre puis on retente une fois, sans jamais forcer.
set -u

WARN_LOG="${TMPDIR:-/tmp}/claude-wip-checkpoint-warnings.log"

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

# --- Garde-fou 1 : ne jamais stager de fichiers à noms sensibles ---------
SECRET_GLOBS=(
  '.env' '.env.*' '*.env'
  '*.pem' '*.key' '*.p12' '*.pfx' '*.keystore' '*.jks'
  'id_rsa' 'id_rsa.*' 'id_dsa' 'id_dsa.*' 'id_ecdsa' 'id_ecdsa.*'
  'id_ed25519' 'id_ed25519.*' '*_rsa' '*_dsa' '*_ed25519'
  '.npmrc' '.netrc' '.pypirc'
  'credentials.json' 'secrets.json' 'secret.json' '*.credentials'
)
add_pathspec=(-- .)
for glob in "${SECRET_GLOBS[@]}"; do
  add_pathspec+=(":(exclude,glob)${glob}" ":(exclude,glob)**/${glob}")
done

git add -A "${add_pathspec[@]}"

# --- Garde-fou 1 (suite) : scanner le contenu stagé pour des secrets -----
SECRET_PATTERN='-----BEGIN[A-Z ]*PRIVATE KEY-----'
SECRET_PATTERN+='|AKIA[0-9A-Z]{16}'
SECRET_PATTERN+='|AIza[0-9A-Za-z_-]{35}'
SECRET_PATTERN+='|gh[pousr]_[A-Za-z0-9]{36,}'
SECRET_PATTERN+='|xox[baprs]-[0-9A-Za-z-]{10,}'
SECRET_PATTERN+='|(api|secret|access|client)[_-]?(key|token|secret)[[:space:]]*[:=][[:space:]]*['"'"'"][^'"'"'"[:space:]]{8,}['"'"'"]'

hit=$(git diff --cached -U0 -- . 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+' | grep -Eio -e "$SECRET_PATTERN" | head -1)

if [ -n "$hit" ]; then
  git reset -q
  {
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [$branch] checkpoint WIP annulé : motif ressemblant à un secret détecté dans le diff stagé."
  } >>"$WARN_LOG" 2>/dev/null
  exit 0
fi

msg="WIP checkpoint: ${branch} @ $(date -u +%Y-%m-%dT%H:%M:%SZ) [auto]"

# Un pre-commit hook du projet (lint, secret-scan...) qui bloque doit rester
# bloquant ici : contrairement à un simple souci de style, on ne veut pas
# court-circuiter une protection du dépôt avec --no-verify.
git commit -q -m "$msg" || exit 0

# --- Garde-fou 2 : ne pas pousser sur une branche supprimée côté remote --
ls_remote_rc=0
git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1 || ls_remote_rc=$?
if [ "$ls_remote_rc" -eq 2 ] \
   && git rev-parse --verify -q "refs/remotes/origin/$branch" >/dev/null 2>&1; then
  # La branche existait côté remote et n'y est plus (probablement mergée et
  # supprimée) : on garde le commit en local, on ne la ressuscite pas.
  exit 0
fi

if git push -q -u origin "$branch" 2>/dev/null; then
  exit 0
fi

# Push rejeté (divergence probable) : merge propre puis un seul retry, sans
# jamais forcer le push.
if git fetch -q origin "$branch" 2>/dev/null \
   && git merge --no-edit -q "origin/$branch" 2>/dev/null; then
  git push -q -u origin "$branch" 2>/dev/null
else
  git merge --abort 2>/dev/null
fi

exit 0
