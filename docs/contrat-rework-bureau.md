# Contrat du rework — le bureau qui livre

15 novembre 2026. **Point d’entrée de la cible des prochains développements.**

Camille a validé la direction graphique du bureau, des cartes illustrées et des
emblèmes. Ce document rattache ce travail au projet ; il ne déclare pas le
rework implémenté et ne transforme pas les chiffres des maquettes en règles.

## 1. Promesse à préserver

« Je choisis ce que mon produit doit devenir, je construis l’organisation qui
le rend possible, puis je vois mes choix produire des livraisons utiles. »

Le bureau est le plateau. Les personnes, les files et les transferts expliquent
le travail. La roadmap exprime des intentions produit ; les lots et tickets
restent reliés à ces intentions. L’organisation transforme le flux et ses
possibilités, au lieu de seulement remplir une collection de multiplicateurs.

## 2. Quelle référence pour quelle question ?

| Question | Référence |
|---|---|
| Que doit viser le prochain développement ? | Ce contrat et le [plan d’intégration](plan-integration-rework.md) |
| À quoi ressemble l’interface et quels gestes offre-t-elle ? | [Maquettes `.pen`](maquettes/product-tycoon-jeu/README.md), [interactions](maquettes/product-tycoon-jeu/interactions.md) et [ressources visuelles](maquettes/product-tycoon-jeu/ressources-visuelles.md) |
| Quelles orientations de gameplay sont retenues ? | Décisions D01 à D12 de la [vision du bureau](vision-bureau-organisation.md) |
| Quelles règles restent à préciser ? | A01 à A08 et cas A à F de la [spécification de travail](spec-journee-travail-livraison.md) |
| Que fait le jeu aujourd’hui ? | [Carnet de règles](carnet-de-regles.md) et code existant |
| Comment fonctionne l’économie existante ? | Specs scoring, Impact, clients et équipe, dans les parties non remplacées explicitement |

Une contradiction entre l’ancien habillage et les maquettes ne réouvre pas la
direction visuelle. Une différence entre le calendrier actuel et une maquette
ne suffit pas à autoriser une nouvelle règle temporelle. Consigner les décisions
qui remplacent une règle, puis mettre à jour le carnet une fois implémentées.

## 3. Ce qui est retenu

### Direction visuelle et interactions

- Bureau chaleureux vu du dessus, avec du volume et des personnages visibles.
  Le découpage 2D/3D de la production reste un choix technique à cadrer ; le
  décor bitmap n’est pas le futur niveau interactif.
- Cartes expressives : illustration ou emblème, nom, état et coût essentiel.
  Effets, dépendances et nuances apparaissent à la sélection ou au survol.
- Médaillon pour l’Impact, bourse pour la caisse, calendrier pour les jours,
  emblèmes cohérents pour les métiers et les tickets.
- Chiffres, sélections et contrôles séparés des illustrations et éditables.
- Une fermeture par contexte, via croix ou Échap. Pas de retour redondant.
- Pas de titre, sous-titre et consigne génériques par réflexe. Conserver un nom
  ou une annonce lorsqu’il porte une information réelle.
- Sélection des personnes et objets dans le bureau ; les panneaux servent une
  décision ou une inspection ponctuelle. Aucun tableau de bord permanent dense.

Les 44 états couvrent la cible à revoir. L’accord porte sur la direction et les
assets ; il ne constitue pas une validation pixel par pixel de chaque écran,
ni une obligation d’implémenter 44 scènes indépendantes.

### Invariants de gameplay

- Un **seul solde d’Impact**, que les investissements débitent et que le quota
  juge. Produire de l’Impact ne crédite pas automatiquement la trésorerie.
- Choisir plusieurs sujets, les prioriser, conserver les travaux inachevés.
- Sujet → lots → tickets, avec des parcours adaptés au type de travail.
- Découpage courant automatique, influencé par l’organisation et les personnes.
- Du temps pour décider ; aucune réussite conditionnée à la vitesse de clic.
- Résultats produit identifiables, avec des synergies et plusieurs façons de
  réussir. Multiplier les sous-tickets ne doit pas créer artificiellement de valeur.
- Aléatoire, paris et information incomplète restent la matière du roguelike.

## 4. Ce qui reste ouvert, sans bloquer tout le chantier

La cadence exacte, la livraison utile, l’attribution d’Impact, les prix, les
quotas, le catalogue, la granularité de découpage et les effets humains restent
à spécifier suivant A01 à A08. Le raccord au moteur Traction × Levier et la
compatibilité des sauvegardes se préparent avant le lot qui les modifie.

Le scénario CSV, ses 80 / 120 Impact, ses +24 et ses coûts sont des exemples.
Ils peuvent alimenter une fixture de revue isolée ; jamais les données de
production ou les calculs de l’interface.

L’intégration des assets, des composants et des gestes déjà retenus peut
commencer lors du prochain développement demandé. Il n’est pas nécessaire de
trancher toute l’économie avant ce socle. Seul un comportement dépendant d’une
règle ouverte attend l’arbitrage correspondant.

## 5. Comment un prochain lot démarre

1. Choisir le premier lot dont les dépendances sont satisfaites dans le plan.
2. Écrire l’expérience visée et les vues de référence du lot.
3. Repérer les données et résolveurs existants à réutiliser. Ne pas recalculer
   le score, les prix ou les quotas dans les composants UI.
4. Traiter les seules décisions ouvertes nécessaires à ce lot.
5. Construire le parcours avec les composants partagés, puis le comparer aux
   références visuelles et vérifier ses états difficiles.
6. Documenter ce qui est réellement livré, ses captures et les limites restantes.

La demande présente prépare cette transmission. Elle ne relance pas le jeu ou
les prototypes. **Le parcours commence par R0** ; l’état de reprise du plan
indique ensuite le prochain lot, sauf instruction différente de Camille.

## 6. Ce qui remplace les anciennes directions

Les specs du bureau FPS, du HUD à panneaux permanents, du thème clair et des
cartes à six zones restent utiles pour comprendre le code existant. Elles ne
définissent plus la cible des nouveaux écrans. Le rythme en sprints reste celui
du jeu implémenté tant que le calendrier du rework n’est pas remplacé explicitement.

Les anciens prototypes HTML et le premier pack `.pen` trop web sont des archives
de discussion. Le `.pen` courant, son manifeste d’assets et ses guides sont les
sources du design. Les PNG natifs, archives ZIP et scripts de dessin sont des
sorties de travail ; ils ne sont pas le code du jeu.
