# PRODUCT TYCOON — Carnet de règles

*Document de travail. Sert de base de réflexion pour le développement — pas encore équilibré, pas encore final.*

**Sommaire**
1. Concept en une phrase
2. Structure temporelle
3. Anatomie d'un sprint
4. Les ressources
5. Tensions entre ressources
6. Le système de cartes
7. Effets persistants — Fondations, prérequis et stacks
8. Roadmap & features
9. Recrutement — le shop
10. Les époques (contextes de run)
11. Modèle d'effet unifié
12. Fins de mandat
13. Hypothèses et questions ouvertes

---

## 1. Concept en une phrase

Un roguelike où vous incarnez le·la CPO fraîchement nommé·e d'une organisation que vous n'avez pas construite. Contexte tiré au sort, équipe héritée, décisions rarement réversibles. Chaque bonne pratique promet une amélioration théorique — son effet réel dépend de qui la reçoit.

---

## 2. Structure temporelle

Trois échelles imbriquées :

| Échelle | Durée fictive | Rôle |
|---|---|---|
| **Sprint** | ~2 semaines | Unité de jeu de base — un tour complet |
| **Trimestre** | 3 sprints | Quota d'Impact et exigence du board, événement "boss" |
| **Mandat** | 4 trimestres, puis optionnellement sans limite | Le run entier, de la nomination à la sortie ou au mandat long |

---

## 3. Anatomie d'un sprint

Quatre phases, dans l'ordre :

1. **Inbox** — un événement aléatoire tombe (le "chaos humain") et force un choix avant toute planification.
2. **Roadmap** — 2 à 4 features proposées, sélection limitée par la **capacité** de l'équipe. Dépasser sa capacité déclenche une surchauffe (dette + cynisme en hausse).
3. **Investissements** — tout ce que l'organisation acquiert, en deux rayons d'un même écran : l'**étal du sprint** (2 candidats + 2 pratiques tirés pour ce sprint, voir §9) puis les **grandes décisions** (catalogue permanent, activation optionnelle, voir §6.2). Les deux sont facultatifs ; l'arbitrage du tour est de choisir *où* passe la pièce.
4. **Résolution** — application des effets, delta affiché (voir maquette HUD dans la landing page).

> Les grandes décisions ont eu leur propre phase jusqu'au Lot 2 de la refonte UI (§20) : n'étant activées que 3-4 fois par mandat, elle n'était qu'un péage à cliquer 8 à 9 sprints sur 12.

---

## 4. Les ressources

Six jauges. Aucune ne s'optimise seule.

| Ressource | Représente | Monte | Descend | À l'extrême |
|---|---|---|---|---|
| 💰 Trésorerie | Temps avant que la survie devienne le seul sujet | Levée de fonds, ventes, coupes budgétaires | Masse salariale, outillage, tout ROI "plus tard" | À sec → **Faillite** |
| 🫶 Moral & confiance d'équipe | S'effondre en un sprint, se reconstruit en dix | Autonomie réelle, reconnaissance, cohérence discours/actes | Pivots non expliqués, reporting excessif, promesses non tenues | Au plancher → **Exode d'équipe** |
| 🧱 Dette organisationnelle | Prix différé de chaque raccourci | Livrer vite, sauter les revues, exceptions "juste cette fois" | Sprints de remise à plat, refus assumés | Au maximum → **Entreprise zombie** |
| 🎯 Capital politique | Crédibilité auprès du board/investisseurs | Résultats visibles, alliés bien placés, reporting rassurant | Objectifs manqués, silence en crise | À zéro → **Rachat hostile** |
| 📈 Valeur perçue | Ce que le marché pense de vous | Features qui résolvent un vrai problème, bouche-à-oreille | Retards visibles, concurrents qui avancent | Au plancher → perte de terrain face à la concurrence |
| 🎭 Cynisme | Jauge invisible du théâtre d'entreprise | Process imposés sans contexte, "parce que ça se fait ailleurs" | Pratiques expliquées et adoptées sincèrement | Au maximum → les meilleures pratiques ne produisent plus que leurs effets pervers |

---

## 5. Tensions entre ressources

- **Capital politique ↑ / Moral ↓** — rassurer le board coûte souvent la confiance du terrain.
- **Trésorerie ↑ / Dette organisationnelle ↑** — couper les coins ronds fait gagner du cash à court terme, à rembourser avec intérêts.
- **Valeur perçue ↑ / Moral ↓** — pousser une feature en urgence épuise l'équipe qui l'a livrée.
- **Cynisme ↑** quand une pratique est copiée sans la culture qui va avec — et plus il est haut, pires deviennent tous les choix suivants.

---

## 6. Le système de cartes

### 6.1 Décisions tactiques
Une main piochée chaque sprint dans un deck — arbitrages du quotidien (priorisation ponctuelle, réponse à un incident, micro-ajustement). C'est la couche aléatoire, façon deckbuilder.

### 6.2 Grandes décisions structurelles
Limitées à 3-4 activations par mandat, et payées en 🪙 comme le reste du rayon (§21) : un coût court (l'argent) et un coût long (le slot). Reflète le fait qu'une organisation ne change pas d'outil toutes les deux semaines. Elles sont **tirées** au rayon des Investissements, comme les candidats et les pratiques (§21 — c'était un menu permanent jusqu'au Lot 2 de la refonte UI) : ce qui n'est pas activé aujourd'hui n'est pas garanti de revenir. Trois familles, qui ne se comportent pas pareil dans le temps (détail en §7) :
- **Outils/process** (RICE, Notion, Jira) — effet direct sur les jauges
- **Stack technique/produit** (ex. React) — effet sur le shop de recrutement, pas sur les jauges
- **Méthodologie d'orga** (ex. Shape Up) — gatée par prérequis, n'apporte rien tant que les bonnes conditions ne sont pas réunies

**Exemples calibrés (indicatif, à équilibrer) :**

| Carte | Équipe | Coût humain | Coût financier | Time-to-market | Productivité |
|---|---|---|---|---|---|
| **RICE Scoring** | Junior (startup, 18 mois) | +25 | −5 | −15 | +30 |
| **RICE Scoring** | Senior (grand groupe, 12 ans) | −35 | −5 | −25 | +10 |
| **Notion** | Junior | +30 | −10 | +15 | −10 |
| **Notion** | Senior | −10 | −10 | −5 | −30 |
| **Jira** | Junior | −30 | −20 | −20 | +15 |
| **Jira** | Senior | +5 | −15 | +5 | +35 |

*(Positif = bénéfice, négatif = coût. Ces axes sont la loupe sur une décision précise ; les ressources du §4 sont le baromètre cumulé sur l'ensemble de l'organisation.)*

---

## 7. Effets persistants — Fondations, prérequis et stacks

*Un choix qui ne vit qu'un sprint ne raconte rien. Ce qui suit remplace un compte à rebours arbitraire par des conséquences lisibles.*

### 7.1 Le principe par défaut
Toute grande décision (outil, feature, recrutement) applique son coût immédiatement. Son effet — bonus ou malus durable — est actif dès le sprint suivant. Un seul palier de décalage, prévisible, pas de grind.

### 7.2 L'exception : la friction contextuelle
Un coût ou un délai supplémentaire ne se justifie que lorsqu'une décision ne correspond pas au terrain — pas comme règle générale. Exemple : Notion adopté par une équipe senior habituée au PowerPoint coûte déjà plus cher (calibré au §6.2), et son bonus met un sprint de plus à se stabiliser, le temps que l'équipe désapprenne un réflexe. Sur une équipe junior : aucun délai supplémentaire.

### 7.3 Les prérequis — le vrai "build"
Une Fondation ambitieuse peut rester inactive tant qu'une condition sur le plateau n'est pas remplie — pas un minuteur, une vérification continue. Affichée comme "en attente" tant que ce n'est pas vrai ; s'active au sprint suivant dès que la condition l'est.

> Exemple : **"Passage en Shape Up"** reste affichée *"🕐 en attente — manque : 1 Lead formé."* Trois sprints plus tard, le joueur recrute ce profil au shop. Au sprint suivant, la condition est remplie : *"+production de features ×2"* s'active automatiquement.

### 7.4 Les stacks transverses
Certaines grandes décisions n'affectent pas les jauges directement, mais modifient un autre système — typiquement le shop de recrutement.

> Exemple : **"Stack React"** ne touche aucune jauge en elle-même. Dès le sprint suivant, les profils "Dev Frontend" apparaissent deux fois plus souvent dans le shop, à coût réduit. Un joueur qui la prend tôt bâtit son équipe technique bien plus vite qu'un autre — un build reconnaissable, pas un bonus caché dans une jauge.

---

## 8. Roadmap & features

Chaque sprint : 2 à 4 features proposées, chacune avec une promesse théorique affichée et un effet terrain caché (même logique de dualité que les cartes structurelles). Le nombre de features prises est plafonné par la **capacité** de l'équipe (déterminée par sa taille et sa composition). Dépasser la capacité = surchauffe = dette + cynisme.

---

## 9. Recrutement — le shop

### 9.1 Anatomie d'une carte Employé
- Poste
- Coût d'embauche + salaire récurrent (ponction continue sur la Trésorerie)
- Contribution à la capacité
- 1-2 traits qui modifient d'autres cartes (synergies ou frictions)
- Risque de départ lié au Moral (sous un seuil, chance de départ — potentiel mini-arc narratif)

### 9.2 Exemples d'archétypes

| Archétype | Coût | Capacité | Trait |
|---|---|---|---|
| Ex-consultant McKinsey | Élevé | + | Frameworks à −50% de coût humain, mais cynisme passif en hausse |
| Rockstar 10x | Élevé | ++ | Productivité individuelle forte, plombe le moral collectif s'il reste trop longtemps |
| Junior ambitieux | Faible | + (léger) | Adopte vite les nouveaux outils, capacité limitée |
| Vétéran désabusé | Faible | + | Résiste aux changements d'outils (coût humain ×1.5 sur cartes structurelles), stabilise le moral en crise |
| Wonderkid fraîchement diplômé | Très faible | + | Apprend vite, mais moral très volatile — part facilement si ça tourne mal |

### 9.3 Habillage par époque
- **Garage days** — petites annonces façon journal papier
- **Époque moderne** — board de recrutement tech, badges "culture fit", préavis, prétentions salariales
- **Ère IA** — catalogue d'agents à "abonner" plutôt que des CV à lire

---

## 10. Les époques (contextes de run)

| Époque | Période | Tension centrale | Boss de fin | Effets systémiques |
|---|---|---|---|---|
| 🛠️ Les années garage | 1976–1984 | Liberté totale ↔ épuisement fondateur | Le pitch devant les investisseurs | Pas de cartes "process" avant un jalon ; décisions informelles moins coûteuses en cynisme ; seuil de cynisme plus tolérant |
| 📋 La grande transformation agile | 2006–2014 | Rituels sincères ↔ théâtre d'entreprise | La revue de sprint devant le comité de direction | Cartes rituelles dispo dès le départ ; leur impact cynisme ×1.5 ; seuil de cynisme plus bas (l'organisation est déjà sceptique) |
| 🤖 L'IA qui remplace tout le monde | 20XX | Productivité affichée ↔ légitimité humaine | Le board demande pourquoi garder des humains | Employés-agents IA disponibles au shop ; gains productivité plus généreux, coûts moral plus élevés ; seuil de capital politique plus bas |

Trois leviers : le **pool** disponible (quelles cartes/employés existent), les **multiplicateurs** (quels axes sont amplifiés), et les **seuils de déclenchement** (à partir de quand une jauge fait basculer une fin).

---

## 11. Modèle d'effet unifié

Un seul objet "effet" partout : **ressource ciblée + magnitude + condition (profil d'équipe / époque) + durée (ponctuel ou tant que l'employé/la carte est actif)**. Les modificateurs s'empilent comme des remises cumulées sur un prix.

**Exemple chiffré :**
> Activer **RICE** en pleine **Transformation Agile**, avec un **Ex-consultant McKinsey** dans l'équipe, profil **senior**.
> - Effet de base (équipe senior) : Coût humain −35
> - Trait employé : réduit de moitié le coût humain sur les cartes de framework → −18
> - Multiplicateur d'époque sur l'effet cynisme des cartes rituelles (×1.5) : un effet secondaire cynisme +7 devient +11
>
> Affiché au joueur : Coût humain −18, Cynisme +11 en petit texte dans le journal du sprint.

Ordre d'application à figer tôt : carte → employé → époque, puis arrondi.

---

## 12. Fins de mandat

| Fin | Description |
|---|---|
| 🚀 IPO | Vous sonnez la cloche. Personne ne sait ce que fait vraiment le produit. |
| 🤝 Rachat | Un plus gros vous avale. Votre roadmap devient un slide dans leur QBR. |
| 💸 Faillite | Le runway touche zéro avant le product-market fit. |
| 🔥 Burn-out fondateur·rice | Vous démissionnez. La légende veut que vous ayez eu raison, en privé. |
| 🚪 Exode d'équipe | Ils partent tous la même semaine. Vous découvrez un canal Slack sans vous. |
| 🤖 Remplacé·e par l'IA | Le board a fini par répondre à sa propre question. |
| 🧟 Entreprise zombie | Tout continue de tourner. Plus personne ne sait pourquoi. |
| 🏛️ Rachat hostile | Vous n'étiez pas dans la salle où ça s'est décidé. |

---

## 13. Hypothèses et questions ouvertes

*Rien ici n'est tranché. Objectif : ne pas perdre les questions en cours de route.*

### Effets persistants (§7)
- La limite de 3-4 grandes décisions par mandat s'applique-t-elle globalement, ou séparément par famille (outils / stack / méthodologie) ?
- Combien de prérequis maximum une Fondation peut-elle porter avant que ce soit illisible pour le joueur ?
- Une décision de stack (type "Stack React") est-elle réversible en cours de mandat, ou définitive une fois prise ?
- Le shop indique-t-il à l'avance quels prérequis débloqueraient quelles Fondations en attente, ou le joueur le découvre-t-il par essai-erreur ?

### Ressources et lisibilité
- Les jauges sont-elles visibles en temps réel pendant la décision, ou seulement à la résolution du sprint ? (change la nature du risque perçu)
- Les seuils de bascule (faillite, exode, entreprise zombie...) sont-ils communiqués à l'avance, ou seulement découverts au moment où ils sont franchis ?

### Cartes et roadmap
- Nombre de features proposées par sprint / taille de la main de cartes tactiques — à calibrer par playtest
- Ce nombre varie-t-il selon l'époque ou la taille d'équipe, ou reste-t-il fixe tout le run ?

### Employés
- Un employé peut-il être licencié activement, ou seulement partir de lui-même (turnover subi) ?
- Deux traits d'employés peuvent-ils entrer en conflit dans la même équipe — et si oui, comment ça se résout ?

### Époques
- Peut-on changer d'époque en cours de mandat (un saut temporel narratif), ou est-ce fixé au tirage du run ?
- Les fins de mandat sont-elles communes à toutes les époques, ou certaines sont-elles propres à une seule (ex. "Remplacé·e par l'IA" n'existe qu'en ère IA) ?

### Boucle méta (entre les mandats)
- Y a-t-il une progression permanente entre les runs (déblocages, panthéon/mur de la honte évoqué au tout départ), ou chaque mandat repart de zéro ?
- Le joueur choisit-il son point de départ (archétype de CPO + époque), ou les deux sont-ils tirés au sort ?

### Non validé
- Archétypes de CPO de départ (piste proposée, jamais tranchée) : fondateur·rice visionnaire, PM parachuté·e en legacy org, growth hacker, coach agile évangéliste, responsable conformité — chacun avec un deck/une capacité de départ différents
- Valeurs finales de tous les effets — tout ce qui est chiffré dans ce document reste indicatif

---

## 14. Décisions de conception du MVP jouable

Pour rendre le jeu réellement jouable (simulation persistante, vraies fins de
mandat), certaines questions ouvertes du §13 ont dû recevoir une réponse
provisoire — pas une réponse définitive, une réponse suffisante pour avancer.
Tous les nombres cités ici vivent dans `data/balance.json`, pas dans le code :
les rééquilibrer ne demande aucune modification de script.

- **Mapping axes de carte → ressources.** Les 4 axes de `cards.json`
  (humain, financier, ttm, productivité) alimentent les 6 ressources ainsi :
  humain → Moral, financier → Trésorerie, time-to-market → Valeur perçue,
  productivité → Dette organisationnelle (relation inversée : plus de
  productivité réduit la dette). Voir `balance.json` → `cardAxisResourceMap`.
- **Seuils de fin de mandat.** Chaque ressource a un extrême qui déclenche une
  fin (repris de son champ `extreme` dans `resources.json`) : Trésorerie à 0
  → Faillite, Moral à 0 → Exode d'équipe, Dette à 100 → Entreprise zombie,
  Capital politique à 0 → Rachat hostile, Valeur perçue à 0 → Burn-out
  fondateur·rice, Cynisme à 100 → Remplacé·e par l'IA. Les seuils sont
  découverts par le joueur en jouant (pas annoncés à l'avance) — répond à la
  question de lisibilité du §13, dans le sens le plus proche du thème du jeu.
- **Longueur de mandat et fins positives.** Le premier arc dure 4 trimestres.
  Après le succès de T4, le joueur choisit sa sortie (IPO ou Rachat selon la
  moyenne de Valeur perçue et Capital politique) ou un mandat long sans limite,
  aux quotas multipliés par 2,2 et aux exigences cumulatives.
- **Époques : portée des effets systémiques.** Pour le MVP, chaque époque ne
  modifie que ce qui est mesurable simplement : les années garage relèvent le
  seuil de fin par Cynisme (plus tolérant), la Transformation agile
  multiplie par 1.5 l'effet Cynisme des grandes décisions activées, l'Ère IA
  abaisse le seuil de fin par Capital politique et modifie légèrement les
  effets Dette/Moral/Trésorerie des grandes décisions. Les autres effets
  narratifs des époques (cartes indisponibles avant un jalon, etc.) restent
  à implémenter — non couverts par le MVP.
- **Grandes décisions : une activation par carte.** Chaque carte structurelle
  (RICE, Notion, Jira) peut être activée une seule fois par mandat, jusqu'à
  la limite globale (`structuralDecisionMaxActivations`, 4 par défaut). Pas
  de réactivation ni de coût de bascule différencié pour le MVP — la nuance
  "coût de bascule" du §7 reste à implémenter.
- **Recrutement : effet immédiat, pas de simulation d'employé actif.** Une
  embauche coûte de la trésorerie, produit un effet immédiat sur les
  ressources, et augmente durablement la capacité de roadmap
  (`capacityBonus`). Il n'y a pas encore d'employé "vivant" avec un trait qui
  s'applique en continu sprint après sprint — les traits de
  `recruitment-archetypes.json` restent illustratifs pour le MVP.
- **Fondations = grandes décisions activées.** Le plateau des Fondations
  affiche l'état réel du mandat en cours (les cartes activées), pas encore de
  Fondation "en attente" avec prérequis (le cas Shape Up du fichier de démo
  reste un exemple de direction, pas une mécanique implémentée).
- **Valeurs de départ.** Les 6 ressources démarrent autour de 50-60 (hautes
  pour les jauges "plus haut = mieux", basses pour Dette et Cynisme). Voir
  `balance.json` → `startingResources`.

---

## 15. Scénarios, aléatoire et modèle économique

Deuxième vague de décisions, prise après un premier retour de jeu sur le MVP :
le tirage d'époque était déterministe (cyclique), il n'y avait pas de vrai
choix de scénario, et la trésorerie ne faisait que descendre — aucune
mécanique ne rendait visible le retour sur les décisions prises. Là encore,
tout ce qui est chiffré vit dans `data/balance.json`.

- **Écran de choix de scénario.** `scenario_screen` s'intercale entre
  l'Accueil et l'Inbox (et entre la fin d'un mandat et le suivant). Les 3
  scénarios de `eras.json` sont affichés, mais seuls ceux listés dans
  `balance.json` → `playableEras` sont sélectionnables — les autres
  s'affichent grisés, "Bientôt disponible". Pour l'instant, seule la
  **Transformation agile** est jouable ; Garage (Silicon Valley) et Ère IA
  attendent leur propre contenu (cartes, événements, modèle économique)
  avant d'être activés.
- **Le scénario conditionne le contenu, pas juste le décor.** Les cartes de
  `cards.json` et les événements de `inbox-events.json` peuvent porter un
  champ optionnel `eras: [...]` — absent, la carte/l'événement est
  disponible dans tous les scénarios ; présent, réservé aux scénarios listés.
  Deux cartes (Daily Standup, Sprint Rétro) sont réservées à la
  Transformation agile pour lui donner une identité propre au-delà des 3
  cartes génériques (RICE, Notion, Jira).
- **Aléatoire réel sur l'Inbox — pioche "sac".** Au lieu d'un tirage cyclique
  par index de sprint, `SprintState.draw_inbox_event()` mélange tous les
  événements éligibles au scénario en cours, les consomme un par un, et
  remélange un nouveau sac une fois épuisé (avec une garde anti-répétition
  immédiate entre deux sacs). Douze événements au total désormais, dont deux
  propres à la Transformation agile.
- **Modèle économique du scénario — le "ROI" rendu visible.** Chaque scénario
  jouable est associé à un `business_model_id` (`balance.json` →
  `eraBusinessModel`), qui détermine comment la Trésorerie *rentre*, pas
  seulement comment elle sort. La Transformation agile utilise le modèle
  **SaaS — revenu récurrent (MRR)** : le MRR est un stock. À chaque Résolution,
  `ScoreResolver` applique le churn puis ajoute `Impact × 0,06` et les ROI
  récurrents déjà acquis. Le Moral et la Dette peuvent porter le churn à 15 %.
  Le revenu versé à la Trésorerie est le nouveau stock de MRR, affiché
  séparément des coûts de décisions — investir dans le moteur produit compose
  désormais d'un sprint à l'autre.
- **Vente à la version (waterfall) — scénario Garage, à venir.** Le modèle
  `waterfall-release` est déclaré dans `balance.json` mais désactivé (pas de
  revenu par point de Valeur perçue) : il accompagnera le scénario Garage
  quand celui-ci sera ouvert — gros paliers de revenu à la sortie d'une
  version plutôt qu'un flux continu, cohérent avec un produit vendu à la
  version plutôt qu'en abonnement.
- **Pivot de business model en cours de run — non implémenté.** L'idée qu'un
  événement Inbox rare puisse faire basculer le modèle économique en cours
  de mandat (ex. un pivot SaaS → vente one-shot) est notée pour plus tard,
  une fois au moins deux modèles réellement jouables.
- **Résolution animée.** La démo rejoue le rapport immuable de `ScoreResolver`
  événement par événement : livraison, bonus de main, équipe, outils,
  stratégie, pratiques, freins, Impact puis conversion. Les compteurs suivent
  les valeurs `before/after`; les jauges persistent ensuite le résultat. Un
  premier clic accélère la séquence, un second la révèle entièrement.
- **Barre de ressources permanente.** Les 4 écrans de phase (Inbox, Roadmap,
  Grandes décisions, Recrutement) affichent désormais un mini-HUD des 6
  ressources en haut de l'écran (`UIHelpers.build_resource_bar()`) — l'état
  *après la dernière Résolution*, pas un aperçu des effets en cours, pour ne
  pas déflorer la Résolution.

---

## 16. L'entreprise : contexte RP et fin des réglages libres

Troisième vague de retours : le profil d'équipe (Junior/Senior) et l'habillage
du shop de recrutement (Époque moderne/Petites annonces) étaient des boutons à
bascule que le joueur pouvait changer librement à tout moment — alors que ce
sont des traits du contexte de la run, pas des réglages. Cette section
documente comment ils sont devenus des conséquences d'un choix fait une seule
fois, au début du mandat.

- **L'entreprise — une "offre d'emploi" par run.** Nouveau fichier
  `data/companies.json` : chaque entrée est une entreprise liée à un scénario
  (`era`), avec un nom, une accroche façon offre d'emploi, une description qui
  pose le contexte, et surtout un `teamProfile` (junior ou senior) qui **fixe**
  le profil d'équipe pour tout le mandat. Deux entreprises sont disponibles
  pour la Transformation agile : Meridia (grand groupe, équipe senior) et
  Karavel (scale-up, équipe junior) — un vrai choix avec un vrai impact sur le
  calibrage des cartes, pas deux variantes cosmétiques.
- **Nouvel écran `company_select_screen`.** S'intercale entre le choix du
  scénario et l'Inbox : le joueur voit les entreprises du scénario choisi et
  en sélectionne une. `SprintState.reset_run(era_id, company_id)` fixe alors
  `team_profile` depuis `company.teamProfile` — ce n'est plus une valeur par
  défaut modifiable en jeu.
- **Grandes décisions : le toggle devient un badge.** L'écran affiche
  toujours l'icône + le libellé du profil d'équipe (repris de `cards.json` →
  `teamProfiles`), mais en lecture seule — impossible de re-basculer entre
  Junior et Senior en cours de mandat pour voir "ce que ça aurait donné".
- **Recrutement : l'habillage suit le scénario.** `data/balance.json` →
  `eraRecruitmentSkin` associe un scénario à un skin de `recruitment-demo.json`
  (Transformation agile → "Époque moderne"). Le bouton de bascule a disparu ;
  le skin "Petites annonces — garage days" attend le scénario Garage pour
  redevenir pertinent thématiquement.
- **Tooltips sur la barre de ressources.** Chaque item de
  `UIHelpers.build_resource_bar()` porte un `tooltip_text` (nom + définition +
  ce qui la fait monter/descendre, tiré de `resources.json`) — affiché au
  survol par le tooltip natif de Godot, sans UI custom à maintenir.
- **Panneau "Entreprise".** `scenes/components/company_panel.tscn` est un
  overlay non-modal (même logique que le panneau Règles de l'Accueil) branché
  sur chaque écran de phase via `UIHelpers.attach_company_menu()` — jamais un
  changement de scène, pour ne pas perturber un état déjà consommé (un
  événement Inbox déjà tiré, par exemple). Il résume le contexte de la run
  (entreprise, scénario, profil, modèle économique, ressources) et réserve une
  section **Pilotage verrouillée** ("🔒 Bientôt disponible — burn down,
  répartition grands comptes / petits comptes...") : l'intention est actée,
  la donnée sous-jacente (quels comptes, quel burn down) n'existe pas encore
  dans la simulation et reste à concevoir avant de débloquer l'écran.

---

## 17. Phase A — fondations économiques et pression

Implémentation du premier lot de la
[spec de profondeur de gameplay](spec-profondeur-gameplay.md) (§13-A). Tout
le chiffrage vit dans `data/balance.json` ; les pools de contenu dans
`data/candidates.json`, `data/practices.json` et `data/hidden-traits.json`.

- **Le roster produit la capacité.** `SprintState.squads[0].roster` remplace le
  `capacity_bonus` plat ; `get_roster()` fournit la vue globale de lecture.
  Chaque entreprise définit son équipe héritée, son
  cap d'effectif et son budget d'action initial (`companies.json`). Devs et
  PM produisent des points de capacité (rendements décroissants au-delà du
  cap de cumul du rôle), les Designers bonifient la Valeur perçue des
  features livrées (÷2 en leur absence), les Ops contiennent la dette
  (+2 Dette/sprint sans eux — le défaut affiché de Karavel). Les salaires
  (junior 1, senior 2) sont prélevés à chaque Résolution, ligne « masse
  salariale ».
- **Le Budget d'investissement 🪙.** `pieces` reste son nom interne. Il gagne
  `floor(sqrt(Impact))`, une allocation plancher (+2/sprint, réduite à +1
  après une revue ratée), le combo de deux quick wins (+2) et les effets
  Inbox (`pieces`). Il se dépense au Marché et en indemnités. À 0 on ne perd
  pas — on est paralysé.
- **Le Marché.** L'écran Recrutement devient un shop unifié : 2 candidats +
  2 pratiques tirés par sprint et stockés dans `SprintState` (pas de
  re-tirage). Chaque pratique achetée inflige +2 Cynisme ; Entretiens
  structurés révèle les traits cachés des candidats dès le Marché, les
  pratiques de révélation roadmap posent leurs flags pour la Phase C.
- **Traits cachés.** Tirés à l'apparition du candidat (~50 % aucun, 30 %
  négatif, 20 % positif), révélés en fin de période d'essai (embauche +
  2 sprints) — leurs effets ne s'appliquent qu'une fois révélés. Négociateur
  s'augmente tout seul, Démission silencieuse part au sprint d'embauche +4,
  Réseau offre −2 🪙 sur l'embauche suivante.
- **Licenciement.** Indemnités 2 🪙, Moral −4, +3 Cynisme par licenciement
  supplémentaire dans le mandat (`fired_count`).
- **La pression.** Valeur perçue −2/sprint (le marché avance), tandis que le
  churn rogne séparément le stock de MRR. Le couperet « Valeur perçue ≤ 0 =
  fin » disparaît, la mort passe par la spirale économique. La revue unique du
  sprint 6 est remplacée par les quotas trimestriels détaillés au §27.
- **Recette.** Les smoke tests pilotent ces systèmes ; la stratégie `careful`
  (ne rien livrer, ne rien acheter, ne rien recruter) manque désormais son
  premier quota, tandis que la spirale de burn-out reste atteignable.

## 18. Phase B — l'économie du joueur : Énergie et actions personnelles

Implémentation du deuxième lot de la
[spec de profondeur de gameplay](spec-profondeur-gameplay.md) (§7, §8.3,
§13-B), construit sur la Phase A. Tout le chiffrage vit dans
`data/balance.json` → `energy`.

- **La jauge d'Énergie ⚡.** Personnelle au CPO, 0-100, départ 70, côté jeu
  uniquement (`SprintState.energy` — jamais dans `resources.json`, partagé
  avec la landing). Affichée dans le groupe « Vous » de la barre de
  ressources, à côté du Capital politique, avec tooltip.
- **Régénération modulée par le Moral.** +12/sprint à la Résolution, ×1 si
  Moral ≥ 60, ×0.5 entre 30 et 60, ×0 sous 30 (`moralRegenTiers`) — les
  problèmes de la boîte finissent par vous suivre à la maison. Le Moral lu
  est celui d'après l'application des effets du sprint : l'état dans lequel
  l'équipe le termine.
- **Actions personnelles.** Boutons contextuels, limités par l'Énergie
  seule ; on peut puiser dans la réserve jusqu'à 0 (la dépense plafonne à
  ce qui reste) : 🤝 **1:1** (Marché ou panneau Entreprise, 10 ⚡) révèle le
  trait caché d'un candidat avant embauche ou d'un employé — sur un employé,
  les traits à déclencheur (Négociateur, Réseau) tombent immédiatement ;
  🔧 **Faire le taf soi-même** (Roadmap, 25 ⚡, cumulable) ajoute +2 points
  de capacité ce sprint ; 🏛️ **Négocier une rallonge** (panneau Entreprise,
  10 ⚡) échange −8 Capital politique (réglé à la Résolution) contre +4
  Pièces immédiates ; 🧘 **Souffler** (Résolution, gratuit) renonce aux
  actions personnelles du prochain sprint contre +10 de régénération, non
  modulée — le repos, lui, marche toujours. « Plonger dans une feature »
  attend la roadmap profonde (Phase C).
- **Burn-out remappé.** La fin Burn-out fondateur·rice se déclenche sur
  **Énergie ≤ 0** à la Résolution (pseudo-ressource `energie` dans
  `endingThresholds`) — l'ancien couperet Valeur perçue avait déjà disparu
  en Phase A. Pas de mort subite : la spirale (Moral bas → régén nulle →
  compenser soi-même → 0) se lit sur la barre.
- **Inbox.** Les `effects` des choix acceptent la pseudo-ressource
  `energie` — trois crises existantes vous suivent désormais à la maison
  (incident en démo, surcharge de Kevin, audit RGPD).
- **Résolution.** Ligne « ⚡ Énergie » détaillée (régén et sa modulation
  par le Moral, bonus de Souffler, événements, dépenses d'actions
  personnelles) et bouton Souffler.
- **Recette.** Les stratégies des smoke tests jouent les actions
  personnelles (`greedy` avec discernement, `stress` en compensation
  permanente) ; critères impératifs vérifiés en sortie non nulle : la
  spirale burn-out reste atteignable (`stress` la déclenche sur Meridia
  vers le sprint 2-4) et `careful` perd toujours.

---

## 19. Refonte UI — Lot 1 : le socle visuel

Premier lot de la [proposition UI](proposition-ui-interface.md), en réponse aux
cinq retours post-Phase B. **Aucune règle ni aucun flux ne change** : les
mêmes données, les mêmes effets, les mêmes phases — seule la façon de les
présenter change. Le lot suivant (§20) fusionne les écrans Grandes décisions et
Marché en « Investissements » ; celui d'après ajoutera la preview d'impact.

- **Le thème passe en clair.** `resources/theme/main_theme.tres` inverse la
  palette (fond `#f4f6f3`, encre `#2a2f38`) et le fond quadrillé sombre devient
  du papier réglé. La direction retenue (« Post-it & Feutre ») est claire : tant
  que le thème restait sombre, chaque écran refait jurait avec les autres. Les
  boutons deviennent des boutons « papier » — fond blanc, filet d'encre épais,
  encre inversée à l'appui, ce qui rend enfin lisible l'état d'un bouton à
  bascule (une feature retenue sur la Roadmap est remplie d'encre).
  `UIHelpers.style_primary_button()` réserve le remplissage plein au geste
  principal d'un écran ou d'une carte.
- **Un seul objet : l'Actif.** `scenes/components/asset_card.tscn` sert les
  trois types (grande décision, candidat, pratique) avec six zones toujours à
  la même place — le joueur apprend la carte une fois. La traduction des trois
  pools de données vers un descripteur commun vit dans `scripts/asset_view.gd` ;
  `cards.json`, `candidates.json` et `practices.json` ne sont **pas** fusionnés,
  seulement présentés par le même composant.
- **L'impact se dit en ressources, plus en axes.** Les cartes de décision
  affichaient les 4 axes abstraits (`humain`, `financier`, `ttm`,
  `productivite`) quand tout le reste du jeu parle en 6 jauges.
  `EffectResolver.card_impact_lines()` applique le même calcul que
  `resolve_card_activation()` (mapping `cardAxisResourceMap`, multiplicateur
  d'époque, arrondi) mais conserve la note d'axe comme texte de ligne : on lit
  « 🫶 Perçu comme un contrôle sur un instinct qui marchait déjà bien −35 ».
  C'est le prérequis pour que la preview du lot 3 soit honnête — elle projettera
  sur les jauges exactement ce qui est écrit sur la carte. Le sens de la
  ressource est respecté (`delta_is_good()` : une dette qui baisse est verte).
- **L'inconnu est une ligne d'impact comme les autres.** « 🔒 Trait caché —
  révélé en fin de période d'essai · ❓ » occupe une ligne de la zone Impact, au
  même endroit que les deltas connus : le pari est affiché, et payer de
  l'information (1:1, Entretiens structurés) transforme la ligne sur place.
- **Le Panneau de bord remplace la barre de ressources.**
  `scenes/components/side_panel.tscn` est une colonne fixe à droite des 4
  écrans de phase : jauges en **barres** (et non en pourcentages — il faut une
  géométrie sur laquelle projeter la preview du lot 3), pièces, bloc « Vous »,
  roster condensé, actifs possédés, quota et bonus qualitatif. Il est sombre dans un monde
  clair : diégétiquement l'écran TV du standup, et pratiquement la garantie que
  les chiffres restent lisibles là où le post-it échouerait.
- **Le roster est actionnable en un clic.** Un clic sur une ligne du panneau
  ouvre le menu 🤝 1:1 / 🚪 Licencier — plus besoin d'ouvrir un overlay puis de
  scroller. Le licenciement gagne une vraie confirmation (il est irréversible et
  coûte du Moral).
- **Les objectifs qualitatifs sont évalués en direct.**
  `SprintState.evaluate_board_objectives()` confronte les conditions de
  `companies.json` à l'état courant. Le panneau les affiche avec leur valeur
  lue ; depuis le lot quota (§27), ils débloquent un bonus et ne décident plus
  de la survie du mandat.
- **Le panneau Entreprise devient le « Dossier entreprise ».** Il garde ce
  qu'on lit une fois par mandat (contexte RP, modèle économique détaillé,
  objectifs commentés, roster détaillé, Pilotage, rallonge) et cède au panneau
  tout ce qui répond à « où j'en suis ». Règle de partage : le panneau répond à
  *où j'en suis*, le dossier à *dans quoi je joue*.
- **Icônes d'objets.** Les cartes portent une icône Kenney (CC0) par Actif — la
  « fausse 3D d'objets posés sur le tableau » de la direction retenue : une
  calculatrice pour RICE, un dossier suspendu pour Jira, un presse-papiers pour
  Discovery, une boussole pour le Tech radar. Le mapping est de la présentation,
  il vit dans `AssetView`, pas dans les données.
- **Ce que le lot ne fait pas.** Le rail replié du panneau, la preview d'impact
  au survol, l'animation d'achat et la fusion des écrans restent devant nous. Le
  flip « tagline ↔ détail » des cartes de décision disparaît : la nouvelle carte
  affiche l'accroche **et** les impacts commentés en même temps, comme le spike
  validé — il n'y a plus deux faces à retourner.
- **Recette.** Les deux smoke tests headless passent sans modification, plus un
  run visuel des 11 écrans (thème clair, cartes, panneau, dossier).

---

## 20. Refonte UI — Lot 2 : les Investissements (5 → 4 phases)

Deuxième lot de la [proposition UI](proposition-ui-interface.md) (§3). Le
premier lot avait donné aux trois types d'Actif la même carte ; celui-ci leur
donne le même écran. Le découpage du tour change, pas les coûts ni les effets —
la seule règle de simulation touchée est le passage des grandes décisions au
tirage, qui a sa propre section (§21).

```
Avant :  Inbox → Roadmap → Grandes décisions → Marché → Résolution
Après :  Inbox → Roadmap → Investissements ─────────→ Résolution
```

- **Une phase disparaît, pas un contenu.** Les grandes décisions ne sont
  activées que 3-4 fois par mandat : leur consacrer un écran plein *à chaque
  sprint* donnait 8 à 9 passages où l'écran n'était qu'un péage à cliquer. Elles
  deviennent un **rayon permanent** de l'écran d'acquisition. Un rayon qu'on
  longe sans s'arrêter coûte zéro clic ; un écran qu'on traverse en coûte un,
  plus un chargement de scène.
- **Un seul rayon, pas d'onglets.** L'intérêt de la fusion est précisément de
  mettre les investissements **en concurrence dans le même champ de vision** :
  « cette pièce, je la garde pour Lina ou je prends Discovery — ou est-ce que ce
  sprint est celui où j'active Jira ? ». Des onglets auraient reconstruit la
  cloison qu'on vient d'abattre. Le premier jet gardait deux rayons empilés
  (l'étal périssable au-dessus, le catalogue de décisions en dessous) ; l'étape
  suivante les a fondus en un seul, où les trois types se mélangent dans le même
  tirage — voir §21.
- **L'écran s'appelle « Investissements ».** Question ouverte du §7 de la
  proposition, tranchée : « Marché » ne couvrait que la moitié de ce qu'on y
  fait — on n'achète pas une méthodologie d'organisation sur un étal. Le mot
  couvre les trois types d'Actif et porte la bonne idée (ça coûte maintenant,
  ça rapporte — ou pas — plus tard). Le rayon périssable, lui, garde le nom
  d'« étal du sprint ». `recruitment_screen` et `decisions_screen` deviennent
  un seul `investments_screen`.
- **Les activées passent en fin de rayon.** Le catalogue met en avant ce qu'il
  reste à décider ; une carte activée reste visible (tamponnée, grisée) mais
  cesse d'occuper la tête de rayon. Elle ne se déplace que le sprint où on
  l'active, et garde son angle : c'est le même objet, posé ailleurs.
- **Le compteur de slots vit dans le titre du rayon** (« 1 activée · 3 slots
  restants sur 4 »), et une seconde fois dans la section Actifs du Panneau de
  bord. Le badge de profil d'équipe 🌱/🏛️, lui, avait déjà migré dans
  l'en-tête du panneau au Lot 1 : c'est un trait de la run, pas de la phase.
- **Les colonnes suivent la fenêtre, et la fenêtre grandit.** Les deux rayons
  partagent un nombre de colonnes calculé sur la largeur disponible (carte de
  236 px mini, 4 colonnes au plus) au lieu d'un compte fixe : avec le Panneau
  de bord qui prend 320 px, une grille à 4 colonnes fixes sortait une barre de
  défilement horizontale — supportable sur un rayon, absurde sur deux qui se
  répondent. Et la fenêtre par défaut passe de 1152×648 (la valeur d'usine de
  Godot) à **1600×900** : à 1152, il ne restait la place que de deux cartes de
  front, soit quatre écrans de défilement vertical pour lire les deux rayons —
  exactement ce que la fusion cherchait à éviter.
- **La Résolution devient la phase 4** ; les libellés de sprint, les
  enchaînements `NEXT_SCENE` et `data/structure.json` suivent.
- **Recette.** Les deux smoke tests headless (dont `smoke_test_ui`, qui passe
  de 10 à 9 écrans) plus un mandat complet joué à la main.

---

## 21. Le tirage des Investissements — hasard assumé, punaise et bail

Changement de **règle**, pas de présentation, arrivé avec le Lot 2 : mettre les
grandes décisions dans le même écran que l'étal a rendu criante l'asymétrie
entre les deux rayons. À gauche du même scroll, une offre périssable qui crée
de l'envie ; à droite, un catalogue permanent qui n'en crée aucune — une carte
qu'on peut activer *n'importe quand* ne se décide jamais maintenant.

- **Les décisions sont tirées comme le reste.** Une carte **activée sort du
  tirage définitivement** (elle ne peut de toute façon plus resservir).
- **Et elles se paient comme le reste.** Une grande décision coûte des 🪙
  (`cards.json` → `costPieces`, de 2 pour un rituel à 6 pour Jira et ses
  licences), en **plus** du slot de mandat. Sans ça, la mise en concurrence du
  rayon unique était fausse : « je garde ma pièce pour Lina ou j'active Jira ? »
  n'était pas une question tant que Jira ne coûtait pas de pièce. C'est aussi ce
  qui rend les décisions arbitrables quand elles deviendront le moteur de
  certains builds — un levier de scaling doit avoir un prix.
  - **Deux coûts, deux raretés.** Les 🪙 sont le budget d'**action** du sprint :
    ce qu'il faut dépenser maintenant, en concurrence directe avec une embauche.
    Le slot est la capacité d'encaissement de l'organisation sur tout le mandat
    (4 bascules, §6.2) : une boîte ne change pas d'outil toutes les deux
    semaines, même riche. L'argent est la contrainte courte, le slot la longue.
  - **Ni l'un ni l'autre n'est l'axe `financier` de la carte**, qui frappe la
    Trésorerie sprint après sprint : le prix d'achat n'est pas le coût
    d'exploitation. Les prix suivent quand même la fiction de cet axe — Daily
    Standup à 2 🪙 (« quasi nul »), Jira à 6 (« licences qui pèsent lourd »).
- **Un seul rayon, trois types mélangés.** Deux rayons séparés garantissaient
  encore à chaque type sa place, donc supprimaient la question « qu'est-ce que
  ce sprint m'a proposé ? ». Les trois types se partagent désormais
  `shopDraw.slotsPerSprint` emplacements (6) tirés dans un pool commun, dans un
  ordre d'affichage **mélangé** — un rayon trié par type redeviendrait trois
  rayons. Certains sprints proposent trois décisions et un seul candidat,
  d'autres l'inverse. C'est là que la concurrence devient réelle : la pièce
  gardée pour Lina est celle qui paierait Discovery, et le slot dépensé sur Jira
  est celui qu'on n'aura pas pour Shape Up.
  - **Garde-fous.** `guaranteedPerSprint` impose un minimum par type (1
    candidat, 1 décision) : le hasard peut décevoir, il ne doit pas produire un
    tour vide. C'est la seule entorse au hasard pur.
  - **`typeWeights`** répartit les emplacements restants entre types — et non la
    taille des pools : sans ça, les 12 candidats écraseraient les 6 décisions
    par simple effet de nombre.
- **Des taux d'apparition, pas un sac.** Le premier jet utilisait une pioche
  « sac » (on vide avant de reconstituer) pour les décisions comme pour les
  candidats. C'était un faux hasard : un sac se compte, et « j'ai vu 4 cartes
  sur 5, la dernière arrive » n'est plus un pari, c'est de la mémoire. Les
  trois rayons tirent donc **au poids, sans mémoire d'un sprint à l'autre** —
  une carte peut revenir deux sprints de suite ou manquer six sprints.
  - Chaque Actif déclare une **rareté** (`commune` / `notable` / `rare`), dont
    le poids vit dans `balance.json` → `shopDraw.rarityWeights`. Le même
    vocabulaire sert aux trois rayons — un seul mot à apprendre.
  - Un Actif peut **peser plus dans un scénario** via `eraWeights` : Jira sort
    deux fois plus souvent en pleine Transformation agile. C'est là que
    l'époque colore l'offre au lieu de seulement filtrer ce qui est disponible
    (`eras`, qui reste un filtre binaire).
  - La rareté ne s'affiche **que** quand elle sort de l'ordinaire (`◆ NOTABLE`,
    `◆◆ RARE`) : un marquage porté par toutes les cartes ne marque plus rien.
  - Seul un candidat déjà **embauché** et une pratique déjà **possédée**
    quittent leur pool : le marché du travail ne se vide pas parce qu'on a
    regardé une annonce.
- **Ce que ça achète, côté joueur.** La question devient « ça me coûte un slot
  sur quatre, mais est-ce que je la reverrai ? » au lieu de « je verrai plus
  tard ». Le regret est la moitié du sel d'un roguelike ; un menu permanent ne
  produit aucun regret.
- **Ce que ça coûte.** Le hasard peut servir trois sprints sans rien
  d'intéressant. D'où le contrepoids :
- **🎲 Re-tirer l'offre**, un bouton qui re-tire les **deux** rayons d'un coup
  contre des pièces. Le prix part de 1 🪙 et monte de 1 à chaque usage **dans le
  sprint** (`shopDraw.reroll`), puis repart à sa base au sprint suivant. Deux
  raisons de le faire monter : la première relance doit être accessible avec
  une allocation de board (2 🪙/sprint), et s'acharner doit coûter l'embauche
  qu'on aurait pu payer. Re-tirer les deux rayons ensemble et non un seul est
  volontaire : renoncer à un bon candidat pour aller chercher une décision fait
  partie du pari.
- **📌 Réserver**, l'autre réponse au hasard — une punaise dans le coin de la
  carte, pas un troisième bouton (deux boutons empilés suffisent déjà à la
  hauteur d'une carte, et « garder pour plus tard » est un geste de
  manipulation d'objet, pas une décision). Elle coûte 1 🪙, garantit l'Actif
  dans l'offre du **sprint suivant**, et **résiste au re-tirage** : payer pour
  garder doit tenir face au hasard qu'on paie pour rejouer. Le bail est d'un
  sprint — sinon une pièce annulerait toute la rareté qu'on vient de créer.
  Décoller la punaise dans le même sprint rembourse.
  - Les deux outils se répondent : 🎲 pour **chercher**, 📌 pour **garder**.
    Le combo « je punaise Lina, puis je re-tire le reste » est voulu.
- **🔒 Les cartes à prérequis et leur bail.** Une carte peut déclarer un
  `requires` (même grammaire de conditions que les objectifs de board, §8.2) :
  elle s'affiche complète, lisible, mais reste inactivable tant que la
  condition est fausse. Sa condition occupe une **ligne d'impact**, au même
  endroit que les deltas : un prérequis est une donnée de la décision, pas un
  message d'erreur.
  - Comme les cartes tournent à chaque sprint, une carte gatée tirée au mauvais
    moment serait une carte perdue. Elle prend donc un **bail** dès qu'elle
    sort : elle reste punaisée sur le rayon pendant un trimestre
    (`shopDraw.lockedLeaseSprints`, 6 sprints), **en plus** du tirage — le
    temps de réunir la condition. Un objectif à moyen terme apparaît au milieu
    du hasard, ce qui donne au rayon une deuxième vitesse de lecture.
  - Première carte du genre : **Passage en Shape Up** (`rare`, demande 2
    profils seniors). Sur Meridia — équipe senior héritée — la condition est
    déjà vraie et la carte n'est qu'un tirage rare de plus ; sur Karavel —
    équipe 100 % junior — c'est un vrai programme de recrutement. La même carte
    ne raconte pas la même chose selon la boîte.
- **Le tampon, et rien qui bouge.** À l'achat, la carte est **tamponnée sur
  place** — « ADOPTÉE », « EMBAUCHÉ·E », « ACTIVÉE » en travers, à l'encre rouge
  d'un tampon administratif : le tampon tombe de haut, s'écrase net et se
  redresse d'un rien (proposition UI §5.2, où il est le feedback d'acquisition
  commun aux quatre pistes de DA).
  - Un premier jet reléguait en fin de rayon ce qui venait d'être acquis, pour
    mettre en avant ce qu'il restait à décider. Mauvais échange : la carte qu'on
    vient d'acheter est précisément celle qu'on regarde, et la voir sauter
    ailleurs au moment du clic casse le lien entre le geste et son effet — on
    cherche des yeux ce qu'on tenait. **Une carte gagne sa place au tirage et la
    garde tout le sprint.** Le feedback est la marque, pas le déplacement.
  - La carte reste visible, tamponnée et grisée, jusqu'à la fin du tour, puis
    disparaît au sprint suivant : ce qu'on possède se relit dans le Panneau de
    bord et sur le plateau des Fondations, pas sur l'étal.
  - C'est la carte qui détecte l'acquisition (son descripteur *gagne* un tampon
    qu'il n'avait pas), pas l'écran qui déclenche une animation. Revenir sur
    l'écran ne re-tamponne donc pas ce qu'on avait déjà acheté.
- **Le rail replié du Panneau de bord**, resté sur l'établi depuis le Lot 1, est
  fait : un clic replie la colonne en un rail de 62 px qui garde les six jauges
  en vignette (barre + valeur, tooltips complets) et rend 260 px aux cartes. Sur
  un écran qui empile deux rayons, c'est une colonne de cartes entière.
- **Contenu.** Le catalogue ne compte que 6 cartes de décision : à 2 tirées par
  sprint, la rareté se sentira surtout quand il en comptera 10-15. C'est du
  contenu à écrire, pas une mécanique à revoir — les poids sont déjà en place et
  se règlent dans `balance.json` sans toucher au code.
- **Recette.** `smoke_test_logic` gagne un bloc déterministe
  (`_test_investment_draw_rules`) : offre sans doublon, stabilité du tirage dans
  le sprint, prix du re-tirage croissant puis remis à zéro, refus à sec,
  décision activée qui ne ressort jamais sur 30 sprints, **taux d'apparition
  vérifiés sur 600 sprints** (une `rare` doit sortir nettement moins qu'une
  `commune`, et `eraWeights` doit peser), **minimums garantis tenus sur 200
  sprints** avec au moins 4 dosages de rayon différents (sinon le « hasard entre
  types » n'en est pas un), punaise qui survit à un re-tirage puis tombe au bout
  d'un sprint, et bail complet d'une carte gatée (verrouillée, activable une
  fois la condition réunie, expirée à l'échéance).
  - `smoke_test_ui` ne se contente plus d'instancier les écrans : il **clique
    les vrais boutons** des Investissements (adopter, embaucher, activer,
    punaiser, replier). C'est ce qui a fait tomber le bug ci-dessous.
- **Un bug de fond, trouvé en jouant.** Tous les composants se reconstruisent
  de zéro à chaque changement d'état, et cette reconstruction est presque
  toujours déclenchée par le clic d'un bouton… qui vit dans le conteneur qu'on
  vide. Le `free()` direct détruisait donc le bouton **pendant l'émission de son
  signal** — « Object was freed or unreferenced while a signal is being emitted
  from it », à chaque embauche, chaque achat de pratique et chaque rallonge
  négociée. `UIHelpers.clear_children()` détache d'abord (`remove_child`, pour
  que l'ancien nœud ne se fasse pas mettre en page à côté de son remplaçant) et
  libère ensuite (`queue_free`). Le défaut datait du Lot 1 et touchait la carte
  d'Actif, le Panneau de bord et le Dossier entreprise.
  - La stratégie `stress` a dû être réécrite : elle activait « la première carte
    du catalogue » et comptait sur le −35 Moral de RICE pour amorcer la spirale
    du burn-out. Ce n'est plus possible — elle prend maintenant **la pire carte
    pour le Moral parmi celles tirées**, et ré-essaie chaque sprint. Le critère
    de recette (« la spirale burn-out reste atteignable ») tient toujours, mais
    il fallait que l'IA de test apprenne à jouer avec l'offre, comme un joueur.

## 24. Phase C — Roadmap profonde (Lot 0)

La Roadmap consomme maintenant exclusivement `data/backlog.json`; le fichier
`roadmap-features.json` reste la donnée de démonstration de la landing.

- **Tirage persistant.** `SprintState.current_backlog_draw` stocke 4 à 5
  propositions filtrées par époque pour le sprint. Le tirage utilise un sac;
  revenir sur l'écran ne change jamais l'offre. Les epics entamés s'ajoutent
  systématiquement aux nouvelles propositions jusqu'à leur complétion. Toute
  livraison quitte définitivement le sac: le même ROI ne peut pas être encaissé
  deux fois.
- **Informations et paris.** Le coût en points est toujours visible. ROI,
  Impact client et Risque sont masqués par défaut; Discovery, UX research et
  Tech radar révèlent définitivement leur colonne. **Plonger dans une feature**
  consomme l'Énergie configurée dans `balance.json` et révèle les trois valeurs
  pour le seul sprint courant.
- **Epics.** Le joueur choisit librement le nombre de points investi dans un
  epic, dont `costPoints` est le total. Aucune conséquence ne tombe avant la
  complétion; les attributs et `completionEffects` se résolvent alors une seule
  fois. **Abandonner l'epic** remet sa progression à zéro, sans remboursement;
  il quitte l'offre courante puis peut revenir dans un futur cycle du sac.
- **Résolution réelle.** Une livraison ajoute son `roi` au bonus MRR récurrent
  du mandat, applique son impact client et son risque (plus les effets de
  complétion), puis alimente le score. Le combo Quick wins est attribué une
  seule fois par `ScoreResolver`, pas par l'ancien flux de pièces. Le bonus
  Designer, la pénalité de surchauffe modulée par les PM et le bonus OKR restent
  résolus par le moteur, jamais par l'UI.
- **Recette.** Le smoke test logique vérifie la taille et la persistance du
  tirage, les révélations de Plonger, l'Énergie dépensée, le ROI permanent et
  la progression puis la complétion d'un epic.

## 25. Inbox en fil interne

L'Inbox conserve exactement le même tirage, les mêmes choix et les mêmes
deltas. Seule sa forme change : chaque événement porte un `channel`, le message
entrant affiche son expéditeur et son horodatage, puis le choix retenu rejoint
le fil comme réponse du joueur avant la conséquence. Un événement sans canal
retombe sur `#direction-produit`.

## 26. Traction × Levier = Impact (Lot 1)

`data/scoring.json` est la table d'équilibrage et
`game/scripts/score_resolver.gd` le moteur pur. Il ne lit ni ne modifie les
autoloads : un snapshot entre, un rapport ordonné en sort. `SprintState`
applique ensuite exactement ce rapport; l'écran de Résolution ne recalcule
rien.

1. Chaque feature rapporte `costPoints × 4 + clientImpact × 3`; une epic ne
   rapporte rien avant sa complétion, puis `costPoints × 6`.
2. Sprint parfait ×1,25, Focus ×1,3, livraison groupée +10, epic bouclée
   ×1,5 et série de livraisons modifient la main dans cet ordre.
3. Rôles, traits visibles et cachés, puis huit combos d'organisation
   data-driven construisent le Levier local de chaque entrée de `squads[]`.
4. Outils, stratégie, pratiques et palier produit construisent le Levier
   global. À une équipe, la couche multi-équipe reste invisible.
5. Cynisme, Dette, surchauffe et Moral au plancher rabotent le résultat avant
   l'Impact final. La conversion alimente MRR, Budget d'investissement, Valeur
   perçue et Capital politique.

Chaque ligne du rapport conserve son étape, sa portée, son icône, son libellé,
son type, sa valeur et ses bornes `before/after`. Les cas headless verrouillent
les scores exacts, le contrat N=2, la série, les freins, le churn, les traits
et l'absence de double comptage économique.

## 27. Quotas trimestriels (Lot 2)

`data/quotas.json` transforme le score en pression de carrière. L'Impact brut
de chaque Résolution est accumulé pendant un trimestre de 3 sprints, puis
comparé aux quotas PM : **120, 270, 560, 1050**. Un quota manqué déclenche la
fin `remercie`; les objectifs qualitatifs de l'entreprise accordent seulement
un bonus de **8 Budget** lorsqu'ils sont tous tenus en plus du quota.

Chaque trimestre tire une exigence : gel des embauches, masse salariale ×2,
livraisons internes sans Traction, frein de Dette doublé, trimestre court de
2 sprints pour 75 % du quota, stratégie imposée, pratiques à +4 Cynisme ou gel
des outils. Après T4, le joueur choisit une sortie positive ou un mandat long :
T5 demande 2310 Impact, puis chaque quota est multiplié par 2,2 et les exigences
s'accumulent. Le panneau garde cette cible visible en permanence; la Résolution
anime sa progression après le replay du score, comme dernier verdict du sprint.

## 28. Les familles de décisions (Lot 3)

Le Lot 1 avait déjà posé, sans le dire, la moitié de ce que ce lot devait
livrer : `ScoreResolver` savait déjà lire un `active_tools[]`, appliquer un
Levier par employé éligible et un malus par réfractaire, et `scoring.json`
portait déjà les sept décisions stratégiques (`open-source`, `freemium`…)
avec leurs multiplicateurs. Ce que le Lot 1 avait anticipé mécaniquement,
mais jamais branché sur du contenu réel : les nombres du Levier vivaient dans
`scoring.json → global.tools`, une table parallèle à `cards.json` que rien
n'obligeait à rester synchrone, et les stratégies n'avaient ni catalogue ni
point d'entrée pour être choisies — seule l'injonction du board pouvait en
tirer une, et même là, l'effet ne survivait qu'au trimestre où il avait été
tiré. Ce lot ferme ces deux trous plutôt que d'en ouvrir un troisième.

**Le Levier déménage sur la carte.** `perEmployee`, `eligibility`,
`refractory` (`{condition, perEmployee}`), `adoptionCondition`,
`flatModifiers`, `cumulative` et `slotBonus` sont maintenant des champs de
`cards.json`, au même endroit que le prix et la rareté — parce que c'est la
carte qui décrit ce qu'elle fait, pas une table à part qu'il fallait deviner
en la recoupant avec l'id. `ScoreResolver.resolve()` reçoit une troisième
table (`cards`, en plus de `scoring` et `hidden_traits`) et y cherche le
Levier de chaque outil actif ; une carte qui ne déclarerait ni `perEmployee`
ni `cumulative` n'aurait aucun Levier par employé et continuerait de peser
uniquement via les combos de composition — un cas que le moteur sait gérer,
mais qu'aucune carte du catalogue actuel n'utilise en pratique : une carte
`outil-process`/`methodologie-orga` coûte des pièces *et* un slot, en
laisser une sans contrepartie de Levier en ferait un piège pur, jamais un
choix. `score_resolver_cases.gd → _test_every_tool_card_has_a_lever` le
garde vrai à l'avenir. **Passage en Shape Up** a bien failli devenir ce
piège : la migration l'avait d'abord laissée sans Levier, sur la lecture
(fausse) que l'entrée `shape-up` de `scoring.json` — qui portait un Levier
« 🤝 Pair programming » sur les devs juniors en binôme — était un vestige
sans carte réelle pour l'incarner. Elle en a une, rare, à 5 🪙 et un
prérequis de 2 seniors ; le Levier lui a donc été reporté tel quel, sous son
vrai nom cette fois (la ligne de score affichait « Pair programming », plus
« Passage en Shape Up »). Le mélange détonne — la carte demande des seniors
pour s'activer mais récompense les devs juniors en binôme — mais c'est le
réglage hérité du Lot 1, pas un arbitrage de ce lot : le corriger changerait
un chiffre de gameplay, ce que ce lot n'a pas mandat de faire seul.

**Le critère de recette se vérifie sans écrire une seule valeur par
entreprise.** Notion déclare `eligibility` (juniors, ou recrues de moins de
4 sprints) et `refractory` (seniors présents depuis plus de 8 sprints), rien
d'autre. Confronté au roster réel de Karavel (cinq juniors, aucun senior
ancien), il vaut +0,08 par personne × 2 d'adoption ; confronté à celui de
Meridia une fois l'équipe héritée en poste depuis 8 sprints ou plus, les
cinq seniors basculent en réfractaires et le même calcul rend −0,05 par
personne, adoption perdue. Aucune ligne du moteur ne teste `company_id` :
le comportement est une conséquence du roster, pas une branche. C'est
maintenant asserté deux fois — `score_resolver_cases.gd` le vérifie sur les
rosters de départ réels des deux entreprises (`_test_notion_lever_by_company_roster`),
`smoke_test_logic.gd` le rejoue à l'échelle du mandat en passant par
`reset_run` (`_test_tool_families_and_strategy_lot3`).

**Les slots : d'un plafond arbitraire à une capacité qui se gagne.**
`structuralDecisionMaxActivations: 4` disparaît. `balance.json → toolSlots`
porte désormais une base indexée par niveau de carrière (`careerLevels.pm.base
= 3`, une seule ligne remplie — les niveaux au-dessus attendent le lot 5),
`extraSlotCosts: [12, 20]` pour les deux slots achetables au Comité, et
`swap` pour le coût de bascule. `SprintState.get_tool_slot_capacity()`
additionne la base, les achats (`buy_tool_slot()`, qui refuse "plafond" au
troisième essai) et le `slotBonus` des outils cumulatifs actifs — 🪞 Sprint
Rétro en porte un, ce qui rend son coût net en place nul et transforme sa
question en « l'ai-je pris assez tôt ? » plutôt qu'en « lui donné-je un
slot ? », comme prévu par la spec. **Libérer un slot** (`release_tool_slot()`)
coûte enfin le prix promis depuis le carnet §7 et jamais posé : 🎭 Cynisme +4,
+3 par bascule déjà faite ce mandat (`swap_count`), le Levier de l'outil
retiré disparaît immédiatement, son compteur cumulatif est perdu (pas
remboursé s'il revient), et la carte réintègre le pool de tirage puisqu'elle
quitte `activated_cards`.

**L'outillage hérité fait le premier arbitrage du run à la place du joueur.**
`companies.json → inheritedTools[]` pré-active un outil dès `reset_run`, avant
même le premier sprint : Meridia hérite de 🗂️ Jira (l'équipe fait 5
personnes — le malus « effectif ≤ 4 » est évité de peu, mais l'adoption ×2 à
8 personnes reste hors d'atteinte au départ, l'outil est tiède), Karavel
hérite de 📓 Notion (équipe 100 % junior, un cadeau immédiat). Les deux
consomment un slot dès le sprint 1 : un run de PM démarre avec 2 slots
réellement libres sur 3, pas 3. Effet de bord qu'il fallait vérifier :
l'outil hérité d'une entreprise n'entre plus jamais dans le tirage du rayon
tant qu'il reste actif (il est déjà dans `activated_cards`) — le test de
taux d'apparition par rareté, qui mesurait spécifiquement l'`eraWeights` de
Jira, tournait donc sur Meridia et comptait zéro sortie. Il tourne maintenant
sur Karavel, qui n'hérite pas de Jira.

**La quatrième famille existe enfin : `data/strategy.json`.** Sept décisions
stratégiques (catalogue affiché : id, icône, nom, description) dont les
multiplicateurs restent dans `scoring.json → global.strategies`, sous les
mêmes ids — deux fichiers, un seul calcul, la même séparation catalogue /
moteur que `cards.json` / `scoring.json`. `SprintState` gagne
`chosen_strategy_ids[]` (permanent, une décision n'est jamais retirée),
`quarter_strategy_chosen` (le verrou du « 1 par trimestre »),
`get_strategy_options()`, `find_strategy()` et `choose_strategy()`. La spec
place ce choix « au Comité de fin de trimestre », qui est le lot 4 et
n'existe pas encore : ces fonctions sont le point d'entrée que l'écran du
Comité appellera, branchées dès maintenant sur `_prepare_quarter()` — le
même point d'entrée de fin de trimestre que les quotas du Lot 2 utilisent
déjà. `committee_screen` n'a pas été construit ; c'est un choix
d'orchestration assumé, pas un oubli. En attendant cet écran, la seule
porte d'entrée jouable reste l'exigence 🗣️ Injonction du board, qui appelle
maintenant `choose_strategy()` au lieu d'écrire directement
`quarter_forced_strategy_id` — et c'est ce qui corrige, en passant, un bug
du Lot 2 : une stratégie imposée ne survivait avant ce lot qu'au trimestre
où elle avait été tirée (`quarter_forced_strategy_id` était réinitialisé à
chaque `_prepare_quarter`), alors que la spec les veut permanentes et
irréversibles pour tout le reste du mandat.

**Recette.** `score_resolver_cases.gd` (`godot --headless --path game -s
res://tests/score_resolver_cases.gd`) : `ScoreResolver: tous les cas sont
passes.` Les deux smoke tests headless : `=== SMOKE TEST LOGIQUE : OK ===`
et `=== SMOKE TEST UI : OK — 9 écrans instanciés, gestes
Roadmap/Investissements joués ===`. Les critères permanents (`careful` perd
avant la fin du mandat, `stress` atteint le burn-out) restent asserté dans
le test lui-même.

## 29. Le Comité d'investissement, les équipes subies, le Compendium (Lot 4)

Ce lot ferme le dernier grand trou du chantier scoring : le Lot 3 avait posé
`buy_tool_slot()`, `release_tool_slot()`, `choose_strategy()` et
`get_strategy_options()` sans écran pour les appeler — trois mécaniques
codées et mortes, invisibles à un joueur. `committee_screen` les branche, et
en profite pour porter tous les autres postes que la spec §12 promettait :
ouvrir un poste, promotion, palier de produit, séminaire, remise à plat,
rachat d'un concurrent, chasseur de têtes, plan de redressement, avance sur
trimestre. Onze postes, une seule règle de construction : chaque section de
l'écran ne fait que lire une fonction de `SprintState` et rejouer son refus
— exactement le contrat déjà en place pour l'étal des Investissements.

**Où le Comité s'insère, et pourquoi cette insertion-là.** La bascule vit
dans `resolution_screen._on_next_sprint_pressed()`, conditionnée par un test
minuscule (`_quarter_just_closed()`) qui compare `quarter_result.sprint` au
`sprint_number` courant *avant* son incrément — exactement le test que
`_setup_quota_replay()` utilisait déjà pour distinguer « le trimestre vient
de se clore ici » de « il s'est clos il y a un sprint ou plus ». Résultat :
un seul point d'entrée gère à la fois le cas normal (trimestre franchi,
mandat continue) et le cas T4 (après le choix « rester pour le mandat
long », qui reconnecte le même bouton) sans dupliquer la logique de
routage. Le Comité ne s'ouvre jamais sur un trimestre manqué (la fin de
mandat court-circuite avant), jamais au fil de l'eau (le test est faux dans
99 % des sprints), et jamais avant que le joueur ait tranché sortie/mandat
long à T4.

**Le prix de la décision stratégique est un tirage, pas une constante.** La
spec donne une fourchette (15-30) plutôt qu'un chiffre : `strategy_purchase_cost()`
tire une fois par trimestre et mémorise le résultat dans
`current_committee_offer`, sur le même principe que le prix du re-tirage de
l'étal — sans ce cache, rouvrir l'écran changerait le prix sous les yeux du
joueur. `choose_strategy()` du Lot 3 reste gratuite (c'est ce que
`_assign_forced_strategy()` continue d'appeler pour l'injonction du board,
qui ne se négocie pas) ; `buy_strategy()` est la version payante, la seule
que le Comité expose, et c'est elle qui prélève les pièces avant de
déléguer à `choose_strategy()` — la logique de « une par trimestre,
irréversible » ne bouge pas d'un octet.

**Le cap d'effectif devient un objet de jeu.** `get_team_cap()` additionne
désormais `companies.json → teamCap` et `team_cap_purchased`, acheté au
Comité sur une échelle de prix (`investments.json → open-seat.costs`,
6/10/16/24 — l'ellipsis de la spec tranchée en un quatrième palier plutôt
que laissée ouverte). Comme les slots d'outillage, la table est finie et le
Comité refuse "plafond" une fois épuisée : un cap qui grandirait sans
limite romprait la tension entre effectif et masse salariale qui structure
tout le jeu depuis la Phase A.

**La promotion cible une personne, pas un slot abstrait.** `promote_employee()`
prend un `employee_id` — le Comité liste tous les juniors du roster et
laisse choisir, plutôt que de promouvoir "le premier junior trouvé" en
silence : une promotion est une décision RP (qui, pas juste combien), et la
carte d'employé mutée en place (GDScript passe les Dictionary par
référence) rejoint immédiatement le calcul de capacité et de Levier sans
repasser par aucun autre code.

**Le palier de produit corrige un chiffre hérité du Lot 1.**
`scoring.json → global.productTier.leverPerTier` valait `0.1` depuis le Lot 1,
qui l'avait câblé mécaniquement sans jamais lui donner de point d'achat. La
spec du Comité (§12) est explicite : *+0,5 Levier permanent* par palier.
Ce lot corrige la valeur pour que l'achat au Comité tienne sa promesse — un
rééquilibrage assumé, pas un vestige qu'on aurait pu laisser trainer parce
que "personne ne l'achetait de toute façon". `_draw_backlog_offer()` ajoute
`product_tier` au plafond de tirage (jamais au minimum garanti : un palier
de produit élargit ce qui *peut* sortir, il ne force rien).

**Le sprint de remise à plat neutralise la Traction sans mentir sur ce qui a
été livré.** `cleanup_sprint_pending` ne vide `delivered` que dans la copie
lue par `ScoreResolver` (`_build_score_snapshot()`), jamais dans `squads[]`
ni `last_roadmap_report` : la Résolution continue d'afficher fidèlement ce
que l'équipe a réellement produit ce sprint-là, seule la conversion en
Impact est mise à zéro. Séparer "ce qui s'est passé" de "ce qui compte pour
le score" évite d'avoir à mentir sur l'un pour faire fonctionner l'autre.

**Le rachat d'un concurrent mélange volontairement deux tempos.** Le MRR et
l'employé arrivent immédiatement (un rachat, ça se signe et ça s'intègre
tout de suite) ; la Dette, elle, passe par `add_pending()` et n'apparaît
qu'à la prochaine Résolution, comme tout ce qui pèse sur les six jauges. Un
même geste d'achat a donc deux horloges différentes, et c'est un choix
délibéré : un stock (MRR, effectif) se déplace d'un coup, un flux (Dette)
suit le rythme du sprint.

**Le chasseur de têtes complète l'offre déjà tirée plutôt que de la
refaire.** `_apply_headhunter_boost()` s'exécute après `_draw_shop_offer()`
et ajoute des candidats jusqu'au seuil promis, sans toucher aux décisions ni
aux pratiques déjà tirées pour ce sprint — rejouer tout le tirage aurait
changé des emplacements que le joueur n'a pas payé pour changer.

**Le plan de redressement se consomme tout seul, jamais sur un bouton.**
`_record_quarter_resolution()` le déclenche automatiquement la première fois
qu'un trimestre manquerait son quota, exactement comme un filet de sécurité
qu'on n'active pas soi-même au moment de tomber. C'est cohérent avec la
mécanique elle-même : décider *a priori* "je veux un rattrapage" a un sens
RP (sécuriser un trimestre difficile à l'avance), décider *a posteriori*
"je l'utilise maintenant" n'en aurait aucun — le quota est déjà tranché au
moment où l'écran pourrait proposer le bouton.

**L'avance sur trimestre débite le cumul, elle n'abaisse pas le quota.**
`buy_quarter_advance()` fait `quarter_impact -= 80` (ou l'inverse en signe,
selon la lecture) sans jamais clamper le résultat à zéro : un cumul qui
passe sous zéro est une information de jeu — le pari coûte cher, et ça doit
se voir — pas un artefact à cacher. C'est une contrainte explicite du lot
suivant (Impact comme ressource centrale, dépassement de quota qui compte) :
ce lot-ci n'ajoute aucun troisième clamp à côté de celui de
`_prepare_quarter()` (remise à zéro trimestrielle) et de celui du panneau
latéral (jauge d'affichage bornée à `[0, quota]`) — les deux existants
restent inchangés, et c'est un choix délibéré de ne rien construire ici qui
leur ferait concurrence.

### Les équipes subies : un champ de données qui manquait, pas un mécanisme

Le taux de conversion des équipes subies (Sales/PMM/CSM) existait déjà en
entier dans `ScoreResolver._resolve_conversion()` avant ce lot — trois
tables de multiplicateurs dans `scoring.json`, lues et appliquées à
l'étape ⑨. Ce qui manquait tenait en une ligne : `companies.json` ne
déclarait `supportTeams` nulle part, et `_build_score_snapshot()` ne le
transmettait pas. Les deux entreprises convertissaient donc identiquement,
avec un défaut 3/3/3 codé en dur dans le resolver. Ajouter
`supportTeams: {sales, pmm, csm}` aux deux entreprises et une ligne dans le
snapshot suffit à débloquer le critère de recette de l'issue — un rappel
que la donnée manquante coûte parfois plus cher à repérer qu'à corriger.

Le défaut 3/3/3 reste dans `support_teams` de `SprintState` (pas
`GameData.companies`) précisément pour ne jamais forcer une troisième
entreprise ou un scénario futur à déclarer le champ : l'absence de
`supportTeams` dans une entrée de `companies.json` reste un choix valide
(niveau neutre), jamais une erreur silencieuse.

**Elles ne gagnent aucun nouveau levier.** Pas d'achat, pas de slot, pas de
niveau à monter au Comité — c'était un point de design ferme de la spec, et
ce lot le respecte à la lettre : aucune fonction de `SprintState` ne
modifie `support_teams` sur demande du joueur. La seule porte qui existe est
déclarative et collatérale : `scoring.json → global.strategies.*.supportTeamDeltas`
(Open source : PMM +1 / Sales −1 ; Arrêter de communiquer : PMM −1, cohérent
avec la prose déjà écrite au Lot 3 avant même que le mécanisme existe) — une
décision stratégique change le monde autour des équipes subies, elle ne les
pilote pas. `_apply_strategy_support_team_deltas()` lit ce champ pour
n'importe quelle stratégie qui le porterait un jour ; en ajouter une
troisième ne demandera aucune ligne de code.

**Les événements Inbox suivent le même principe : niveau bas = crise,
niveau haut = pression, jamais l'inverse.** `supportTeam` + `levelRange`
filtrent l'éligibilité dans `_eligible_inbox_events()`, exactement comme
`eras[]` le fait déjà pour les scénarios — la troisième couche de filtre
d'un mécanisme qui n'en avait besoin que de deux jusqu'ici. Six événements
(deux par équipe subie) couvrent les trois gabarits de la spec : le deal
bloqué sur une promesse en l'air, la survente qui force à suivre le rythme,
le silence produit que personne ne sait raconter, la campagne qui arrive
avant la feature, les tickets qui saturent le support, l'insight que la
Discovery avait raté.

**La visibilité à l'étape ⑨ passe par le rapport, pas par un second
calcul.** `_resolve_conversion()` expose désormais `teamRates` (niveau +
multiplicateur des trois équipes) et trois lignes `conversion_rate` dans le
rapport ; `resolution_screen` les affiche dans une section dédiée
"CONVERSION — ÉQUIPES SUBIES", après la ligne d'Impact — elles convertissent
l'Impact déjà résolu, jamais un levier dessus, donc jamais mélangées à la
section "LEVIERS & FRICTIONS" qui précède l'Impact. Un seul calcul (celui du
resolver), affiché à l'endroit qui correspond à sa place réelle dans la
chaîne Traction × Levier = Impact → conversion.

### Le Compendium des synergies et `PlayerProfile`

Aucune persistance entre deux runs n'existait avant ce lot — rien en
`user://`, à part un screenshot de prototype jamais branché. Le Compendium
en avait besoin, et le Lot 5 (progression de carrière) en aura besoin aussi
: plutôt que de coder une persistance ad hoc pour le Compendium seul,
`PlayerProfile` (nouvel autoload) porte une interface générique — des
combos découverts d'un côté, un espace clé/valeur libre de l'autre, le tout
dans un unique `ConfigFile` en `user://player_profile.cfg`. Le coût
d'écriture est nul (quelques dizaines d'entrées au grand maximum), donc
sauvegarder à chaque découverte plutôt que de batcher n'est pas un
problème.

**La détection lit le rapport, elle ne retente aucune condition.**
`record_score_report()` scanne les lignes déjà produites par
`ScoreResolver.resolve()` (`squads[].lines` + `global.lines`) et les
confronte au catalogue de combos par la paire (icône, libellé) — unique
pour chacun des 15 combos du jeu (8 `organizationCombos`, 5 `handBonuses`,
2 `interSquadCombos`, vérifié en Python avant d'écrire le mécanisme).
Réévaluer les conditions des combos ici aurait dupliqué une logique déjà
tranchée par le resolver ; lire sa sortie ne duplique rien.

**Le catalogue reste une lecture de `scoring.json`, jamais une copie.**
`get_combo_catalog()` reconstruit la liste à chaque appel depuis les trois
tables existantes — ajouter un seizième combo dans `scoring.json` suffira à
le faire apparaître au Compendium, en `???` jusqu'à sa première apparition,
sans toucher à une ligne de `player_profile.gd`.

**Un piège de test à connaître : `user://` est un vrai fichier, qui survit
d'un run headless à l'autre.** `PlayerProfile.clear_all()` existe
uniquement pour ça — sans point d'entrée pour vider le profil, toute
assertion "tel combo n'est pas encore découvert" deviendrait flaky après le
premier passage du smoke test sur la machine. Ne jamais l'appeler depuis le
jeu : `reset_run()` ne doit jamais effacer une progression méta, c'est tout
l'intérêt de la séparer de `SprintState`.

### Un test flaky préexistant, pas une régression de ce lot

`smoke_test_logic.gd` échouait par intermittence (mesuré à 32/40 puis
33/40 sur des runs répétés, taux identique avant et après ce lot) sur
l'assertion « le premier trimestre doit proposer au moins une décision
stratégique ». La cause, une fois tracée : l'exigence trimestrielle
`board-injunction` (1 chance sur 8 dans `quotas.json`) force une décision
stratégique dès `reset_run()`, via `_prepare_quarter(1)` →
`_assign_forced_strategy()` → `choose_strategy()`, qui verrouille
`quarter_strategy_chosen` avant que le test n'ait la main. Le test, écrit
au Lot 3, supposait à tort qu'un catalogue vide au premier trimestre ne
pouvait être qu'une erreur — alors que c'est exactement le comportement
voulu une fois sur huit. Le moteur avait raison, le test avait tort :
corrigé pour accepter un catalogue vide *seulement si* une injonction l'a
déjà consommé (`quarter_strategy_chosen` et `quarter_forced_strategy_id`
non vides), sinon échouer comme avant. La distinction compte : une
assertion qui accepterait silencieusement n'importe quel catalogue vide ne
testerait plus rien.

Même piège retombé une seconde fois, cette fois dans un test écrit *pour*
ce lot : `_test_support_teams_and_compendium_lot4()` lisait
`SprintState.support_teams` juste après `reset_run()` en supposant qu'il
reflétait encore `companies.json` — sans compter qu'une injonction du board
peut, à cet instant précis, avoir déjà forcé une stratégie qui porte elle-
même un `supportTeamDeltas` (la mécanique décrite plus haut). Pire :
réinitialiser ensuite `chosen_strategy_ids` pour tester un choix volontaire
d'"open-source" pouvait faire rejouer une seconde fois l'effet de bord
d'une stratégie déjà appliquée par l'injonction, faussant la comparaison
avant/après. Mesuré à 26/30 puis 60/60 après correctif : distinguer la
déclaration brute (`companies.json`, jamais mutée) de l'état runtime
(`support_teams`, réaligné explicitement avant chaque sous-test qui en
dépend) règle la même classe de bug que le premier flaky, avec la même
cause profonde — le hasard d'une injonction de board tirée à T1, que tout
test touchant au premier trimestre doit désormais neutraliser
explicitement plutôt que d'espérer qu'il ne tombe pas dessus.

## 30. L'échelle — multi-squad, attention, progression de carrière (Lot 5)

Ce lot ferme le chantier scoring (#12) : le socle multi-squad était déjà
câblé depuis le Lot 1 (`ScoreResolver` itère sur `squads[]`, distingue
`local`/`global`, calcule déjà les deux combos inter-squads) — il restait à
lui donner du contenu et une carrière pour y accéder. Le lot se découpe en
paliers, livrés et poussés séparément ; ce qui suit documente le palier 1
(la carrière visible), complété au fil des paliers suivants dans cette même
section.

**Palier 1 — la carrière visible.** `data/careers.json` est la nouvelle
table qui décrit ce qui est propre à la carrière (ordre de déblocage,
nombre d'équipes par niveau, texte affiché) — les slots d'outillage
(`balance.json → toolSlots.careerLevels`) et les quotas (`quotas.json →
careerLevels`) restent dans leurs tables historiques, simplement complétées
des 4 lignes manquantes (`lead-pm`, `director`, `cpo`, `ceo`), sans aucune
duplication de valeur entre les trois fichiers. Le déblocage est strict et
vit dans `SprintState._unlock_next_career_level()` : "gagner" un niveau,
c'est franchir son 4e trimestre (`quarter_exit_choice_pending` devient vrai
pour la première fois à ce niveau) — la spec dit explicitement un mandat
"complet" en 4 trimestres, avant même la question de sortir ou de
continuer en mandat long. Le déblocage est donc acquis dès l'atteinte de T4,
qu'on choisisse ensuite de partir ou de rester.

**Pourquoi la persistance ne recalcule jamais la règle de déblocage.**
`PlayerProfile.unlock_career_level()` ne fait qu'enregistrer un fait acquis
(le niveau a été gagné) ; c'est `SprintState`, seul à connaître l'état du
mandat en cours, qui décide *quand* l'appeler. Aucun écran ne recalcule la
condition de déblocage : `career_select_screen` et `mandate_end_screen` se
contentent de lire `PlayerProfile.is_career_level_unlocked()` — même
principe que le Compendium du Lot 4 (`record_score_report()` scanne un
rapport déjà tranché, il ne rejoue aucune condition).

**Le menu de démarrage réutilise le pattern `playableEras`, au pixel près.**
`career_select_screen.gd` est une copie quasi littérale de
`scenario_screen.gd` : mêmes cartes, même `modulate` atténué sur les niveaux
non débloqués, même bouton désactivé portant le texte de la condition
manquante (`unlockLabel`). Le flux de lancement gagne une étape :
accueil → **niveau de carrière** → scénario → entreprise, chaque écran
gardant son bouton retour vers le précédent (`career_select_screen` est
maintenant la destination du retour de `scenario_screen`, plus l'accueil).

**`reset_run()` retombe sur "pm" si le niveau demandé n'est pas débloqué.**
Le garde-fou n'est pas seulement dans l'écran de sélection (qui désactive
déjà le bouton) : `reset_run(era, company, chosen_career_level)` revérifie
lui-même `PlayerProfile.is_career_level_unlocked()` avant d'adopter le
niveau demandé. Un appel sans 3e argument (tous les tests existants, et tout
code qui ne connaît pas encore la carrière) retombe donc silencieusement sur
"pm" avec une seule équipe — c'est ce qui garantit qu'un run de niveau PM
reste strictement identique à avant ce lot, sans qu'aucun test n'ait eu
besoin d'être réécrit pour ça.

**Les équipes du kit de carrière démarrent vides, pas héritées.**
Au-delà de PM, `squads[]` gagne `careers.json → squadsMin - 1` entrées via
`_new_empty_squad()` : aucun roster, à staffer par recrutement. Alternative
envisagée et écartée : générer un roster de départ par équipe supplémentaire
aurait demandé d'étendre `companies.json` pour un contenu multi-squad par
entreprise, alors qu'aucune entreprise n'est encore jouable au-delà de PM
niveau récit (une seule époque jouable). Le choix retenu ne coûte aucune
donnée supplémentaire et raconte la même histoire que la promotion réelle :
on hérite d'une équipe déjà montée, on construit les autres soi-même. Nom
affiché : "Équipe B", "Équipe C"... jamais le mot "squad", y compris dans ce
contexte à N>1 — la règle de masquage ne vaut qu'à N=1, mais autant rester
cohérent partout où un humain lit l'écran.

**Le recrutement au-delà de PM équilibre plutôt que de choisir, pour
l'instant.** `hire_candidate()` gagne un paramètre optionnel
`target_squad_id` (défaut "", donc l'équipe principale — comportement
historique inchangé). Sans sélecteur dédié dans `investments_screen` (coupé
faute de temps à ce palier, voir PR), une recrue sans équipe précisée
rejoint l'équipe la moins fournie. C'est un choix de design assumé, pas un
oubli : préférer un équilibrage simple et déterministe à un empilement
systématique sur l'équipe héritée, en attendant l'écran de sélection.

**Fin de mandat : annoncer, ou rappeler ce qui manque.**
`mandate_end_screen._load_career_progress()` lit
`SprintState.newly_unlocked_career_level` (non vide seulement le sprint où
le déblocage vient de tomber) pour l'annonce festive, et sinon calcule le
prochain niveau non débloqué dans `careers.json → order` pour rappeler sa
condition en clair — sans jamais recalculer si elle est remplie, seule
`PlayerProfile` sait répondre à ça.

### 30.4 L'attention : on ne pilote pas tout (palier 3)

Le multi-équipe ne devient un sujet de jeu que le jour où l'on ne peut plus
tout regarder. C'est le rôle de `careers.json → attention`.

`slotsByLevel` dit combien d'équipes le joueur pilote lui-même sur un sprint,
et cette table monte **beaucoup** moins vite que le nombre d'équipes : 1 sur 1
en PM, puis 1 sur 2, 2 sur 5, 3 sur 10, 4 sur 24. Le choix est délibéré et il
est le propos du chantier : la capacité d'attention d'un humain ne grandit pas
avec son titre, seule l'organisation grandit. Le passage PM → Lead PM fait donc
mal d'un seul coup — on délègue la moitié de son périmètre du jour au
lendemain, sans transition. C'est voulu, et c'est aussi ce qui rend le niveau
suivant désirable plutôt que confortable.

À N=1 la table donne 1 slot pour 1 équipe : `resolve_unpiloted_squads()` ne
trouve jamais rien à faire et le déroulé d'un run PM est **exactement** celui
d'avant le multi-équipe. Ce n'est pas une précaution de test, c'est la
propriété qui autorisait à livrer tout ce lot sans toucher au jeu existant, et
elle est assertée comme telle.

Une équipe non pilotée joue quand même son sprint : elle se donne un plan
toute seule, dont la qualité est **celle de son meilleur PM**. Trois profils
dans `autoPilotProfiles`, choisis par `auto_pilot_profile_id()` :
sans PM on prend les tickets dans l'ordre du tirage, sans réfléchir ; un PM
junior trie par valeur brute (`roi + clientImpact`) en ignorant le risque ; un
PM senior trie par **rendement** (`perPoint`, donc divisé par le coût) et pèse
le risque. C'est la traduction mécanique de « pondérée par la composition » :
une équipe sans PM n'est pas punie par un malus arbitraire, elle est punie
parce qu'elle choisit mal, ce qui se lit dans ce qu'elle livre.

`build_auto_plan_for_squad()` est un **seul calcul pour deux usages** : c'est
la fonction qui prévisualise ce qu'une équipe va faire et c'est exactement
celle qui est rejouée pour l'appliquer. Un écran ne peut donc pas afficher
autre chose que ce qui sera joué — le banc logique assert la stabilité entre
deux lectures. Le plan sort au format canonique de
`roadmap_screen._current_plan()` (`{id, points}` toujours renseigné), pour que
`backlog_plan_points()` serve aussi bien au panier du joueur qu'à celui d'une
équipe déléguée.

Un plan vide reste une réponse légitime : une équipe de deux personnes ne se
lance pas dans une feature qui coûte plus que sa capacité du sprint. Le banc
teste donc la bonne propriété — un plan vide n'est un défaut *que* s'il restait
une feature abordable sur la table. La première version de cette assertion
exigeait naïvement un plan non vide et tombait une fois sur dix selon le
tirage ; c'est le troisième test de la série à se faire piéger par l'aléatoire
du backlog, après les deux du Lot 4 (§29). La règle qui se dégage, pour les
prochains : **ne jamais asserter sur le résultat d'un tirage, toujours sur la
relation entre le tirage et la décision qui en découle.**

### 30.5 Ce que le palier 3 ne fait pas encore

`roadmap_screen` ne sait piloter qu'une équipe : il déclare donc explicitement
ne piloter que l'équipe principale (`set_piloted_squads([...])`) avant de
résoudre les autres en auto-pilotage. Sans cette déclaration, une équipe
« pilotée » selon la table d'attention mais absente de l'écran perdrait
purement et simplement son sprint. Le jour où le sélecteur d'équipe arrive,
seule cette ligne change — le moteur, lui, est complet et sait déjà refuser un
choix qui dépasse les slots disponibles.

---

## 31. L'Impact-monnaie — Lot A : les deux monnaies

Livré par l'issue #35, d'après [`docs/spec-impact-monnaie.md`](spec-impact-monnaie.md)
§2 et §3. C'est le lot le plus large du dépôt en surface touchée : il remplace
l'économie entière et passe sur tous les écrans d'achat d'un coup.

### 31.1 Ce qui disparaît, et ce qui reste

| Avant | Après |
|---|---|
| 🪙 `SprintState.pieces` | **Supprimé.** `impact_wallet` est la seule monnaie. |
| `Budget = floor(√Impact)` + allocation plancher de 2 | **Supprimé.** Le portefeuille encaisse l'Impact du sprint tel quel. |
| Trésorerie (ressource 0..100) | Fusionnée dans `revenue`, sans plafond, hors de `resources.json`. |
| `quarter_impact`, remis à zéro chaque trimestre | **Supprimé.** Un seul nombre, jamais remis à zéro. |
| MRR, stock affiché | Reste **comme moteur** (`recurring_revenue`), disparaît **comme compteur**. |

La suppression de l'allocation plancher n'est pas cosmétique : elle était le
seul revenu qu'on touchait sans rien produire. Ne rien faire ne rapporte plus
rien du tout, et le premier critère de recette permanent (« `careful` doit
perdre ») est désormais mécanique plutôt que dépendant de l'équilibrage.

### 31.2 Le MRR n'a pas été supprimé, il a été démonté

L'issue demandait de fusionner trésorerie et MRR en une seule valeur. Pris au
pied de la lettre, ça supprimait la seule mécanique **composée** de l'économie :
sans base d'abonnements qui persiste, le revenu d'un sprint ne dépend plus que
de ce sprint-là, le churn n'a plus rien à éroder, et le niveau CSM de
l'entreprise ne sert plus à rien.

L'arbitrage retenu : **une seule valeur affichée** (le Revenue), et la base
d'abonnements devient un rouage interne (`recurring_revenue`) qui ne se montre
plus que comme une ligne du rapport de sprint — « vos abonnements ont rapporté
+14 ce sprint ». Le joueur n'a plus deux compteurs à surveiller ; le moteur, lui,
garde sa composition. C'est la lecture de « fusionner » qui préserve le
`CLAUDE.md` (« le MRR est un stock cumulatif — c'est la composition qui crée
l'envie de continuer ») sans trahir l'intention de l'issue.

### 31.3 Un prix maintenant, une charge pour toujours

Deux fonctions, et deux seulement, portent toute l'économie d'achat :

- `SprintState.resolved_price(kind, id, data)` — **aucun écran ne lit un prix
  brut**. C'est là que vit la remise Réseau, et là que le lot B (#36) branchera
  l'indexation sur l'escalade : `price_index()` existe déjà, vaut 1.0, et est
  déjà appelée. Le lot B est une fonction à remplir, pas des écrans à rouvrir.
- `SprintState.recurring_charge(kind, id, data)` — la charge de Revenue qu'un
  poste engage à chaque sprint, **comptée par siège** (`licensePerSeat` sur les
  outils et les pratiques, `licenseFlat` sur les décisions stratégiques,
  `licenseFlatPerTier` sur les paliers de produit). Grandir n'augmente donc
  jamais seulement la production : la facture suit, mécaniquement.

`get_recurring_charges()` sert à la fois l'affichage (panneau, Comité, dossier)
et le prélèvement de la Résolution — un seul calcul, deux usages. Le jour où
l'addition affichée et l'addition prélevée divergent, c'est qu'on a dupliqué la
règle.

### 31.4 Le verdict porte sur le solde, pas sur la production

`quarter_impact` a disparu au lieu d'être conservé « pour le quota ». Deux
grandeurs qui portent le même nom rendaient l'objectif illisible — c'est le
piège écarté par la spec §4. Conséquence directe et voulue : **dépenser au shop
du sprint fait reculer vers l'objectif en cours**, dépenser au Comité (après le
verdict) ne menace que le trimestre suivant. Le joueur découvre seul une
cadence : investir tôt dans le trimestre, sécuriser à la fin.

Les quotas ont donc été **re-dérivés en lecture cumulative** (T2 contient T1) :
`[150, 760, 2200, 4600]` pour le PM. Ce n'est pas l'escalade définitive — c'est
le chantier de #36 — mais laisser la table par-quarter avec une lecture
cumulative aurait livré un jeu où le bot `greedy` gagne 77 % du temps. Après
re-dérivation, il gagne 11 % (18 runs sur 160), contre 12 % sur `main` : la
difficulté est conservée, pas seulement le code.

### 31.5 Le portefeuille peut passer sous zéro, et ce n'est pas une défaite

Trois règles distinctes, à ne pas confondre dans le code comme à l'écran :

- **Revenue ≤ 0 → faillite**, fin de run (`endingThresholds`, inchangé de
  nature — seulement d'échelle, la valeur n'étant plus bornée à 100).
- **Objectif trimestriel manqué → licenciement**, fin de run.
- **Portefeuille à zéro → rien.** C'est une bourse vide, pas une défaite. Un
  achat ne fait jamais passer le portefeuille sous zéro (`_pay_impact()` refuse) ;
  seule l'🎲 Avance sur trimestre le creuse, et c'est un pari explicite. Ce qui
  tue, c'est de ne pas avoir reconstitué **à l'heure du verdict** — pas d'avoir
  été à zéro en chemin.

### 31.6 Ce que le premier sprint ne peut pas faire

Le portefeuille démarre à zéro : rien n'est achetable au sprint 1. C'est assumé
(spec §3.4), mais un étal entièrement grisé sans un mot est un bug aux yeux du
joueur. L'étal affiche donc la règle en clair — « vous n'avez pas encore produit
d'Impact » — et le même message revient, reformulé, chaque fois que le
portefeuille est vide plus tard dans le mandat. `companies.json` gagne
`startingImpact` (0 partout aujourd'hui) pour les scénarios qui démarreront avec
une avance, comme trait de contexte de run.

### 31.7 Deux gestes changent de monnaie

- 🏛️ **Négocier une rallonge** verse désormais du **Revenue**, jamais de
  l'Impact : le board peut remplir la caisse, il ne peut pas produire à votre
  place. C'est le seul geste qui aide à survivre sans rien construire.
- 🎲 **Avance sur trimestre** est le seul poste qui va dans l'autre sens : il
  **vend de l'Impact contre du Revenue**. Symétrique du reste du jeu, et le seul
  moyen d'être endetté en Impact.

### 31.8 Un quota en dur, trouvé par la bande

`get_current_quota()` retombait sur `base_quota = 1050.0` au-delà de la table —
une valeur d'équilibrage dans un script, exactement ce que la question 7 de la
vision interdit. Elle n'avait jamais gêné parce qu'elle valait le T4 de
l'époque ; en re-dérivant les quotas, elle a silencieusement figé tout le
mandat long sur l'ancien barème. C'est un test rendu data-driven qui l'a
trouvée, pas une relecture. Le repli est désormais la **dernière ligne de la
table**, jamais un nombre écrit ici.

### 31.9 Le défaut que ce lot laisse derrière lui : le Revenue ne contraint plus

Le banc imprime désormais le Revenue final, sa base d'abonnements et sa facture.
Première mesure, sur 40 runs (160 mandats par stratégie) :

| Stratégie | Revenue final (médiane) | Base d'abonnements | Charges |
|---|---|---|---|
| `greedy` | **1229** | 243/sprint | **22/sprint** |
| `careful` | 10 | 0/sprint | 14/sprint |

La caisse encaisse dix fois ce qu'elle paie : **elle cesse d'exister comme
contrainte après T2**. Les charges par siège (§31.3) ne peuvent pas gagner cette
course — l'effectif passe de 5 à 7 personnes pendant que le revenu fait ×20.

La cause n'est pas le calibrage, elle est structurelle : le revenu de
l'entreprise est **piloté par l'Impact**
(`scoring.json → conversion.saas-mrr.impactToMrr`, hérité de l'économie
précédente). Produire remplit donc la caisse tout seul, les deux monnaies ne
sont pas indépendantes, et l'arbitrage annoncé par la spec §3.7 — *nourrir la
boîte ou nourrir la performance* — n'a jamais eu d'objet.

La règle manquante a été écrite à cette occasion : **l'économie de l'entreprise
n'est pas l'économie de l'Impact** (spec §3.8, résumée dans `CLAUDE.md` et
devenue la 9e question de la vision). Sa mise en œuvre — couper la conversion,
faire porter le Revenue par le contenu (features à ROI, primes, événements,
équipes subies) — est un chantier de contenu autant que de moteur : c'est
l'issue #42.

Ce qu'il faut retenir pour la suite : c'est une **question posée par Camille sur
la PR** qui a fait mesurer, pas un test. Les trois bancs étaient au vert, les
captures relues, et le défaut était invisible — parce qu'aucune assertion ne
regardait le Revenue. La leçon est la même que §29 et §30.4, appliquée à
l'économie : ce qui n'est pas imprimé au banc n'existe pas.

### 31.10 Ce que ce lot ne fait pas

- **L'escalade définitive des quotas et l'indexation des prix** sont le lot B
  (#36). Ici, les quotas ont seulement été re-dérivés pour que la difficulté
  survive au changement de lecture, et `price_index()` attend son contenu.
- **Le banc de trajectoires** (spec §7) n'est pas écrit : la calibration a été
  faite en comptant les fins du banc `greedy/careful/stress` existant sur 40
  runs. Suffisant pour ne pas régresser, insuffisant pour régler une courbe.
- **Les six jauges reléguées en alertes** (spec §8) restent au lot D.
- **L'indépendance des deux économies** (spec §3.8) est écrite mais pas
  implémentée : `impactToMrr` vaut toujours 0,06. Voir §31.9.

---

## 32. Le Revenue a des clients (issue #42)

Mise en œuvre de [`spec-clients-revenue.md`](spec-clients-revenue.md), et
solde du défaut laissé par le lot A (§31.9) : **l'économie de l'entreprise
n'est plus l'économie de l'Impact**.

### 32.1 Le Revenue n'est plus un stock, c'est une population

`recurring_revenue` (la base d'abonnements) et `recurring_roi` (le bonus
permanent des livraisons) ont disparu au profit de `SprintState.clients` — un
dictionnaire `segment_id → population`. Chaque sprint :

```
clients ← clients − churn + arrivées ± conversions
Revenue ← Revenue + Σ(clients × prix) − salaires − licences − support des clients
```

Le double comptage documenté au §31.9 (`recurring_roi` réinjecté à chaque
sprint, poussant le revenu vers `roi ÷ churn`) **ne peut plus s'écrire** : une
feature amène des clients *une fois*, et les clients paient *chaque sprint*. Il
n'y a plus de grandeur ambiguë entre les deux. C'est le meilleur argument pour
ce modèle — il rend une classe entière d'erreurs impossible plutôt que de la
corriger.

Un modèle déclare 2 à 3 segments, jamais plus. Meridia joue `grands-comptes`
(15 pilotes, 25 comptes signés), Karavel `freemium-volume` (760 gratuits, 58
abonnés) : même époque, deux économies qui ne se jouent pas pareil. Les
gratuits **coûtent sans payer** (`unitCost` sans `price`), ce qui rend le
freemium dangereux tout seul — c'était la condition pour que « passer en
payant » soit un pari et pas un cadeau.

### 32.2 Ce qui a été coupé, et pourquoi ça ne se recalibre pas

Trois règles ont été **supprimées**, pas ajustées :

| Règle | Ce qu'elle faisait | Pourquoi elle part |
|---|---|---|
| `conversion.saas-mrr.impactToMrr` | 6 % de l'Impact du sprint → revenu | Fusionne les deux monnaies en une seule grandeur à deux noms |
| `conversion.recurringRoiMultiplier` | le ROI cumulé réinjecté chaque sprint | Le double comptage de §31.9 |
| `conversion.perceivedValue` | Impact → Valeur perçue | Premier maillon de la fuite `Impact → perception → Revenue` |

Ce n'était pas un problème de taux : c'est le **sens de la dépendance** qui
était faux. Un garde-fou mécanique remplace la vigilance : le banc
(`score_resolver_cases.gd → _test_no_revenue_comes_from_impact`) fait varier
l'Impact du simple au quadruple, à livraison et population identiques, et exige
que la caisse et la population ne bougent pas d'un chiffre.

### 32.3 La Valeur perçue devient la Réputation produit

Le renommage n'est pas cosmétique, et c'est la décision de fond du lot. « Ce que
le marché pense que vous valez » mélangeait **la perception du produit par ses
utilisateurs** et **la perception du joueur par ceux qui le jugent**. C'est ce
mot pour deux choses qui avait laissé la fuite s'installer sans que personne ne
la voie. Trois entités perçoivent quelque chose, chacune a sa grandeur :

- les **utilisateurs** jugent le produit → 📈 Réputation produit, alimentée
  **uniquement par les livraisons** (`EffectResolver.resolve_backlog()`) ;
- le **board** juge le joueur → 🎯 Capital politique, alimenté par l'Impact ;
- l'**équipe** juge le joueur → 🤝 Confiance, lot suivant.

Le 📣 Product marketing ne convertit plus l'Impact : il **amplifie ce que les
livraisons font à la réputation**. Même équipe subie, même table de niveaux,
autre entrée. Et `goodEnding` ne moyenne plus une perception produit et une
perception joueur : 🚀 l'IPO se gagne sur ce que vaut **le produit**
(Réputation ≥ 62 **et** une population qui paie au moins ses charges), 🤝 le
rachat est tout le reste — quelqu'un vous achète, ce qui n'exige rien du
produit.

### 32.4 La Traction ne lit plus l'effet client — l'arbitrage était à ce prix

**C'est l'écart assumé avec `spec-scoring-sprint.md` §5**, qui écrivait
`Traction = costPoints × 4 + clientImpact × 3`.

`roi` et `clientImpact` ont fusionné en un seul champ `clients` (spec §8.4 :
« une feature a **un** effet client, point »). Mais cette valeur est devenue une
grandeur **économique**, convertie en clients réels par le modèle du run : la
même feature vaut 72 inscrits chez Karavel et 0,9 compte chez Meridia. La
multiplier par 3 pour en faire de la Traction n'a plus de sens dimensionnel — et
surtout, la garder rendait **mécaniquement corrélées** « ce qui score » et « ce
qui paie », donc impossibles les deux familles que l'issue demande : celles qui
**paient sans scorer** et celles qui **scorent sans payer**. Avec une seule
valeur alimentant les deux, tout ce qui rapporte score, et le dilemme n'existe
pas.

La Traction ne vient donc plus que des **points livrés**. Le score continue de
lire la colonne client, mais comme une **condition** et non comme un terme :
« Le board veut du visible » (quotas.json) annule la Traction des livraisons qui
n'amènent aucun client, et Enterprise first double celle des features à effet
client ≥ 3. Cinq features ont été ajoutées pour tenir les deux extrêmes —
🎁 Programme de parrainage (1 point, +6 clients) et ⚙️ Refonte du moteur de
calcul (6 points, 0 client, −4 Dette).

### 32.5 Ce que le banc dit, et ce qu'il ne dit pas encore

40 runs, 160 mandats par stratégie, cinq trajectoires (`careful` et `stress`
inchangées, `greedy` conservée, `economie` et `levier` ajoutées pour le critère
de recette 2) :

| Stratégie | Sprint médian | 💥 médian | 💰 médian | 💰/charges | Fins positives | Faillites |
|---|---|---|---|---|---|---|
| `careful` | 3 | 0 | 50 | 2,8× | 0 % | 0 % |
| `economie` | 9 | 1416 | 97 | **2,3×** | 2 % | 1 % |
| `levier` | 8 | 1922 | 33 | **0,8×** | 8 % | **30 %** |
| `greedy` | 8 | 1331 | 107 | **3,0×** | 3 % | 6 % |

Le rapport `Revenue final / charges par sprint` passe de **56× à 3,0×** sur
`greedy` : la caisse a recommencé à contraindre. Et on meurt **des deux
côtés** — `levier` fait faillite 30 % du temps avec ~1900 💥 en poche,
`economie` manque son quota avec une caisse pleine.

**Ce qui reste gênant, et qu'il faut dire** : les deux trajectoires franchissent
bien le mandat (T3 ou T4 selon les tirages, dans les deux sens), mais `levier`
gagne **quatre fois plus souvent** que `economie` (8 % contre 2 %). Ce n'est pas un défaut de calibrage : c'est la
conséquence directe de la séparation des deux économies. L'argent n'achète
rien — l'Impact est la seule monnaie — donc une bonne caisse ne **produit**
jamais de score, elle **permet** seulement de tenir plus longtemps une
organisation qui en produit. Le pari de `levier` (sur-investir, risquer la
faillite) a une espérance meilleure que celui de `economie` (ne jamais engager
une charge à découvert). Corriger ça sans ré-ouvrir la fuite demanderait de
rendre la faillite plus fréquente ou l'escalade des quotas moins raide (#36) —
pas d'ajouter un chemin Revenue → Impact, qui reconstruirait exactement ce que
ce lot vient de démonter.

### 32.6 Quatre pièges rencontrés en route

- **Un prix affiché et un prix encaissé qui divergent.** Le `priceMultiplier`
  des décisions stratégiques était d'abord lu par `ScoreResolver` seul, pendant
  que `resolved_segment_price()` servait l'affichage. Deux chemins de calcul
  pour un même prix : la ligne de composition sous le solde se serait mise à
  mentir dès la première décision. Il écrit maintenant dans
  `segment_price_multipliers`, la seule table que les deux lisent.
- **Une flakiness introduite par un test, pas par le code.** Trois runs sur 40
  échouaient sur l'injonction du board : les assertions de quota nettoyaient
  `chosen_strategy_ids` (à cause du nouveau `quotaMultiplier` d'Expansion
  internationale) sans remettre `quarter_strategy_chosen` à `false`, ce qui
  rendait `_assign_forced_strategy()` silencieusement inopérant quelques lignes
  plus bas. Mesure sur `main` d'abord (40/40), puis sur la branche (37/40) :
  c'est la comparaison qui a distingué « ma régression » de « défaut
  préexistant ».
- **Une assertion qui comparait deux tirages entre eux** — §29 apprise une
  quatrième fois, et cette fois par la relecture. Le critère « aucune
  trajectoire ne domine » avait été écrit
  `|meilleur trimestre économie − meilleur trimestre Levier| ≤ 1`, sur deux
  échantillons indépendants de **quatre mandats**. Elle est tombée une fois sur
  40 sur un moteur parfaitement sain (économie T4 contre Levier T2) ; la
  distribution mesurée depuis montre les deux ordres (18 fois T4/T4, 15 fois
  T3/T4, 2 fois T4/T3). La règle : la **viabilité** d'une trajectoire est une
  propriété du moteur et s'assère (chacune doit passer au moins un verdict) ;
  la **domination** est une mesure de calibrage, elle se lit sur 40 runs et se
  documente ici. On n'assère pas une comparaison entre deux échantillons de
  quatre.
- **Encaisser sur la nouvelle population et facturer sur l'ancienne.**
  `_apply_recurring_charges()` tournait avant `_apply_score_conversion()` : le
  Revenue entrait sur la population résolue pendant que le support se facturait
  sur celle d'avant. Une grosse acquisition offrait donc un sprint de support
  gratuit, et des clients partis restaient facturés un sprint de trop. L'ordre
  est inversé, et une assertion compare désormais `last_client_cost` à
  `get_client_support_cost()` **après** résolution. Symétriquement, le pivot
  « Fin du gratuit » vidait le segment d'entrée sans en fermer la porte : la
  livraison du sprint suivant le repeuplait, et la décision promettait une
  disparition qu'elle ne tenait pas. `segment_arrival_multipliers` la ferme
  pour de bon, et `_test_business_model_pivot()` joue le sprint d'après.

### 32.7 Ce que ce lot ne fait pas

- **L'équipe individuelle** ([`spec-equipe-individuelle.md`](spec-equipe-individuelle.md))
  est le lot d'après. Les deux réécrivent des effets de contenu et ne doivent
  jamais se faire en même temps.
- **L'escalade des quotas et l'indexation des prix** restent l'issue #36.
- **`waterfall-release`** est déclaré avec `segments: []` : le scénario Garage
  l'attend, et les gros paliers de revenu à la sortie d'une version ne sont pas
  écrits.
- **Le pivot « Fin du gratuit »** existe et se joue, mais n'est volontairement
  **pas dans le pool de l'injonction du board** : imposer un changement de
  modèle économique irréversible sans le choisir n'est pas un pari, c'est une
  punition.
