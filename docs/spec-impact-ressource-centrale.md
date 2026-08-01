# Spec — L'Impact comme ressource centrale

**Statut : proposition, en attente de relecture.** Rien de ce document n'est
implémenté. Écrit dans la nuit du 31/07 au 01/08/2026, à la demande de
Camille, pendant le chantier scoring (lots 4 et 5).

Ce document se lit après [`spec-scoring-sprint.md`](spec-scoring-sprint.md),
dont il ne remet en cause ni la formule ni le phasage : il ne touche qu'au
**statut** de l'Impact dans le jeu — ce qu'on en voit, ce qu'on en garde, et
ce qu'on en fait quand on en produit beaucoup.

---

## 1. La demande

> *« Rendre l'Impact une ressource centrale du jeu : visible depuis le début,
> avec des objectifs visibles et clairs de bout en bout, et qu'on puisse
> dépasser dans les objectifs de trimestre. Comme cela va devenir la money,
> il ne faut pas limiter. »*

Quatre exigences distinctes, qui ne coûtent pas le même prix :

1. **Centralité** — l'Impact cesse d'être un résultat de fin de sprint pour
   devenir un objet qu'on suit en permanence.
2. **Visibilité de bout en bout** — on voit les quatre quotas du mandat dès
   le premier sprint, pas seulement celui du trimestre en cours.
3. **Dépassement** — franchir un quota de loin doit valoir mieux que le
   franchir de justesse.
4. **Pas de limitation** — puisque l'Impact devient la monnaie, les plafonds
   qui l'écrasent sont à réexaminer.

---

## 2. L'état du code — ce qui a été vérifié, pas supposé

Le constat est plus sévère que la demande ne le laisse entendre. Trois
mécanismes distincts limitent aujourd'hui l'Impact, et deux sont invisibles.

**① Le surplus est détruit à chaque trimestre.**
`SprintState._prepare_quarter()` remet `quarter_impact = 0`
(`sprint_state.gd:349`), et le verdict est strictement binaire :
`passed = quarter_impact >= get_current_quota()` (ligne 1896). Terminer un
trimestre à 1051 ou à 3000 pour un quota de 1050 produit **exactement le
même état de jeu**. Tout ce qui dépasse est jeté sans trace, sans ligne de
journal, sans mention à l'écran.

**② La jauge est clampée au quota.**
`side_panel.gd:557` : `bar.value = clampi(impact, 0, target)`. Le dépassement
n'est pas seulement perdu mécaniquement — il est **invisible**. Un joueur qui
écrase son quota voit la même barre pleine qu'un joueur qui l'atteint au
point près. Rien dans l'écran ne lui apprend qu'il a fait mieux.

**③ La conversion en Budget est une racine carrée.**
`ScoreResolver._resolve_conversion()` : `Budget = floor(√Impact) + allocation`.
C'est un compresseur violent, et c'est le point le plus important de ce
document :

| Impact du sprint | Budget gagné | Impact ×4 → Budget ×… |
|---|---|---|
| 100 | 10 | — |
| 400 | 20 | ×2 |
| 1 600 | 40 | ×2 |
| 6 400 | 80 | ×2 |

**Quadrupler son Impact ne fait que doubler son pouvoir d'achat.** C'est,
mathématiquement, la limitation la plus forte du jeu — bien plus que le
plafond de trimestre. Elle est aussi la moins visible, parce qu'elle
n'apparaît nulle part comme une règle : elle est dans la forme de la courbe.

**④ Deux plafonds secondaires.** `conversion.perceivedValue.maxPerSprint = 6`
borne la Valeur perçue gagnée par sprint, et le Capital politique ne monte
que par paliers de 150 d'Impact.

**⑤ L'Impact n'est pas une ressource.** `data/resources.json` en déclare six
— Trésorerie, Moral, Dette organisationnelle, Capital politique, Valeur
perçue, Cynisme. L'Impact n'en fait pas partie : il n'a ni entrée de données,
ni jauge propre, ni bornes, ni direction. Il vit dans `last_score_report` et
dans `quarter_impact`, deux variables de travail.

**Ce qui, en revanche, ne manque pas :** les quotas des quatre trimestres
sont **déjà connus dès le premier sprint** — `quotas.json → careerLevels.pm.quarterQuotas = [120, 270, 560, 1050]`.
L'objectif « visible de bout en bout » ne demande donc **aucune donnée
nouvelle**, seulement de l'afficher.

---

## 3. Ce qui est proposé

### 3.1 L'Impact devient une septième entrée, mais pas une septième jauge

L'Impact ne doit **pas** rejoindre `resources.json`. Les six ressources
partagent une grammaire — bornées 0..100, une direction (monter est bon ou
mauvais), des seuils d'état, une friction. L'Impact n'a aucune de ces
propriétés : il n'est pas borné, il est cumulatif sur un trimestre, et il se
consomme en franchissant un quota. L'y forcer casserait le modèle d'effet
unifié (carnet §11) pour un gain cosmétique.

**Il devient à la place le bandeau permanent du Panneau de bord**, au-dessus
des six jauges : la seule quantité affichée en grand, avec son cumul
trimestriel, son objectif, et — c'est le point — **ce qu'il vaut en Budget**.
L'Impact est la monnaie : le joueur doit lire les deux nombres au même
endroit, tout le temps.

### 3.2 Le dépassement se garde, il ne se jette plus

**C'est le cœur de la demande, et le changement le moins cher.** À la clôture
d'un trimestre réussi, le surplus `quarter_impact − quota` n'est plus remis à
zéro. Trois destinations possibles, à trancher (§4.1) :

- **A — report** : le surplus s'ajoute au trimestre suivant. Simple, lisible,
  mais dangereux : un gros T1 pré-paye T2, et la difficulté s'effondre en
  cascade. Contre la ligne « le jeu doit être difficile ».
- **B — conversion en Budget** : le surplus est payé au Comité, au même taux
  que l'Impact de sprint. Récompense immédiate, sans toucher à la pression du
  quota suivant. **C'est ma recommandation.**
- **C — score de mandat** : le surplus alimente un score cumulé, affiché à la
  fin, qui ne sert qu'au classement et au déblocage. Zéro impact sur
  l'équilibrage, valeur de rejouabilité maximale, gratification différée.

B et C ne s'excluent pas : le surplus peut payer *et* compter au score final.
A me paraît à écarter, pour la raison ci-dessus.

### 3.3 Les objectifs, de bout en bout

Le Panneau de bord affiche **les quatre quotas du mandat en permanence**,
avec celui du trimestre en cours mis en avant et les suivants en retrait mais
lisibles. Un joueur doit pouvoir se dire au sprint 2 : *« le T4 demande 1050,
je suis sur un rythme de 90 par sprint, je ne passerai pas — il faut que je
change quelque chose maintenant. »* C'est exactement l'information qui manque
aujourd'hui, et elle est **déjà dans les données**.

Corollaire : la jauge de trimestre **cesse d'être clampée**. Au-delà de
100 %, elle continue, dans une teinte de dépassement. Voir son surplus
s'accumuler est la moitié du plaisir.

### 3.4 « Ne pas limiter » — ce que ça veut dire vraiment

Ici je dois signaler une tension, parce qu'elle ne se voit pas depuis
l'énoncé. **Le plafond qui limite réellement l'Impact n'est pas le quota,
c'est la racine carrée de la conversion en Budget.** Lever les plafonds de
trimestre sans toucher à `floor(√Impact)` ne changera presque rien au
sentiment de puissance : le joueur verra de plus gros nombres et achètera à
peu près autant de choses.

Trois options, à trancher (§4.2) :

- **A — garder la racine.** C'est un choix de design défendable et
  probablement volontaire : elle empêche l'emballement exponentiel d'un
  moteur à combos, où un run qui décolle décolle sans fin. C'est le
  garde-fou qui rend le jeu difficile en fin de mandat.
- **B — adoucir l'exposant** : `Budget = floor(Impact^0.6)` au lieu de
  `^0.5`. La progression reste sous-linéaire (pas d'emballement) mais
  quadrupler l'Impact rapporte ×2,3 au lieu de ×2. Réglage continu, pilotable
  depuis `scoring.json`, réversible. **Ma recommandation** — c'est le
  compromis qui répond à « ne pas limiter » sans casser le frein.
- **C — linéariser** : `Budget = Impact / k`. Répond littéralement à la
  demande, et fait très probablement exploser l'équilibrage du late game.

Dans tous les cas, **l'exposant doit vivre dans `data/scoring.json`**, pas
dans le code : c'est la règle du dépôt, et c'est ce qui permettra de trancher
au playtest plutôt que sur le papier.

---

## 4. Les points à trancher

### 4.1 Que devient le surplus de trimestre ?

Report (A), Budget (B), score de mandat (C), ou B+C. **Je recommande B+C** :
le surplus paie immédiatement au Comité *et* compte dans un score de fin de
mandat. On récompense sans dégrader la difficulté du trimestre suivant.

### 4.2 Jusqu'où « ne pas limiter » ?

Garder `√` (A), adoucir vers `^0.6` (B), linéariser (C). **Je recommande B.**
Mais c'est un arbitrage de game design qui t'appartient : la racine carrée
est peut-être exactement le frein que tu voulais, et dans ce cas la réponse à
« ne pas limiter » est ailleurs — dans la visibilité du dépassement (§3.3) et
dans le score de mandat (§4.1 C), pas dans la courbe.

### 4.3 Faut-il aussi lever `perceivedValue.maxPerSprint = 6` ?

Ce plafond existe pour empêcher un run qui décolle de saturer la Valeur
perçue en trois sprints. Il est cohérent avec « le jeu doit être difficile ».
**Je propose de le garder** et de ne traiter que la conversion en Budget —
mais il fait partie de la même famille de questions.

### 4.4 Quel niveau de carrière ?

Tout ce document raisonne à N=1 squad, niveau PM. Les quotas étant déjà
indexés par niveau de carrière (`quotas.careerLevels`), la table de
dépassement devra l'être aussi. À écrire dès le premier jet, une seule ligne
remplie — c'est le contrat d'architecture du `CLAUDE.md`.

---

## 5. Coût et séquencement

**Ce n'est pas un chantier cher, sauf sur un point.**

| Chantier | Coût | Risque |
|---|---|---|
| Dé-clamper la jauge, afficher le dépassement | très faible | nul |
| Afficher les 4 quotas de bout en bout | faible | nul — la donnée existe |
| Bandeau Impact + équivalent Budget | faible | nul |
| Garder le surplus (option B) | faible | faible |
| Score de mandat cumulé (option C) | moyen | faible — demande la persistance inter-runs, que le Lot 4 est en train de créer pour le Compendium |
| Changer l'exposant de conversion | **très faible en code** | **élevé en équilibrage** — touche toute la courbe économique du jeu |

**Séquencement proposé :** ce lot vient **après** les lots 4 et 5, pas à leur
place. Les points de §3.1 à §3.3 sont de la lecture et de l'affichage : ils
ne coûtent presque rien et se posent proprement sur l'existant. Le §3.4
(l'exposant) mérite d'être isolé dans son propre passage, parce que c'est le
seul qui demande un vrai playtest pour être jugé — et parce qu'il touche la
grandeur dont dépend tout le reste de l'économie.

Une remarque de dépendance : le **score de mandat cumulé** (§4.1 option C)
a besoin d'une persistance entre les runs. Le Lot 4 en crée une pour le
Compendium des synergies. Il n'y a rien à faire de plus aujourd'hui que de
s'assurer qu'elle reste générique — c'est déjà dans le brief du dev.
