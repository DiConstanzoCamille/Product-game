# Spécification — Le score du sprint : Traction, Levier, Impact

> Document de travail issu de la demande du 30/07/2026 : *« on survit, mais on
> n'a pas le côté satisfaisant d'un Balatro à combo en gagnant plein de sous ».*
> Rien de ce qui suit n'est implémenté. Ce document décrit une **cible de
> conception** ; le [carnet de règles](carnet-de-regles.md) décrit l'état
> actuel, la [spec de profondeur](spec-profondeur-gameplay.md) décrit les
> phases A→D dont celle-ci reprend et **remplace en partie** la phase D.
>
> En une phrase : le sprint cesse d'être une soustraction de ressources pour
> devenir **une main qu'on résout**, et le mandat cesse d'être « tenir 12
> tours » pour devenir « battre le trimestre suivant, encore une fois ».

**Sommaire**
1. Le problème
2. Le principe — Traction × Levier = Impact
3. L'ordre de résolution : la « main » du sprint
4. Les sources de Traction — ce que j'ai produit
5. Les sources de Levier — l'organisation que je suis
6. Les freins — pourquoi le moteur ne s'emballe pas
7. La conversion — l'Impact devient de l'argent qui compose
8. Le quota trimestriel — le vrai boss
9. La croissance — le Comité d'investissement
10. L'animation de résolution
11. Ce que ça change dans l'existant
12. Données
13. Phasage
14. Points à trancher

---

## 1. Le problème

Le jeu actuel est une **simulation de survie** : six jauges qui descendent,
des décisions qui coûtent, un revenu linéaire d'une dizaine de points, et
douze sprints à tenir. Trois symptômes :

| Symptôme | Cause structurelle |
|---|---|
| Aucun moment de jubilation | Rien ne se **multiplie**. Tout est additif et borné 0-100. |
| Les bonnes décisions ne récompensent pas visiblement | Le revenu (`compute_revenue()`) ne dépend que de deux jauges, pas de ce que j'ai fait ce sprint. |
| Pas d'envie d'aller plus loin | La fin est une date, pas un mur à franchir. Le meilleur run et le pire durent 12 sprints. |
| Pas de gestion d'équipe | Le cap d'effectif est fixé par l'entreprise, immuable. Recruter ne fait que compléter un trou. |
| On ne construit rien | Aucun objet du jeu ne devient plus fort avec le temps. |

La réponse tient en une phrase : **il faut un score de sprint, produit d'une
base et d'un multiplicateur, dont les deux facteurs se construisent sur la
durée, et un mur qui monte plus vite que le score.**

---

## 2. Le principe — Traction × Levier = Impact

Trois grandeurs nouvelles, propres au sprint (elles ne sont **pas** des
jauges 0-100 — c'est le point) :

| Grandeur | Symbole | Ce que c'est | Vient de |
|---|---|---|---|
| **Traction** | 📊 | La valeur brute produite ce sprint | Les features livrées |
| **Levier** | ⚙️ | Ce que l'organisation fait de cette valeur | Équipe, Fondations, Pratiques, Produit |
| **Impact** | 💥 | `Traction × Levier` | Le résultat du sprint |

> **La phrase de design :** *ce que j'ai produit* × *l'organisation que j'ai
> construite*. Les deux facteurs sont indépendants et se construisent
> séparément — c'est exactement la tension « faire » vs « organiser » du
> métier, et c'est aussi ce qui rend le score explosif : ×2 sur chaque
> facteur, ×4 sur le résultat.

Une équipe parfaite qui ne livre rien fait **0**. Une livraison massive dans
une organisation nulle fait un score plat. C'est le cœur.

L'Impact ne remplace pas les six jauges : il les **alimente** (§7). Les
jauges restent le baromètre de santé et les conditions de mort ; l'Impact
est le débit.

---

## 3. L'ordre de résolution : la « main » du sprint

L'ordre est figé et c'est lui qui fait le spectacle — chaque étape est un
temps de l'animation (§10). Le joueur apprend l'ordre en trois sprints et
commence alors à *jouer avec*.

```
①  LIVRAISON        chaque feature livrée révèle sa Traction            → 📊
②  BONUS DE MAIN    combos sur la livraison elle-même (focus, sprint    → 📊
                    parfait, série)
③  L'ÉQUIPE         chaque membre déclenche, puis les combos            → 📊 et ⚙️
                    d'organisation nommés
④  LES FONDATIONS   chaque grande décision activée déclenche            → ⚙️
⑤  LES PRATIQUES    petits leviers conditionnels                        → ⚙️
⑥  LE PRODUIT       palier de produit atteint                           → ⚙️
⑦  LES FREINS       Cynisme, Dette, surchauffe, Moral au plancher       → ✂️
⑧  IMPACT           Traction × Levier, affiché en grand
⑨  CONVERSION       Impact → MRR, 🪙 Pièces, 📈 Valeur perçue
⑩  LE QUOTA         la barre du trimestre se remplit
```

Deux règles de lisibilité, non négociables :

- **Un effet, une ligne, une place fixe.** Chaque source de Traction ou de
  Levier s'affiche à son étape, jamais ailleurs. Le joueur doit pouvoir
  pointer du doigt d'où vient un chiffre.
- **Les freins sont les derniers.** Voir son 340 se faire raboter à 190 par
  du Cynisme accumulé doit faire mal *après* avoir vu le 340. C'est ce qui
  transforme « le Cynisme, c'est mal » en « je dois traiter mon Cynisme ».

---

## 4. Les sources de Traction — ce que j'ai produit

### 4.1 Les features (l'essentiel)

**Prérequis : la roadmap profonde** (spec de profondeur §6) doit être
branchée — `data/backlog.json` existe déjà avec `costPoints`, `roi`,
`clientImpact`, `risk`, `quickWin`, mais l'écran Roadmap consomme encore les
4 features de démo. C'est le lot 0 de ce chantier (§13).

```
Traction d'une feature = costPoints × tractionPerPoint
                       + clientImpact × tractionPerClientImpact
```

Avec `tractionPerPoint = 4` et `tractionPerClientImpact = 3` :

| Feature | Points | Impact client | Traction |
|---|---|---|---|
| 📤 Export Excel (quick win) | 1 | +2 | **10** |
| 🔐 SSO grands comptes | 3 | +3 | **21** |
| 🏗️ Refonte du portail | 5 | +5 | **35** |
| 🤖 Chatbot « intelligent » | 3 | −2 | **6** |
| 📊 Dashboard COMEX | 3 | 0 | **12** |

Les features à impact client négatif rapportent quand même un peu (on a
livré quelque chose) mais elles sont un piège de Traction — et elles font en
plus baisser la Valeur perçue. **Sans Discovery/UX research, on ne sait
pas.** C'est là que les Pratiques cessent d'être décoratives : elles
révèlent la colonne qui décide du score.

### 4.2 Les epics

Une epic ne rapporte **rien** tant qu'elle n'est pas complète, puis
`total des points × epicTractionPerPoint (6)` d'un coup. Une epic de 10
points = **60 de Traction** dans un seul sprint. C'est le gros coup qu'on
prépare pendant quatre sprints et qu'on fait tomber pile au sprint qui
conclut le trimestre. Le jeu de timing démarre ici.

### 4.3 Les bonus de main (étape ②)

Combos qui portent sur la livraison elle-même, indépendants de l'équipe :

| Combo | Condition | Effet |
|---|---|---|
| 🎯 **Sprint parfait** | Points consommés = capacité, à l'unité près | Traction ×1.25 |
| 🔎 **Focus** | Toutes les features livrées partagent un même tag (`tags[]` à ajouter au backlog) | Traction ×1.3 |
| 🧩 **Livraison groupée** | ≥ 3 features livrées | +10 Traction |
| ⚡ **Quick wins en série** | ≥ 2 quick wins livrés | +2 🪙 supplémentaires |
| 📦 **Epic bouclée** | Une epic se termine ce sprint | Traction ×1.5 |
| 🕳️ **Sprint vide** | Aucune feature livrée | Traction 0, et la série casse |

La **série** (`streak`) : nombre de sprints consécutifs avec au moins une
feature livrée sans surchauffe. `+0.05 de Levier par sprint de série`,
plafonné à +0.5, remis à zéro par un sprint vide ou une surchauffe. C'est le
compteur qui punit le « je saute un sprint pour souffler » — et qui rend le
choix de souffler réellement coûteux.

---

## 5. Les sources de Levier — l'organisation que je suis

Le Levier démarre à **×1.0** et s'additionne (les sources donnent `+0.x`,
pas `×0.x`) — additionner reste lisible, et c'est le produit final
Traction × Levier qui fait l'explosion.

### 5.1 Les combos d'organisation (étape ③) — le cœur de la demande

Des synergies **nommées**, qui s'affichent en bandeau pendant l'animation.
Ce sont elles qui donnent envie de recomposer l'équipe plutôt que de
l'empiler.

| Combo | Condition sur le roster | Levier |
|---|---|---|
| 🔺 **Trio produit** | ≥ 1 PM, ≥ 1 Dev, ≥ 1 Designer | +0.3 |
| 🛡️ **Squad complète** | Trio produit + ≥ 1 Ops | +0.6 *(remplace le Trio)* |
| 🔨 **Force de frappe** | ≥ 3 Devs | +0.4 |
| 🎓 **Binôme senior** | ≥ 2 seniors dans le même rôle | +0.25 |
| 🌱 **Sang neuf** | ≥ 2 employés recrutés dans les 3 derniers sprints | +0.25 |
| 🗿 **Vieille garde** | ≥ 3 employés présents depuis le sprint 1 | +0.35 |
| 🎭 **Théâtre** | ≥ 2 PM et 0 Dev | **−0.5** |
| 👑 **Tour d'ivoire** | Effectif ≥ 6 et aucun Ops | **−0.3** |

**Sang neuf** et **Vieille garde** sont volontairement contradictoires : on
ne peut pas avoir les deux sans un gros effectif. Le joueur doit choisir une
identité d'organisation — la boîte qui se renouvelle ou celle qui capitalise
— et ce choix devient lisible dans le score.

Les combos négatifs existent pour la même raison que les positifs : rendre
la composition *lisible*. « 6 PM = specs sans code » (retour de playtest
d'origine) devient un bandeau rouge **🎭 Théâtre −0.5** en pleine
résolution, impossible à rater.

### 5.2 Les membres eux-mêmes

Chaque employé déclenche à son tour, comme un joker. Deux couches :

- **Rôle** — le Designer donne `+2 Traction par feature livrée` (déjà dans
  `balance.json`), le PM `+0.05 Levier par PM` (plafonné), l'Ops soigne la
  Dette (donc le frein du §6).
- **Traits** — les traits cachés existants prennent une seconde vie
  chiffrée : 💎 Pépite `+0.15 Levier`, 🤝 Mentor `+0.1 Levier`, 🏝️ Fantôme
  `contribution ÷ 2` (déjà implémenté), 😤 Râleur `−0.1 Levier`. Et les
  **traits visibles** (jamais branchés, cf. spec profondeur §4.6) deviennent
  enfin mécaniques : « Maintient seule un module que personne n'ose ouvrir »
  → `+0.2 Levier si aucune feature à risque ≥ 4 n'est livrée, −0.3 sinon`.

C'est ici que se joue « mes bonus passifs liés à des membres de l'équipe ».

### 5.3 Les Fondations (étape ④)

Les grandes décisions cessent d'être un coût ponctuel sur les jauges pour
devenir des **multiplicateurs permanents et conditionnels** — le vrai
« build » du run :

| Fondation | Levier de base | Bonus conditionnel |
|---|---|---|
| 🧮 **RICE** | +0.25 | +0.25 si ≥ 3 features proposées ont été **refusées** ce sprint (prioriser, c'est arbitrer) |
| 🗂️ **Jira** | +0.2 | +0.3 si effectif ≥ 6 (le process paie à l'échelle, pas avant) |
| 📓 **Notion** | +0.15 | +0.3 si ≥ 2 recrues de moins de 3 sprints (l'onboarding) |
| 🔁 **Daily standup** | +0.08 par Dev | plafonné à +0.4 |
| 🪞 **Sprint rétro** | **+0.05 cumulatif par sprint depuis son activation** | pas de plafond |

**Sprint rétro est la carte qui change tout** : c'est le levier qui grandit
tout seul. Prise au sprint 2, elle vaut +0.5 au sprint 12. Prise au sprint
9, elle ne vaut rien. Une carte dont la valeur dépend du *moment* où on la
joue est ce qui transforme un menu en décision. Il en faut deux ou trois de
cette famille.

### 5.4 Les Pratiques (étape ⑤)

Petits leviers conditionnels, en plus de leur rôle de révélation actuel :

| Pratique | Levier |
|---|---|
| 🔍 Discovery | +0.2 si toutes les features livrées ont un `clientImpact > 0` |
| 🎯 OKR | +0.25 si une feature à `roi ≥ 2` est livrée |
| 🧭 Tech radar | +0.15 si aucune feature à `risk ≥ 5` n'est livrée |
| 📊 Product analytics | +0.1 fixe |

Elles restent chères en Cynisme (+2 à l'achat) : acheter tout le rayon
construit un levier qui se fait manger par son propre frein (§6). L'arbitrage
est réel.

### 5.5 Le palier de produit (étape ⑥)

Le produit lui-même monte de niveau au Comité d'investissement (§9) :
`+0.5 de Levier par palier`, et `+1 feature proposée par sprint`. C'est
l'achat de croissance le plus cher et le plus structurant.

---

## 6. Les freins — pourquoi le moteur ne s'emballe pas

Appliqués en dernier (étape ⑦), en **multiplicatif**, et affichés en rouge.
C'est ce qui garde le jeu difficile : plus le moteur est gros, plus les
freins font mal en valeur absolue.

| Frein | Formule | À l'extrême |
|---|---|---|
| 🎭 **Cynisme** | Levier × `(1 − (cynisme − 40) / 120)` au-delà de 40 | Cynisme 100 → **×0.5** |
| 🧱 **Dette** | Traction × `(1 − (dette − 40) / 150)` au-delà de 40 | Dette 100 → **×0.6** |
| 🔥 **Surchauffe** | Impact × 0.6 si la capacité a été dépassée | (en plus des pénalités jauges actuelles) |
| 💔 **Moral au plancher** | Levier **plafonné à ×1.5** si Moral < 30 | Le moteur est débranché |

Le plafond de Levier par le Moral bas est le frein le plus violent et le
plus juste : **une organisation qui va mal ne combote pas.** Tout le build
patiemment construit devient inopérant tant que l'équipe n'est pas
réparée — ce qui donne enfin une raison mécanique de dépenser pour le Moral
au lieu de le laisser filer.

---

## 7. La conversion — l'Impact devient de l'argent qui compose

C'est le point « les points sont liés aux produits, et la trésorerie en
fonction du business model ». Le business model n'est plus une formule
d'affichage : c'est **la règle de conversion de l'Impact**.

### 7.1 SaaS — MRR cumulatif (Transformation agile)

```
MRR ← MRR × (1 − churn) + Impact × impactToMrr (0.06)
Revenu du sprint = MRR
churn = f(Moral, Dette) — 4 % de base, jusqu'à 15 % si Moral bas et Dette haute
```

**Le MRR devient un stock, pas un flux calculé.** Un sprint à 300 d'Impact
ajoute +18 de MRR **pour tous les sprints suivants**. C'est la composition
qui manque aujourd'hui : investir tôt paie longtemps, et négliger fait
fondre l'acquis (churn) sans qu'on ait besoin d'un couperet.

C'est aussi ce qui rend le début dur et la fin grisante — exactement la
courbe d'un Balatro.

### 7.2 Vente à la version — waterfall (Garage, à venir)

L'Impact ne se convertit pas chaque sprint : il s'accumule dans une
**version en préparation**. Sortir la version encaisse
`Impact accumulé × releaseRate` d'un coup en Trésorerie, et remet le
compteur à zéro. Gros paliers, gros risques, rien entre deux.
Le même moteur de score, deux économies radicalement différentes — de quoi
donner une vraie identité au scénario Garage quand il ouvrira.

### 7.3 Les autres sorties

En plus du revenu, chaque sprint :

- 🪙 **Pièces** : `floor(Impact / 25)` + allocation du board
- 📈 **Valeur perçue** : `+floor(Impact / 30)`, **plafonné à +6/sprint** (la
  jauge reste une jauge, elle ne doit pas exploser avec le score)
- 🎯 **Capital politique** : `+1` par tranche de 150 d'Impact (le board voit
  passer les gros chiffres)

---

## 8. Le quota trimestriel — le vrai boss

**C'est la pièce qui transforme « survivre 12 tours » en « aller plus
loin ».**

### 8.1 Structure

Le trimestre passe de 6 à **3 sprints** (`trimesterLengthSprints: 3`). À la
fin de chaque trimestre, le board attend un **quota d'Impact cumulé** sur
les 3 sprints. Le quota est **annoncé au premier sprint du trimestre** et
affiché en permanence dans le Panneau de bord, sous forme de barre qui se
remplit.

| Trimestre | Sprints | Quota d'Impact cumulé |
|---|---|---|
| T1 | 1-3 | **120** |
| T2 | 4-6 | **270** |
| T3 | 7-9 | **560** |
| T4 | 10-12 | **1 050** |
| T5+ | *(mode long mandat)* | ×1.9 par trimestre |

Progression ×~2 par trimestre, quand un moteur bien construit progresse
×2,5-3 : **la marge se gagne, elle ne se subit pas.** Ne rien construire,
c'est manquer T2 ou T3 mathématiquement.

### 8.2 L'exigence du trimestre (le « boss »)

Chaque trimestre tire une **exigence** aléatoire, visible dès son premier
sprint, qui déforme les règles :

| Exigence | Effet |
|---|---|
| 🧊 **Gel des embauches** | Aucun recrutement pendant le trimestre |
| 💼 **Le DAF regarde** | Masse salariale ×2 |
| 🎪 **Le board veut du visible** | Les features à `clientImpact ≤ 0` ne rapportent aucune Traction |
| 🏚️ **Audit technique** | Le frein de Dette compte double |
| 📉 **Trimestre court** | 2 sprints au lieu de 3, quota réduit de 25 % seulement |
| 🗣️ **Injonction du board** | Une Fondation vous est **imposée** (coût payé, effet subi) |
| 🕵️ **Comité de pilotage** | Chaque Pratique achetée coûte +4 Cynisme au lieu de +2 |

Les objectifs qualitatifs actuels de `companies.json` (Cynisme ≤ 45, etc.)
ne disparaissent pas : ils deviennent le **bonus de trimestre** — les tenir
en plus du quota rapporte un paquet de 🪙 supplémentaire au Comité (§9).

### 8.3 L'échec

Quota manqué = **fin de mandat immédiate**, nouvelle fin `🪑 Remercié·e` :
*« Le comité vous remercie pour votre contribution. Un cabinet accompagnera
la transition. »*

C'est dur, et c'est le point. Un boss qu'on peut rater sans mourir n'est pas
un boss — et c'est précisément ce qui manque au jeu aujourd'hui. Un filet
existe mais il **s'achète** : le **Plan de redressement** (Fondation rare,
chère) offre un unique rattrapage dans le mandat.

### 8.4 La fin du mandat

Les 12 sprints ne sont plus une fin, ce sont **quatre trimestres franchis**.
À la fin de T4, le joueur choisit :

- **🚀 Sortir par le haut** — IPO/rachat selon les jauges, run marqué comme
  gagné, score final enregistré.
- **♾️ Rester** — le mandat continue, les quotas s'envolent (×1.9), on joue
  pour le score. C'est le mode qui donne envie de refaire un run pour battre
  son propre chiffre.

---

## 9. La croissance — le Comité d'investissement

Entre deux trimestres, un écran dédié : **le Comité d'investissement**.
C'est là qu'on dépense le paquet de 🪙 gagné en franchissant le quota, et
c'est là que se répare le trou « pas de gestion d'équipe ».

Le Marché de sprint (2 candidats + 2 pratiques) ne change pas — il reste le
petit achat régulier. Le Comité est le **gros achat structurel**, plus rare
et plus cher.

| Investissement | Coût 🪙 | Effet |
|---|---|---|
| 🪑 **Ouvrir un poste** | 6, puis 10, puis 16… | +1 au cap d'effectif |
| 📈 **Promotion** | 5 | Un junior devient senior (salaire +1, contribution senior) |
| 🚀 **Palier de produit** | 12 / 25 / 45 | +0.5 Levier permanent, +1 feature proposée par sprint |
| 🏝️ **Séminaire d'équipe** | 8 | −15 Cynisme |
| 🧹 **Sprint de remise à plat** | 6 + **un sprint entier** | −20 Dette, 0 Traction ce sprint |
| 🤝 **Rachat d'un concurrent** | 30 | +12 MRR immédiat, +1 employé aléatoire, +8 Dette |
| 🔄 **Reroll du Marché** | 3 | Retire l'offre du sprint |
| 🏛️ **Plan de redressement** | 20 | Un rattrapage de quota dans le mandat |
| 🎯 **Chasseur de têtes** | 8 | Le prochain Marché propose 4 candidats, traits révélés |

Le cap d'effectif devient donc un **objet de jeu** et non une contrainte
subie, et le licenciement (déjà implémenté dans le Panneau de bord, menu au
clic sur une ligne du roster) prend enfin un sens offensif : virer un 🏝️
Fantôme pour libérer un poste et déclencher un combo est une décision
gagnante, pas seulement un aveu d'échec.

### 9.1 Le Compendium des synergies

Un onglet du Dossier entreprise liste **tous** les combos du jeu : ceux déjà
déclenchés au moins une fois sont affichés en clair, les autres en `???`
avec seulement leur icône et leur famille. Collectionner les combos devient
un objectif de méta-progression à coût de développement quasi nul — et ça
règle la découvrabilité sans tutoriel.

---

## 10. L'animation de résolution

**C'est le livrable qui porte tout le reste.** Un moteur de score sans
spectacle ne se ressent pas.

Cadre diégétique : l'écran de Résolution devient **la démo de sprint** —
l'équipe présente ce qu'elle a fait, et le tableau des chiffres se remplit
en direct.

```
┌──────────────────────────────────────────────────────────────┐
│  SPRINT 7 — LA DÉMO                              T3  ▓▓▓░░░  │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│              📊  184        ×        ⚙️ 2.4                  │
│                                                              │
│   ① 🔐 SSO grands comptes ............................ +21   │
│      🏗️ Refonte du portail ........................... +35   │
│      📦 Epic « Socle technique » bouclée ............. +60   │
│   ② 🎯 SPRINT PARFAIT ............................. ×1.25    │
│   ③ 🎨 Patrice · Designer ............................. +4   │
│      🛡️ SQUAD COMPLÈTE ............................. +0.60   │
│      💎 Sofia · Pépite ............................. +0.15   │
│   ④ 🪞 Sprint rétro (5 sprints) .................... +0.25   │
│      🧮 RICE ....................................... +0.25   │
│   ⑦ 🎭 Cynisme 62 ................................... ×0.82  │
│                                                              │
│   ═══════════════════════════════════════════════════════    │
│                    💥  IMPACT  441                           │
│   ═══════════════════════════════════════════════════════    │
│   MRR 42 → 68   ·   🪙 +17   ·   📈 +6   ·   🎯 +2           │
│                                                              │
│   TRIMESTRE 3 ······················ 441 / 560   ▓▓▓▓▓▓▓░░   │
└──────────────────────────────────────────────────────────────┘
```

Règles d'animation :

- **Un pas = un événement.** Chaque ligne apparaît séquentiellement, ~0,25 s
  d'intervalle, avec le compteur concerné qui s'incrémente en tween.
- **Le son monte en pitch** à chaque incrément, et se réinitialise à chaque
  étape. C'est 80 % de la satisfaction pour 5 % du travail.
- **Les combos nommés prennent la largeur** : bandeau, léger screenshake,
  couleur pleine. On doit avoir envie de les revoir.
- **Les freins arrivent en dernier, en rouge, et *retirent*** — le compteur
  redescend visiblement.
- **L'Impact final flashe**, et sa taille de police dépend de sa magnitude
  (un 900 doit occuper l'écran).
- **Clic = accélérer, second clic = tout révéler.** Indispensable : au
  sprint 30, personne ne veut revoir la séquence complète.
- La barre de quota se remplit **en dernier**, et change de couleur quand
  elle franchit le seuil. Si le trimestre se joue sur ce sprint, la barre
  est le climax, pas l'Impact.

---

## 11. Ce que ça change dans l'existant

| Système actuel | Devient |
|---|---|
| `compute_revenue()` — revenu dérivé de 2 jauges | Conversion de l'Impact en MRR cumulatif (§7) |
| Décroissance Valeur perçue −2/sprint | **Conservée**, mais doublée par le churn de MRR : deux pressions distinctes |
| Revue de board au sprint 6, qualitative | Quota chiffré tous les 3 sprints + exigence + objectifs qualitatifs en bonus (§8) |
| Mandat = 12 sprints | 4 trimestres, puis mode long mandat (§8.4) |
| Grandes décisions = coût ponctuel sur jauges | Coût ponctuel **+ levier permanent conditionnel** (§5.3) |
| Traits visibles décoratifs | Modificateurs de Levier (§5.2) |
| Roadmap sur 4 features de démo | `backlog.json` branché, points/ROI/impact/risque réels |
| Cap d'effectif figé | Achetable au Comité (§9) |
| Fin par jauge à l'extrême | **Conservées telles quelles** + nouvelle fin `remercie` sur quota manqué |

Les six jauges, l'Énergie, les Pièces, l'Inbox, les traits cachés, le Marché
et le Dossier entreprise **ne changent pas de nature**. C'est une couche
au-dessus, pas une réécriture.

---

## 12. Données

| Fichier | Statut | Contenu |
|---|---|---|
| `data/scoring.json` | **nouveau** | Combos de main, combos d'organisation, leviers de Fondations/Pratiques, formules de freins |
| `data/quotas.json` | **nouveau** | Quotas par trimestre, courbe du mode long, pool des exigences |
| `data/investments.json` | **nouveau** | Catalogue du Comité d'investissement (§9) |
| `data/backlog.json` | modifié | + `tags[]` (pour le combo Focus), + les epics |
| `data/balance.json` | modifié | + `scoring` (taux de conversion Traction, `impactToMrr`, churn, ratios Pièces/Valeur), `trimesterLengthSprints: 3` |
| `data/endings.json` | modifié | + `remercie` |
| `data/cards.json`, `practices.json` | modifiés | + champ `levier` |

`SprintState` gagne : `traction`, `levier`, `last_score_report` (le détail
ligne à ligne, pour l'animation), `mrr`, `quarter_impact`, `quarter_index`,
`quarter_requirement_id`, `streak`, `product_tier`, `combos_discovered[]`.

Un nouvel autoload/module **`ScoreResolver`** calcule la main et **retourne
un rapport structuré** (liste ordonnée d'étapes, chacune `{etape, icone,
libelle, type, valeur}`). L'écran de Résolution ne fait que **rejouer ce
rapport** — pas de logique de score dans l'UI. C'est ce qui rend le système
testable en headless : le smoke test logique vérifie des scores, pas des
pixels.

---

## 13. Phasage

- **Lot 0 — La roadmap profonde** *(prérequis, déjà specifié en Phase C)* :
  brancher `backlog.json` sur l'écran Roadmap, coûts en points réels, epics,
  colonnes cachées révélées par les Pratiques. Sans ça il n'y a rien à
  scorer.
- **Lot 1 — Le score et son animation** : `ScoreResolver`, Traction/Levier/
  Impact, bonus de main, combos d'organisation, leviers de Fondations et
  Pratiques, freins, conversion MRR cumulatif, et **la séquence animée
  complète**. → *Critère : un sprint bien joué doit donner envie de refaire
  le même.*
- **Lot 2 — Le quota trimestriel** : trimestres de 3 sprints, quotas
  escaladés, exigences, fin `remercie`, barre de quota permanente, mode long
  mandat. → *Critère : un joueur qui ne construit pas de moteur meurt à T2
  ou T3.*
- **Lot 3 — La croissance** : Comité d'investissement, cap d'effectif
  achetable, promotions, paliers de produit, Compendium des synergies.
  → *Critère : deux runs sur la même entreprise produisent deux
  organisations différentes.*
- **Lot 4 — La profondeur de build** : traits visibles branchés, Fondations
  à levier croissant supplémentaires, modèle waterfall pour le scénario
  Garage, équilibrage sur 20+ runs headless.

Chaque lot se conclut comme d'habitude : les deux smoke tests headless, un
run visuel, et la mise à jour du carnet de règles.

---

## 14. Points à trancher

1. **L'échec de quota tue-t-il le run ?** Proposé : oui, fin `Remercié·e`,
   avec un rattrapage achetable. Alternative plus douce : le quota manqué
   coûte tout le Capital politique et l'allocation, sans tuer. Le jeu
   perdrait beaucoup en tension.
2. **Trimestre à 3 sprints ?** Proposé : oui (4 boss dans un mandat de 12).
   Alternative : 4 sprints (3 boss, plus de respiration, moins de rythme).
3. **Le MRR est-il un stock cumulatif ?** C'est le choix le plus structurant
   du document — c'est lui qui crée la composition, donc l'addiction, mais
   il rend le début plus rude et la fin potentiellement très riche.
4. **Le Levier s'additionne-t-il ou se multiplie-t-il ?** Proposé :
   addition (`+0.3`), plus lisible. La multiplication (`×1.3`) donne des
   courbes plus explosives mais devient illisible au-delà de 4-5 sources.
5. **Le Sprint parfait à l'unité près** est-il trop punitif quand la
   capacité varie ? Tolérance à ±1 point ?
6. **Le plafond de Levier par Moral bas** est très violent. Est-ce le bon
   endroit pour rendre le Moral indispensable, ou faut-il un frein
   progressif plutôt qu'un plafond ?
7. **Le mode long mandat** (jouer après T4 pour le score) vaut-il le coût de
   développement dès le lot 2, ou attend-il le lot 4 ?
8. **Combien de combos d'organisation au lancement ?** 8 proposés. En
   dessous de 6 la composition n'est pas un jeu ; au-delà de 12 sans
   Compendium c'est illisible.
9. **Les combos négatifs** (🎭 Théâtre, 👑 Tour d'ivoire) : punir la
   mauvaise composition *dans le score* est-il trop dur, sachant que ces
   compositions coûtent déjà en masse salariale ?
