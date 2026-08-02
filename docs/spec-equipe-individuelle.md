# Spec — L'équipe n'est pas une jauge, ce sont des gens

**Statut : proposition, en attente de relecture.** Rien de ce document n'est
implémenté. Écrit le 02/08/2026, à partir de la question de Camille sur la
PR #40, dans la foulée de
[`spec-clients-revenue.md`](spec-clients-revenue.md).

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
| 🤝 **Confiance** *(envers vous)* | Décisions annulées, promesses non tenues, licenciements, pivots non expliqués | 1:1, tenir une ligne sur plusieurs sprints, décisions cohérentes | **Rupture** — la personne reste mais cesse de contribuer (facteur de contribution à zéro) |
| ⚡ **Énergie** | Points livrés au-dessus de la capacité, sprints d'affilée sans répit | Sprints sous-chargés, congés, remise à plat | **Burn-out** — arrêt, la personne quitte le roster pour de bon |
| 💸 **Satisfaction salariale** | Ancienneté sans promotion, séniorité mal payée, voir arriver une recrue mieux payée | Promotion, augmentation | **Démission pour l'extérieur** — elle part chez le concurrent |

Les quatre passent le test : on peut aimer son travail et ne pas croire son CPO
(Moral haut, Confiance basse) ; être payé correctement et épuisé (Salaire haut,
Énergie basse). Ils ne bougent ni pour les mêmes raisons ni avec les mêmes
remèdes.

**Il n'y en aura pas un cinquième.** Chaque critère ajouté multiplie le contenu
à écrire et la surface d'affichage ; quatre est déjà le maximum lisible sur une
ligne de roster.

### 3.1 Le joueur est une personne comme les autres

Le CPO porte **les mêmes quatre niveaux**. C'est la façon élégante de ne pas
dupliquer l'Énergie : aujourd'hui ⚡ est une jauge à part avec sa propre fin
(`burnout-fondateur`) et sa propre régénération modulée par le Moral d'équipe.
Demain c'est la même règle appliquée à la ligne « Vous » du roster — et
`burnout-fondateur` devient le cas particulier d'une règle générale, au lieu
d'un système parallèle.

Une conséquence agréable : votre Confiance n'existe pas (vous ne pouvez pas
vous décevoir vous-même), mais votre **Satisfaction salariale**, oui. Un CPO
sous-payé qui fait tourner la boîte est un ressort qu'on n'avait pas.

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
| 📈 Valeur perçue | **Reste.** C'est le marché. |
| ⚡ Énergie du joueur | **Descend**, comme un critère de la ligne « Vous » (§3.1). |

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

1. **Le Moral d'entreprise est-il une moyenne ou un minimum ?** La moyenne
   lisse : une personne au fond se voit peu. Le minimum dramatise : un seul
   employé à bout fait s'effondrer les frictions du score. Recommandation :
   moyenne pondérée par la contribution, **plus** une alerte dédiée sur le
   minimum — l'un pour le moteur, l'autre pour l'œil.
2. **Le départ pour Confiance à 0 : la personne part, ou reste sans
   contribuer ?** « Reste et ne produit plus » est plus cruel et plus vrai
   (c'est la démission silencieuse au sens propre), mais occupe un poste sans
   qu'on comprenne pourquoi. Recommandation : elle reste, **et l'alerte le
   dit** — c'est au joueur de licencier ou de réparer.
3. **Combien de niveaux affiche-t-on par défaut ?** Zéro (alertes seules),
   ou un état de synthèse par personne ? Recommandation : un point de couleur
   par personne, les chiffres au clic.
4. **Les nouvelles recrues arrivent-elles à 100 partout ?** Probablement pas :
   une recrue arrive avec un Moral élevé et une Confiance neutre — elle ne vous
   connaît pas encore. Ça donne du sens à la période d'essai.
5. **Est-ce que ça remplace le Cynisme ?** Le Cynisme ressemble à « la Confiance
   moyenne, inversée ». À vérifier au moment d'écrire : si les deux bougent
   toujours ensemble, il faut en supprimer un.

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
