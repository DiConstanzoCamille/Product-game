# Vision de conception — Construire une organisation qui livre

Consolidation du 15 novembre 2026, après les essais du bureau vu du dessus.

**Statut : direction de travail partagée, règles détaillées en discussion.**
Camille demande d’arrêter le développement du prototype et de poursuivre sur
les documents qui prépareront le futur jeu. Les maquettes sont conservées comme
témoins d’exploration ; leur comportement ne constitue pas une spécification.
Le jeu Godot et le site publié restent inchangés.

Le [contrat du rework](contrat-rework-bureau.md) et le
[plan d’intégration](plan-integration-rework.md) donnent désormais le point
d’entrée opérationnel des prochains développements. Ce document développe
leur vision de gameplay. Le
[carnet de règles](carnet-de-regles.md) reste la référence sur le jeu existant.
La [spécification de la journée et de la livraison](spec-journee-travail-livraison.md)
développe les comportements proposés et les arbitrages encore ouverts.

## 1. Promesse et plaisir central

« Je choisis ce que mon produit doit devenir, je construis l’organisation qui
permet de le réaliser, puis je vois mes décisions produire des livraisons. »

Le joueur agit sur deux dimensions liées : les sujets produit dans lesquels
il investit et l’organisation qui les fait progresser. Le bureau rend visibles
les personnes, les files d’attente, les transferts et les blocages. La livraison
est la conséquence attendue de ce travail et le moment où ses résultats se lisent.

L’organisation ne se résume pas à une collection de multiplicateurs. Une
amélioration doit se comprendre dans le fonctionnement du bureau : moins
d’attente, meilleur découpage, capacité supplémentaire, moins de reprises,
travail pertinent qui arrive au bon poste.

## 2. Ce que les échanges permettent de retenir

| Décision | Statut et portée |
|---|---|
| D01 — Un seul solde d’Impact | Confirmé. Il sert à investir et reste comparé au quota. Dépenser le fait reculer. |
| D02 — Choix produit et organisation forment une même boucle | Direction retenue. La roadmap alimente un flux que l’on transforme par ses décisions. |
| D03 — Bureau vu du dessus, personnes et travaux visibles | Direction retenue après essais. Le rendu final en 2D ou 3D reste à choisir. |
| D04 — Plusieurs couches de backlog | Direction retenue : sujet → lots → tickets, avec des parcours adaptés au travail. |
| D05 — Découpage courant automatique | Correction explicitement demandée. Le joueur ne confirme plus la granularité à chaque transfert. |
| D06 — Le découpage dépend de l’organisation | Direction retenue. Profils, pratiques, paramètres ou investissements peuvent l’influencer ; leur combinaison reste à spécifier. |
| D07 — Un rythme de décisions quotidiennes | Orientation à développer. Le joueur doit disposer de temps pour observer, acheter, prioriser et gérer l’équipe. Le contrat exact de la journée reste ouvert. |
| D08 — Des livraisons concrètes et identifiables | Problème à résoudre : la multiplication des tickets techniques a affaibli la compréhension du résultat produit. |
| D09 — Les événements humains peuvent affecter le flux | Piste souhaitée : absence, retard, disponibilité, charge et réponses de management. Pas encore un catalogue de règles validé. |
| D10 — Conception avant développement | Confirmé. Prototypes HTML figés ; les prochains développements suivent le contrat et ses lots. Le socle UI retenu peut avancer, les règles ouvertes attendent l’arbitrage du lot concerné. |
| D11 — Direction graphique et assets | Validés après les maquettes : bureau chaleureux, cartes illustrées et emblèmes de ressources en volume. Les nombres restent éditables. Ce n’est pas une validation de l’équilibrage ou de chaque pixel des 44 états. |
| D12 — Grammaire d’interaction de jeu | Retenue : détails à la demande, objets / cartes sélectionnables, une fermeture par contexte, retrait des titres et commandes redondants. Les interactions se vérifient ensuite dans le jeu rendu. |

L’ordinateur est la référence de conception pour ce chantier. Le mobile est
mis de côté pour l’instant, sans décider de son impossibilité future.

## 3. La boucle cible

Choisir des sujets → engager et prioriser → laisser l’organisation travailler
→ observer les résultats de la journée → ajuster la suite.

La journée organise le rythme des décisions. Le trimestre donne un horizon
d’engagement et une échéance. Le mandat conserve l’ambition d’une partie qui
évolue dans le temps. Les durées et leur articulation avec les quotas actuels
restent à définir ; les 18 jours du prototype n’ont pas été validés.

« Sprint » peut désigner un mode d’organisation particulier. Ce mot ne doit
pas imposer une méthode unique à toutes les entreprises du jeu.

## 4. Des choix produit qui ont deux horizons

Le joueur peut poursuivre un sujet durable, par exemple ouvrir sa marketplace
aux vendeurs professionnels, tout en choisissant des réalisations précises :
un connecteur, un parcours d’inscription, une synchronisation des stocks.

Une orientation produit peut émerger des choix de sujets et de leurs
synergies. Le jeu n’a pas besoin de prescrire une solution complète à travers
une « étoile du Nord » préfabriquée. Il peut néanmoins donner un contexte,
des contraintes et des demandes qui rendent les choix intéressants.

Les propositions disponibles ne sont pas du travail automatiquement engagé.
Le joueur choisit plusieurs sujets, examine leurs compromis et ordonne sa file.
De nouvelles propositions peuvent apparaître sans effacer les travaux en cours.
Le rythme des tirages et le maintien des propositions non retenues restent ouverts.

## 5. Des couches de travail, avec un parent reconnaissable

| Objet | Sens pour le joueur |
|---|---|
| Sujet | Ce qu’on veut améliorer ou explorer dans le produit, avec une intention et un périmètre. |
| Lot | Une partie cohérente du sujet, assez précise pour progresser dans un métier ou un groupe de métiers. |
| Ticket | Une unité de réalisation confiée à un poste ou une personne. |
| Incrément utilisable | Une amélioration réellement disponible, identifiable par le joueur ; définition précise à valider. |

Le bureau montre plusieurs files, pas un même ticket qui change simplement de
colonne. Le parent conserve la trace de ses descendants, de leur état et de
ce qui est déjà utilisable. L’interface courante met en avant les sujets ;
les détails des lots et tickets s’ouvrent au poste ou sur le parent.

Tous les sujets ne suivent pas la même chaîne. Un travail technique peut
éviter une activité de design. Une investigation peut produire une décision
ou une nouvelle piste plutôt qu’une fonctionnalité. Une analyse technique ou
un découpage spécifique peut devenir une activité pertinente selon le contexte.
Le modèle ne prescrit pas que PM, designer et développeur travaillent toujours
séquentiellement dans cet ordre.

## 6. Le découpage devient une propriété de l’organisation

Le joueur règle ou transforme la manière de travailler à des moments utiles.
L’organisation applique ensuite ce fonctionnement aux sujets compatibles.
Les décisions répétitives « deux ou trois lots ? », puis « un ou deux tickets ? »
sont retirées de la boucle cible.

Exemples à spécifier, sans engagement sur ces effets exacts :

- Une designer sait rendre des sous-sujets exploitables plus tôt.
- Une pratique aide à découper un périmètre en incréments utilisables.
- Un outil facilite la transmission entre conception et développement.
- Une expertise technique réduit les reprises sur un type de connecteur.

Les lots plus petits peuvent alimenter l’aval plus tôt, mais demandent parfois
davantage de préparation ou de coordination. Les lots plus gros peuvent être
efficients dans un autre contexte. Aucun profil ne doit être un remplacement
universellement supérieur à tous les autres.

Une intervention ponctuelle reste une possibilité de conception pour un
sujet exceptionnel ; son existence et son coût ne sont pas encore décidés.
Elle ne doit pas réintroduire la confirmation de chaque ticket.

## 7. Ralentir les décisions, pas seulement les animations

Le défaut observé est un manque de temps pour agir sur l’entreprise. Réduire
la vitesse des personnages ne résout pas à lui seul la succession de fenêtres.

La proposition à instruire est une préparation de journée sans pression, une
simulation observable de cette journée, puis un bilan court. La boutique, les
priorités, l’organisation et l’équipe sont consultables avant l’avancement du
temps. Les gestes rapides ne doivent pas conditionner la réussite.

Un changement de jour ajoute du temps de travail. Il ne termine pas tous les
sujets et ne vide pas leurs files. Effort de travail, attente, transfert et
délai calendaire doivent rester distinguables. Les calendriers des personnes
peuvent ensuite expliquer une absence ou un démarrage retardé.

La possibilité d’intervenir en cours de simulation, de mettre en pause ou de
rejouer le déroulé est à arbitrer dans la spécification détaillée.

## 8. Rendre la livraison concrète

Le joueur doit pouvoir raconter ce qui a changé dans son produit : « le vendeur
peut importer son catalogue » ou « l’acheteur peut terminer sa commande ».
Une liste de tickets numérotés ne remplit pas cette fonction.

Il faut distinguer le travail terminé et la valeur effectivement disponible.
La proposition à examiner est de rattacher la livraison à un incrément utilisable,
avec ses dépendances, plutôt que de payer automatiquement chaque sous-ticket
technique. Le choix entre livrer un premier périmètre utile et attendre un
ensemble plus complet devient alors lisible.

Cette règle n’est pas encore validée. La répartition proportionnelle de la
valeur entre tous les tickets, utilisée dans la maquette, n’est pas reprise
automatiquement comme règle finale.

Garde-fous : aucune rémunération en double entre parents et descendants ;
aucune création artificielle de valeur par simple multiplication des tickets.
Un éventuel bonus de cadence doit correspondre à une mécanique explicite et à
des livraisons pertinentes, pas au nombre de fragments internes.

## 9. L’économie et les styles de partie

Le solde unique d’Impact conserve son rôle d’investissement et d’objectif.
Les clients, revenus et charges financent l’entreprise séparément : un gain
d’Impact n’est pas une entrée automatique de trésorerie.

Trois styles doivent pouvoir trouver des contextes favorables :

- Le volume : des livraisons fréquentes et une organisation qui absorbe le flux.
- La valeur : des opportunités choisies et des réalisations à forte utilité.
- L’efficience : des investissements ciblés, une organisation compacte et des charges maîtrisées.

Vitesse, qualité de réalisation et utilité produit ne se confondent pas.
Construire rapidement un sujet inutile, ou le réaliser très soigneusement,
ne doit pas garantir une bonne décision produit.

La future mesure de l’Impact doit tenir compte de ce que le flux représente
déjà. Un gain de capacité qui permet une livraison supplémentaire ne doit pas
être récompensé une deuxième fois par inadvertance. Le raccord avec la formule
Traction × Levier, ses combos et les quotas fera l’objet d’un arbitrage dédié.

## 10. Des personnes qui comptent dans ce fonctionnement

Le bureau rend une disponibilité ou une difficulté observable. Une absence
peut réduire la capacité d’un poste, un retard différer sa prise en charge,
une surcharge augmenter les reprises ou appeler une réponse de management.
Ces effets sont des pistes, pas des coefficients fixés.

Le joueur peut alors prioriser, redistribuer, décaler une ambition ou investir
pour rendre son organisation moins fragile. Les événements humains doivent
créer des arbitrages compréhensibles sans remplacer les confirmations de
découpage par une nouvelle série d’interruptions obligatoires.

Les états humains déjà présents dans le jeu — moral, confiance, énergie,
satisfaction salariale — constituent un point de départ à examiner. Leur
suppression ou leur remplacement par des absences aléatoires n’a pas été décidé.

## 11. Lecture de l’interface

- En haut : propositions, sélection et sujets engagés ; intention et progression produit.
- Dans le bureau : personnes, postes, files et transferts ; compréhension de l’organisation.
- À la demande : hiérarchie du travail, causes d’attente, bonus actifs et détails humains.
- Au bilan : ce qui est devenu utilisable, les effets observés et les problèmes à traiter.

Les bonus doivent être reliés à des observations. Une file qui se vide, deux
travaux réellement traités en parallèle ou un transfert plus fluide expliquent
un investissement. Le libellé « trajets −35 % » et la machine à café étaient
des exemples de maquette ; ni cet objet ni ce coefficient ne sont actés.

Un [dossier de 44 vues et états éditables en `.pen`](maquettes/product-tycoon-jeu/README.md)
met ces parcours en discussion, dans la direction graphique du bureau chaleureux.
Les retours sur les interfaces trop web ont conduit à privilégier les choix par
cartes distinctes, la sélection directe des personnes dans le bureau, les détails
à la demande et une seule fermeture par contexte. Les bandeaux de revue hors jeu
distinguent l’interface des hypothèses de conception. Ce dossier ne relance pas
le développement des prototypes et ne valide pas les règles qu’il illustre.

## 12. Ce qui est figé, et la suite du travail

On stabilise la direction décrite par les décisions D01 à D12, pas les durées,
les prix, le nombre de lots ni le catalogue du prototype. Aucun lot de
développement n’est lancé par ce document.

Le socle visuel et les interactions déjà retenues peuvent être intégrés lors
du prochain développement demandé, suivant R0 du plan. Les arbitrages ci-dessous
concernent les futurs lots de simulation et leur raccord ; ils ne sont pas un
blocage global de l’intégration UI.

Avant la future implémentation :

1. Définir une journée jouable et le contrôle de son avancement.
2. Définir ce qui constitue une livraison utile et son attribution d’Impact.
3. Définir le découpage automatique, ses sources et ses effets sur les files.
4. Définir un petit ensemble de réponses humaines et organisationnelles.
5. Rejouer des cas écrits et valider les règles avec Camille.
6. Établir ensuite le raccord aux systèmes existants et le découpage technique.

Documents d’appui : [spécification de travail](spec-journee-travail-livraison.md),
[enseignements et historique des prototypes](prototype-bureau-flux.md),
[économie actuelle](spec-clients-revenue.md), [équipe actuelle](spec-equipe-individuelle.md).
