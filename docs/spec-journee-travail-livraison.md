# Spécification de travail — Journée, découpage et livraison

15 novembre 2026. **Brouillon à discuter avant implémentation.**

Ce document développe la [vision du bureau et de l’organisation](vision-bureau-organisation.md).
Il propose des comportements observables et des cas à relire ; ces propositions
ne valident pas à elles seules toutes les nouvelles règles du jeu. Les prototypes
HTML restent figés. L’ordre des décisions encore ouvertes figure en §9.

Le [contrat du rework](contrat-rework-bureau.md) distingue cette conception de
l’habillage déjà retenu. Le socle UI peut avancer dans R0 du
[plan d’intégration](plan-integration-rework.md) lors d’une demande de développement.
Chaque lot de simulation attend les seuls arbitrages dont il dépend.

## 1. Résultat recherché

Le joueur dispose d’un moment calme pour examiner son entreprise, prendre des
décisions puis faire avancer le travail. L’organisation traite les sujets et
les découpe sans demander une validation à chaque transmission. Au bilan,
le joueur sait ce qui est devenu utilisable et pourquoi certains travaux ont
attendu. Il a une raison concrète d’ajuster la journée suivante.

## 2. Contrat de journée proposé — à valider

### Préparer

Le temps est arrêté. Le joueur peut consulter les nouvelles informations,
sélectionner des sujets, réordonner du travail non commencé, ouvrir la boutique,
examiner son équipe et modifier les éléments d’organisation autorisés.
Consulter un écran ne consomme pas du temps de simulation.

L’absence de chronomètre réel n’implique pas que toutes les actions soient
gratuites : achats, changements d’organisation et interventions de management
peuvent avoir leurs coûts propres. Un budget quotidien d’attention, l’Énergie
actuelle ou une limite d’interventions restent à arbitrer ; ne pas les ajouter
par défaut pour remplir cette phase.

### Simuler

Une action explicite fait avancer la journée. Les personnes disponibles
prennent le travail autorisé dans leur file, réalisent leur part et transmettent
leurs sorties. Le découpage habituel se produit automatiquement.

La visualisation peut être accélérée ou abrégée sans changer le résultat simulé.
Les règles d’intervention pendant cette séquence restent ouvertes : observation
avec pause seulement, ou possibilité de décisions dont le temps d’effet est
explicitement annoncé. Le joueur ne doit pas gagner grâce à sa vitesse de clic.

### Comprendre, puis préparer la suite

La fin de journée stabilise l’état. Le bilan présente les nouveautés utiles,
les résultats financiers pertinents et les quelques problèmes qui appellent
une décision. Les tickets achevés restent consultables dans l’historique.
Les sujets et travaux inachevés conservent leur identité et leur avancement.

Éviter un bouton de validation pour chaque ticket livré, chaque bonus et
chaque événement courant. L’accès à la préparation suivante doit rester court.
L’articulation exacte entre bilan et préparation du lendemain est à maqueter
après validation de ce contrat, sans relancer le prototype maintenant.

## 3. Temps de travail et délai

| Notion | Ce qu’elle explique |
|---|---|
| Effort | La quantité de travail requise à un poste, selon le sujet et la capacité disponible. |
| Disponibilité | La part de la journée pendant laquelle une personne peut réellement contribuer. |
| Attente | Le temps passé dans une file ou à attendre une information, une dépendance ou une capacité. |
| Transmission | Le passage du travail entre activités ; son coût de coordination éventuel. |
| Délai | Le temps calendaire jusqu’à une sortie utile, qui dépend de ces différents éléments. |

Un sujet estimé à plusieurs jours de travail peut traverser plusieurs journées.
L’effort ne se transforme pas directement en promesse de date. Le parallèle
et les dépendances modifient le délai ; une nouvelle recrue ne double pas
automatiquement le débit de toute l’entreprise.

Les pas internes de simulation et l’unité de mesure des efforts restent à
définir. Il faut pouvoir représenter une disponibilité partielle sans imposer
un écran de planning à l’heure. Le temps des déplacements visibles doit être
discuté : coût logistique réel, représentation d’une coordination, ou simple
animation. Les pas des personnages ne sont pas encore un contrat d’équilibrage.

## 4. Objets et relations de travail proposés

Un sujet porte une intention produit, un périmètre et des informations connues
ou incertaines. Ses lots et tickets restent reliés à cette intention. Ils ne
créent pas une nouvelle monnaie ni un score indépendant.

Un lot regroupe une partie cohérente du sujet. Un ticket porte une activité
réalisable. Les relations peuvent inclure parent, descendants, dépendances et
sortie utilisable attendue. L’état « travail terminé » se distingue de l’état
« amélioration disponible » tant que des dépendances restent nécessaires.

L’interface doit distinguer au minimum : proposition, sélection préparée,
travail engagé, attente, traitement, blocage, travail terminé et résultat livré.
Ce sont des distinctions sémantiques, pas une exigence de huit colonnes visibles.

Les sujets techniques, exploratoires et fonctionnels ont des parcours adaptés.
Un saut d’étape indique qu’une activité n’est pas requise ; il ne signifie
pas que son effort a été exécuté instantanément. L’ajout d’une analyse technique
doit correspondre à une décision ou une propriété de l’organisation identifiable.

## 5. Découpage automatique proposé

### Sources possibles

Le fonctionnement pourrait dépendre du type de sujet, des compétences des
personnes, des pratiques adoptées et des outils actifs. Le poids et l’ordre
d’application de ces sources sont encore à définir. Un réglage manuel gratuit
qui écrase tous ces effets n’est pas supposé disponible.

Le joueur doit comprendre avant un investissement ce qui va changer dans le
fonctionnement : lots plus petits, préparation différente, transmission plus
rapide, périmètres mieux exploitables ou moins de reprises. Le rendement futur
reste dépendant des travaux qui traverseront réellement cette organisation.

### Sorties attendues

Le découpage génère des travaux identifiables et liés au parent, avec un effort,
un ordre et des dépendances compréhensibles. Une même organisation doit pouvoir
produire des découpages différents selon le sujet, sans ouvrir un dialogue
obligatoire à chaque frontière.

Le gain principal peut être une arrivée plus précoce de travail exploitable
en aval, même si l’effort total ne baisse pas. Une granularité excessive peut
entraîner une préparation ou une coordination supplémentaire. Les conditions
de ces effets et leurs valeurs restent à écrire.

### Changements en cours de travail

Proposition à valider : une nouvelle règle de découpage s’applique aux futurs
travaux compatibles. Les tickets déjà en cours ne sont ni effacés ni
recréés gratuitement. Une éventuelle réorganisation de l’existant doit annoncer
ce qu’elle conserve et ce qu’elle coûte.

Le joueur intervient sur les priorités et les exceptions utiles. Le tri exact
entre décision stratégique, paramètre de fonctionnement et intervention ponctuelle
reste un chantier de conception ; il ne faut pas déplacer les anciennes
confirmations dans une fiche à ouvrir plusieurs fois par jour.

## 6. Livrer quelque chose que le joueur peut nommer

### Proposition privilégiée à discuter

Définir des incréments utilisables au sein du sujet. Ils peuvent être livrés
lorsque les travaux requis sont terminés et leurs dépendances satisfaites.
Le joueur choisit un périmètre produit ; il ne doit pas étiqueter manuellement
chaque ticket technique pour que ce système fonctionne.

Exemple : « un vendeur peut importer un premier catalogue » est un résultat
compréhensible. « le parseur est développé » peut être du travail nécessaire
sans être encore une capacité disponible pour ce vendeur.

Le bilan relie le résultat aux travaux qui l’ont rendu possible et aux bonus
organisationnels observés. Le détail des tickets reste disponible, tandis que
le premier niveau montre ce qui a changé dans le produit.

### Attribution de valeur à trancher

- Quels résultats accordent de l’Impact, et à quel moment ?
- Quel effet sur les clients dépend du périmètre effectivement utilisable ?
- Comment les dépendances, la qualité, les risques et les reprises modifient-ils le résultat ?
- Comment une livraison partielle peut-elle être utile sans être un découpage artificiel rentable ?
- Comment les travaux internes améliorent-ils l’organisation sans se faire passer pour une fonctionnalité client ?

La règle de distribution fixe des points entre tous les tickets du prototype
reste un exemple technique. Elle ne répond pas encore à ces questions.
L’exploration peut ouvrir une information ou une option ; elle ne produit pas
automatiquement le même type de livraison qu’un développement.

## 7. Événements humains proposés

La journée offre un moment pour prendre connaissance d’une indisponibilité
ou d’une difficulté et choisir une réponse avant de lancer le travail.

| Situation illustrative | Effet sur le flux à examiner | Choix possibles à concevoir |
|---|---|---|
| Absence temporaire | Capacité indisponible et travail conservé | Attendre, réaffecter, modifier l’ambition de la journée. |
| Arrivée tardive | Capacité partielle ou prise en charge différée | Ajuster la priorité, mobiliser une autre personne, accepter le délai. |
| Surcharge ou fatigue | Capacité, qualité ou reprises affectées selon les règles retenues | Réduire les engagements, laisser du repos, changer la répartition. |
| Expertise manquante | Attente, incertitude ou effort accru sur certains sujets | Former, recruter, demander une aide ou choisir un autre périmètre. |

Ces événements ne sont pas encore spécifiés en probabilités, durées ou coûts.
Ils doivent être raccordés aux personnes et états existants avant d’ajouter
de nouvelles jauges. Une réaffectation peut demander une transmission ou une
reprise de contexte ; elle ne doit pas être supposée instantanée et gratuite.

Limiter les interruptions obligatoires et rendre les informations ordinaires
consultables dans le briefing. Un incident doit expliquer son effet sur le
travail et les options accessibles, sans exiger un dialogue pour chaque personne
et chaque journée.

## 8. Cas écrits pour la prochaine relecture

### A — Petits lots, mêmes sujets

Comparer une organisation qui garde de gros lots et une organisation qui
produit plus tôt de petits périmètres. Observer l’arrivée du travail en aval,
les coûts de préparation et la première amélioration utilisable. Aucun dialogue
de découpage courant n’apparaît. Vérifier que les deux fonctionnements ont
des situations favorables et que la fragmentation seule ne crée pas de valeur.

### B — Le connecteur existe, mais n’est pas encore utilisable

Les travaux techniques progressent sur plusieurs journées. Le bilan distingue
les tickets achevés de la capacité d’import disponible. Lorsqu’un premier
périmètre devient utilisable, le joueur comprend ce qu’un vendeur peut faire
et pourquoi cette livraison apporte son résultat.

### C — Le designer est absent une journée

La préparation annonce l’indisponibilité et montre les sujets concernés. Le
joueur peut consulter la boutique et ses options sans faire avancer le temps.
Les travaux prêts pour les développeurs peuvent progresser ; les travaux qui
nécessitent encore la contribution absente attendent. Le lendemain, le travail
reprend sans perte silencieuse de progression.

### D — Un poste aval est saturé

L’ajout d’une personne en amont ne fait pas automatiquement disparaître la
file de développement. Comparer une autre priorité, un investissement adapté
au poste et une organisation qui engage moins de travaux. L’effet doit se
voir dans les files et les résultats, pas seulement dans un nombre de bonus.

### E — Une journée calme

L’organisation traite ses tickets et les découpe sans intervention routinière.
Le joueur peut simplement observer, lire le bilan et avancer. Le jeu ne doit
pas fabriquer une décision obligatoire pour justifier chaque journée.

### F — Acheter avant l’échéance

L’investissement réduit le solde d’Impact comparé au quota et annonce ses
éventuelles charges monétaires. La journée ne démarre pas pendant que le joueur
examine le choix. Le rendement observé peut justifier ou non le pari, sans
conversion automatique de l’Impact en trésorerie.

## 9. Arbitrages à traiter avant le découpage technique

| ID | Question | Proposition de départ, non validée |
|---|---|---|
| A01 | Quel contrôle du temps ? | Préparation sans pression, action explicite pour simuler une journée, bilan stable. |
| A02 | Qu’est-ce qui compte comme livraison ? | Un incrément utilisable, relié à ses travaux et dépendances. |
| A03 | Qui détermine le découpage ? | Organisation et profils ; définir le rôle respectif des pratiques, outils et réglages. |
| A04 | Quand les changements prennent-ils effet ? | Sur les futurs travaux, avec un traitement explicite de l’existant. |
| A05 | Combien d’interventions et d’événements quotidiens ? | Assez pour créer un arbitrage, sans dialogues routiniers ; budget éventuel à décider. |
| A06 | Quel calendrier économique ? | Définir le raccord jours / trimestres / charges / quotas ; ne pas diviser arbitrairement les valeurs par sprint. |
| A07 | Comment les combos se raccordent-ils au flux réel ? | Éviter les doubles récompenses involontaires ; garder plusieurs styles viables. |
| A08 | Quel premier périmètre de production ? | Quelques parcours de sujets et réponses humaines ; catalogue, rendu et migrations à choisir ensuite. |

La conception est prête pour le découpage technique lorsque ces comportements
ont été relus, que les cas A à F ont une réponse cohérente et que les règles
économiques et temporelles sont explicitement validées. Il n’est pas nécessaire
de relancer du développement pour résoudre ces questions.
