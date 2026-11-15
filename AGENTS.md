# Product Tycoon — entrée des prochains développements

Échanges en français. Lire [CLAUDE.md](CLAUDE.md) pour les conventions et la
recette du projet.

## Cible du travail

Pour le prochain développement du jeu ou de son interface, commencer par :

1. [Contrat du rework](docs/contrat-rework-bureau.md) : direction retenue,
   portée des validations et règles encore ouvertes.
2. [Plan d’intégration](docs/plan-integration-rework.md) : lots R0 à R5 et
   critères de sortie. **Son état de reprise indique le prochain lot** ;
   le parcours commence par R0.
3. [Maquettes de référence](docs/maquettes/product-tycoon-jeu/README.md) :
   fichier `.pen`, 44 états, gestes et assets. Lire les vues du lot concerné.
4. [Carnet de règles](docs/carnet-de-regles.md) : comportement réellement
   implémenté, à préserver tant qu’une règle n’est pas remplacée explicitement.

Les nouveaux écrans suivent cette direction par défaut : bureau vu du dessus,
cartes et emblèmes en volume, détails à la demande, gestes directs. Les anciennes
specs FPS, thème clair, panneau permanent et cartes à six zones documentent
l’existant ou l’historique ; elles ne doivent pas réinstaller leur ancienne UX.

## Au début d’un lot

- Annoncer l’expérience visée, le lot et les vues `Jxx` concernés.
- Distinguer habillage / interaction et changement de règle. La direction
  graphique et les assets sont déjà validés ; ne pas redemander cet accord.
- Pour une règle ouverte, préparer l’arbitrage précis nécessaire au lot avant
  de l’implémenter. Cela ne bloque pas les travaux indépendants déjà validés.
- Une correction de maintenance reste ciblée ; elle n’impose pas de refaire
  tout le jeu. Tout nouveau composant UI doit néanmoins rejoindre le socle commun.
- À la clôture, consigner le lot terminé, ses preuves et le prochain lot dans
  le plan. Lire cet avancement avant de repartir pour ne pas refaire R0.

## Garde-fous

- Un seul solde d’Impact, dépensable et comparé au quota ; trésorerie indépendante.
- Aucun chiffre de maquette ne devient une règle ou une valeur en dur.
- Découpage courant automatique ; pas de dialogue à chaque transfert de ticket.
- Le décor illustré est une référence artistique, pas un bureau simulé à livrer
  comme une image fixe. Les nombres et contrôles restent de vrais composants.
- Ne pas relancer les anciens prototypes HTML. Développer dans le projet Godot
  lors d’une demande de développement ; ne pas démarrer du gameplay sur une
  simple demande de documentation ou de maquette.
- Vérifier le parcours et les captures nominales / d’alerte, pas seulement la
  présence des fonctionnalités. Voir la recette de `CLAUDE.md` et du lot.

Le contrat donne la cible ; le carnet décrit l’existant. Une instruction plus
récente de Camille peut modifier la cible : mettre alors les documents à jour.
