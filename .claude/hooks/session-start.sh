#!/bin/bash
# Provisionne Godot pour les sessions Claude Code sur le web.
#
# Le dépôt n'a pas de gestionnaire de dépendances : sa seule dépendance est le
# moteur. Sans lui, une session ne peut ni jouer les trois bancs, ni générer
# les `.uid` (le piège le plus répétitif du dépôt), ni prendre de captures —
# c'est-à-dire ne peut rien recetter de ce que le CLAUDE.md exige.
#
# Le hook n'échoue jamais : s'il ne parvient pas à installer le moteur, il le
# dit et rend la main. Une session sans Godot reste utile (specs, données,
# documentation) ; une session bloquée au démarrage ne l'est pas.
set -uo pipefail

# En local, Godot est déjà installé comme l'auteur le souhaite : on ne touche à rien.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

VERSION="4.7"              # doit suivre `config/features` de game/project.godot
CHANNEL="stable"
BIN_DIR="$HOME/.local/bin"
GODOT_BIN="$BIN_DIR/godot"

note() { printf '  %s\n' "$*" >&2; }

if [ -x "$GODOT_BIN" ] || command -v godot >/dev/null 2>&1; then
  note "Godot déjà présent — rien à installer."
  [ -x "$GODOT_BIN" ] && echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "${CLAUDE_ENV_FILE:-/dev/null}"
  exit 0
fi

ARCHIVE="Godot_v${VERSION}-${CHANNEL}_linux.x86_64"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Plusieurs origines : selon la politique d'egress de l'environnement, l'une ou
# l'autre passe. On s'arrête à la première qui répond.
MIRRORS=(
  "https://github.com/godotengine/godot/releases/download/${VERSION}-${CHANNEL}/${ARCHIVE}.zip"
  "https://downloads.tuxfamily.org/godotengine/${VERSION}/${ARCHIVE}.zip"
  "https://godotengine.github.io/godot-builds/releases/${VERSION}-${CHANNEL}/${ARCHIVE}.zip"
)

for url in "${MIRRORS[@]}"; do
  note "Tentative : ${url%%/releases*}"
  if curl -fsSL --connect-timeout 20 --max-time 300 -o "$TMP/godot.zip" "$url" 2>/dev/null; then
    mkdir -p "$BIN_DIR"
    if unzip -q -o "$TMP/godot.zip" -d "$TMP" && mv "$TMP/$ARCHIVE" "$GODOT_BIN"; then
      chmod +x "$GODOT_BIN"
      echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "${CLAUDE_ENV_FILE:-/dev/null}"
      note "Godot installé : $("$GODOT_BIN" --version 2>/dev/null | head -1)"
      exit 0
    fi
  fi
done

# Aucun miroir joignable — très probablement la politique réseau de
# l'environnement. On l'écrit noir sur blanc pour que la session sache qu'elle
# ne pourra rien recetter, plutôt que de le découvrir au moment de conclure.
cat >&2 <<'MSG'

  ⚠️  Godot n'a pas pu être installé (aucun miroir joignable).

  Cette session ne peut donc PAS :
    · jouer smoke_test_logic.gd, smoke_test_ui.gd, score_resolver_cases.gd
    · générer les .uid d'un nouveau .gd ou .tscn
    · prendre les captures d'écran (xvfb est là, le moteur non)
    · faire tourner la boucle de 40 runs

  Aucun lot touchant game/ ne peut être recetté depuis ici. Le dire dans la PR
  plutôt que de livrer en aveugle.

  Pour débloquer : autoriser godotengine.org (ou github.com/godotengine) dans
  la politique réseau de l'environnement — voir
  https://code.claude.com/docs/en/claude-code-on-the-web

MSG
exit 0
