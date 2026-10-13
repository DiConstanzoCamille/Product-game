# Collection Atelier

Six modèles originaux conçus pour le bureau de Product Tycoon : lampe articulée,
plante en pot cannelé, pot à crayons avec papeterie, deux carnets reliés, casque
sur support et vide-poche avec clé USB et trombones. Aucun modèle ni texture tiers.

Les GLB sont autonomes : géométrie, normales et matériaux PBR embarqués, sans
texture externe, sans plugin, utilisables en GL Compatibility. Les détails sont
géométriques (chanfreins, vis, reliures, nervures, parois intérieures). Les pièces
sont regroupées par matériau à l'export pour limiter les appels de rendu.

## Utilisation et retouches

Ouvrir `res://scenes/components/atelier_collection.tscn` pour déplacer, tourner
ou remplacer les objets dans l'éditeur. Chaque instance a son origine au sol,
une échelle en mètres, Y vers le haut et sa face principale vers +Z.
La lumière chaude de la lampe est définie dans cette scène et reste indépendante
du modèle. Les six objets sont décoratifs ; ils ne créent aucune zone de clic.

Cette scène est instanciée par `DeskArt.build_room()`. Elle remplace la lampe,
la plante et la pile de livres procédurales ; les autres objets s'ajoutent dans
les espaces latéraux. Les surfaces de jeu, leurs ancrages et la caméra gardent
leur contrat d'interaction.

## Sources reproductibles

Depuis la racine du dépôt, avec Blender 4.3 ou supérieur :

```sh
blender -b --factory-startup --python tools/desk_assets/build_collection.py
godot --headless --path game --editor --import
```

Le script contient les profils, dimensions, palette et matériaux. Il recrée les
six GLB ainsi que `catalog.json` (maillages, sommets, triangles, taille).
Blender n'est nécessaire que pour régénérer les modèles, pas pour jouer.
Ne pas modifier les scènes importées dans `.godot/` ; modifier la source ou la
scène d'assemblage. L'apparence est vérifiée avec le rendu du jeu, pas uniquement
dans Blender.

Planche de présentation (nécessite un affichage) :

```sh
SHOT_DIR=/chemin/absolu godot --path game --resolution 1600x900 -s res://tests/atelier_gallery.gd
```
