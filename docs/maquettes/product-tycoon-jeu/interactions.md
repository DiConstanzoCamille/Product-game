# Grammaire d’interaction et intention de mouvement

Ce document décrit la cible de jeu à revoir. Les interactions et animations
ne sont pas exécutées par le `.pen`.

## Naviguer comme dans un jeu

- Le bureau est le niveau de base. Un clic sur une personne, un poste, un objet
  ou une carte ouvre son contexte. Les quatre outils restent des accès rapides.
- Une croix ferme le contexte courant ; Échap fait la même chose. Le contexte
  précédent est restauré quand un panneau en avait ouvert un autre.
- Aucun bouton « Revenir au sujet » ou « Retour au bureau » ne répète cette
  fermeture. Une confirmation d’achat peut être quittée sans dépenser.
- Une carte est la cible entière. Son état sélectionné est visible ; il n’est
  pas nécessaire de répéter « Examiner » ou « Choisir » dans un gros bouton.
- La roadmap se réordonne par déplacement. Les flèches du clavier et les
  commandes contextuelles de la carte sélectionnée permettent le même geste.
- Entrée confirme une sélection explicite. Échap ferme sans confirmer.
  Aucun raccourci ne valide un achat à l’ouverture d’une fenêtre.
- Les détails secondaires apparaissent au survol ou à la sélection. La couche
  ordinaire conserve intention produit, état du travail et cause d’un blocage.

La croix ne fait pas avancer le calendrier. Fermer un bilan masque son panneau ;
« Préparer demain » change explicitement de phase. Le résultat de livraison
est déjà attribué quand sa présentation apparaît : la fermeture ne le perd pas.

## Donner du répondant

| Geste | Intention de mouvement proposée | Version avec animations réduites |
|---|---|---|
| Survol d’une carte | Soulèvement court de 6 px, ombre plus ample, reflet sur le bord ; 140 ms | Bord doré instantané |
| Sélection | Carte redressée et légèrement avancée, sceau visible ; 180 ms | Sceau et contraste |
| Appui sur une commande | Enfoncement de 3 px, reflet émail réduit ; 80 ms | Changement de contraste |
| Ouverture d’un panneau | Arrivée depuis l’objet d’origine, faible dépassement et stabilisation ; 220 ms | Apparition simple |
| Achat | Ressources débitées une seule fois, objet prêt à placer ; courte ponctuation sonore | Mise à jour immédiate et repère statique |
| Livraison | Pause visuelle du flux, capacité révélée puis Impact et combo comptés ; environ 700 ms au total, abrégeable | Résultat complet immédiatement |
| Bonus actif | Petit écho au poste ou au lot concerné au moment de l’effet | Badge statique consultable |

Ces durées sont des intentions à tester, pas une spécification d’équilibrage.
Le joueur ne doit pas gagner grâce à la vitesse de ses clics. Aucun rebond
permanent ou flash continu n’est demandé pour attirer l’attention.

## Matières et séparation des calques

Le décor du bureau et le cadre bois/papier/laiton sont des illustrations bitmap.
Le cadre est réutilisé comme matière de panneau et recadré pour le papier des
cartes. Titres, textes, icônes, cartes, états, bandeaux et commandes restent
des calques éditables. Le cadre ne contient aucun texte ou contrôle intégré.

Le relief de l’interface ne doit pas dépendre uniquement de cette texture :
chevauchements, position de sélection, profondeur d’appui et réactions du monde
devront porter la même intention dans l’implémentation.

Les emblèmes de ressources et de métiers prolongent cette famille dans les
compteurs, prix, files et récompenses. Voir [ressources-visuelles.md](ressources-visuelles.md).
Les nombres restent séparés de l’illustration. Une réaction du compteur ne
doit jamais déclencher une deuxième attribution du gain.

## Revue avant développement

- Confirmer la déclinaison des panneaux et cartes après le retour « trop plat ».
- Vérifier la densité avec un bureau animé et davantage de sujets.
- Tester priorités et réserve sans instructions permanentes.
- Valider le contrat de journée et les interventions possibles pendant la pause.
- Fixer les conditions de livraison utile, les combos et la conséquence d’un quota manqué.

Les chiffres illustratifs des maquettes servent à comprendre les décisions,
pas à figer les règles du futur jeu.
