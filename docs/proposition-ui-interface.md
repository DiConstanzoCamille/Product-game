# Proposition UI — Objet unifié, panneau permanent, feedback live, direction artistique

> Document de proposition (30/07/2026), en réponse aux retours de Camille sur
> l'état post-Phase B. Rien ici n'est implémenté : c'est une cible d'interface
> et de direction artistique, à trancher avant la Phase C — la roadmap
> profonde ajoutera un troisième « rayon » d'objets (features/epics) et il
> vaut mieux poser la grammaire commune avant de la remplir.
>
> Maquette interactive associée : **[Product Tycoon — Maquette UI comparée](https://claude.ai/code/artifact/84d5088d-9d6f-41a0-a108-7adec6fc502f)**
> (4 pistes de direction artistique commutables sur le même écran, avec la
> preview d'impact au survol, l'animation d'achat, le 1:1 qui lève une
> inconnue et le panneau repliable en rail — tous fonctionnels).
> Source : `maquette-ui-product-tycoon.html` (fichier autonome, sans dépendance).

**Sommaire**
1. Lecture des retours — le problème commun
2. A — L'Actif : un seul type d'objet, une seule grammaire
3. A — L'écran fusionné : « Investissements » absorbe le Marché et les Grandes décisions
4. B — Le Panneau de bord : l'entreprise toujours à l'écran
5. C — Ressentir ses achats : preview, impulsion, engagement
6. D — Direction artistique : 4 pistes comparées
7. Récapitulatif des arbitrages proposés et questions à trancher

---

## 1. Lecture des retours — le problème commun

Les cinq retours pointent, sous des angles différents, le même défaut
structurel : **le jeu présente trois fois le même geste avec trois interfaces
différentes, et aucune des trois ne montre ses conséquences au moment du
geste.**

| Retour | Symptôme | Cause commune |
|---|---|---|
| 1. Le Marché devrait être dans les Grandes décisions | Deux écrans pleins pour deux variantes du même acte d'achat | Pas d'abstraction commune |
| 2. Il manque un « type d'objet » unifié | Carte, candidat et pratique ont chacun leur layout, leurs boutons, leur vocabulaire | Pas d'abstraction commune |
| 3. L'impact est illisible avant l'achat | Des chiffres statiques dans une fiche, pas de projection sur MON état | Les jauges et les objets vivent dans des zones séparées |
| 4. Aucune animation à l'achat | L'effet n'existe visuellement qu'à la Résolution | Les jauges (barre du haut) sont un affichage figé, pas une surface de feedback |
| 5. Le roster est planqué dans un overlay | L'état de l'entreprise est un menu, pas un contexte | Idem — l'état de la run n'a pas de place permanente à l'écran |

La proposition tient donc en trois pièces solidaires : **un objet-carte
unifié** (§2), présenté dans **un écran d'acquisition fusionné** (§3), dont
l'impact se projette en direct sur **un panneau d'état permanent** (§4-5).
Retirer une des trois pièces affaiblit les deux autres : le panneau permanent
est précisément *la surface* sur laquelle la preview d'impact devient
possible.

---

## 2. A — L'Actif : un seul type d'objet, une seule grammaire

### 2.1 La définition

Camille a raison : carte de décision, candidat et pratique sont le même objet
de gameplay. Proposition de nom interne : **l'Actif** — un objet que
l'organisation acquiert, à un coût, et qui pèse ensuite durablement sur elle.
Le mot est volontairement corpo (ça colle au ton du jeu) et il donne un nom
naturel à la section « ce qu'on possède » du panneau (§4).

| | 🃏 Grande décision | 👤 Candidat | ✨ Pratique |
|---|---|---|---|
| **Monnaie** | 1 slot d'activation (3-4/mandat) | 🪙 pièces (+ cap d'effectif) | 🪙 pièces |
| **Coût récurrent** | — (coût de bascule, plus tard) | salaire 💰/sprint | — |
| **Coût caché/culturel** | deltas selon profil d'équipe | trait caché (pari) | +2 🎭 Cynisme |
| **Effet persistant** | modificateurs pour le mandat | production de rôle + traits | déblocages permanents |
| **Disponibilité** | catalogue permanent | tirage du sprint | tirage du sprint |
| **Réversibilité** | non (MVP) | licenciement (à prix croissant) | non |

Tout tient dans les mêmes cases. Les différences (monnaie, récurrence,
disponibilité) sont des *valeurs de champs*, pas des raisons d'avoir trois
composants d'interface.

### 2.2 La carte d'Actif — anatomie unique

Un seul composant visuel (`asset_card.tscn` à terme), six zones fixes. Chaque
type remplit les zones avec ses champs, mais **la position de chaque
information est identique partout** — le joueur apprend la carte une fois :

```
┌──────────────────────────────┐
│ ① TYPE + catégorie/rôle      │  pastille DÉCISION / CANDIDAT / PRATIQUE
│ ② Identité                   │  avatar (candidat) · icône (pratique) · réf (décision)
│ ③ Accroche                   │  tagline / trait / description — le texte qui a du mordant
│ ④ IMPACT                     │  lignes standard « icône ressource + delta + note »
│    dont l'inconnu : 🔒 / ❓   │  trait caché, colonnes non révélées → le pari est AFFICHÉ
│ ⑤ COÛT (bandeau bas)         │  monnaie + récurrent : « 6 🪙 · salaire 2 💰/sprint »
│ ⑥ ACTIONS                    │  verbe spécifique : Activer / Embaucher / Adopter
│                              │  + secondaires : 🤝 1:1 (⚡)
└──────────────────────────────┘
```

Décisions de détail :

- **La zone Impact parle en ressources, pas en axes.** Aujourd'hui les cartes
  de décision affichent les 4 axes (`humain`, `financier`, `ttm`,
  `productivité`) alors que le reste du jeu parle en 6 jauges. Le mapping
  existe déjà (`balance.json` → `cardAxisResourceMap`) : la carte doit
  afficher le delta **final en ressources** (🫶 −7, 🧱 −5…), avec la note
  d'axe en sous-texte. C'est la condition pour que la preview (§5) soit
  honnête — on projette sur les jauges ce qui est écrit sur la carte.
- **L'inconnu est une ligne d'impact comme les autres.** « 🔒 Trait caché —
  révélé en fin de période d'essai » occupe une ligne de la zone ④, au même
  endroit que les deltas connus. Acheter de l'information (1:1, Entretiens
  structurés, Discovery) = transformer des lignes 🔒 en lignes chiffrées,
  visuellement, sur place. La boucle « payer pour savoir » de la spec
  profondeur devient littérale.
- **Les verbes restent spécifiques.** Un seul composant, mais on n'écrit pas
  « Acquérir » partout : Activer / Embaucher / Adopter portent chacun leur
  poids RP. La grammaire est commune, le vocabulaire reste incarné.
- **Le flip est conservé** comme geste de détail (accroche ↔ notes
  d'impact détaillées) : c'est déjà une signature du jeu (landing +
  decisions_screen), il devient le geste « lire le dossier » de *toutes*
  les cartes.
- **Phase C incluse d'office :** les features/epics de la roadmap profonde
  rentrent dans la même anatomie (coût en points de capacité, colonnes
  ROI/Impact/Risque 🔒 en zone Impact). La grammaire est pensée pour 5 types,
  on en livre 3 d'abord.

### 2.3 Côté données (suggestion, non bloquant)

À terme, un schéma commun `{id, type, cost{pieces?, slot?, salary?,
cynisme?}, effects[], locks[], availability}` permettrait à `EffectResolver`
et à la carte d'Actif de traiter les trois pools uniformément. Ce n'est pas
un prérequis de la maquette — `cards.json`, `candidates.json` et
`practices.json` peuvent être *présentés* par le même composant sans être
fusionnés tout de suite.

---

## 3. A — L'écran fusionné : « Investissements » absorbe le Marché et les Grandes décisions

> **Nom tranché (30/07/2026) : l'écran fusionné s'appelle « Investissements ».**
> « Marché » ne couvrait que la moitié de ce qu'on y fait — on n'« achète » pas
> une méthodologie d'organisation sur un étal. « Investissements » couvre les
> trois types d'Actif (on investit dans une personne, dans une pratique, dans
> une décision structurelle) et porte la bonne idée : ça coûte maintenant, ça
> rapporte — ou pas — plus tard. Le mot reste corpo, donc raccord avec le ton.
> Le rayon périssable garde, lui, le nom d'« étal du sprint ».

### 3.1 Le flux passe de 5 à 4 phases

```
Avant :  Inbox → Roadmap → Grandes décisions → Marché → Résolution
Après :  Inbox → Roadmap → Investissements ─────────→ Résolution
```

La phase 3 disparaît en tant qu'écran ; les Grandes décisions deviennent un
**rayon permanent des Investissements**. Justification de gameplay, pas seulement
d'ergonomie : les grandes décisions ne sont activées que 3-4 fois par mandat
— leur consacrer un écran plein *à chaque sprint* donne 8 à 9 passages où
l'écran n'est qu'un péage à cliquer. Un rayon qu'on longe sans s'arrêter
coûte zéro clic ; un écran qu'on traverse en coûte un, plus un chargement de
scène.

### 3.2 Structure de l'écran « Investissements »

Pas d'onglets : **deux rayons empilés dans un seul scroll**, parce que tout
l'intérêt de la fusion est de mettre les investissements en concurrence dans
le même champ de vision (« cette pièce, je la garde pour Lina ou je prends
Discovery ? » — et juste en dessous, « ou est-ce que ce sprint est celui où
j'active Jira ? »).

```
┌────────────────────────────────────────────┬─────────────┐
│  SPRINT 5 — PHASE 3 : INVESTISSEMENTS      │             │
│                                            │   PANNEAU   │
│  📦 L'ÉTAL DU SPRINT      « tiré ce sprint »│     DE      │
│  [👤 candidat] [👤 candidat] [✨ prat.] [✨ prat.] │    BORD     │
│                                            │             │
│  🃏 LES GRANDES DÉCISIONS   « 2 slots / 4 » │   (§4 —     │
│  [carte] [carte] [carte] [carte]…          │  permanent) │
│                                            │             │
│  [← Roadmap]              [Résolution →]   │             │
└────────────────────────────────────────────┴─────────────┘
```

- **L'étal du sprint** en premier : c'est la partie périssable (tirage du
  sprint, règle anti-re-tirage inchangée). L'urgence en haut.
- **Les grandes décisions** en dessous : catalogue permanent, trié avec les
  activées en fin de rayon (tamponnées « Activée »), compteur de slots
  visible en titre de rayon.
- Les deux rayons affichent le **même composant carte d'Actif** — seule la
  couleur de pastille ① et le contenu des zones changent.
- Les filtres/tri ne sont pas nécessaires au volume actuel (4 + 5 cartes) ;
  à prévoir quand le catalogue de décisions dépassera ~8 entrées.

### 3.3 Ce que ça change ailleurs

- Le badge de profil d'équipe (🌱/🏛️) affiché sur l'écran Décisions migre
  dans l'en-tête du Panneau de bord (§4) — c'est un trait de la run, pas de
  la phase.
- Le compteur « X/4 grandes décisions activées » vit deux fois : en titre du
  rayon, et dans la section Actifs du panneau.
- La numérotation des phases est mise à jour partout (labels de sprint,
  `NEXT_SCENE` des écrans) ; l'écran Résolution ne change pas de rôle.
- La revue de board, l'Inbox, la Roadmap : inchangées.

---

## 4. B — Le Panneau de bord : l'entreprise toujours à l'écran

### 4.1 Principe

Une **colonne fixe à droite, ~320 px, présente sur les 4 écrans de phase**.
Pas un overlay, pas un menu : la partie de l'écran où l'entreprise existe en
continu. Elle remplace la barre de ressources horizontale du haut (qui
disparaît) et absorbe la partie « état » du panneau Entreprise actuel.

Pourquoi à droite : le sens de lecture met le contenu de phase (ce que je
décide) à gauche et l'état (ce que ça me coûte) à droide du geste ; c'est
aussi la position des inspecteurs dans les outils que le jeu parodie, et la
zone survolée par le pouce des chiffres — les deltas de la preview (§5)
apparaissent au plus près des cartes.

### 4.2 Contenu, de haut en bas

```
┌─ PANNEAU DE BORD ────────────────┐
│ 🏛️ Meridia          Sprint 5/12  │  ← en-tête : entreprise, sprint,
│ équipe senior · SaaS (MRR)       │     profil, modèle éco
├──────────────────────────────────┤
│ ENTREPRISE                       │
│ 💰 Trésorerie   ▓▓▓▓▓░░░░░  42  │  ← 5 jauges en BARRES (pas des
│ 🫶 Moral        ▓▓▓▓▓▓░░░░  55  │     chiffres) : c'est la surface
│ 🧱 Dette        ▓▓▓▓░░░░░░  38  │     de la preview d'impact (§5)
│ 📈 Valeur perçue▓▓▓▓▓░░░░░  47  │
│ 🎭 Cynisme      ▓▓▓▓▓░░░░░  47  │
│ 🪙 7 pièces                      │
├──────────────────────────────────┤
│ VOUS                             │
│ 🎯 Capital pol. ▓▓▓▓▓▓░░░░  61  │
│ ⚡ Énergie      ▓▓▓▓▓▓░░░░  55  │
├──────────────────────────────────┤
│ ÉQUIPE 5/7 · 8 pts · 7 💰/sprint │
│ ◉ Hervé      PM sr               │  ← ligne par personne : avatar,
│ ◉ Danielle   Dev sr              │     rôle ; badge 🔒 essai en cours,
│ ◉ Marek      Dev sr              │     trait révélé en icône.
│ ◉ Solange    Ops sr              │     Survol = fiche · clic = actions
│ ◉ Patrice    Designer sr    🔒   │     (🤝 1:1 · licencier)
├──────────────────────────────────┤
│ ACTIFS                           │
│ 🃏 Décisions 1/4 : [Notion ✓]    │  ← chips ; survol = rappel d'effet
│ ✨ Pratiques : 🔍 🗂️             │
├──────────────────────────────────┤
│ 📋 REVUE DE BOARD — sprint 6     │
│ 🎭 Cynisme ≤ 45        ✗ (47)   │  ← conditions évaluées EN DIRECT
│ 🃏 ≥ 1 décision active  ✓        │
├──────────────────────────────────┤
│ [ 🏢 Dossier entreprise ]        │  ← ouvre l'overlay actuel (allégé)
└──────────────────────────────────┘
```

Trois choix forts :

1. **Les jauges deviennent des barres.** Le mini-HUD actuel affiche « 55% »
   en chiffres ; une preview d'impact a besoin d'une géométrie sur laquelle
   projeter un segment fantôme. Les barres portent la couleur d'état
   (bon/attention/danger) déjà calculée par `EffectResolver.gauge_state()`.
2. **Le roster est lisible d'un coup d'œil, actionnable en un clic.** La
   ligne condensée montre qui existe, son rôle, et son statut d'incertitude
   (🔒 période d'essai). Le clic ouvre un mini-popover d'actions (1:1,
   licencier) — le licenciement garde sa confirmation, mais n'exige plus
   d'ouvrir un overlay puis de scroller.
3. **La revue de board est évaluée en continu.** Les conditions
   (`boardObjectives`) sont déjà de la donnée ; les afficher avec ✓/✗ live
   répond à « comprendre ce qu'il faut prioriser » sans rien ajouter à la
   simulation.

### 4.3 Comportement par phase

| Phase | Comportement du panneau |
|---|---|
| Inbox | Visible, preview active sur les choix d'événement (mêmes chips que §5) |
| Roadmap | Visible, preview sur les features ; la ligne ÉQUIPE affiche le compteur de points du panier en Phase C |
| Investissements | Visible, c'est son écran de gloire (preview + impulsion d'achat) |
| Résolution | Visible et **c'est lui qui s'anime** : les tweens de jauge de la Résolution jouent dans le panneau, le centre de l'écran garde le journal (revenu, masse salariale, verdicts) |

- **Repliable en rail** (~56 px, icônes + valeurs) pour les petites fenêtres
  ou les joueurs qui veulent l'écran entier ; état mémorisé. Jamais fermé.
- **Note technique Godot :** à court terme, le panneau est un composant
  (`side_panel.tscn`) instancié par chaque écran comme
  `build_resource_bar()` aujourd'hui — reconstruit à chaque changement de
  scène, sans état à préserver puisque tout vit dans `SprintState`. À moyen
  terme, si on veut des animations de panneau *à travers* les changements de
  phase (une jauge qui finit son tween pendant la transition), il faudra
  basculer vers une scène de sprint unique dont le contenu central change —
  chantier séparé, pas un prérequis.

### 4.4 Ce que devient le panneau Entreprise actuel

Il reste, **allégé, comme « Dossier entreprise »** — la lecture longue et les
actions rares :

| Reste dans le Dossier (overlay) | Migre vers le Panneau de bord |
|---|---|
| Description RP, accroche, scénario, modèle éco détaillé | Ressources, pièces, effectif |
| Objectifs de board commentés + verdict passé | Rappel live des conditions |
| 🏛️ Négocier une rallonge (action rare, à réfléchir) | Roster condensé + 1:1/licencier |
| Sections Pilotage (burn down, comptes) | Chips Actifs (décisions, pratiques) |
| Roster détaillé (traits complets, historique) | — |

Règle de partage : **le panneau répond à « où j'en suis », le dossier à
« dans quoi je joue »**. Ce qu'on consulte à chaque décision est permanent ;
ce qu'on lit une fois par mandat est derrière un clic.

---

## 5. C — Ressentir ses achats : preview, impulsion, engagement

Trois moments, trois mécanismes. La règle de partage avec la Résolution est
posée d'abord, parce que c'est elle qui protège la dramaturgie existante :

> **Ce que le joueur décide se voit immédiatement. Ce que la simulation lui
> fait reste révélé à la Résolution.** Deltas d'un achat/activation/embauche :
> immédiats. Revenu, masse salariale, décroissance du marché, traits cachés,
> conséquences d'événements : à la Résolution, comme aujourd'hui.

### 5.1 La preview au survol — l'intention

Au survol d'une carte d'Actif (ou de son bouton d'action) :

- Sur chaque jauge concernée du panneau : un **segment fantôme** (hachuré,
  pulsation lente) entre la valeur actuelle et la valeur projetée, plus une
  **chip de delta** (`+8` verte / `−4` rouge) alignée sur la jauge.
- Les jauges non concernées s'estompent légèrement — l'œil va où l'effet va.
- **L'inconnu est montré comme inconnu** : un candidat au trait caché non
  révélé affiche une chip `❓` scintillante sur les jauges potentiellement
  touchées. La preview dit « ici, vous pariez » — et vend le 1:1 au passage.
- **Les seuils parlent** : si la projection franchit un seuil connu, la chip
  gagne un ⚠️ et une ligne de conséquence : « 🫶 → 28 : sous 30, votre
  régénération d'⚡ tombe à zéro ». C'est ça, « comprendre l'impact » — pas
  le chiffre, la conséquence.
- Coûts compris : la chip 🪙 sur la ligne pièces, le salaire récurrent en
  sous-texte (« −2 💰/sprint, chaque sprint »).

### 5.2 L'impulsion à l'achat — l'acte

Au clic sur Activer / Embaucher / Adopter :

1. La **chip de delta vole de la carte vers sa jauge** (200 ms, courbe
   sortante) — le lien cause→effet est un trajet visible.
2. La **jauge se remplit/se vide en tween immédiat** (300 ms), avec un léger
   punch d'échelle sur la valeur. Les pièces se décomptent en roulement.
3. La carte est **tamponnée** (« ACTIVÉE », « EMBAUCHÉ·E », « ADOPTÉE ») avec
   un impact franc — voir §6, le tampon est le feedback d'acquisition commun
   aux quatre pistes de DA.
4. Pour une embauche : la ligne apparaît dans ÉQUIPE avec un slide-in, le
   compteur d'effectif et la masse salariale se mettent à jour.
5. Un tick sonore par type d'Actif (à définir avec la DA).

### 5.3 L'engagement — lisible jusqu'à la Résolution

Après l'acte, la jauge affiche la **valeur projetée**, avec un petit
**marqueur d'origine** (▲ discret à l'ancienne valeur) et un liseré
« engagé ce sprint ». Le joueur lit d'un coup d'œil : où j'étais, ce que
*mes* décisions ont déjà déplacé, et il sait que la Résolution ajoutera ce
que le sprint *lui* fait (revenu, salaires, marché).

Deux options d'implémentation, à trancher :

- **Option 1 — projection visuelle (recommandée)** : mécaniquement rien ne
  change (`add_pending()` s'applique toujours à la Résolution), le panneau
  affiche `valeur + somme des pendings de décision`. Zéro risque sur l'ordre
  d'application carte → employé → époque, et la Résolution reste l'unique
  point d'application. Le marqueur d'origine rend le montage honnête.
- **Option 2 — application immédiate** : les deltas de décision sont
  réellement appliqués à l'achat. Plus simple à lire, mais change la
  sémantique de la Résolution et le calcul des seuils de fin (une jauge
  peut-elle déclencher une fin en pleine phase Investissements ?). Déconseillé sans
  passage par les smoke tests.

---

## 6. D — Direction artistique : 4 pistes

Les quatre pistes habillent **le même écran** (Investissements + Panneau de
bord) — c'est ce que montre la maquette interactive, style commutable. Le
texte du jeu (taglines, traits, badges) est déjà la moitié de la DA : toutes
les pistes doivent le laisser respirer.

### Piste 1 — « Post-it & Feutre » *(demandée — fausse 3D pixel art, tableau blanc)*

**Le monde :** l'openspace d'une boîte en transformation agile. Le fond est
un tableau blanc (traces de feutre mal effacées, aimants) ; les cartes
d'Actif sont des objets physiques posés dessus en fausse 3D pixel art —
légère rotation, ombre portée, scotch ou aimant :

- 👤 Candidat = **badge d'accès** avec portrait pixel et trou de lanière ;
- ✨ Pratique = **post-it** jaune, écriture feutre ;
- 🃏 Grande décision = **fiche cartonnée A5** aimantée, réf au tampon ;
- L'étal du sprint = une zone « cette semaine » entourée au feutre.

**Le Panneau de bord y est diégétique : l'écran TV du standup**, accroché à
droite du tableau — un dashboard sombre dans un monde clair. C'est
l'hybridation recommandée : le monde tactile en pixel art, les données sur un
écran d'écran, lisibles et animables proprement (la preview hachurée sur du
post-it serait illisible ; sur la TV, elle est naturelle).

**Feedback d'achat :** tamponner la fiche, coller le badge sur le tableau
d'équipe, arracher le post-it — les gestes physiques existent déjà dans ce
monde.

- ✅ Cohérence thème maximale (on joue *la* transformation agile), chaleur,
  identité forte en screenshot, gestes d'acquisition naturels.
- ⚠️ Coût d'assets le plus élevé (pixel art : cartes, portraits, props,
  états) ; densité d'information à surveiller (6 jauges + roster + 9 cartes) ;
  la lisibilité des chiffres impose l'hybridation écran-TV ; le texte long
  français sur du post-it demande une vraie police feutre lisible.

### Piste 2 — « Console de pilotage » *(dashboard SaaS sombre, minimal)*

**Le monde :** on pilote une boîte SaaS depuis un SaaS. Extension assumée de
l'existant (fond sombre, Space Grotesk, IBM Plex Mono) : panneaux plats,
bordures fines, chiffres en mono tabulaire, états colorés sobres. Les cartes
d'Actif sont des rows/tiles d'un back-office ; l'ironie est que l'outil est
propre pendant que l'organisation brûle.

- ✅ Coût quasi nul (assets et helpers actuels réutilisés), lisibilité
  maximale, preview/deltas natifs dans ce langage, livrable vite — c'est la
  piste « on converge cette semaine ».
- ⚠️ Froid, générique (ressemble à Linear/Grafana — se distingue mal en
  screenshot), tout l'humour repose sur le texte, feedback émotionnel faible :
  un tween de barre n'a pas le poids d'un tampon.

### Piste 3 — « Presse business » *(illustré/éditorial façon presse éco)*

**Le monde :** le mandat raconté par la presse. Papier crème, serif à
l'ancienne, filets typographiques ; les candidats sont des **petites
annonces encadrées**, les pratiques des **encarts publicitaires** («
Adoptez la Discovery ! »), les décisions des **manchettes**. Les deltas
s'écrivent en cotations (▲ +8 / ▼ −4) ; le Panneau de bord est la colonne
« Marchés » du quotidien ; la Résolution devient **la une du journal
interne** — l'idée la plus forte de la piste.

- ✅ Épouse parfaitement le ton satirique de l'écriture, screenshots très
  mémorables, la Résolution-journal est un moment de game feel offert.
- ⚠️ Illustration coûteuse (portraits gravure/caricature), l'UI dense se
  plie mal à la métaphore (un journal ne se survole pas), preview live
  moins naturelle sur du papier ; risque de kitsch si à moitié exécuté.

### Piste 4 — « Mémo corpo » *(néo-brutalisme document interne détourné)*

**Le monde :** la bureaucratie elle-même. Blanc cassé, noir, filets épais,
typo utilitaire ; chaque Actif est **littéralement un document** : dossier de
candidature (candidat), note de service (pratique), ordre de mission à
contresigner (décision). Références de formulaire partout (« PRD-014 »,
déjà dans `cards.json` !), cases à cocher, surligneur jaune, agrafes. Le
Panneau de bord est une **fiche de suivi** épinglée. L'acquisition = un
**tampon rouge** qui claque (APPROUVÉ / RECRUTÉ·E / EN VIGUEUR).

- ✅ L'objet unifié devient littéral (tout est de la paperasse — la
  grammaire d'interaction *est* le thème), coût d'assets très faible
  (typographie + 3 tampons + textures légères), le tampon est le meilleur
  feedback d'achat des quatre pistes, satire froide très raccord.
- ⚠️ Austère (12 sprints de formulaires, il faut des respirations), palette
  contrainte, moins « jeu » au premier regard, le pixel art des avatars
  actuels n'y a pas sa place (photos d'identité tramées à produire).

### Comparatif

| Critère | 1. Post-it & Feutre | 2. Console | 3. Presse | 4. Mémo corpo |
|---|---|---|---|---|
| Lisibilité des données | ◐ (via écran-TV) | ● | ◐ | ● |
| Coût de production d'assets | ✗ élevé | ● quasi nul | ✗ élevé | ◐ faible |
| Cohérence thème (transfo agile) | ● | ◐ | ● | ● |
| Identité / mémorabilité | ● | ✗ | ● | ◐ |
| Compatibilité feedback live (§5) | ◐ | ● | ✗ | ● |
| Extensible aux autres époques | ◐ (re-skin lourd) | ● | ◐ | ● (le doc traverse les époques) |

### Recommandation

**Piste 1 « Post-it & Feutre », hybridée, comme direction cible — avec la
piste 4 comme plan B économique, et des emprunts assumés entre les deux.**

Concrètement :

1. Le **monde de jeu** (rayons des Investissements, cartes, Roadmap, Inbox) en tableau
   blanc / post-it / fausse 3D pixel art — c'est l'identité, et c'est là que
   le thème « transformation agile » paie le plus.
2. Le **Panneau de bord** en écran de standup sombre (langage de la piste 2)
   — diégétique dans l'openspace, et il garantit la lisibilité des jauges et
   la netteté de la preview d'impact.
3. Le **tampon** de la piste 4 comme feedback d'acquisition universel — un
   tampon sur un post-it ou une fiche cartonnée fonctionne parfaitement dans
   le monde 1.
4. Si le coût pixel art s'avère trop lourd pour converger vite : **basculer
   sur la piste 4** (Mémo corpo), qui partage le tampon, les fiches et la
   référence de formulaire, et dont 80 % se fait en typographie et
   StyleBox — la migration 4 → 1 plus tard reste possible puisque la
   structure d'écran est identique.

La maquette permet de comparer les quatre sur pièce — c'est à Camille de
trancher.

---

## 7. Récapitulatif des arbitrages proposés et questions à trancher

**Proposé (à valider) :**
1. Un type d'objet unifié, **l'Actif**, servi par un composant carte unique à
   six zones (§2.2), pensé pour accueillir les features/epics de la Phase C.
2. Fusion des phases 3 et 4 en un écran **Investissements** à deux rayons (étal du
   sprint + grandes décisions) ; le flux passe à 4 phases.
3. Un **Panneau de bord** permanent à droite (jauges en barres, roster
   condensé actionnable, actifs, revue de board live), repliable en rail ;
   la barre de ressources horizontale disparaît ; l'overlay Entreprise
   devient un « Dossier » de lecture longue.
4. Feedback en trois temps : **preview fantôme au survol** (avec inconnues ❓
   et alertes de seuil), **impulsion animée à l'achat** (chip volante, tween,
   tampon), **projection engagée** jusqu'à la Résolution (option 1 : purement
   visuelle, la mécanique d'application ne change pas).
5. DA : **Post-it & Feutre hybridé** (monde tactile + panneau-écran + tampon),
   plan B **Mémo corpo**.

**Questions ouvertes pour Camille :**
- Le nom joueur des choses : « Actif » est-il le bon mot à l'écran (section
  du panneau), ou reste-t-il purement interne ?
- ~~L'écran fusionné garde-t-il le nom « Marché » ?~~ **Tranché le 30/07/2026 :
  « Investissements »** (voir l'encadré du §3).
- La Rallonge reste-t-elle dans le Dossier, ou mérite-t-elle un bouton dans
  la section VOUS du panneau (plus visible = plus tentante = plus de
  tension) ?
- Preview d'impact : montre-t-on la valeur projetée exacte, ou une fourchette
  quand des modificateurs cachés existent (plus honnête, plus illisible) ?
- Option 1 vs option 2 pour l'application des deltas (§5.3) — l'option 1 est
  recommandée, mais c'est une décision de game design, pas d'UI.
- Le rail replié : les jauges y gardent-elles leurs chips de preview
  (minuscules), ou le survol d'une carte déplie-t-il temporairement le
  panneau ?
