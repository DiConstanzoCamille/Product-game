# Portable retravaillé — 05/09/2026

Asset procédural : `game/scripts/components/laptop_model.gd`.
Intégration : `DeskRoom._build_laptop()`.

- `laptop_detail.png` : caméra de contrôle trois-quarts, modèle entier.
- `desk_calme.png` et `desk_roadmap.png` : véritable caméra de jeu.
- `contact-sheet.png` : revue d'ensemble des 24 captures.

Le cadrage de jeu conserve la dalle à sa taille de référence ; le clavier
est principalement hors champ. La vue trois-quarts est un outil de recette,
pas une modification du cadrage livré.

## Reproduire

Depuis la racine du dépôt, définir `SHOT_DIR` avec le chemin absolu de ce
dossier, puis lancer Godot avec `--path game` et, successivement :

1. `res://tests/screenshot_screens.tscn`
2. `res://tests/laptop_asset_preview.tscn`

Le script PowerShell `contact-sheet.ps1` reconstruit la planche de contact.
Captures obtenues à 1920×1080, renderer Compatibility, Godot 4.7.1.

Les scènes `smoke_test_logic.tscn` et `smoke_test_ui.tscn` passent en headless.
Le parcours visuel est automatisé ; aucune partie manuelle complète n'est
revendiquée. Les autres accessoires restent ceux du lot précédent.
