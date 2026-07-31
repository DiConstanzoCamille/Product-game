# Spécification — Le score du sprint : Traction, Levier, Impact

> Document de travail issu de la demande du 30/07/2026 : *« on survit, mais on
> n'a pas le côté satisfaisant d'un Balatro à combo en gagnant plein de sous ».*
> **v2 (31/07/2026)** — intègre les arbitrages de Camille et deux
> réorientations majeures : le **découpage des décisions en trois familles**
> (§7) et **l'Impact comme monnaie** (§10). Ajoute le modèle d'échelle
> multi-squad et la progression de carrière (§13).
>
> Rien de ce qui suit n'est implémenté. Le [carnet de règles](carnet-de-regles.md)
> décrit l'état actuel ; la [spec de profondeur](spec-profondeur-gameplay.md)
> décrit les phases A→D, dont ce document **remplace la phase D**.
>
> En une phrase : le sprint cesse d'être une soustraction de ressources pour
> devenir **une main qu'on résout**, et le mandat cesse d'être « tenir 12
> tours » pour devenir « battre le trimestre suivant, encore une fois ».

**Sommaire**
1. Le problème
2. Les arbitrages validés
3. Le principe — Traction × Levier = Impact
4. L'ordre de résolution : la « main » du sprint
5. Les sources de Traction — ce que j'ai produit
6. Les sources de Levier — l'organisation que je suis
7. Les décisions — trois familles qui ne se ressemblent pas
8. Les freins — pourquoi le moteur ne s'emballe pas
9. La conversion — l'Impact devient de l'argent qui compose
10. L'Impact est la monnaie
11. Le quota trimestriel — le vrai boss
12. La croissance — le Comité d'investissement
13. L'échelle — de la squad au groupe
14. L'animation de résolution
15. Ce que ça change dans l'existant
16. Données
17. Phasage
18. Points à trancher

---

## 1. Le problème

Le jeu actuel est une **simulation de survie** : six jauges qui descendent,
des décisions qui coûtent, un revenu linéaire d'une dizaine de points, et
douze sprints à tenir. Cinq symptômes :

| Symptôme | Cause structurelle |
|---|---|
| Aucun moment de jubilation | Rien ne se **multiplie**. Tout est additif et borné 0-100. |
| Les bonnes décisions ne récompensent pas visiblement | Le revenu ne dépend que de deux jauges, pas de ce que j'ai fait ce sprint. |
| Pas d'envie d'aller plus loin | La fin est une date, pas un mur à franchir. Le meilleur run et le pire durent 12 sprints. |
| Pas de gestion d'équipe | Le cap d'effectif est fixé par l'entreprise, immuable. |
| On ne construit rien | Aucun objet du jeu ne devient plus fort avec le temps. |

La réponse tient en une phrase : **il faut un score de sprint, produit d'une
base et d'un multiplicateur, dont les deux facteurs se construisent sur la
durée, et un mur qui monte plus vite que le score.**

---

## 2. Les arbitrages validés

Tranchés le 31/07/2026, ils ne sont plus des questions ouvertes :

| Sujet | Décision |
|---|---|
| **Échec de quota** | **Tue le run** — fin `🪑 Remercié·e`, avec un rattrapage achetable (§11.3) |
| **MRR cumulatif** | **Assumé.** La composition est le cœur du plaisir. La difficulté se rattrape **après T4**, pas en bridant le moteur |
| **Longueur du trimestre** | **3 sprints.** Moins réaliste (un vrai trimestre en fait 6) mais 12 sprints = 1 an et 4 boss par mandat : c'est le rythme qui gagne |
| **Plafond de Levier par Moral bas** | **Validé.** Les jauges humaines doivent peser sur le score, pas seulement sur la survie |

---

## 3. Le principe — Traction × Levier = Impact

Trois grandeurs nouvelles, propres au sprint (elles ne sont **pas** des
jauges 0-100 — c'est le point) :

| Grandeur | Symbole | Ce que c'est | Vient de |
|---|---|---|---|
| **Traction** | 📊 | La valeur brute produite ce sprint | Les features livrées |
| **Levier** | ⚙️ | Ce que l'organisation fait de cette valeur | Équipe, Outils, Stratégie, Produit |
| **Impact** | 💥 | `Traction × Levier` | Le résultat du sprint |

> **La phrase de design :** *ce que j'ai produit* × *l'organisation que j'ai
> construite*. Les deux facteurs sont indépendants et se construisent
> séparément — c'est la tension « faire » vs « organiser » du métier, et
> c'est aussi ce qui rend le score explosif : ×2 sur chaque facteur, ×4 sur
> le résultat.

Une équipe parfaite qui ne livre rien fait **0**. Une livraison massive dans
une organisation nulle fait un score plat.

L'Impact ne remplace pas les six jauges : il les **alimente** (§9), et il
**paie les achats** (§10). Les jauges restent le baromètre de santé et les
conditions de mort ; l'Impact est le débit.

---

## 4. L'ordre de résolution : la « main » du sprint

L'ordre est figé et c'est lui qui fait le spectacle — chaque étape est un
temps de l'animation (§14). Le joueur apprend l'ordre en trois sprints et
commence alors à *jouer avec*.

```
①  LIVRAISON        chaque feature livrée révèle sa Traction            → 📊
②  BONUS DE MAIN    combos sur la livraison (focus, sprint parfait,     → 📊
                    epic bouclée, série)
③  L'ÉQUIPE         chaque membre déclenche, puis les combos            → 📊 et ⚙️
                    d'organisation nommés
                    ↑ ①②③ se répètent par squad quand il y en a
                       plusieurs (§13) — le sous-total de chaque squad
                       tombe avant le passage au global
④  LES OUTILS       chaque outil interne déclenche, par employé         → ⚙️
                    éligible, avec son ×2 d'adoption
⑤  LA STRATÉGIE     décisions stratégiques et stack                     → ⚙️ / 📊
⑥  LES PRATIQUES    et le palier de produit                             → ⚙️
⑦  LES FREINS       Cynisme, Dette, surchauffe, Moral au plancher       → ✂️
⑧  IMPACT           Traction × Levier, affiché en grand
⑨  CONVERSION       Impact → MRR, 💶 Budget, 📈 Valeur perçue
                    (modulée par les équipes subies — §9.4)
⑩  LE QUOTA         la barre du trimestre se remplit
```

Deux règles de lisibilité, non négociables :

- **Un effet, une ligne, une place fixe.** Le joueur doit pouvoir pointer du
  doigt d'où vient un chiffre.
- **Les freins sont les derniers.** Voir son 340 se faire raboter à 190 par
  du Cynisme accumulé doit faire mal *après* avoir vu le 340. C'est ce qui
  transforme « le Cynisme, c'est mal » en « je dois traiter mon Cynisme ».

---

## 5. Les sources de Traction — ce que j'ai produit

### 5.1 Les features (l'essentiel)

**Prérequis : la roadmap profonde** (spec de profondeur §6). `data/backlog.json`
existe déjà avec `costPoints`, `roi`, `clientImpact`, `risk`, `quickWin`, mais
l'écran Roadmap consomme encore les 4 features de démo. C'est le lot 0 (§17).

```
Traction d'une feature = costPoints × tractionPerPoint (4)
                       + clientImpact × tractionPerClientImpact (3)
```

| Feature | Points | Impact client | Traction |
|---|---|---|---|
| 📤 Export Excel (quick win) | 1 | +2 | **10** |
| 🔐 SSO grands comptes | 3 | +3 | **21** |
| 🏗️ Refonte du portail | 5 | +5 | **35** |
| 🤖 Chatbot « intelligent » | 3 | −2 | **6** |
| 📊 Dashboard COMEX | 3 | 0 | **12** |

Les features à impact client négatif rapportent un peu (on a livré quelque
chose) mais sont un piège de Traction — et font baisser la Valeur perçue.
**Sans Discovery/UX research, on ne sait pas.** C'est là que les Pratiques
cessent d'être décoratives : elles révèlent la colonne qui décide du score.

### 5.2 Les epics

Une epic ne rapporte **rien** tant qu'elle n'est pas complète, puis
`total des points × 6` d'un coup. Une epic de 10 points = **60 de Traction**
dans un seul sprint. C'est le gros coup qu'on prépare pendant quatre sprints
et qu'on fait tomber pile au sprint qui conclut le trimestre. Le jeu de
timing démarre ici.

### 5.3 Les bonus de main (étape ②)

| Combo | Condition | Effet |
|---|---|---|
| 🎯 **Sprint parfait** | Points consommés = capacité (± 1) | Traction ×1.25 |
| 🔎 **Focus** | Toutes les features livrées partagent un `tag` | Traction ×1.3 |
| 🧩 **Livraison groupée** | ≥ 3 features livrées | +10 Traction |
| ⚡ **Quick wins en série** | ≥ 2 quick wins livrés | +2 💶 |
| 📦 **Epic bouclée** | Une epic se termine ce sprint | Traction ×1.5 |
| 🕳️ **Sprint vide** | Aucune feature livrée | Traction 0, la série casse |

La **série** (`streak`) : sprints consécutifs avec au moins une feature
livrée sans surchauffe. `+0.05 de Levier par sprint`, plafonné à +0.5, remis
à zéro par un sprint vide ou une surchauffe. Le compteur qui rend le choix
de souffler réellement coûteux.

---

## 6. Les sources de Levier — l'organisation que je suis

Le Levier démarre à **×1.0** et s'additionne (les sources donnent `+0.x`) —
c'est le produit final Traction × Levier qui fait l'explosion.

### 6.1 Les combos d'organisation (étape ③)

Des synergies **nommées**, affichées en bandeau pendant l'animation. Ce sont
elles qui donnent envie de recomposer l'équipe plutôt que de l'empiler.

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

**Sang neuf** et **Vieille garde** sont volontairement contradictoires : le
joueur doit choisir une identité d'organisation — la boîte qui se renouvelle
ou celle qui capitalise — et ce choix devient lisible dans le score.

Les combos négatifs rendent la composition *lisible*. « 6 PM = specs sans
code » (retour de playtest d'origine) devient un bandeau rouge **🎭 Théâtre
−0.5** en pleine résolution, impossible à rater.

### 6.2 Les membres eux-mêmes

Chaque employé déclenche à son tour, comme un joker :

- **Rôle** — le Designer donne `+2 Traction par feature livrée`, le PM
  `+0.05 Levier par PM` (plafonné), l'Ops soigne la Dette (donc le frein).
- **Traits cachés** — 💎 Pépite `+0.15 Levier`, 🤝 Mentor `+0.1`, 🏝️ Fantôme
  `contribution ÷ 2`, 😤 Râleur `−0.1`.
- **Traits visibles** — jamais branchés à ce jour (spec profondeur §4.6), ils
  deviennent enfin mécaniques : *« Maintient seule un module que personne
  n'ose ouvrir »* → `+0.2 Levier si aucune feature à risque ≥ 4 n'est livrée,
  −0.3 sinon`.

C'est ici que se joue « mes bonus passifs liés à des membres de l'équipe » —
et c'est aussi ce sur quoi les **Outils internes** viennent se brancher (§7.1).

---

## 7. Les décisions — trois familles qui ne se ressemblent pas

*Réorientation majeure de la v2.* Les « grandes décisions » actuelles
(RICE, Notion, Jira) font toutes la même chose : un coût ponctuel sur les
jauges. C'est faux thématiquement et plat mécaniquement. Elles se scindent
en **trois familles qui n'agissent pas sur le même objet, ne s'achètent pas
au même endroit et ne se déclenchent pas au même moment.**

### 7.0 Ce qui existe déjà — ne pas le refaire

Le **Lot 2 de la refonte UI** (carnet §20-21, mergé le 30/07/2026) a livré la
moitié de l'infrastructure que cette section supposait absente. À prendre
comme acquis :

- L'écran `investments_screen` **existe** : Grandes décisions et Marché sont
  déjà fusionnés, le sprint fait déjà 4 phases.
- Les grandes décisions sont déjà **tirées** au lieu d'être un menu permanent
  (raretés `commune`/`notable`/`rare` pondérées, `eraWeights`, garde-fous
  `guaranteedPerSprint`), déjà **payantes en 🪙** (`costPieces`), et déjà
  soumises à un **slot de mandat** (`structuralDecisionMaxActivations: 4`).
- Un **reroll** à prix croissant, une **réserve** (punaise) et un **bail**
  (`lockedLeaseSprints`) existent déjà.
- Les cartes portent déjà un champ **`family`** (`outil-process`,
  `methodologie-orga`).

**Conséquence sur cette spec :** le tirage par sprint est *meilleur* que le
Comité pour les outils, parce qu'il produit du **regret** — *« ça me coûte un
slot sur quatre, mais est-ce que je la reverrai ? »*. On ne le déplace pas.
Ce qui suit ne change donc que trois choses : **ce que les cartes font**
(§7.1), **combien de slots on a et comment on en libère un** (§7.1.1), et
**une quatrième famille qui, elle, n'existe pas** (§7.2).

### 7.0.b Où vit chaque famille

| Famille | `family` existant | Agit sur | S'obtient | Limite |
|---|---|---|---|---|
| 🛠️ **Outils internes** | `outil-process` + `methodologie-orga` | ⚙️ Levier, **par employé** | Tirage du sprint (existant) | **Les slots** (§7.1.1) et le prix — jamais un compteur d'achats |
| 🧱 **Stack technique** | `stack-technique` *(à créer)* | Le tirage et le risque des features | Tirage du sprint | 1 active à la fois |
| 🧭 **Décisions stratégiques** | **nouvelle** | 📊 Traction, conversion, marché | **Comité de fin de trimestre** | **1 par trimestre**, irréversible |

Les deux premières relèvent du quotidien et gardent leur place dans l'étal.
La troisième est d'une autre nature — on ne décide pas de passer en open
source entre deux tickets — et justifie à elle seule le Comité (§12).

### 7.1 🛠️ Les outils internes — un bonus qui vit dans l'équipe

**Principe :** un outil interne ne donne pas un bonus fixe. Il donne un
bonus **par employé éligible**, avec un **multiplicateur d'adoption ×2** si
un critère d'équipe est rempli, et un **malus par réfractaire**.

```
Levier de l'outil = (perEmployé × nb éligibles − malus × nb réfractaires)
                    × multiplicateur d'adoption
```

C'est la formalisation de l'intuition d'origine (carnet §6.2, le tableau
RICE/Notion/Jira Junior vs Senior) — sauf qu'au lieu d'être une constante
figée au choix de l'entreprise, elle **suit le roster en temps réel et
grandit quand on recrute.**

| Outil | Éligibles (`+0.08` chacun) | Réfractaires (`−0.05`) | ×2 d'adoption si |
|---|---|---|---|
| 📓 **Notion** | Juniors, et recrues de < 4 sprints | Seniors présents depuis > 8 sprints | Aucun senior ancien dans l'équipe |
| 🗂️ **Jira** | Tous (+0.05) | — *(malus fixe −0.15 si effectif ≤ 4)* | Effectif ≥ 8 |
| 🧮 **RICE** | PM et Designers | — | ≥ 3 features **refusées** ce sprint |
| 🔁 **Sprint planning** | Devs et PM (+0.06) | — | Le sprint précédent était un Sprint parfait |
| 🪞 **Sprint rétro** | *cumulatif : +0.05 par sprint depuis l'activation* | — | Cynisme ≤ 30 |
| 🤝 **Pair programming** | Devs juniors | Devs seniors « solitaires » | ≥ 2 Devs juniors et ≥ 2 Devs seniors |
| 📐 **Design system** | Designers et Devs front | — | ≥ 2 Designers |

**Ce que ça produit comme jeu :**

- **Notion sur Karavel** (scale-up junior) est une bombe et grandit à chaque
  recrutement. **Notion sur Meridia** (senior, méfiante) est un levier
  **négatif** — exactement ce que dit la fiction depuis le début, désormais
  vrai mécaniquement.
- **Jira est mauvais à 4 personnes et indispensable à 8.** Un outil dont la
  valeur dépend de la *taille* est la meilleure preuve que le modèle tient
  à l'échelle (§13).
- **Sprint rétro** est le levier qui grandit tout seul — pris au sprint 2 il
  vaut +0.5 en fin de mandat, pris au sprint 9 il ne vaut rien. Une carte
  dont la valeur dépend du *moment* où on la joue transforme un menu en
  décision. Et son ×2 est gaté par le Cynisme : une rétro dans une orga
  cynique, c'est du théâtre.

### 7.1.1 Les slots d'outillage — la vraie limite

Le slot de mandat existe déjà (`structuralDecisionMaxActivations: 4`) — il
s'agit de le **généraliser**, pas de l'inventer. Ce qui borne l'outillage,
ce sont deux choses qui bornent différemment :

- **Le prix**, qui gate le **début** de partie : les `costPieces` actuels
  (2 pour un rituel, 6 pour Jira) contre ~5 💶 gagnés par sprint. On achète
  1 outil tous les deux sprints, et chaque achat fait mal.
- **Les slots**, qui gatent la **fin** de partie : l'organisation ne peut
  porter que `N` outils actifs simultanément.

**Le nombre de slots de base vient du kit de départ, donc du niveau de
carrière** (§13.4) : **3 au niveau PM**, jusqu'à **7 au niveau CEO**. Plus on
gère de monde, plus l'organisation peut absorber d'outillage — et un des
slots de départ est déjà occupé par l'**outillage hérité** (§7.1.3). Un run
de PM commence donc à **2 slots réellement libres**.

En cours de run, on peut en ouvrir **2 de plus au maximum**, au Comité, à
prix croissant (12 puis 20 💶). Le gros de la capacité d'outillage se gagne
en carrière, pas en budget. *(Le `structuralDecisionMaxActivations: 4` fixe
d'aujourd'hui devient donc `3 + achats` au niveau PM.)*

> **Le basculement est le cœur du late game.** Au T1 on manque d'argent ; au
> T4 on a 90 💶 par trimestre et **on manque de place**. La question passe de
> « qu'est-ce que je peux me payer ? » à « lequel de mes cinq outils mérite
> encore son slot ? ». C'est exactement la courbe des slots de jokers d'un
> Balatro, et c'est ce qui empêche la fin de partie de devenir un achat
> automatique de tout le catalogue.

### 7.1.1.b Les outils qui rendent leur place — `slotBonus`

Certains outils portent un **`slotBonus: +1`** : ils ouvrent un slot en
s'installant, donc leur coût net en place est **zéro**.

C'est la soupape du système, et elle sert d'abord aux **outils cumulatifs**.
🪞 **Sprint rétro** porte ce bonus : sans lui, l'outil qu'on ne peut jamais
retirer (§7.1.2) gèlerait un tiers d'un build de PM pour tout le run — la
carte la plus intéressante du jeu deviendrait la plus étouffante.

Avec le `slotBonus`, la décision se déplace au bon endroit : **installer un
outil cumulatif tôt n'est plus un sacrifice de place, c'est une course
contre la montre.** Pris au T1 il vaut +0.5 en fin de mandat, pris au T4 il
ne vaut rien. La question n'est plus « est-ce que je lui donne un slot ? »
mais « l'ai-je eu assez tôt ? ».

Deux ou trois outils du catalogue portent ce bonus — jamais les plus
puissants en Levier direct : un outil qui donne de la place *et* du gros
Levier n'aurait aucun coût d'opportunité.

### 7.1.2 Remplacer un outil — le coût de bascule

Aujourd'hui un slot dépensé l'est **définitivement** : les 4 activations d'un
mandat sont irrévocables. Un slot occupé devient libérable, au Comité. C'est
enfin le **coût de bascule** que le carnet promet depuis le §7 sans jamais
l'avoir implémenté :

- **🎭 Cynisme +4**, et **+3 de plus par bascule déjà faite dans le mandat**.
  Une fois, c'est un arbitrage ; trois fois, c'est *« on change d'outil tous
  les six mois »*, et l'organisation le fait payer.
- Le Levier de l'outil retiré **disparaît immédiatement**.
- **Les compteurs cumulatifs sont remis à zéro.** 🪞 Sprint rétro accumulé
  sur 8 sprints repart de 0 s'il est retiré, même si on le rachète au
  trimestre suivant.
- L'outil retiré **retourne dans le pool** et pourra être reproposé — le
  piège du « je le reprendrai plus tard » est donc réel et visible.

Cette dernière règle donne aux outils cumulatifs un statut à part : ils sont
les plus forts **et** les plus difficiles à déloger. Elle ne les rend pas
étouffants pour autant, puisqu'ils rendent leur place (§7.1.1.b) — la
punition porte sur le **compteur**, jamais sur l'espace de build.

Retirer un outil à `slotBonus` retire aussi le slot qu'il donnait : si les
slots restants sont tous occupés, la bascule est simplement impossible tant
qu'on n'a pas libéré autre chose. Pas de cas limite à gérer.

### 7.1.3 L'outillage hérité

*« Une organisation que vous n'avez pas construite »* est la phrase
d'ouverture du carnet de règles. Les slots sont l'endroit où elle devient
mécanique : **chaque entreprise démarre avec 1 ou 2 outils déjà installés**,
choisis par quelqu'un d'autre, qui occupent des slots.

- **Meridia** hérite de 🗂️ **Jira** — installé par le cabinet de conseil,
  et l'équipe fait 5 personnes : le malus « effectif ≤ 4 » est passé de peu,
  le ×2 d'adoption est hors d'atteinte. L'outil est tiède et prend un slot.
  Le libérer coûte du Cynisme dans une boîte qui en a déjà.
- **Karavel** hérite de 📓 **Notion** — parfaitement adapté à son équipe
  junior. Un cadeau, pour une fois.

Le premier vrai arbitrage du run devient donc : *est-ce que je garde ce dont
j'hérite ?* C'est une bien meilleure première décision que « quelle carte
j'achète », et ça ne coûte que deux lignes de données.

**Et c'est volontairement exigeant.** Répondre à cette question demande
d'avoir compris trois mécaniques à la fois — les conditions d'éligibilité de
l'outil, le coût de bascule, et la rareté des slots. Un joueur qui garde
Jira chez Meridia par défaut, sans regarder, se prive d'un slot sur deux
pendant tout son run. **Il faut comprendre pour gagner** : c'est la
philosophie assumée du jeu, pas un accident de conception.

Les outils internes restent **l'engrenage incrémental du run** : c'est en les
combinant avec un roster choisi qu'on fait les gros multiplicateurs.

### 7.2 🧭 Les décisions stratégiques — rares, irréversibles, structurantes

Elles ne touchent pas l'équipe : elles redéfinissent **ce que le produit est
pour le marché**. Une par trimestre maximum, choisie parmi 2 ou 3 proposées
au Comité d'investissement (§12) — jamais au Marché du sprint.

| Décision | Effet |
|---|---|
| 🔓 **Passer en open source** | Traction ×1.4 · conversion Impact→MRR ÷ 2 · candidats −30 % au Marché (la réputation attire) |
| 💳 **Freemium** | Conversion Impact→MRR +30 % · churn de base ×1.5 |
| 🏢 **Enterprise first** | Features à `roi ≥ 2` : Traction ×2 · les quick wins ne rapportent plus rien |
| 🔌 **Plateforme / API publique** | +0.15 Levier **par palier de produit** (scale avec la croissance) |
| 🌍 **Expansion internationale** | MRR ×1.35 · quota du trimestre +20 % |
| 🤫 **Arrêter de communiquer** | −1 niveau Product marketing · +0.4 Levier (l'équipe ne fait plus de démos) |
| 🧯 **Année de consolidation** | Traction ×0.7 pendant un trimestre · Dette −30 · Cynisme −15 |

Ce sont les cartes qui font qu'un run se raconte : *« j'ai fait un run open
source avec une vieille garde et un design system »*. Elles sont
**irréversibles** — c'est ce qui les rend mémorables.

Le plafond arbitraire actuel (`structuralDecisionMaxActivations: 4`)
disparaît : **4 trimestres = 4 décisions stratégiques maximum**, la limite
devient structurelle au lieu d'être un nombre dans un fichier.

### 7.3 🧱 La stack technique

Inchangée dans l'intention (carnet §7.4) : elle n'agit ni sur les jauges ni
sur le Levier, mais sur **le Marché** (quels profils apparaissent, à quel
prix) et sur **le risque des features** (`risk` réduit ou majoré).
Achetée au Comité, surtout en début de mandat — une stack prise au T4 ne
sert à rien, et c'est très bien.

### 7.4 Outils et Pratiques ne sont pas la même chose

Les deux donnent du Levier — il faut que la frontière soit nette, sinon le
joueur ne saura pas dans quel rayon regarder :

| | 🛠️ **Outils** | 🧠 **Pratiques** |
|---|---|---|
| Ce que c'est | Une **licence** | Un **savoir-faire** |
| S'achète | Comité, fin de trimestre | Marché, chaque sprint |
| Occupe un slot | **Oui** | Non |
| Se remplace | **Oui**, avec un coût de bascule | Non — on ne désapprend pas |
| Effet | Levier **par employé éligible** | Révélation d'information + petit levier conditionnel |
| Coût culturel | Cynisme à la bascule | +2 Cynisme à l'achat |

*Une pratique change ce que l'organisation sait ; un outil change comment
elle travaille.* On ne désinstalle pas « parler à ses clients ».

### 7.5 Conséquence sur les phases du sprint

**Rien à faire — c'est déjà fait.** Le Lot 2 UI a supprimé l'écran Grandes
décisions et ramené le sprint à 4 phases (Inbox → Roadmap → Investissements
→ Résolution). Le Comité de fin de trimestre (§12) **s'ajoute** à ce
découpage sans le modifier : il tombe tous les 3 sprints, entre une
Résolution et l'Inbox suivante.

Ce qu'on gagne : un rythme **court/long** au lieu d'un rythme plat. Trois
sprints rapides où l'on joue son étal, puis un temps d'arrêt où l'on regarde
sa machine. C'est là que se prennent les décisions stratégiques, les
bascules d'outils et les investissements de croissance.

---

## 8. Les freins — pourquoi le moteur ne s'emballe pas

Appliqués en dernier (étape ⑦), en **multiplicatif**, en rouge. Plus le
moteur est gros, plus les freins font mal en valeur absolue.

| Frein | Formule | À l'extrême |
|---|---|---|
| 🎭 **Cynisme** | Levier × `(1 − (cynisme − 40) / 120)` au-delà de 40 | Cynisme 100 → **×0.5** |
| 🧱 **Dette** | Traction × `(1 − (dette − 40) / 150)` au-delà de 40 | Dette 100 → **×0.6** |
| 🔥 **Surchauffe** | Impact × 0.6 si la capacité a été dépassée | (en plus des pénalités jauges) |
| 💔 **Moral au plancher** | Levier **plafonné à ×1.5** si Moral < 30 | Le moteur est débranché |

Le plafond de Levier par Moral bas est le frein le plus violent et le plus
juste : **une organisation qui va mal ne combote pas.** Tout le build
patiemment construit devient inopérant tant que l'équipe n'est pas réparée —
ce qui donne enfin une raison mécanique de dépenser pour le Moral.

### 8.1 Le 🎯 Capital politique — hypothèses de travail

*Non tranché. Consigné pour ne pas reperdre le raisonnement en playtest.*

Le Capital politique **n'est pas une monnaie** (la piste du lobbying a été
écartée, §9.4) et **ne doit pas devenir un levier de score majeur**. Trois
hypothèses de rôle, à valider en jouant :

1. **C'est un indicateur avant tout.** Il se lit, il ne se dépense pas. Les
   deltas qui l'affectent restent **anecdotiques** — quelques points par
   sprint, jamais des paquets de 20.
2. **Il module légèrement, il ne décide pas.** Au mieux un petit
   multiplicateur au bord du calcul (un frein doux sous un seuil, un bonus
   marginal au-dessus), jamais un facteur de l'ordre du Cynisme ou du Moral.
3. **Il garde son couperet.** Capital politique à 0 → fin `Rachat hostile`.
   C'est sa vraie fonction : une jauge qu'on regarde du coin de l'œil et qui
   tue si on l'ignore trop longtemps.

**D'où il bouge :** des choix de sprint, pas des achats. Le cas typique, et
il branche trois systèmes d'un coup :

> 💼 Le Sales (§9.4) a vendu une feature qui n'existe pas. Elle arrive dans
> votre backlog sans que vous l'ayez choisie.
> — **La faire** : elle consomme des points de capacité pour une Traction
> médiocre (elle n'a pas été priorisée pour ses mérites).
> — **Ne pas la faire** : 🎯 Capital politique en baisse, et un coût
> financier (le deal tombe). Vous gardez votre capacité pour mieux.

C'est le bon gabarit : un arbitrage lisible, un coût des deux côtés, et le
Capital politique qui **enregistre** la décision plutôt que de la payer.

---

## 9. La conversion — l'Impact devient de l'argent qui compose

Le business model n'est plus une formule d'affichage : c'est **la règle de
conversion de l'Impact**.

### 9.1 SaaS — MRR cumulatif (Transformation agile)

```
MRR ← MRR × (1 − churn) + Impact × impactToMrr (0.06) × niveauSales
Revenu du sprint = MRR
churn = churnBase (4 %) × niveauCSM, jusqu'à 15 % si Moral bas et Dette haute
```

**Le MRR devient un stock, pas un flux recalculé.** Un sprint à 300 d'Impact
ajoute +18 de MRR **pour tous les sprints suivants**. C'est la composition
qui manque aujourd'hui : investir tôt paie longtemps, et négliger fait
fondre l'acquis sans qu'on ait besoin d'un couperet. C'est aussi ce qui rend
le début dur et la fin grisante — la courbe d'un Balatro.

### 9.2 Vente à la version — waterfall (Garage, à venir)

L'Impact s'accumule dans une **version en préparation**. Sortir la version
encaisse `Impact accumulé × releaseRate` d'un coup, et remet le compteur à
zéro. Gros paliers, gros risques, rien entre deux. Même moteur de score,
deux économies radicalement différentes.

### 9.3 Les autres sorties

- 💶 **Budget** : voir §10 — c'est la monnaie du jeu
- 📈 **Valeur perçue** : `+floor(Impact / 30) × niveauPMM`, plafonné à
  +6/sprint (la jauge reste une jauge)
- 🎯 **Capital politique** : `+1` par tranche de 150 d'Impact

### 9.4 Les équipes subies — Sales, Product marketing, CSM

*Réponse à « on n'a pas de rôles product marketing, sale, csm ».*

Ces équipes existent dans la boîte, **elles ne sont pas dans votre roster**,
vous ne les composez pas. Elles ont chacune un **niveau 0-5** fixé par
l'entreprise au début du run, et **chacune possède exactement un taux de
conversion** :

| Équipe subie | Possède | Niveau 0 | Niveau 3 | Niveau 5 |
|---|---|---|---|---|
| 💼 **Sales** | `Impact → MRR` | ×0.5 | ×1.0 | ×1.4 |
| 📣 **Product marketing** | `Impact → Valeur perçue` | ×0.5 | ×1.0 | ×1.4 |
| 🎧 **CSM / Support** | le **churn** | ×1.6 | ×1.0 | ×0.6 |

C'est un découpage propre : chaque équipe subie détient une des trois
sorties de la conversion, et chacune produit un échec que tout le monde
reconnaît — *« on a livré un truc génial et personne ne l'a vendu »*,
*« on livre en silence »*, *« ça rentre par la porte et ça sort par la
fenêtre »*.

**Elles différencient les entreprises bien plus que le profil d'équipe :**

- **Meridia** (grand groupe) : Sales 4, PMM 2, CSM 3 — la force de vente
  existe, personne ne sait raconter le produit.
- **Karavel** (scale-up) : Sales 2, PMM 4, CSM 1 — on communique très bien,
  on ne retient personne.

**Elles ne sont pas pilotables. Du tout.**

Pas d'achat, pas de lobbying, pas de niveau à monter au Comité. On ne les
dirige pas, on **fait avec** — exactement comme dans une vraie boîte, où le
Sales et le Support ne sont pas dans votre périmètre et où votre travail
consiste à composer avec ce qu'ils sont.

Concrètement, elles agissent de deux façons :

**① Leur taux, en permanence.** Le niveau fixé au début du run s'applique à
chaque Résolution, dans la ligne de conversion (étape ⑨). C'est un
paramètre du contexte, au même titre que le profil d'équipe.

**② Leurs événements, dans l'Inbox.** Chaque équipe subie alimente le pool
d'événements avec des situations qui lui sont propres, dont la fréquence et
la tonalité **dépendent de son niveau** :

| Équipe | Niveau bas → | Niveau haut → |
|---|---|---|
| 💼 Sales | *« Un deal à 200 k€ est bloqué sur une feature qui n'existe pas. Le commercial l'a promise. »* | *« Le Sales a vendu trois fois ce que la roadmap prévoyait. Il faut suivre. »* |
| 📣 PMM | *« Personne dans la boîte ne sait décrire ce que fait le produit. »* | *« La campagne sort dans 2 sprints — la feature n'est pas prête. »* |
| 🎧 CSM | *« Le support crie au secours : 40 tickets sur le même bug. »* | *« Le support a remonté un pattern client que la Discovery avait raté. »* |

Un niveau bas génère des crises, un niveau haut génère de la pression — les
deux coûtent, mais pas la même chose. **Une équipe subie forte n'est pas un
cadeau, c'est une contrainte différente.**

Certaines décisions stratégiques les font bouger comme effet de bord (Open
source → PMM +1, Sales −1) : on ne les pilote toujours pas, on change le
monde autour d'elles.

Conséquence à assumer : le 🎯 **Capital politique** ne gagne pas de nouveau
débouché ici. Il garde ceux qu'il a — la revue de board et l'action
🏛️ Négocier une rallonge (spec profondeur §7.2). À surveiller en playtest :
si la jauge reste une jauge qu'on ne fait que perdre, le problème se réglera
ailleurs, pas en rendant pilotable ce qui ne doit pas l'être.

À grande échelle (§13), les équipes subies deviennent la principale **source
de variance** entre deux runs de Director ou de CPO : plus on monte, plus la
part du résultat qui dépend de ce qu'on ne contrôle pas est grande.

---

## 10. L'Impact est la monnaie

*Réponse à « la money pour acheter pourrait être de l'impact ? ».* **Oui, et
c'est un gain net.** Les Pièces actuelles sont une allocation abstraite du
board, sans lien avec ce qu'on fait — exactement le reproche.

**Les Pièces 🪙 deviennent le Budget 💶, dérivé de l'Impact du sprint :**

```
Budget gagné = floor(√Impact) + allocation plancher du board (2, ou 1 si revue ratée)
```

| Impact du sprint | 40 | 100 | 250 | 560 | 1 000 | 2 000 |
|---|---|---|---|---|---|---|
| 💶 **Budget** | 6 | 10 | 15 | 23 | 31 | 44 |

**Pourquoi la racine et pas une proportion :** un gros Impact doit donner
plus de moyens, mais pas *proportionnellement* plus — sinon en fin de partie
tout est achetable et le Shop cesse d'être un choix. La racine compresse :
**×25 d'Impact donne ×5 de pouvoir d'achat.** Formulé dans le jeu : *les
rendements décroissants de l'investissement*. L'allocation plancher garantit
qu'on n'est jamais totalement paralysé.

Ce que ça change immédiatement :

- **Le Marché du sprint et le Comité partagent une monnaie qui se mérite.**
  Bien jouer un sprint paie *tout de suite* en pouvoir d'achat. La boucle se
  referme sur elle-même — c'est le cœur de l'addiction.
- **Le quota compte l'Impact brut**, avant conversion. Dépenser son Budget
  n'ampute pas le trimestre : sinon la spirale de mort devient inévitable.
- **Un pari optionnel existe quand même** : 🎲 **Avance sur trimestre** au
  Comité — `+10 💶 immédiats contre −80 d'Impact sur le quota en cours`
  (valeurs par trimestre dans les données). Le joueur *peut* hypothéquer son
  trimestre, ce n'est jamais le système qui le lui impose.
- La Trésorerie 💰 ne change pas de rôle : elle paie les **salaires** et
  reste la jauge de survie. Deux économies, désormais toutes deux lisibles :
  **la Trésorerie survit, le Budget investit.**

---

## 11. Le quota trimestriel — le vrai boss

### 11.1 Structure

Trimestre = **3 sprints** (`trimesterLengthSprints: 3`). À la fin de chaque
trimestre, le board attend un **quota d'Impact cumulé**, annoncé au premier
sprint du trimestre et affiché en permanence dans le Panneau de bord.

| Trimestre | Sprints | Quota (niveau PM, 1 squad) |
|---|---|---|
| T1 | 1-3 | **120** |
| T2 | 4-6 | **270** |
| T3 | 7-9 | **560** |
| T4 | 10-12 | **1 050** |
| T5+ | *(mode long mandat)* | **×2.2 par trimestre** |

Progression ×~2 par trimestre pendant qu'un moteur bien construit progresse
×2,5-3 : **la marge se gagne, elle ne se subit pas.** Le ×2.2 post-T4 est
l'endroit où la difficulté se durcit franchement, comme validé au §2.

*(Les quotas sont définis par niveau de carrière — voir §13.4.)*

### 11.2 L'exigence du trimestre (le « boss »)

Chaque trimestre tire une **exigence** aléatoire, visible dès son premier
sprint, qui déforme les règles :

| Exigence | Effet |
|---|---|
| 🧊 **Gel des embauches** | Aucun recrutement pendant le trimestre |
| 💼 **Le DAF regarde** | Masse salariale ×2 |
| 🎪 **Le board veut du visible** | Les features à `clientImpact ≤ 0` ne rapportent aucune Traction |
| 🏚️ **Audit technique** | Le frein de Dette compte double |
| 📉 **Trimestre court** | 2 sprints au lieu de 3, quota réduit de 25 % seulement |
| 🗣️ **Injonction du board** | Une décision stratégique vous est **imposée** |
| 🕵️ **Comité de pilotage** | Chaque Pratique achetée coûte +4 Cynisme au lieu de +2 |
| 🔒 **Outillage gelé** | Aucun outil interne achetable ce trimestre |

**En mode long mandat (T5+), les exigences s'accumulent au lieu de se
remplacer.** C'est la spirale de fin de partie.

Les objectifs qualitatifs actuels de `companies.json` (Cynisme ≤ 45…) ne
disparaissent pas : ils deviennent le **bonus de trimestre** — les tenir en
plus du quota rapporte un gros paquet de Budget au Comité.

### 11.3 L'échec

Quota manqué = **fin de mandat immédiate**, nouvelle fin `🪑 Remercié·e` :
*« Le comité vous remercie pour votre contribution. Un cabinet accompagnera
la transition. »*

Un filet existe mais il **s'achète** : le 🏛️ **Plan de redressement**
(Comité, cher) offre un unique rattrapage dans le mandat.

### 11.4 La fin du mandat

Les 12 sprints ne sont plus une fin, ce sont **quatre trimestres franchis**.
À la fin de T4, le joueur choisit :

- **🚀 Sortir par le haut** — IPO/rachat selon les jauges, run gagné, score
  enregistré, **et le niveau de carrière suivant se débloque** (§13.4).
- **♾️ Rester** — le mandat continue, quotas ×2.2, exigences cumulatives. On
  joue pour le score.

---

## 12. La croissance — le Comité d'investissement

Entre deux trimestres, un écran dédié. C'est là qu'on dépense le Budget gagné
en franchissant le quota, et là que se répare le trou « pas de gestion
d'équipe ».

L'écran `investments_screen` reste le rendez-vous de **chaque sprint** :
candidats, pratiques, outils, stack, avec son tirage, ses raretés, son
reroll et sa punaise. Le Comité est un écran **différent**, qui n'apparaît
que tous les 3 sprints, et qui ne propose que ce qui ne se décide pas au fil
de l'eau.

| Investissement | Coût 💶 | Effet |
|---|---|---|
| 🧭 **Décision stratégique** | 15-30 | **1 seule par trimestre**, parmi 2-3 proposées (§7.2) |
| 🔧 **Ouvrir un slot d'outillage** | 12 puis 20 | +1 slot, **2 maximum par run** (la base vient du niveau de carrière) |
| ♻️ **Libérer un slot** | **coût de bascule** (§7.1.2) | Retire un outil actif — son remplaçant se rachètera à l'étal |
| 🪑 **Ouvrir un poste** | 6, puis 10, 16… | +1 au cap d'effectif |
| 📈 **Promotion** | 5 | Un junior devient senior (salaire +1, contribution senior) |
| 🚀 **Palier de produit** | 12 / 25 / 45 | +0.5 Levier permanent, +1 feature proposée par sprint |
| 🏝️ **Séminaire d'équipe** | 8 | −15 Cynisme |
| 🧹 **Sprint de remise à plat** | 6 + **un sprint entier** | −20 Dette, 0 Traction ce sprint |
| 🤝 **Rachat d'un concurrent** | 30 | +12 MRR, +1 employé aléatoire, +8 Dette |
| 🎯 **Chasseur de têtes** | 8 | Prochain étal : 4 candidats, traits révélés |
| 🏛️ **Plan de redressement** | 20 | Un rattrapage de quota dans le mandat |
| 🎲 **Avance sur trimestre** | — | +10 💶 contre −80 d'Impact sur le quota en cours |

*(Pas de reroll ici : il existe déjà à l'étal, par sprint, à prix croissant —
carnet §21. On ne le duplique pas.)*

Le cap d'effectif devient un **objet de jeu**, et le licenciement (déjà
implémenté : clic sur une ligne du roster dans le Panneau de bord) prend un
sens offensif — virer un 🏝️ Fantôme pour libérer un poste et déclencher un
combo est une décision gagnante, pas un aveu d'échec.

### 12.1 Le Compendium des synergies

Un onglet du Dossier entreprise liste **tous** les combos du jeu : ceux déjà
déclenchés une fois sont en clair, les autres en `???` avec seulement leur
icône et leur famille. Collectionner devient un objectif de méta-progression
à coût de développement quasi nul — et ça règle la découvrabilité sans
tutoriel.

---

## 13. L'échelle — de la squad au groupe

*Réponse à « je veux être certain que notre modèle fonctionne avec 1 squad
ou avec 6 ou 10 ».* **Il fonctionne, à une condition d'architecture posée
dès maintenant (§13.5).**

### 13.1 La formule est fractale

```
Impact = ( Σ  Traction_squad × Levier_local_squad ) × Levier_global
        squads
```

- **Levier local** = combos de composition de la squad + ses membres (§6)
- **Levier global** = outils internes, pratiques, stratégie, palier de
  produit, combos inter-squads, freins (§7, §8)

À **N = 1**, la formule est *exactement* celle des §3-8 : un seul terme dans
la somme. **Rien à changer, rien à jouer différemment.**

À **N = 6**, six sous-totaux tombent, puis un multiplicateur global les
frappe tous. Et la même formule se réapplique **un niveau plus haut** :
squads → tribus → domaines. Un CEO qui gère 3 × 8 squads calcule
`Σ Impact_domaine × Levier_groupe`. **Une seule implémentation, quatre
niveaux de jeu.** C'est la preuve que le modèle tient.

### 13.2 Ce qui devient local, ce qui reste global

| Objet | À N=1 | À N>1 |
|---|---|---|
| Backlog et capacité | Un seul | **Un par squad**, pas de transfert de points |
| Combos de composition | Sur le roster | **Par squad** — six Trios produit valent six fois |
| Outils internes | Sur le roster | **Global**, mais compté sur *tous* les employés — c'est là que 🗂️ Jira décolle |
| Pratiques, stratégie, produit | Global | Global, inchangé |
| Freins | Global | Global, inchangé |
| Équipes subies | Global | Global — **et déterminantes** |

Deux combos **inter-squads** n'existent qu'à N ≥ 3 :

- 🏛️ **Standardisation** — ≥ 3 squads partagent le même archétype de
  composition → **+0.4 global**
- 🌀 **Chaos organisé** — toutes les squads ont une composition différente →
  **−0.3 global**, annulé si 🗂️ Jira ou 📐 Design system est actif

### 13.3 L'attention — la vraie ressource du management

À N > 1, **on ne peut piloter que `k` squads par sprint** (k = 1 + bonus
d'outils et de niveau). Une squad pilotée : vous choisissez ses features.
Une squad non pilotée : **elle choisit toute seule**, pondérée par sa
composition — et une squad avec un bon PM choisit bien, une squad sans PM
prend le premier ticket du backlog.

> **C'est là que le jeu change de nature.** À 1 squad, on choisit des
> features. À 6 squads, on choisit **qui choisit les features**. C'est
> littéralement le passage de PM à Lead PM, et ça tombe pile sur un système
> déjà construit : l'⚡ Énergie et les actions personnelles (spec profondeur
> §7) — *« on ne peut pas être partout »* cesse d'être une phrase et devient
> la contrainte centrale.

Le PM local devient l'objet le plus précieux du jeu, et la 🚪 gestion
d'équipe (virer, promouvoir, déplacer quelqu'un d'une squad à l'autre)
devient le vrai gameplay du late game.

### 13.4 La progression de carrière — les « decks »

Le parallèle Balatro est direct et il est déjà à moitié construit :

| Balatro | Product Tycoon |
|---|---|
| **Deck** (passif de départ) | **L'entreprise** — `companies.json`, son roster hérité, ses équipes subies, son défaut |
| **Stake / Ante** (difficulté débloquée) | **Le niveau de carrière** — le nombre de squads sous responsabilité |

| Niveau | Squads | 🔧 Slots de base | Débloqué par | Ce qui apparaît |
|---|---|---|---|---|
| 👤 **PM** | 1 | **3** *(dont 1 hérité)* | départ | Le jeu des §3-12 |
| 👥 **Lead PM** | 2-3 | **4** | Gagner en PM | Attention limitée, PM locaux, backlogs séparés |
| 🏢 **Director** | 5-7 | **5** | Gagner en Lead PM | Combos inter-squads, équipes subies déterminantes, tribus |
| 🎩 **CPO** | 10-12 | **6** | Gagner en Director | Décisions stratégiques majeures, board hostile |
| 👑 **CEO** | 3 × 8 (domaines) | **7** | Gagner en CPO | On gère des Directors, pas des squads — la formule remonte d'un cran |

Le nombre exact de squads au démarrage d'un niveau dépend des **bonus de
début de run et des choix** — deux runs de Lead PM ne commencent pas
forcément à la même taille.

Les quotas (§11.1) sont **définis par niveau**, pas en absolu : chaque niveau
a sa propre table T1→T4, calibrée sur le nombre de squads. Un Director ne
joue pas avec les chiffres d'un PM.

**Le déblocage est strict : il faut gagner un niveau pour ouvrir le
suivant.** Pas de contournement au bout de N runs joués — un Lead PM se
mérite. C'est la condition pour que le titre veuille dire quelque chose.

**Mais les niveaux verrouillés doivent être visibles et expliqués.** Un
joueur qui ne sait pas qu'il existe un après ne joue pas pour y accéder :

- Le menu de démarrage affiche **tous** les niveaux, les verrouillés grisés
  avec leur condition en clair (*« 🔒 Lead PM — gagnez un mandat complet en
  PM (4 trimestres franchis) »*).
- La règle est **identique à celle déjà en place** pour les scénarios non
  jouables (`playableEras` → « Bientôt disponible » grisé sur
  `scenario_screen`) : on réutilise le pattern, pas une nouvelle UI.
- L'écran de fin de mandat annonce le déblocage quand il tombe, et rappelle
  la condition manquante quand ce n'est pas encore le cas.

### 13.5 Le contrat de compatibilité — à honorer dès le lot 1

**C'est la décision d'ingénierie la plus importante de ce document.**

Même si on n'implémente que N=1 avant longtemps, il faut écrire dès le
premier jour :

1. `SprintState.squads: Array` — **un tableau, avec une seule entrée
   aujourd'hui**, chaque entrée portant `{id, nom, roster[], backlog_draw[],
   capacite, livrees[]}`. Le `roster` global devient une vue calculée sur
   l'union des squads.
2. `ScoreResolver` **itère toujours sur les squads** et produit un
   sous-total par squad, même quand il n'y en a qu'une.
3. Le rapport de score distingue explicitement **local** et **global** dans
   chaque ligne.
4. À N=1, **l'UI masque entièrement la couche squad** — le joueur ne doit
   jamais voir le mot « squad » dans son premier run.
5. Les quotas et les coûts vivent dans des tables **indexées par niveau de
   carrière**, avec une seule ligne remplie aujourd'hui.

Coût aujourd'hui : quasi nul. Coût si on ne le fait pas : une réécriture du
moteur de score et de tous les écrans de phase.

### 13.6 Est-ce trop tôt ?

**Non pour le modèle, oui pour le contenu.** Le modèle doit être figé
maintenant, sinon on se construit un cul-de-sac. L'implémentation multi-squad
et les niveaux de carrière restent en lot 5, après que le jeu à 1 squad soit
réellement bon — parce que *« construire le jeu avec 1 team produit »* est la
bonne façon d'apprendre ce qui est fun avant de le multiplier par six.

---

## 14. L'animation de résolution

**C'est le livrable qui porte tout le reste.** Un moteur de score sans
spectacle ne se ressent pas.

Cadre diégétique : l'écran de Résolution devient **la démo de sprint** —
l'équipe présente ce qu'elle a fait, et le tableau se remplit en direct.

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
│   ④ 📓 Notion · 4 éligibles, 0 réfractaire ......... +0.32   │
│      🪞 Sprint rétro (5 sprints) ×2 adoption ....... +0.50   │
│   ⑤ 🔓 Open source ................................. ×1.40   │
│   ⑦ 🎭 Cynisme 62 ................................... ×0.82  │
│                                                              │
│   ═══════════════════════════════════════════════════════    │
│                    💥  IMPACT  441                           │
│   ═══════════════════════════════════════════════════════    │
│   MRR 42 → 68 (💼 Sales 4)  ·  💶 +23  ·  📈 +5  ·  🎯 +2    │
│                                                              │
│   TRIMESTRE 3 ······················ 441 / 560   ▓▓▓▓▓▓▓░░   │
└──────────────────────────────────────────────────────────────┘
```

Règles d'animation :

- **Un pas = un événement.** Chaque ligne apparaît séquentiellement (~0,25 s)
  avec le compteur concerné qui s'incrémente en tween.
- **Le son monte en pitch** à chaque incrément, et se réinitialise à chaque
  étape. 80 % de la satisfaction pour 5 % du travail.
- **Les combos nommés prennent la largeur** : bandeau, léger screenshake,
  couleur pleine. On doit avoir envie de les revoir.
- **Les outils affichent leur décompte** (`4 éligibles, 0 réfractaire`) : le
  joueur comprend en une ligne pourquoi Notion vaut +0.32 chez lui et −0.10
  chez le voisin.
- **Les freins arrivent en dernier, en rouge, et *retirent*** — le compteur
  redescend visiblement.
- **L'Impact final flashe**, taille de police proportionnelle à sa magnitude.
- **Clic = accélérer, second clic = tout révéler.** Indispensable.
- La barre de quota se remplit **en dernier** et change de couleur au
  franchissement. Si le trimestre se joue sur ce sprint, **la barre est le
  climax, pas l'Impact**.
- À N > 1 squads : chaque squad résout son sous-total dans un encart, puis
  les encarts se replient et le global les frappe. La séquence reste unique.

---

## 15. Ce que ça change dans l'existant

| Système actuel | Devient |
|---|---|
| `compute_revenue()` — revenu dérivé de 2 jauges | Conversion de l'Impact en MRR cumulatif (§9.1) |
| 🪙 Pièces — allocation abstraite du board | 💶 **Budget dérivé de l'Impact** (§10) |
| Décroissance Valeur perçue −2/sprint | **Conservée** + churn de MRR : deux pressions distinctes |
| Revue de board au sprint 6, qualitative | Quota chiffré tous les 3 sprints + exigence + objectifs qualitatifs en bonus (§11) |
| Mandat = 12 sprints | 4 trimestres, puis mode long mandat (§11.4) |
| Grandes décisions = coût ponctuel sur les jauges | **Levier par employé éligible** (§7.1) + une **4e famille stratégique** au Comité (§7.2) |
| `structuralDecisionMaxActivations: 4` fixe et définitif | **Slots indexés sur le niveau de carrière** (3 au PM), +2 achetables, et **libérables** (§7.1.1) |
| « Coût de bascule » du carnet §7, jamais implémenté | **Libérer un slot** (§7.1.2), Cynisme croissant par bascule |
| Écran Investissements, tirage, raretés, reroll, punaise, bail | **Conservés tels quels** — le tirage produit du regret, on n'y touche pas (§7.0) |
| Traits visibles décoratifs | Modificateurs de Levier (§6.2) |
| Roadmap sur 4 features de démo | `backlog.json` branché, points/ROI/impact/risque réels |
| Cap d'effectif figé | Achetable au Comité (§12) |
| 🎯 Capital politique | **Inchangé dans sa nature** — indicateur, pas monnaie. Hypothèses de rôle en §8.1 |
| `roster[]` | `squads[]` de longueur 1 (§13.5) |
| Fins par jauge à l'extrême | **Conservées** + nouvelle fin `remercie` sur quota manqué |

Les six jauges, l'Énergie, l'Inbox, les traits cachés, le Marché et le
Dossier entreprise **ne changent pas de nature**. C'est une couche au-dessus,
pas une réécriture.

---

## 16. Données

| Fichier | Statut | Contenu |
|---|---|---|
| `data/scoring.json` | **nouveau** | Combos de main, combos d'organisation locaux et globaux, formules de freins |
| `data/cards.json` | **modifié, pas remplacé** | Les cartes existantes gagnent le modèle par employé (§7.1) : `perEmployee`, `eligibility`, `refractory`, `adoptionCondition`, `slotBonus`, `cumulative`. Elles gardent `family`, `rarity`, `costPieces`, `eraWeights` |
| `data/strategy.json` | **nouveau** | Décisions stratégiques (§7.2) — la seule famille qui n'existe pas encore |
| `data/quotas.json` | **nouveau** | Quotas **par niveau de carrière** × trimestre, courbe du mode long, pool des exigences |
| `data/investments.json` | **nouveau** | Catalogue du Comité (§12) |
| `data/careers.json` | **nouveau** *(lot 5)* | Niveaux de carrière, nombre de squads, **slots de base**, conditions de déblocage et leur libellé affiché |
| `data/backlog.json` | modifié | + `tags[]` (combo Focus), + les epics |
| `data/companies.json` | modifié | + `supportTeams` (niveaux Sales/PMM/CSM), + `inheritedTools[]` (§7.1.3) |
| `data/inbox-events.json` | modifié | + `supportTeam` et `levelRange` : les événements des équipes subies, filtrés par leur niveau (§9.4) |
| `data/balance.json` | modifié | + `scoring`, `impactToMrr`, churn, `budgetFromImpact`, `toolSlots` (base, coûts d'ouverture, plafond, coût de bascule), `trimesterLengthSprints: 3` |
| `data/endings.json` | modifié | + `remercie` |
| `data/practices.json` | modifié | + champ `levier` conditionnel (§5.4) |

`SprintState` gagne : `squads[]`, `traction`, `levier`, `last_score_report`,
`mrr`, `quarter_impact`, `quarter_index`, `quarter_requirement_id`, `streak`,
`product_tier`, `support_teams{}`, `combos_discovered[]`, `career_level`,
`tool_slots`, `active_tools[]` (avec leur compteur cumulatif), `swap_count`.

Un module **`ScoreResolver`** calcule la main et **retourne un rapport
structuré** (liste ordonnée d'étapes `{etape, portee, icone, libelle, type,
valeur}`). L'écran de Résolution ne fait que **rejouer ce rapport** — aucune
logique de score dans l'UI. C'est ce qui rend le système testable en
headless : le smoke test vérifie des scores, pas des pixels.

---

## 17. Phasage

- **Lot 0 — La roadmap profonde** *(prérequis, déjà spécifié en Phase C)* :
  brancher `backlog.json`, coûts en points réels, epics, colonnes cachées
  révélées par les Pratiques. Sans ça il n'y a rien à scorer.
- **Lot 1 — Le score et son animation** : `ScoreResolver` (avec le contrat
  `squads[]` du §13.5), Traction/Levier/Impact, bonus de main, combos
  d'organisation, freins, conversion MRR cumulatif, Budget dérivé de
  l'Impact, et **la séquence animée complète**.
  → *Critère : un sprint bien joué donne envie de refaire le même.*
- **Lot 2 — Le quota trimestriel** : trimestres de 3 sprints, quotas
  escaladés, exigences, fin `remercie`, barre de quota permanente, mode long
  mandat à ×2.2.
  → *Critère : un joueur qui ne construit pas de moteur meurt à T2 ou T3.*
- **Lot 3 — Les familles de décisions** : outils internes à bonus par
  employé (sur les `cards.json` existants, qui portent déjà `family`,
  `rarity` et `costPieces`), **slots indexés carrière et coût de bascule**,
  nouvelle famille stratégique au Comité. Le tirage, l'écran et le reroll du
  Lot 2 UI sont **réutilisés tels quels**.
  → *Critères : (1) Notion est excellent chez Karavel et mauvais chez
  Meridia sans qu'aucune valeur ne soit écrite en dur pour ça ; (2) au T1 on
  manque d'argent, au T4 on manque de slots.*
- **Lot 4 — La croissance et les équipes subies** : Comité d'investissement,
  cap achetable, promotions, paliers de produit, Sales/PMM/CSM et **leurs
  événements Inbox dédiés**, Compendium des synergies.
  → *Critère : deux runs sur la même entreprise produisent deux
  organisations différentes.*
- **Lot 5 — L'échelle** : multi-squad, attention limitée, combos
  inter-squads, niveaux de carrière, slots de base par niveau, déblocages
  stricts **affichés et expliqués dans les menus**, quotas par niveau.
  → *Critères : (1) le même `ScoreResolver` sert à 1 squad et à 10 ; (2) un
  joueur qui n'a jamais gagné sait quand même que Lead PM existe et ce qu'il
  faut faire pour l'ouvrir.*

Chaque lot se conclut comme d'habitude : les deux smoke tests headless, un
run visuel, et la mise à jour du carnet de règles.

---

## 18. Points à trancher

### 18.1 Tranché

| Question | Décision |
|---|---|
| Échec de quota, MRR cumulatif, trimestre à 3 sprints, plafond de Levier | §2 |
| Fréquence des outils internes | **Au Comité, achats illimités.** Ce sont le **prix** et les **slots** qui bornent, pas un compteur d'achats (§7.1.1) |
| Décisions stratégiques | **1 par trimestre**, irréversible (§7.2) |
| Formule du Budget | Racine carrée retenue **comme point de départ**, à recalibrer en playtest — pas un choix de conception, un réglage |
| Nombre de slots de base | **Vient du kit de départ, donc du niveau de carrière** : 3 au PM (dont 1 hérité) → 7 au CEO. +2 achetables en cours de run (§7.1.1) |
| Le slot gelé par un outil cumulatif | Réglé par le **`slotBonus`** : les outils cumulatifs rendent leur place (§7.1.1.b). La punition porte sur le compteur, jamais sur l'espace de build |
| L'outillage hérité | **Retenu.** Il oblige à comprendre trois mécaniques pour bien ouvrir un run — c'est l'intention, pas un effet de bord (§7.1.3) |
| Pilotage des équipes subies | **Aucun.** Pas de lobbying, pas d'achat. Elles appliquent leur taux et déclenchent leurs événements ; on s'adapte (§9.4) |
| Déblocage de carrière | **Strict** — il faut gagner pour évoluer. Et les niveaux verrouillés sont **visibles avec leur condition** (§13.4) |

### 18.2 Réglages en attente de playtest

**Plus aucune question de conception bloquante.** Ce qui reste sont des
valeurs, pas des choix de structure — on pose une base et on ajuste en
jouant :

| Réglage | Base posée | Comment on tranchera |
|---|---|---|
| Nombre d'outils à `slotBonus` | **Peu** — pas de cible chiffrée | Émergera en construisant le catalogue d'outils et d'objets. On regarde après coup si les slots restent une contrainte |
| Courbe de prix des outils | 8-18 💶 contre ~24 💶 au T1 | Smoke test puis playtest. Rythme visé : 1 à 2 achats au premier Comité |
| Rôle du Capital politique | Indicateur, deltas anecdotiques, petit multiplicateur, couperet à 0 | Hypothèses consignées en **§8.1** — à creuser quand le score tournera |
