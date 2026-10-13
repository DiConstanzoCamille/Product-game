# Recette des interactions — 07/09/2026

- `interactions.txt` : événements de fenêtre, deux modes, drag/drop réel,
  relâchement extérieur, Échap, perte de focus simulée, molette, clics sur
  le corps de la clôture et le clavier. Exécution avec rendu OpenGL.
- `roadmap_drag_*.png` : aperçu du ticket porté vers la colonne sprint.
- `roadmap_scroll_*.png` : molette après ajout d'un espace de débordement
  dans le fixture de test (pas un changement du contenu du jeu).
- `fps.txt`, `ui.txt`, `logic.txt` : suites headless de non-régression.
- `parcours.txt` : deux parcours rendus automatisés jusqu'à une fin de run,
  réponses au courrier et signature cliquées, puis clic après redimensionnement.
- `captures.txt` et autres PNG : tour visuel de tous les écrans.

Lancer `Godot --path game res://tests/smoke_test_desk_input.tscn`, avec
`--headless` pour la version sans rendu. Définir `SHOT_DIR` avec un chemin
absolu pour les captures et utiliser un `--log-file` absolu sous Windows.
Les captures du framebuffer ne contiennent pas le curseur natif Windows ;
la recette vérifie explicitement `Input.mouse_mode == MOUSE_MODE_VISIBLE`.
Une vérification humaine du ressenti et de l'affichage du curseur reste utile.
