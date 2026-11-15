# Prototype de discussion — Le bureau et ses flux

**Prototypes figés au 15 novembre 2026, à la demande de Camille.** Ce document
conserve leurs hypothèses et leurs vérifications. Le découpage manuel répétitif
et la cadence continue ont été remis en question après essai. La conception
se poursuit dans la [vision consolidée](vision-bureau-organisation.md) et la
[spécification de travail](spec-journee-travail-livraison.md), sans nouvelle
modification des prototypes.

Les fichiers HTML et captures de ces explorations sont conservés localement,
hors du paquet de merge de la cible. Ce document reste leur historique ; les
références partagées de conception sont le contrat et les maquettes actuelles.

15 novembre 2026. Prototype HTML indépendant du jeu Godot. Autorisé par Camille
pour explorer le game design et les interactions, sans modifier le jeu publié.
Les valeurs sont illustratives et les règles ci-dessous sont des hypothèses
locales au prototype, pas des décisions de production.

## Expérience recherchée

Choisir un travail produit, le reconnaître dans la roadmap persistante, voir
qui le prend, où il attend et comment un investissement change sa progression.
La livraison produit de l’Impact ; les achats débitent le même solde comparé
au contrat. Les clients, pas l’Impact, alimentent la trésorerie.

## Périmètre

- Bureau dessiné du dessus : cadrage, design, développement et sortie.
- Trois personnes au départ, un emplacement pour un deuxième développeur.
- Roadmap de quatre sujets persistants, priorités modifiables avant prise en charge.
- Connecteur à choisir parmi trois périmètres, durées et effets différents.
- Investigation qui révèle un nouveau choix de solution au lieu de produire
  automatiquement un multiplicateur de score.
- Animation des trajets, du ticket transporté, du travail et des files d’attente.
- Boutique ouvrable et refermable : poste, recrutement, machine à café.
- Pause, vitesse et avance d’une journée ; consultation des sujets et postes.
- Fin de période avec livraisons, travaux conservés et comparaison au quota.

## Hypothèses de simulation

Le temps est continu, mesuré en jours fictifs. Les durées de déplacement
consomment du temps au même titre que le travail. Un salarié prend un sujet,
va le chercher, travaille à son poste et l’apporte à l’étape suivante. Il
revient ensuite à son poste. Les files sont servies dans l’ordre de priorité.
Les étapes dépendent du sujet ; une investigation ne passe pas en développement.

La durée de traitement dépend du sujet et du rôle. Un nouveau développeur
ajoute un traitement simultané, sans accélérer artificiellement le designer.
Le café réduit les durées des trajets : hypothèse ludique volontaire, pas
affirmation sur le travail réel. Le poste est un prérequis visible au recrutement.

La résolution paie le sujet une seule fois, une fois effectivement livré.
Les coûts d’Impact et les charges monétaires sont séparés. Les achats se font
en pause ; consulter un détail met aussi en pause et conserve la progression.
Fermer reprend seulement si la simulation tournait avant l’ouverture.

La fin du trimestre arrête la simulation sans supprimer les travaux. Le test
permet de poursuivre pour observer leur avancement même si le quota a été
manqué ; ce n’est pas une nouvelle règle de défaite du jeu.

## Cas à observer

1. Choisir un connecteur court puis démarrer : reconnaître le sujet transporté.
2. Laisser plusieurs travaux arriver au développement et observer l’attente.
3. Acheter un poste puis recruter : vérifier le solde qui baisse et les deux
   développeurs qui traitent réellement deux sujets en parallèle.
4. Acheter le café : observer les trajets plus courts, sans changement des efforts.
5. Terminer l’investigation : choisir une solution qui rejoint la roadmap.
6. Ouvrir puis fermer la boutique pendant un trajet : retrouver le même sujet.
7. Atteindre l’échéance : retrouver les sujets encore en cours au trimestre suivant.

## Limites assumées

Pas de construction libre du bâtiment ni de déplacement des meubles, pas de
simulation complète des caractères, de l’aléatoire ou des méthodes de travail.
Ce circuit n’est pas une prescription « PM puis designer puis développeur » :
c’est un exemple de départ pour examiner les interactions et les goulots.
La roadmap contient ici des sujets et leurs solutions ; les initiatives
longues à plusieurs livraisons feront l’objet d’un essai suivant si le flux plaît.
La priorité est l’ordinateur ; le repli étroit conserve les actions mais ne
constitue pas une validation d’une version mobile.

Le prochain arbitrage porte sur ce que l’on comprend en regardant fonctionner
ce petit bureau, avant de discuter de la fidélité au moteur Godot existant.

## Support et vérification

Version autonome : `maquettes/bureau-vivant.html` (archive locale), sans
installation ni connexion au moteur du jeu. Elle commence en pause ; Démarrer
ouvre le choix du connecteur, puis les personnages prennent les sujets.

Vérifications effectuées :

- Parcours navigateur : roadmap visible, choix de connecteur, prise en charge,
  ouverture des investissements, confirmation de coût, installation du poste,
  recrutement, achat du café, démarrage et pause de la simulation.
- Exploration : deux solutions disponibles ; la solution choisie rejoint
  réellement la roadmap et entre dans les files de traitement.
- Échéance : bilan affiché au jour 18, passage au trimestre suivant avec
  les travaux, leurs étapes et leur progression conservés.
- Aucun message d’erreur JavaScript relevé pendant le contrôle final.
- Simulation hors navigateur : trois connecteurs, prérequis du recrutement,
  absence de double achat, effets des charges, deux développements simultanés
  après recrutement et absence de paiement répété après l’échéance.

Sur un même scénario fictif avec choix du connecteur sur mesure et solution
courte sélectionnée dès sa découverte, le bureau initial termine deux
livraisons avant l’échéance ; le bureau équipé du deuxième poste, de Maya et
du café en termine quatre. Ce résultat vérifie que la simulation change
réellement ; il ne valide ni l’équilibrage ni la valeur stratégique des prix.

Les gains sont volontairement connus dans les fiches de ce scénario pour
comparer les choix. Cela ne décide pas du degré d’incertitude du jeu final.
La faillite, les crises humaines et les méthodes alternatives ne sont pas
simulées dans ce premier périmètre. Un essai humain reste nécessaire pour
juger la lecture des déplacements et le plaisir des décisions.

## Itération 2 — Donner la main sur la roadmap

Retour de Camille : conserver le bureau et ses transferts, mais rendre les
choix produit manipulables. Cette itération est une nouvelle maquette, pas
une modification des règles du jeu Godot.

- Séparer propositions, sélection en préparation, file engagée et historique.
- Choisir plusieurs sujets avant de les engager ; les personnes ne prennent
  aucun sujet qui n’a pas été engagé par le joueur.
- Afficher l’effort en jours de travail, distinct du délai calendaire :
  travail restant, trajets et attentes traversent réellement plusieurs jours.
- Réordonner directement les sujets non démarrés et les remettre dans les
  propositions. Les travaux commencés conservent leur état.
- De nouvelles propositions arrivent tous les trois jours fictifs ; les
  sujets livrés quittent la file active et restent consultables dans l’historique.
  Le catalogue est fini et cette cadence est une hypothèse du prototype.
- Un changement de jour ne détruit jamais les travaux en cours. Les nouvelles
  propositions s’ajoutent aux choix possibles, pas au travail engagé.
- Inclure un sujet technique qui passe du cadrage au développement sans design.
- Rendre les personnages sélectionnables : consulter leur travail et suspendre
  ou réactiver leur poste sans perdre la progression. Le salaire reste payé.
- Signaler le café sur les personnages en déplacement, en conservant son effet
  existant sur les trajets et non sur l’effort de développement.

À tester : sélectionner deux sujets, inverser leur ordre, observer le premier
pris ; avancer d’un jour et retrouver le travail partiel ; attendre une nouvelle
proposition ; suspendre un poste puis le réactiver ; livrer et retrouver le sujet
dans l’historique. Le bureau inférieur conserve son cadrage et ses mécanismes.

### Complément demandé : les backlogs ont plusieurs couches

Un sujet cadré ne passe plus en bloc au poste suivant. Le joueur choisit un
découpage en deux lots cohérents ou trois petits lots. Chaque lot de conception
ouvre ensuite le choix d’un ticket de réalisation complet ou de deux petits
tickets. Les travaux techniques peuvent aller directement du cadrage aux tickets
de développement. L’investigation se termine après ses lots d’exploration.

Les files des postes contiennent ces objets distincts, liés par des numéros
hiérarchiques (sujet 1, lot 1.2, ticket 1.2.1). Le sujet parent reste visible
tant que tous ses descendants ne sont pas terminés. Sa fiche montre l’arbre.
Le joueur peut réordonner des tickets encore en attente au poste ou en retenir
un dans la file ; la décision affecte réellement le prochain travail pris.

Le découpage ajoute de petits coûts de préparation. Les petits lots peuvent
alimenter l’aval plus tôt, au prix d’un effort total légèrement supérieur.
Le potentiel d’Impact et de clients du sujet est réparti entre ses tickets :
multiplier les tickets ne multiplie pas artificiellement sa valeur totale.
Chaque ticket reçoit sa part une seule fois à la livraison ; les parents ne
sont pas rémunérés une deuxième fois.

Les passages de frontières ouvrent une décision à la première occurrence.
La fenêtre se ferme sans annuler le travail ; un bouton Découper reste disponible
sur le parent ou au poste pour reprendre le choix. Ce rythme et le coût de
préparation sont des hypothèses à tester, pas des règles validées du jeu final.

### Version et vérification de cette itération

Maquette autonome : `maquettes/bureau-vivant-roadmap.html` (archive locale).
La première version reste disponible pour comparaison.

Parcours navigateur vérifié : choix d’un connecteur, sélection de deux sujets,
engagement commun, inversion des priorités et prise effective du sujet remonté.
Au jour 3, le sujet cadré a ouvert le choix de découpage ; trois lots distincts
ont été placés dans la file design. Un lot conçu a ensuite donné deux tickets
de développement. Les nouvelles propositions ont rejoint le catalogue sans
être automatiquement engagées.

Le poste de Noé a été suspendu puis réactivé. Dans sa file, le ticket 2.1.2 a
été remonté puis différé ; Noé a effectivement pris le ticket 2.1.1. La fiche
du sujet a montré les lots, tickets, états et numéros correspondants. La reprise
après rechargement a conservé le jour, les files et le poste suspendu. Aucun
message d’erreur JavaScript relevé pendant le contrôle final.

Le modèle a également été vérifié pour les quatre combinaisons : deux ou trois
lots de conception, puis un ou deux tickets par lot. Le potentiel de 78 Impact
du connecteur sur mesure reste exactement 78 une fois tous ses tickets livrés,
avec le même total de cinq nouveaux clients. La suspension conserve l’avancement,
les sujets non engagés ne sont pas pris, et une investigation ouvre une nouvelle
proposition sans rapporter artificiellement de l’Impact.

Le découpage reste guidé par quelques options pour cette maquette. Le nommage
libre, le regroupement, les dépendances complexes et les décisions de granularité
automatisées par des pratiques ne sont pas simulés ici.
