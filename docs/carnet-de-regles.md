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

Cinq phases, dans l'ordre :

1. **Inbox** — un événement aléatoire tombe (le "chaos humain") et force un choix avant toute planification.
2. **Roadmap** — 2 à 4 features proposées, sélection limitée par la **capacité** de l'équipe. Dépasser sa capacité déclenche une surchauffe (dette + cynisme en hausse).
3. **Grandes décisions** — activation optionnelle d'une décision structurelle (voir §6.2). Pas systématique à chaque sprint.
4. **Recrutement** — accès optionnel au shop.
5. **Résolution** — application des effets, delta affiché (voir maquette HUD dans la landing page).

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
Pas de pioche : un menu permanent, activé quand le joueur le décide. Limité à 3-4 activations par mandat, avec un vrai coût de bascule. Reflète le fait qu'une organisation ne change pas d'outil toutes les deux semaines. Trois familles, qui ne se comportent pas pareil dans le temps (détail en §7) :
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
