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
| **Trimestre** | ~6 sprints | Point de contrôle : revue de board, événement "boss" |
| **Mandat** | Variable | Le run entier, de la nomination à la sortie |

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
- **Longueur de mandat et fins positives.** Un mandat dure 12 sprints
  (`mandateLengthSprints`). S'il se termine sans fin négative, le score final
  est la moyenne de Valeur perçue et Capital politique : ≥ 60 → IPO, sinon →
  Rachat. Valeur arbitraire de calibrage MVP, à ajuster en playtest.
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
  **SaaS — revenu récurrent (MRR)** : chaque sprint, un revenu tombe
  automatiquement, proportionnel à la Valeur perçue et modulé par le Moral
  (un moral bas simule du churn et rogne le revenu, un moral haut le
  bonifie légèrement). Calculé dans `SprintState.compute_revenue()`, affiché
  séparément des coûts de décisions en Résolution (voir plus bas) — c'est la
  boucle qui manquait : investir dans la Valeur perçue et le Moral compose
  en revenu récurrent au lieu de rester un pur centre de coût.
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
- **Résolution animée.** Les jauges passent de l'ancienne à la nouvelle
  valeur par un tween (au lieu d'un affichage figé), avec un léger décalage
  entre chaque jauge. Le revenu du sprint défile de 0 jusqu'à sa valeur
  réelle dans un bloc dédié, à côté du coût net des décisions et du solde —
  pour que le joueur voie distinctement ce qui rentre et ce qui sort.
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

- **Le roster produit la capacité.** `SprintState.roster` remplace le
  `capacity_bonus` plat : chaque entreprise définit son équipe héritée, son
  cap d'effectif et son budget d'action initial (`companies.json`). Devs et
  PM produisent des points de capacité (rendements décroissants au-delà du
  cap de cumul du rôle), les Designers bonifient la Valeur perçue des
  features livrées (÷2 en leur absence), les Ops contiennent la dette
  (+2 Dette/sprint sans eux — le défaut affiché de Karavel). Les salaires
  (junior 1, senior 2) sont prélevés à chaque Résolution, ligne « masse
  salariale ».
- **Les Pièces 🪙.** Monnaie d'action de l'entreprise : allocation du board
  (+2/sprint, réduite à +1 après une revue ratée), prime de performance
  (`floor(revenu/4)`), quick wins, événements Inbox (pseudo-ressource
  `pieces` dans `effects`). Se dépense au Marché et en indemnités. À 0 on ne
  perd pas — on est paralysé.
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
- **La pression.** Valeur perçue −2/sprint (le marché avance) ; le revenu
  SaaS ne compte que les points de Valeur perçue au-dessus d'un seuil de
  notoriété (`revenueValeurPercueOffset`) et tombe à zéro sous le seuil de
  décrochage (≤ 5) — le couperet « Valeur perçue ≤ 0 = fin » disparaît, la
  mort passe par la spirale économique. La **revue de board** tombe à la fin
  du sprint 6 : objectifs par entreprise (visibles dès l'offre d'emploi),
  overlay de verdict en Résolution, +5 🪙/+8 Capital politique en cas de
  succès, −12 Capital politique et allocation réduite sinon.
- **Recette.** Les smoke tests pilotent ces systèmes ; critère impératif :
  la stratégie `careful` (ne rien livrer, ne rien acheter, ne rien recruter)
  perd avant la fin du mandat — vérifié en faillite vers les sprints 7-11
  sur les deux entreprises.

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
  roster condensé, actifs possédés, revue de board. Il est sombre dans un monde
  clair : diégétiquement l'écran TV du standup, et pratiquement la garantie que
  les chiffres restent lisibles là où le post-it échouerait.
- **Le roster est actionnable en un clic.** Un clic sur une ligne du panneau
  ouvre le menu 🤝 1:1 / 🚪 Licencier — plus besoin d'ouvrir un overlay puis de
  scroller. Le licenciement gagne une vraie confirmation (il est irréversible et
  coûte du Moral).
- **La revue de board est évaluée en direct.** `SprintState.evaluate_board_objectives()`
  confronte les conditions de `companies.json` à l'état courant sans rien
  modifier ; le panneau les affiche cochées avec la valeur lue (« ✗ (47) »), et
  `_run_board_review()` s'en sert au sprint 6 pour son verdict — une seule
  implémentation des conditions, deux usages.
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
