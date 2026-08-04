# Spécification — Profondeur de gameplay (v2)

> Document de travail issu du playtest du 29/07/2026, révisé après un second
> passage de conception ("il ne doit pas être simple de faire une entreprise
> qui fonctionne"). Rien de ce qui suit n'est implémenté : c'est la cible de
> conception pour les prochaines phases, découpée en lots (§13). En cas de
> contradiction avec le [carnet de règles](carnet-de-regles.md), ce document
> décrit l'intention *future* ; le carnet décrit l'état *actuel*.

## 1. Les problèmes constatés et les systèmes qui y répondent

| Retour de playtest | Système de réponse |
|---|---|
| La capacité d'équipe est identique à chaque sprint | **Équipe** (§4) : la capacité est *produite* par le roster |
| Les features n'ont ni coût différencié, ni durée, ni ROI visible | **Roadmap profonde** (§6) : points, epics, infos cachées |
| Impossible de savoir quoi prioriser sans infos business | **Pratiques** (§5.2) + **actions personnelles** (§7.2) |
| Le shop garde les mêmes items, tout est achetable | **Shop unifié** (§5) : tirage limité + monnaie |
| Toujours les mêmes profils au recrutement | **Pool de candidats** (§5.1) tiré par sac |
| Pas de gestion d'équipe (headcount, composition) | **Roster** (§4) : cap, rôles, déséquilibres punis |
| 6 PM = specs sans code, 6 designers = maquettes sans prod | **Rôles** (§4.2) : chaque rôle produit une chose unique |
| Trop simple de faire une entreprise qui fonctionne | **La pression** (§8) : décroissance naturelle + revue de board |
| Des malus cachés sur certains employés | **Traits cachés** (§4.5) : le recrutement est un pari |
| Deux économies pour des choix difficiles et des surprises | **Économie du joueur** (§7) : Énergie + actions personnelles |

---

## 2. Les deux économies — le cadre général

Le jeu sépare désormais explicitement ce qui appartient à **l'entreprise** et
ce qui appartient **au joueur** (le·la CPO). C'est la source principale de
tension : ce qui est bon pour l'une coûte souvent à l'autre.

| | Ressources | Ce qui la tue |
|---|---|---|
| **L'entreprise** | 💰 Trésorerie · 🫶 Moral · 🧱 Dette · 📈 Valeur perçue · 🎭 Cynisme · 🪙 Pièces (budget d'action) | Faillite, exode, zombie... |
| **Le joueur** | 🎯 Capital politique (crédibilité au board) · ⚡ **Énergie** (nouvelle jauge personnelle) | Rachat hostile, **burn-out** |

Exemples de tensions voulues :
- Compenser un rôle manquant en "faisant le taf soi-même" sauve le sprint de
  l'entreprise… en brûlant votre Énergie (§7.2).
- Demander une rallonge au board convertit *votre* Capital politique en
  Pièces pour *l'entreprise* (§7.2).
- Une équipe au Moral bas régénère mal *votre* Énergie (§7.1) — les problèmes
  de la boîte finissent toujours par vous suivre à la maison.
- La fin **Burn-out fondateur·rice** est remappée sur Énergie ≤ 0 (aujourd'hui
  déclenchée par Valeur perçue ≤ 0, thématiquement bancal — voir §8.3).

---

## 3. Les Pièces 🪙 — économie d'action de l'entreprise

### Intention
La Trésorerie reste la jauge de **survie** (0 = faillite). Les Pièces sont la
monnaie d'**action** : la marge de manœuvre que le board vous accorde pour
recruter et outiller. À 0 pièce on ne perd pas — on est paralysé, ce qui est
thématiquement juste pour un CPO sans budget.

### Gains
- **Allocation du board** : +2 pièces/sprint — *réduite à +1 si la dernière
  revue de board a été ratée* (§8.2).
- **Performance** : + `floor(revenu du sprint / 4)` à la Résolution.
- **Quick wins** : features taguées `quickWin` → +1 à +3 pièces à la livraison.
- **Événements Inbox** : certains choix donnent/coûtent des pièces
  (pseudo-ressource `pieces` dans `effects`).
- **Rallonge** : action personnelle du joueur (§7.2) — Capital politique → Pièces.
- **Combos** *(phase D)* : synergies de roster.

### Dépenses
Shop (§5), indemnités de licenciement (§4.4), reroll *(phase D)*.

### Chiffres de départ (indicatifs, `balance.json`)
Pièces initiales par entreprise (Meridia 5, Karavel 4). Pas de plafond en v1.

---

## 4. L'Équipe — roster, rôles, composition, paris

### 4.1 Le roster
`SprintState.roster` : employés `{id, name, role, seniority, salary, trait,
hidden_trait, hiddenRevealed, hiredSprint}`. Chaque entreprise définit son
**roster de départ** et son **cap d'effectif** (`companies.json`) :

- **Meridia** (senior, cap 7) : 1 PM sr, 2 Dev sr, 1 Ops sr, 1 Designer sr —
  équilibré, cher en masse salariale.
- **Karavel** (junior, cap 6) : 1 PM jr, 3 Dev jr, 1 Designer jr — **pas
  d'Ops** : la dette monte toute seule tant qu'on n'a pas recruté. Le défaut
  de la boîte est visible dès l'offre d'emploi.

Affichage "5/6" dans la barre de ressources et le panneau Entreprise.

### 4.2 Les rôles — qui produit quoi
Principe : **chaque rôle produit une chose que les autres ne produisent pas,
et son absence a un coût.**

| Rôle | Produit (par employé/sprint) | Absence totale |
|---|---|---|
| **Dev** | +2 points de capacité (senior +3) | Capacité quasi nulle |
| **PM** | +1 point · −25 % pénalité de surchauffe (max −50 %) | Pénalité pleine, aucun cadrage |
| **Designer** | +1 Valeur perçue par feature livrée (max +2) | Effets Valeur perçue **÷ 2** |
| **Ops** | −1 Dette/sprint (max −2) | **+2 Dette/sprint** |

La capacité de roadmap est la somme des contributions du roster
(`capacity_bonus` actuel supprimé). Rendements décroissants au-delà des caps
de cumul : empiler un seul rôle ne marche jamais.

### 4.3 Salaires
Chaque employé coûte sa `salary` en Trésorerie à chaque Résolution (junior 1,
senior 2), ligne "masse salariale" visible. Grosse équipe ⇒ gros revenu requis.

### 4.4 Licenciement *(validé : dès la phase A)*
Indemnités 2 pièces, Moral −4, **Cynisme +3 par licenciement supplémentaire
dans le mandat** (le premier passe pour une décision, les suivants pour une
politique). Réversible, mais à prix croissant — cohérent avec le thème.

### 4.5 Traits cachés — le recrutement est un pari
Chaque candidat tiré au shop porte, en plus de son trait visible, un
`hidden_trait` **tiré au sort au moment du tirage** (le même nom peut cacher
autre chose dans une autre run) et masqué à l'embauche.

**Révélation :**
- Automatique à la **fin de la période d'essai** (embauche + 2 sprints) —
  ligne de journal : *"Fin de période d'essai : Sofia est une Pépite."*
- Anticipée par un **1:1** (action personnelle, §7.2) — sur un employé déjà
  recruté *ou sur un candidat avant embauche*.
- Systématique avec la pratique **Entretiens structurés** (§5.2) : tous les
  candidats du shop arrivent révélés.

**Pool de traits cachés (mix négatif/positif — le pari doit avoir un upside) :**

| Trait | Effet |
|---|---|
| 😤 Râleur d'openspace | −1 Moral/sprint |
| 🏝️ Fantôme | contributions de rôle ÷ 2 |
| 💸 Négociateur | à la fin de la période d'essai : +1 salaire, sinon il part |
| 🧨 Démission silencieuse | part sans prévenir au sprint d'embauche +4 |
| 💎 Pépite | +1 point de capacité |
| 🤝 Mentor | +1 Moral/sprint |
| 📣 Réseau | −2 pièces sur le prochain recrutement |

Distribution indicative : ~50 % neutre (aucun trait caché), ~30 % négatif,
~20 % positif — l'embauche non vérifiée doit rester jouable mais piquante.

### 4.6 Traits visibles
Branchés dans `EffectResolver` selon l'ordre carte → employé → époque (§11 du
carnet) en **phase C** (l'infrastructure existe déjà).

---

## 5. Le Shop unifié — le marché du sprint

Un seul écran (l'actuel Recrutement), deux rayons, une offre **tirée au sort
chaque sprint et stockée dans `SprintState`** (revenir sur l'écran ne
retire pas — même règle anti-abus que l'Inbox).

### 5.1 Rayon Candidats
- Pool `data/candidates.json` (~12 entrées Transformation agile) : `{id, name,
  role, seniority, costPieces, salary, trait, badges, eras[]}` + trait caché
  assigné au tirage (§4.5).
- **2 candidats/sprint** (sac). Embaucher = pièces + cap d'effectif respecté.

### 5.2 Rayon Pratiques
Pool `data/practices.json` (~8 entrées) : `{id, name, icon, costPieces,
description, unlocks, eras[]}`. **2 pratiques/sprint** parmi les non
possédées. Permanentes pour le mandat. **Chaque achat de pratique inflige
+2 Cynisme** — un process de plus, l'organisation lève les yeux au ciel ;
l'information a un coût culturel.

| Pratique | Révèle / débloque |
|---|---|
| 🔍 Discovery | Colonne **ROI** des features (§6.3) |
| 🎨 UX research | Colonne **Impact client** |
| 🧭 Tech radar | Colonne **Risque** (Dette) |
| 🗂️ Entretiens structurés | **Traits cachés des candidats** au shop (§4.5) |
| 📊 Product analytics | Section **Burn down** du Pilotage + métriques post-livraison |
| 💼 Segmentation clients | Section **Grands comptes / petits comptes** du Pilotage |
| 🎯 OKR | +2 Capital politique par feature à fort ROI livrée |

(le "🔒 Bientôt disponible" du panneau Entreprise se *joue* au lieu d'être
un patch.)

### 5.3 Bonus actifs visibles
Barre de ressources étendue (§10) ; le panneau Entreprise liste le détail.

---

## 6. La Roadmap profonde — backlog, points, epics, information

### 6.1 Backlog et tirage
`data/backlog.json` (~18 entrées Transformation agile ;
`roadmap-features.json` reste la démo landing). **4-5 items tirés/sprint**
(sac, filtre `eras[]`) + les epics en cours toujours affichés.

### 6.2 Coût en points
`costPoints` (1-5) **toujours visible**. La capacité (produite par le roster)
se dépense en points. UI panier : "7 pts / 8 disponibles". Surchauffe punie,
modulée par les PM.

### 6.3 Informations cachées
Trois attributs masqués par défaut ("🔒 ?") :
- `roi` : bonus **permanent** de revenu/sprint une fois livré (+0 à +3 MRR) ;
- `clientImpact` : delta Valeur perçue à la livraison (**−2 à +6** — certaines
  features réclamées font *baisser* la valeur perçue) ;
- `risk` : delta Dette à la livraison (−3 à +8).

Sans pratiques, on choisit sur la promesse marketing et le coût — le pilotage
à l'aveugle d'une organisation sans discovery. Chaque pratique révèle sa
colonne pour toutes les features, définitivement. L'action personnelle
**Plonger dans une feature** (§7.2) révèle tout, mais pour *une* feature et
*un* sprint.

### 6.4 Epics
8-12 points au total, investissement libre par sprint, *"En cours depuis N
sprints — reste M points"*. Effets à la complétion uniquement. Abandonner ne
rembourse rien (sunk cost réel). Prépare le modèle waterfall du scénario
Garage.

### 6.5 La Résolution affiche en plus
Masse salariale, pièces gagnées, delta d'Énergie du joueur, et les attributs
*réels* des features livrées — la Résolution devient le moment où
l'organisation découvre ce qu'elle a vraiment acheté.

---

## 7. L'économie du joueur — Énergie ⚡ et actions personnelles

### 7.1 L'Énergie
Jauge personnelle 0-100 (départ 70), **côté jeu uniquement** (pas dans
`resources.json`, partagé avec la landing).

- **Régénération** : +12/sprint à la Résolution… **modulée par le Moral de
  l'équipe** : ×1 si Moral ≥ 60, ×0.5 si Moral 30-60, ×0 si Moral < 30. Une
  équipe qui va mal vous épuise — le pont mécanique entre les deux économies.
- **Dépenses** : les actions personnelles (§7.2) ; certains événements Inbox
  pourront coûter de l'Énergie (les crises vous suivent à la maison).
- **Énergie ≤ 0 → fin Burn-out fondateur·rice** (§8.3). Pas de mort subite
  cachée : la barre est visible en permanence, la spirale (Moral bas → régén
  nulle → compenser soi-même → 0) se voit venir.

### 7.2 Les actions personnelles
Boutons contextuels sur les écrans concernés, limités par l'Énergie (pas de
compteur d'actions séparé — une seule ressource à lire) :

| Action | Où | Coût | Effet |
|---|---|---|---|
| 🤝 **1:1** | Marché / panneau Entreprise | 10 ⚡ | Révèle le trait caché d'un candidat ou d'un employé |
| 🔬 **Plonger dans une feature** | Roadmap | 15 ⚡ | Révèle ROI/Impact/Risque d'une feature, ce sprint |
| 🔧 **Faire le taf soi-même** | Roadmap | 25 ⚡ | +2 points de capacité ce sprint |
| 🏛️ **Négocier une rallonge** | Panneau Entreprise | 10 ⚡ | −8 Capital politique → +4 Pièces |
| 🧘 **Souffler** | Résolution | 0 | Renoncer aux actions du prochain sprint → +10 régén bonus |

C'est le "temps du CPO" : on ne peut pas être partout, chaque sprint dit qui
vous êtes — l'enquêteur, le pompier, le lobbyiste, ou l'épuisé.

---

## 8. La pression — pourquoi "ne rien faire" doit perdre

Constat des smoke tests actuels : la stratégie `careful` (ne rien acheter, ne
rien activer) atteint tranquillement la fin du mandat. Inacceptable pour un
roguelike. Trois mécaniques :

### 8.1 Décroissance naturelle
**Valeur perçue −2/sprint** appliquée à chaque Résolution : le marché avance,
les concurrents livrent. Ne rien livrer = décliner. Comme le revenu dérive de
la Valeur perçue, l'inaction crée une spirale de revenu — la survie passe par
la livraison, pas par la thésaurisation.

### 8.2 La revue de board (le "boss" trimestriel)
`eras.json` promet un boss ("La revue de sprint devant le comité de
direction") — il existe enfin. **À la fin du sprint 6** (mi-mandat,
`trimesterLengthSprints`), un écran-overlay de revue compare l'état de la
boîte aux **objectifs fixés par l'entreprise à l'embauche** — visibles dès le
choix du poste et rappelés dans le panneau Entreprise (ça répond aussi à
"comprendre ce qu'il faut prioriser") :

- **Meridia** : *"Prouvez que l'agilité marche"* — Cynisme ≤ 45 **et** ≥ 1
  grande décision active.
- **Karavel** : *"Structurez sans casser la machine"* — Dette ≤ 35 **et**
  revenu du sprint ≥ 12.

**Réussite** : +5 Pièces, +8 Capital politique.
**Échec** : −12 Capital politique, allocation réduite à +1 pièce/sprint pour
le reste du mandat, et une ligne cinglante au journal. (Phase D : le board
peut en plus *imposer* une grande décision.)

### 8.3 Remap des fins de mandat
- **Burn-out fondateur·rice** : déclenchée par **Énergie ≤ 0** (aujourd'hui
  Valeur perçue ≤ 0, thématiquement faux).
- **Valeur perçue ≤ 5** : plus aucun revenu (le seuil direct de fin saute —
  la mort passe par la spirale économique, plus lisible qu'un couperet).

---

## 9. La boucle complète

```
                 L'ENTREPRISE                                LE JOUEUR
  Roster (rôles) ──produit──> Capacité ──> Features/Epics      Énergie ⚡
     ^    ^                                   │                  │  ^
     │    └── traits cachés (paris)           ├─> ROI → Revenu   │  │ régén ×Moral
  recrute (pièces, cap)                       ├─> Impact → 📈    │  │
     │                                        └─> Risque → 🧱    │  │
  Shop du sprint <──finance── 🪙 Pièces <──alloc + perf──────────┤  │
     │                            ^                              │  │
     └─> Pratiques ──révèlent──> Infos cachées <──"Plonger"──────┤  │
              │                                                  │  │
              └─> +2 Cynisme chacune          1:1, Taf soi-même ─┘  │
                                                                    │
  Revue de board (sprint 6) ──réussite/échec──> 🎯 Capital ─rallonge─> 🪙
  Décroissance 📈 −2/sprint (le marché n'attend pas)
```

Le choix central : **produire (devs), soigner (designers/ops), savoir
(pratiques), ou payer de sa personne (énergie)** — et aucune des quatre
voies ne suffit seule.

## 10. Impacts UI par écran

- **Barre de ressources** : deux groupes séparés visuellement —
  `[Entreprise : 💰🫶🧱📈🎭 · 🪙 12 · 👥 5/7 · icônes pratiques]`
  `[Vous : 🎯 61% · ⚡ 55]` — tooltips partout.
- **Choix d'entreprise** : + roster de départ, cap, **objectifs de la revue
  de board** (on sait ce qu'on signe).
- **Roadmap** : badges de coût en points, colonnes 🔒/valeurs, barres d'epic,
  panier de points, boutons "Plonger" (⚡) et "Faire le taf soi-même" (⚡).
- **Marché** : solde de pièces, 2+2 items, prix, boutons 1:1 (⚡) sur les
  candidats, indication cap d'effectif.
- **Résolution** : masse salariale, pièces gagnées, delta Énergie, révélation
  des attributs des features livrées, option "Souffler".
- **Revue de board** : nouvel overlay à la fin du sprint 6 (objectifs,
  verdict, conséquences).
- **Panneau Entreprise** : roster détaillé (+ boutons licencier / 1:1),
  pratiques, objectifs de board, action Rallonge, sections Pilotage
  déverrouillables.

## 11. Données — nouveaux fichiers et modifications

| Fichier | Statut | Contenu |
|---|---|---|
| `data/candidates.json` | **nouveau** | pool de candidats (§5.1) |
| `data/practices.json` | **nouveau** | pool de pratiques (§5.2) |
| `data/backlog.json` | **nouveau** | pool features/epics (§6) |
| `data/hidden-traits.json` | **nouveau** | pool de traits cachés + poids (§4.5) |
| `data/companies.json` | modifié | + `startingRoster[]`, `teamCap`, `startingPieces`, `boardObjectives` |
| `data/balance.json` | modifié | + `pieces`, `roles`, `salaries`, `firing`, `shopDraw`, `energy` (régén, coûts d'actions, seuils Moral), `pressure` (décroissance, revue de board), remap `endingThresholds` |
| `data/inbox-events.json` | modifié | `effects` accepte `pieces` et `energie` |
| `recruitment-demo.json`, `roadmap-features.json`, `hud-demo.json`, `resources.json` | inchangés | démo landing / 6 jauges partagées (l'Énergie vit côté jeu) |

`SprintState` gagne : `pieces`, `energy`, `roster[]`, `owned_practices[]`,
`current_shop_offer`, `current_backlog_draw`, `epic_progress{}`,
`board_review_passed`, `fired_count`. Tous les tirages du sprint sont
stockés (pas de re-tirage en revisitant un écran).

## 12. Équilibrage initial (tout dans `balance.json`)

Roster de départ ⇒ ~7-8 points de capacité ; features 1-5 points ; revenu
typique (~10-14) ⇒ +4-5 pièces/sprint ⇒ **~1 achat/sprint**. Masse salariale
de départ (5-7) sous le revenu typique, marge qui se referme si on recrute
sans faire croître le revenu. Décroissance −2 Valeur perçue/sprint ⇒ il faut
livrer ~1 feature à impact positif par sprint juste pour rester à flot.
Énergie : 70 de départ, +12 de régén pleine ⇒ ~1 action personnelle/sprint
en rythme de croisière, 2 en puisant dans la réserve. À valider au smoke
test logique (stratégies `stress`/`greedy`/`careful` à réécrire — **critère
de recette : `careful` doit désormais perdre**).

## 13. Phasage d'implémentation

- **Phase A — Fondations économiques + pression** : roster, rôles, salaires,
  cap, licenciement, traits cachés (révélation période d'essai seulement),
  pièces, shop à tirage limité, décroissance naturelle, revue de board.
  → Critère : le jeu est *déjà* plus dur ; `careful` perd.
- **Phase B — L'économie du joueur** : Énergie, actions 1:1 / Taf soi-même /
  Rallonge / Souffler, régén liée au Moral, remap du burn-out.
- **Phase C — Roadmap profonde** : backlog, points, epics, infos cachées,
  révélation par pratiques + action Plonger, ROI → revenu, traits visibles
  dans `EffectResolver`.
- **Phase D — Méta** : dashboards Pilotage réels, combos, reroll, board qui
  impose des décisions, démissions volontaires, pivot de business model.

Chaque phase se termine par la mise à jour des deux smoke tests et un run
visuel complet.

## 14. Questions ouvertes

- **Départs volontaires** (Moral bas ⇒ démissions subies) : phase D, à confirmer.
- **Plafond de pièces / d'énergie thésaurisée** : à observer en playtest.
- **Difficulté par entreprise** : Karavel (sans Ops) est objectivement plus
  dure que Meridia — assumé comme difficulté asymétrique affichée ? (badge
  "défi" sur l'offre d'emploi ?)
- **Tailles de tirage** (2+2 shop, 4-5 backlog) et **distribution des traits
  cachés** (50/30/20) : réglages de départ, à ajuster en jouant.
- **Salaires évolutifs / inflation** : phase D.
