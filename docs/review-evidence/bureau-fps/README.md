# Bureau retravaillé et vue FPS assise — recette du 07/09/2026

- `desk_calme.png` : cadrage d'observation, clavier et plateau visibles.
- `desk_app.png`, `desk_roadmap.png` : cadrage de lecture du laptop.
- `desk_shop.png`, `desk_closing.png`, `desk_committee.png` : accessoires présentés.
- `fps_gauche.png`, `fps_droite.png`, `fps_haut.png`, `fps_bas.png` : bornes du regard.
- `fps_redimensionne.png` : fenêtre 1280×900, après réponse par clic 3D.
- `asset_tasse.png` : détail de la paroi intérieure et de l'anse.
- `run_*` : captures des deux runs automatisés jusqu'à leur fin.
- `smoke-logic.txt`, `smoke-ui.txt`, `smoke-fps.txt` : suites headless au vert.
- `recette-rendue.txt` : parcours rendus sans erreur moteur.

Les parcours choisissent de ne rien livrer ni acheter et perdent rapidement.
Ils valident la boucle, pas la qualité d'une stratégie gagnante. La visée et
les clics sur courrier/signature utilisent le routage physique réel. Le
confort humain n'est pas considéré comme validé par ces scripts.

Pour reproduire, définir `SHOT_DIR` avec un dossier absolu, puis lancer
Godot 4.7.1 avec `--path game` et `res://tests/screenshot_screens.tscn`, puis
`res://tests/fps_visual_walkthrough.tscn`. Les trois suites headless sont
`smoke_test_logic.tscn`, `smoke_test_ui.tscn` et `smoke_test_fps.tscn` sous
`res://tests/`. Pour enregistrer un log Windows, utiliser un chemin absolu
avec `--log-file`.
