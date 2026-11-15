# Intégration des assets dans les prochains lots

Le [manifeste](assets-manifest.json) identifie les fichiers, dimensions, rôles,
régions d’atlas et empreintes de cette cible. C’est un inventaire de transmission,
pas un fichier de données de gameplay à faire consommer au moteur.

## Ce que R0 reprend

- Les illustrations de sujets et d’objets sont des candidats à l’UI de production.
- Les emblèmes d’Impact, caisse, calendrier et métiers peuvent être repris dans
  les composants, compteurs, prix et récompenses.
- Les valeurs, libellés, badges, sélections et effets de survol restent séparés.
- Les atlas utilisent trois colonnes normalisées. Ne pas supposer une largeur
  entière identique pour tous les PNG : le fichier d’atelier fait 1774 px.
- Intégrer les polices et leurs notices avec les assets du jeu. Fredoka est la
  cible des titres et chiffres expressifs ; elle n’est pas encore fournie dans
  `game/assets/fonts/`. Les familles IBM Plex déjà présentes restent réutilisables.

## Ce que l’on n’importe pas comme système de jeu

- `studio-jeu.png` est la référence artistique du bureau. Il ne remplace pas la
  scène, les personnes, les postes et leurs interactions.
- `cadre-bureau.png` est conservé comme historique de la première déclinaison
  de panneaux, remplacée ensuite. Il n’est pas un asset runtime retenu.
- Les captures `.jpg` / `.png` et le ZIP sont des aperçus ou des distributions.
  Ne pas poser un écran complet en texture pour prétendre l’avoir implémenté.
- Les scripts JavaScript de `sources/` étaient des opérations de session de
  l’éditeur. Ils ne sont pas un générateur de scène ou une dépendance du jeu.

## Revue visuelle et versionnement

Le `.pen`, les six PNG sources (dont le cadre historique), les guides et le
manifeste restent versionnés. Les 44 JPEG et les planches de revue permettent de
relire la cible depuis le dépôt sans ouvrir pen.dev. Les PNG natifs en double,
les exports anciens et le ZIP sont ignorés par Git et conservés localement.

Pour actualiser les références : exporter les vues du `.pen` dans pen.dev,
mettre à jour le rapport de vérification, puis lancer `export-apercus.py` avec
Pillow. Ce script convertit les images, pas le design. Régénérer le manifeste
si un PNG source change et relire les références concernées.

Le premier lot runtime documente ensuite le dossier d’import, les noms utilisés
dans le jeu et les notices correspondantes. Aucune copie vers `game/` n’est
effectuée par le présent paquet documentaire.
