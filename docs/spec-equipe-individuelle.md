# Spec — L'équipe n'est pas une jauge, ce sont des gens

**Statut : implémenté — issue #43, carnet §36.** Écrit à partir de la
question de Camille sur la PR #40, puis tranché avec elle point par point (les
décisions sont datées dans le texte). À séquencer **après**
[`spec-clients-revenue.md`](spec-clients-revenue.md) — voir §9.

C'est **le même mouvement appliqué à l'autre côté du plateau** : là où une
grandeur abstraite ne raconte rien, on descend d'un cran vers ce qu'elle cache.
Le Revenue cachait des clients ; le Moral cache des personnes.

---

## 1. La demande

> *« Pour chaque employé on devrait avoir un niveau de moral, de confiance
> (envers le joueur), d'énergie, satisfaction de salaire et peut-être autre
> chose ? Comme ça ce ne serait pas des indicateurs abstraits au niveau de
> l'interface mais plutôt une vue combinée. Et ce sera beaucoup plus simple pour
> la gestion des effets des différents items, events, etc. On va agir au facteur
> le plus bas directement. Pareil si un employé atteint 0 sur un critère il va
> partir en burn-out ou autre. »*

---

## 2. Ce que ça change, en une phrase

> **Le Moral cesse d'être une valeur stockée pour devenir la vue combinée de
> l'état réel des personnes.**

`Moral 42` ne dit rien et ne se joue pas. *« Marek est à 12 de confiance depuis
que vous avez annulé son chantier ; il cherche ailleurs »* est une information,
une histoire et une décision — les trois d'un coup.

---

## 3. Les quatre critères

Chaque personne du roster porte quatre niveaux 0-100. Le test qui décide si un
critère mérite d'exister : **une cause distincte et un remède distinct**. Deux
critères qui montent et descendent ensemble sont un seul critère avec deux noms
— c'est exactement le piège qu'on vient d'éviter côté monnaies.

| Critère | Ce qui le fait baisser | Ce qui le remonte | Ce qu'il produit à 0 |
|---|---|---|---|
| 🫶 **Moral** | Surchauffe de sprint, dette subie, trimestre manqué, départs autour de soi | Séminaire, sprints tenus, livraisons réussies | **Démission** — la personne s'en va |
| 🤝 **Confiance** *(envers vous)* | Décisions annulées, promesses non tenues, licenciements, pivots non expliqués | 1:1, tenir une ligne sur plusieurs sprints, décisions cohérentes | **Rupture** — un événement Inbox vous met devant le cas (§3.3) |
| ⚡ **Énergie** | Points livrés au-dessus de la capacité, sprints d'affilée sans répit | Sprints sous-chargés, congés, remise à plat | **Burn-out** — arrêt, la personne quitte le roster pour de bon |
| 💸 **Satisfaction salariale** | Ancienneté sans promotion, séniorité mal payée, voir arriver une recrue mieux payée | Promotion, augmentation | **Démission pour l'extérieur** — elle part chez le concurrent |

Les quatre passent le test : on peut aimer son travail et ne pas croire son CPO
(Moral haut, Confiance basse) ; être payé correctement et épuisé (Salaire haut,
Énergie basse). Ils ne bougent ni pour les mêmes raisons ni avec les mêmes
remèdes.

**Il n'y en aura pas un cinquième.** Chaque critère ajouté multiplie le contenu
à écrire et la surface d'affichage ; quatre est déjà le maximum lisible sur une
ligne de roster.

### 3.1 La Confiance est le troisième sommet du triangle

*Décision du 02/08/2026, prise avec `spec-clients-revenue.md` §5.1.1.*

Trois entités perçoivent quelque chose dans ce jeu, et **il ne faut jamais les
mélanger** — c'est un mot employé pour deux choses qui avait laissé s'installer
la fuite `Impact → Valeur perçue → Revenue` :

| Qui perçoit | Quoi | La grandeur |
|---|---|---|
| Les **utilisateurs** | le produit | 📈 Valeur perçue *(à renommer Réputation produit)* |
| Le **board** | le joueur | 🎯 Capital politique |
| L'**équipe** | le joueur | 🤝 **Confiance** — cette spec |

La Confiance n'est donc pas un critère de plus : c'est **la moitié manquante de
la perception du joueur**. Le board a toujours eu la sienne (le Capital
politique) ; l'équipe n'avait rien, et son jugement était noyé dans un Moral qui
mesurait autre chose. Deux conséquences :

- **Le Moral ne juge plus personne.** Il mesure ce que l'équipe *vit* (charge,
  dette, échecs), pas ce qu'elle *pense de vous*. C'est ce qui rend les deux
  critères réellement distincts au lieu de bouger ensemble.
- **Ce que le produit vaut n'a rien à voir avec ce que vous valez.** Une équipe
  peut vous faire confiance en livrant un produit que le marché ignore, et
  l'inverse.

### 3.2 Le joueur est une personne comme les autres

Le CPO porte **les mêmes quatre niveaux**. C'est la façon élégante de ne pas
dupliquer l'Énergie : aujourd'hui ⚡ est une jauge à part avec sa propre fin
(`burnout-fondateur`) et sa propre régénération modulée par le Moral d'équipe.
Demain c'est la même règle appliquée à la ligne « Vous » du roster — et
`burnout-fondateur` devient le cas particulier d'une règle générale, au lieu
d'un système parallèle.

Une conséquence agréable : votre Confiance n'existe pas (vous ne pouvez pas
vous décevoir vous-même), mais votre **Satisfaction salariale**, oui. Un CPO
sous-payé qui fait tourner la boîte est un ressort qu'on n'avait pas.

### 3.3 Une rupture n'est pas un état, c'est une scène

*Décision du 02/08/2026.*

Quand la Confiance de quelqu'un touche zéro, la personne **reste et cesse de
contribuer** — mais ça ne se produit pas en silence dans un coin du panneau. Ça
**déclenche un événement Inbox** qui vous met devant le cas, avec une décision
à prendre :

> **Marek ne dit plus rien en réunion.**
> Trois sprints qu'il livre le minimum et qu'il regarde ailleurs.
> · Lui donner un vrai sujet — coûte de la capacité ce sprint, remonte sa Confiance
> · Le recadrer — remonte sa contribution, coûte du Moral à toute l'équipe
> · Laisser filer — ne coûte rien maintenant, et il partira

C'est ce qui transforme un état passif en moment de jeu. Le reproche qu'on
pouvait faire à « reste et ne produit plus » — un poste occupé sans qu'on
comprenne pourquoi — tombe : on comprend, on a le choix, et on paie ce choix.

Même principe pour les autres seuils : un burn-out imminent, une démission
salariale annoncée sont des scènes, pas des lignes de journal.

### 3.4 Chaque personne a un caractère

*Décision du 02/08/2026.*

Les quatre niveaux ne suffisent pas : deux personnes dans la même situation
doivent réagir différemment, sinon le roster est une rangée de clones avec des
prénoms. **Chaque employé porte une personnalité**, qui se traduit
mécaniquement par deux choses et deux seulement :

1. **Des niveaux de départ décalés** — l'idéaliste arrive avec une Confiance
   haute, le mercenaire avec une Confiance basse et une exigence salariale
   forte.
2. **Des facteurs d'influence** — de combien chaque événement déplace chacun de
   ses niveaux. Le même licenciement coûte 30 de Confiance à l'idéaliste et 5
   au vétéran désabusé, qui en a vu d'autres.

```json
{ "id": "veteran-desabuse",
  "depart":    { "moral": 55, "confiance": 40, "energie": 70, "salaire": 60 },
  "influence": { "moral": 0.6, "confiance": 0.4, "energie": 1.0, "salaire": 1.2 } }
```

Rien d'autre. Une personnalité n'ajoute **pas** de règle spéciale, pas d'effet
scripté, pas de condition : c'est un jeu de curseurs sur des mécaniques qui
existent déjà. C'est ce qui permet d'en avoir huit sans que le contenu
explose.

`data/recruitment-archetypes.json` contient déjà cinq caractères écrits en
prose — ex-consultant, rockstar 10x, junior ambitieux, vétéran désabusé,
wonderkid — dont le README note qu'ils « restent illustratifs ». Ils cessent de
l'être : la description devient la promesse, les deux tables ci-dessus
deviennent la mécanique.

**La personnalité est une information cachée**, comme le reste : on la devine
aux réactions, le 🤝 1:1 la révèle. C'est ce qui donne au recrutement son pari
— cette senior est-elle solide ou cassante ? — et au 1:1 sa raison d'exister
au-delà du premier sprint.

---

## 4. Ce qui descend d'un niveau — et ce qui reste en haut

C'est le point de périmètre, et il évite que la proposition devienne une
réécriture du jeu.

| Jauge actuelle | Devient |
|---|---|
| 🫶 **Moral** | **Descend.** Vue calculée sur les personnes — moyenne pondérée par la contribution. |
| 🧱 Dette organisationnelle | **Reste.** C'est l'état du système, pas un sentiment. |
| 🎭 Cynisme | **Reste.** C'est la culture de l'organisation, pas d'un individu. |
| 🎯 Capital politique | **Reste.** C'est le vôtre, face au board. |
| 📈 Valeur perçue | **Reste**, mais se recentre sur le produit — c'est ce que les *utilisateurs* en pensent, jamais ce qu'on pense de vous (§3.1). |
| ⚡ Énergie du joueur | **Descend**, comme un critère de la ligne « Vous » (§3.2). |

**Une seule des cinq jauges descend.** Le reste du moteur continue de lire
`moral` — mais à travers un point d'entrée unique (`get_team_moral()`) qui
calcule au lieu de stocker. Sans ça, il faudrait rouvrir le ScoreResolver (cap
de Levier au Moral bas), le churn (`lowMoralDebt`), la régénération d'Énergie et
les fins. Avec, aucun de ces quatre appelants ne bouge.

---

## 5. Ce que ça simplifie vraiment : l'écriture du contenu

C'est l'argument principal de la demande, et il est juste. Aujourd'hui un
événement dit `"moral": -6` — six points sur une moyenne d'entreprise, dont
personne ne sait ce qu'ils représentent. Demain il dit **qui** il touche et
**sur quoi** :

```json
{ "cible": "un-dev-au-hasard", "confiance": -25,
  "reveal": "Vous annulez le chantier de Marek en réunion. Il n'a rien dit." }
```

### 5.1 La grammaire de ciblage

Elle doit rester **courte et fermée**, sinon chaque contenu devient un cas
particulier :

| Cible | Sens |
|---|---|
| `tous` | tout le roster |
| `un-au-hasard` | une personne tirée |
| `role:dev` | tous les porteurs d'un rôle |
| `seniorite:junior` | tous les juniors |
| `le-plus-ancien` · `le-mieux-paye` · `le-plus-fragile` | une sélection déterministe et lisible |
| `vous` | le joueur |

Six formes couvrent tout ce que le catalogue actuel exprime, et permettent des
effets qu'on ne sait pas écrire aujourd'hui — « la personne qui a livré le plus
ce sprint », « celle que vous avez recrutée en dernier ».

### 5.2 Les traits cachés deviennent des dérives, pas des coups

Aujourd'hui un trait produit un effet ponctuel (`moralPerSprint: -1`,
`quitsAtHiredPlus: 4`). Demain il **modifie la façon dont les niveaux bougent**
— ce qui est à la fois plus simple à écrire et plus intéressant à jouer :

| Trait | Aujourd'hui | Demain |
|---|---|---|
| Râleur d'open-space | −1 Moral d'entreprise par sprint | son Moral baisse deux fois plus vite, **et contamine ses voisins de rôle** |
| Mentor | +1 Moral par sprint | remonte le Moral des juniors autour de lui |
| Fantôme | contribution ×0,5 | sa Confiance ne bouge jamais : rien ne l'atteint |
| Démission silencieuse | part au sprint N+4 | part dès qu'un critère passe sous 20, sans jamais alerter |

---

## 6. Les trois pièges

### 6.1 Vingt-huit nombres à surveiller

Sept personnes × quatre critères, c'est l'inverse de « une seule grandeur au
centre » (question 2 de la vision). **Le joueur ne lit jamais vingt-huit
nombres.**

La règle d'affichage, la même que pour les six jauges de
`spec-impact-monnaie.md` §8 : **on ne montre que ce qui pose problème.** Le
panneau affiche une ligne par personne avec un seul état de synthèse (aucune
barre tant que tout va bien), et fait remonter uniquement les alertes :

```
ÉQUIPE  7 personnes · 2 alertes
  Marek      🤝 12  cherche ailleurs
  Danielle   ⚡ 18  deux sprints en surchauffe
  Hervé · Solange · Patrice · Lina · Nadia      —
```

Le détail des quatre niveaux d'une personne s'ouvre au clic, là où le mini-menu
d'actions existe déjà.

### 6.2 Un départ ne doit jamais surprendre

Un employé qui disparaît sans prévenir est frustrant, pas difficile. Chaque
critère a donc **deux seuils** : un seuil d'alerte (le panneau le signale, on a
le temps d'agir) et le seuil de départ. La « démission silencieuse » reste
l'unique trait qui saute l'alerte — c'est ce qui fait sa valeur.

### 6.3 Le coût réel est dans le contenu

Le moteur est simple : quatre nombres par personne, une table de dérive par
sprint, une grammaire de ciblage. **Ce qui coûte, c'est de réécrire les effets
de tout le catalogue** — cartes, événements, features, postes du Comité — pour
qu'ils ciblent des gens au lieu d'une moyenne. C'est le vrai périmètre du lot,
et il ne faut pas le sous-estimer sous prétexte que le moteur tient en une page.

---

## 7. Ce que ça débloque

- **Le recrutement devient un choix de personne**, pas une ligne de capacité :
  cette senior est chère et exigeante, ce junior est enthousiaste et fragile.
- **Le licenciement devient lisible** : on voit ce qu'il fait à la Confiance des
  autres, personne par personne, au lieu d'un −4 global.
- **Le 1:1 devient l'action la plus intéressante du jeu** : aujourd'hui il
  révèle un trait caché une fois. Demain il remonte la Confiance de quelqu'un —
  et l'Énergie du joueur devient le budget d'attention qu'on répartit entre des
  gens.
- **Les fins gagnent des visages** : l'exode d'équipe n'est plus un seuil, c'est
  la troisième démission d'affilée.

---

## 8. Ce qui reste à trancher

1. ~~Le Moral d'entreprise : moyenne ou minimum ?~~ **Tranché** (02/08) :
   moyenne pondérée par la contribution pour le moteur, **plus** une alerte
   dédiée sur le minimum pour l'œil. L'un ne remplace pas l'autre.
2. ~~Confiance à 0 : la personne part ou reste ?~~ **Tranché** (02/08) : elle
   reste et cesse de contribuer, **et un événement Inbox vous met devant le
   cas** — voir §3.3. Un état passif devient une scène jouable.
3. ~~Combien de niveaux affiche-t-on par défaut ?~~ **Tranché** (02/08) : un
   point de couleur par personne, les chiffres au clic, et seulement les
   alertes en clair (§6.1).
4. ~~Les recrues arrivent-elles à 100 partout ?~~ **Tranché** (02/08) : non, et
   **leurs niveaux de départ dépendent de leur caractère** — voir §3.4.
5. ~~Est-ce que ça remplace le Cynisme ?~~ **Tranché** (02/08) : non, les deux
   survivent. Le Cynisme est ce que l'organisation pense des **méthodes**
   (« encore un process »), la Confiance ce que les gens pensent de **vous** —
   une équipe peut vous croire et railler la énième rétrospective. **À
   revérifier en écrivant les effets** : si les deux finissent par bouger
   ensemble sur tout le catalogue, il faudra en supprimer un.

**Il ne reste donc aucune décision de conception ouverte sur ce document.** Ce
qui reste est du calibrage : les valeurs de départ et les facteurs d'influence
des huit caractères, et les seuils d'alerte de chaque critère.

---

## 9. Séquencement

Ce chantier et [`spec-clients-revenue.md`](spec-clients-revenue.md) sont le même
geste appliqué aux deux côtés du plateau, mais **ils ne se bloquent pas**. Celui
des clients touche l'économie et le catalogue de features ; celui-ci touche
l'équipe et le catalogue d'événements. Ils peuvent se faire dans n'importe quel
ordre — mais **pas en même temps** : les deux réécrivent des effets de contenu,
et une PR qui fait les deux serait irrelisible.

Recommandation : **les clients d'abord**, parce que l'économie est déjà à
moitié ouverte par le lot A et que la règle d'indépendance des deux monnaies
reste fausse tant que ce n'est pas fait.
