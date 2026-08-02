# Spec — L'Impact comme monnaie unique

**Statut : proposition, en attente de relecture.** Rien de ce document n'est
implémenté. Écrit le 01/08/2026 après la discussion de conception qui suit la
livraison des lots 4 et 5 du chantier scoring.

Ce document **remplace** [`spec-impact-ressource-centrale.md`](spec-impact-ressource-centrale.md)
(PR #29), qui raisonnait encore avec les pièces et la conversion en racine
carrée. Il ne remet en cause ni la formule `Traction × Levier = Impact`, ni le
phasage de [`spec-scoring-sprint.md`](spec-scoring-sprint.md) — il change ce
qu'on fait de l'Impact une fois produit.

---

## 1. La demande

> *« Je voudrais quelque chose de simple et compréhensible. Le revenu de
> l'entreprise et l'impact du joueur. Le revenu évite la faillite. L'impact
> valorise les choix du joueur. Les deux doivent être illimités et être la
> money au cœur de l'expérience. Je dois pouvoir dépenser de l'impact pour
> acheter des choses. Là on a trop de valeurs, trop de tout, sans savoir ce qui
> est le plus important. »*

Le diagnostic est juste. Le jeu affiche aujourd'hui six ressources bornées, un
MRR, une trésorerie, des pièces, un Impact de trimestre et un Impact de sprint.
Dix grandeurs, aucune hiérarchie. Un joueur ne sait pas laquelle regarder.

---

## 2. Ce qui disparaît

| Ce qui existe | Ce que ça devient |
|---|---|
| 🪙 **Pièces** (`SprintState.pieces`) | **Supprimé.** L'Impact est la monnaie. |
| `Budget = floor(√Impact)` | **Supprimé.** Plus de conversion, donc plus d'exposant à régler. |
| **Trésorerie** (ressource 0..100) | Fusionnée dans le **Revenue**. |
| **MRR** (stock cumulatif) | Fusionné dans le **Revenue**. |
| `quarter_impact` remis à 0 (`_prepare_quarter`) | **Supprimé.** L'Impact se garde. |
| Jauge d'Impact clampée (`side_panel.gd:557`) | **Supprimé.** Plus de plafond d'affichage. |

La suppression de la racine carrée mérite d'être notée : c'était la vraie
limite du modèle, celle qui écrasait le moteur exactement au moment où il
devenait intéressant. La question « quel exposant ? » ne se pose plus — il n'y
a plus de conversion du tout.

---

## 3. Deux monnaies, deux rôles non interchangeables

### 💥 L'Impact — la performance du joueur

Un **portefeuille** qui s'accumule de sprint en sprint, sans plafond, jamais
remis à zéro. Il monte quand on produit (`Traction × Levier`), il descend quand
on achète au Comité. C'est **la** valeur du jeu : celle qu'on regarde, celle
qui est jugée, celle qu'on dépense.

### 💰 Le Revenue — la survie de l'entreprise

Le résultat de la fusion trésorerie + MRR : une valeur **sans plafond**, qui
paie à chaque sprint les salaires, les licences d'outils et les coûts récurrents
des décisions prises. Il tombe à zéro → l'entreprise ne paie plus → l'équipe
part → la production s'effondre.

### Pourquoi les deux ne se remplacent pas

C'est le cœur du dispositif, et c'est Camille qui l'a formulé :

> *« Si je dépense tout le cash de l'entreprise mais que je gagne quand même
> beaucoup d'impact, je ne pourrai pas scale les prochains tours. »*

On peut donc **mourir riche d'Impact et sans trésorerie**. Et surtout, ça donne
enfin son poids au recrutement : un employé de plus, c'est de la production
d'Impact en plus **et une charge fixe permanente**. Recruter juste avant un gros
objectif devient un pari, ce qui supprime la réponse « recruter est toujours
bon » — aujourd'hui vraie, et donc ennuyeuse.

### 3.1 Un prix en Impact, une charge en Revenue

**L'Impact est la seule monnaie d'achat**, au shop du sprint comme au Comité.
Le Revenue ne sert jamais de prix : faire payer certains achats en Revenue
recréerait deux monnaies dépensables et reperdrait exactement la lisibilité
qu'on vient de gagner.

La distinction est ailleurs :

> **Un achat coûte de l'Impact maintenant, et engage du Revenue pour toujours.**

Recruter, c'est un prix en Impact (l'embauche) *et* un salaire en Revenue à
chaque sprint jusqu'à la fin du mandat. Un outil, c'est un prix en Impact et une
licence récurrente. Chaque achat pose donc **deux questions distinctes, dont
aucune ne remplace l'autre** : ai-je les moyens de l'acheter, ai-je les moyens
de le garder ? On peut avoir un Impact énorme et ne pas pouvoir se permettre un
senior de plus.

C'est ce qui donne au Revenue son rôle de contrainte sans en faire une seconde
caisse à surveiller.

### 3.2 Les deux temps d'achat, et leur asymétrie

| | Quand | Ce qu'on y achète | Risque |
|---|---|---|---|
| **Shop du sprint** (Investissements) | pendant le trimestre | petits ajustements : candidats, pratiques | **Fait reculer vers l'objectif en cours** |
| **Comité** | entre les trimestres, après le verdict | paris structurels : outils, slots, décisions | Ne menace que le trimestre suivant |

Cette asymétrie n'est pas un effet de bord, c'est le rythme du jeu. Acheter au
premier sprint d'un trimestre est confortable — il reste deux sprints pour
reconstituer. Acheter au dernier est un pari sérieux. Le joueur découvre donc
seul une cadence : **investir tôt dans le trimestre, sécuriser à la fin**. Des
sprints aujourd'hui interchangeables gagnent du relief, sans qu'aucune règle
supplémentaire soit écrite.

Conséquence de dimensionnement : les prix du shop de sprint doivent rester
**petits devant ceux du Comité**. Ajustements fréquents d'un côté, paris
structurels de l'autre.

### 3.3 Le premier sprint n'achète rien

Le portefeuille démarre à zéro : on ne peut donc rien acheter au sprint 1, avant
d'avoir produit quoi que ce soit. **C'est assumé.** Le premier sprint sert à
livrer avec ce dont on a hérité, et la première décision d'achat arrive une fois
qu'on a vu ce que l'équipe vaut réellement.

C'est aussi un levier de variété pour plus tard : des scénarios pourront démarrer
avec un capital d'Impact initial — l'entreprise qui a déjà levé, celle qui
reprend un produit qui marchait. Une ligne de `companies.json`, à traiter comme
un trait de contexte de run, pas comme une règle générale.

### 3.4 Ce que ça change pour la Roadmap

Si le Revenue vient des features à ROI et l'Impact de `Traction × Levier`, alors
le choix de backlog devient un arbitrage réel : **nourrir la boîte ou nourrir la
performance**. Livrer la feature ennuyeuse qui finance les salaires, ou celle qui
fait décoller le score sans rien rapporter.

Ce choix n'existe pas aujourd'hui — tout va dans le même pot. Il apparaît
gratuitement avec la séparation des deux monnaies, et c'est probablement son
meilleur effet secondaire.

---

## 4. L'objectif trimestriel porte sur le portefeuille

À la fin de chaque trimestre, le board demande : **« as-tu N d'Impact ? »** On
regarde le solde, pas la production. En dessous, fin de run.

Le premier réflexe de conception est de séparer « l'Impact produit » (qui serait
jugé) de « l'Impact disponible » (qu'on dépenserait), pour que dépenser ne fasse
pas reculer vers l'objectif. **C'est un piège, et il a été écarté** : deux
grandeurs qui portent le même nom rendent l'objectif illisible, ce qui est
précisément le défaut qu'on corrige. Un seul nombre.

L'objection évidente — « alors il suffit de thésauriser » — **tombe grâce à
l'échelle des objectifs**. Si l'objectif suivant vaut cinq fois le précédent,
puis vingt fois, aucune accumulation linéaire ne rattrape la courbe. La seule
issue est de **multiplier sa production**, donc de vider son portefeuille pour
acheter du levier. La contrainte n'a pas besoin d'être ajoutée : elle est
produite par l'escalade.

Et le rythme se règle tout seul, parce que le Comité a lieu **entre** les
trimestres, après le verdict. On produit, on est jugé, **puis** on dépense.
Comme en boutique dans Balatro : dépenser ne met jamais en danger l'objectif en
cours, seulement le suivant.

### 4.1 L'escalade actuelle est trop douce

`quotas.json → careerLevels.pm.quarterQuotas` vaut aujourd'hui
`[120, 270, 560, 1050]`, soit environ ×2,2 puis ×2,1 puis ×1,9. Avec un
portefeuille **conservé** entre les trimestres, un facteur 2 se franchit en
accumulant sans rien acheter — le cliquet fait le travail à la place du joueur.

**L'escalade doit devenir franchement plus raide** pour que l'investissement
soit obligatoire. Le chiffre exact n'est pas décidable à l'œil : voir §7.

---

## 5. La condition structurelle : le Levier doit pouvoir se multiplier

**C'est le point le plus important de ce document, et celui à relire en
priorité.**

L'intention est claire : construire et ajuster des items pour qu'on puisse
« casser » le jeu, comme les combos exponentiels de Balatro ou de Clover Pit.
**La structure actuelle l'interdit**, quel que soit le contenu qu'on y ajoute.

Constat, vérifié dans `data/scoring.json` et `game/scripts/score_resolver.gd` :

- le Levier est **exclusivement additif** — 48 valeurs en `+` (`baseLever`,
  `lever`, `leverPerMember`, `leverPerSprint`, `leverPerTier`) ;
- le resolver ne multiplie **jamais** le Levier : `lever *=` n'existe nulle
  part ;
- les 17 multiplicateurs du fichier portent tous sur la **Traction**
  (`pointsMultiplier`, `handBonuses`) ou sur des grandeurs annexes (`mrrMultiplier`,
  `churnMultiplier`), jamais sur le Levier.

Le Levier vaut donc `1.0 + 0.3 + 0.6 + 0.4 + …` et plafonne autour de 3 ou 4.
Ajouter cinquante items additifs ne changerait rien à la nature de la courbe :
**une somme de petits bonus ne produit pas d'exponentielle.** Le plaisir visé
— celui du moment où les chiffres décollent — est mathématiquement hors
d'atteinte.

Balatro a exactement cette structure, et c'est ce qui la rend lisible : le Mult
reçoit des `+Mult` **et** des `×Mult`, et ce sont les seconds qui font les runs
à dix puissance douze. Les premiers seuls plafonnent.

### 5.1 Proposition — une troisième couche

```
Levier_final = (baseLever + Σ additifs) × Π multiplicateurs
```

Une nouvelle famille d'effets `leverMultiplier`, appliquée **après** la somme
des additifs, et **composée entre elle** (deux ×1,5 donnent ×2,25, pas ×3).

L'ordre n'est pas un détail, c'est ce qui crée la recherche de combo : le joueur
empile d'abord des additifs pour grossir la base, puis cherche les
multiplicateurs pour la faire exploser. Un ×1,5 sur un Levier de 1,2 ne vaut
rien ; le même ×1,5 sur un Levier de 4 gagne la partie. **C'est là que naît le
« j'ai trouvé quelque chose ».**

Quelques sources possibles, à écrire comme contenu et non comme règles en dur :
une décision stratégique tardive et chère, un palier de produit élevé, un combo
d'organisation rare (les six rôles couverts, une squad entièrement senior), un
outil de fin de partie. Elles doivent être **rares, chères et conditionnelles** —
un multiplicateur facile détruit la courbe au lieu de la créer.

### 5.2 Ce que ça n'est pas

Ce n'est pas un rééquilibrage : c'est une capacité qui n'existe pas. Tant
qu'elle n'existe pas, tout item ajouté sera additif par construction, et le
contenu ne pourra jamais « casser » le jeu — au mieux le rendre un peu plus
long.

---

## 6. Rendre le pari lisible

Un poste du Comité affiche aujourd'hui « +0,4 Levier ». Un joueur ne sait pas
convertir ça en quoi que ce soit.

**Proposition : la projection contrefactuelle.** Le même poste annonce :

> *« Avec cet outil, ton dernier sprint aurait produit **340** au lieu de 240. »*

C'est la même donnée, mais elle devient une promesse. Techniquement c'est
gratuit : on rejoue le dernier sprint dans `ScoreResolver` avec le levier
modifié — un seul calcul, deux usages, le pattern déjà en place dans le projet
(`evaluate_board_objectives()`, `card_impact_lines()`).

Et pour que ce soit un **pari** et non un calcul : la projection est vraie sur
le passé, jamais promise sur le futur. Le trimestre suivant apporte son aléa —
événements Inbox, tirage de backlog, équipes subies, départs. On voit ce que ça
*aurait* rapporté, jamais ce que ça *va* rapporter. C'est exactement là que vit
le gamble.

---

## 7. Le banc de trajectoires

L'escalade des objectifs (§4.1) et la puissance des multiplicateurs (§5.1) sont
deux courbes qui doivent se croiser au bon endroit. Trop raide, le run est perdu
d'avance quoi que fasse le joueur — et il ne le saura qu'à la fin. Trop douce,
tout devient trivial dès qu'on a compris la ligne.

Ce réglage ne se fait pas à l'œil et ne se playteste pas en une soirée.
**Proposition : un banc headless qui joue N runs sur chaque trajectoire** et
sort le trimestre de mort de chacune :

| Trajectoire | Attendu |
|---|---|
| Ne rien acheter | Meurt tôt — c'est déjà un critère de recette permanent |
| Investir tôt, puis produire | **Doit passer** le mandat |
| Investir tard | Meurt au trimestre où l'escalade décroche |
| Tout miser, s'endetter | Doit gagner **ou** mourir spectaculairement, jamais stagner |

La règle de difficulté devient vérifiable à chaque lot au lieu d'être une
intuition. C'est le prolongement direct du critère « `careful` doit perdre »,
appliqué à la nouvelle économie.

---

## 8. Les six ressources passent au second plan

Elles restent — elles font le sel RP et le côté entreprise vivante — mais
cessent d'être des compteurs à suivre pour devenir des **conséquences à subir**.

Concrètement : plus de rangée permanente de six jauges. Une ressource ne se
manifeste que **lorsqu'elle pose un problème** (seuil franchi, tendance
dangereuse), sous forme d'alerte. Le reste du temps, le panneau montre l'Impact,
le Revenue, et l'objectif du trimestre.

---

## 9. Ce qui reste à trancher

1. **L'ordre de grandeur de l'escalade** — à dériver du banc de §7, pas à
   choisir a priori.
2. **La puissance et la rareté des multiplicateurs de Levier** — même méthode.
3. **L'endettement en Impact.** Le Lot 4 a introduit l'« avance sur trimestre »
   qui débite sans clamp : un solde négatif est déjà possible. Décision prise de
   **garder et assumer**, à réexaminer au playtest.
4. **Les salaires** : payés en Revenue à chaque sprint — reste à décider si un
   Revenue insuffisant déclenche un départ immédiat, une dette, ou une chute de
   moral.

---

## 10. Coût et séquencement

Ce chantier touche l'économie entière : il ne se découpe pas en petits lots
indépendants.

| Lot | Contenu | Risque |
|---|---|---|
| **A** | Fusion trésorerie+MRR en Revenue ; suppression des pièces et de `√` ; l'Impact devient le portefeuille | Élevé — touche tous les écrans d'achat |
| **B** | Objectifs sur le portefeuille, escalade raide, affichage de bout en bout | Moyen |
| **C** | La couche `leverMultiplier` (§5) + le banc de trajectoires (§7) | Moyen, mais c'est **le lot qui rend le jeu intéressant** |
| **D** | Projection contrefactuelle au Comité ; ressources reléguées en alertes | Faible |

Le lot A est le plus dangereux : supprimer les pièces touche le Comité, la
Roadmap, les Investissements et le panneau latéral d'un coup. Il doit se faire
d'une traite, sinon le jeu reste à moitié dans chaque économie.

Le lot C est celui qu'il ne faut pas repousser : sans lui, tout contenu ajouté
d'ici là sera additif, donc à refaire.
