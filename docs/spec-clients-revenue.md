# Spec — Le Revenue a des clients

**Statut : proposition, en attente de relecture.** Rien de ce document n'est
implémenté. Écrit le 02/08/2026, à partir de la question de Camille sur la PR
#40.

Ce document ne remet en cause ni la formule `Traction × Levier = Impact`, ni
la séparation des deux économies de
[`spec-impact-monnaie.md`](spec-impact-monnaie.md) §3.8 — il **rend concret**
le côté Revenue de cette séparation, qui reste aujourd'hui une abstraction
(« une base d'abonnements érodée par un churn »).

---

## 1. La demande

> *« Le ROI devrait être simple : on gagne +3 clients par exemple. Mais du coup
> si on fait des choix qui font fuir les clients, cela crée des dilemmes
> intéressants. J'ai 10k users sur un modèle freemium, je prends une décision de
> passer en payant uniquement, je perds 50 % des users mais je reste avec mon
> coût de N/user — cela rendrait plus simple à comprendre l'économie de
> l'entreprise. Et sur du B2B, il suffirait de dire qu'on commence avec un prix
> de base à 5k/user mais avec 500 users. »*

Le diagnostic est juste, et il va plus loin que la lisibilité. Aujourd'hui le
Revenue est produit par un stock sans nom, érodé par un pourcentage : le joueur
n'a aucune prise dessus et aucune image mentale. On lui demande de suivre une
grandeur qu'on ne peut pas raconter.

---

## 2. Le modèle

> **Le Revenue n'est pas un stock. C'est une population qui paie.**

```
Revenue ← Revenue + (clients × prix_par_client) − charges_du_sprint
clients ← clients − départs + arrivées
```

Trois nombres, dont **un seul bouge en permanence** :

| | | |
|---|---|---|
| **`clients`** | la population | la seule variable que le joueur pilote |
| **`prix_par_client`** | l'ARPU du modèle économique | une **constante du run**, sauf décision explicite |
| **`charges`** | salaires + licences par siège + coût par client | déjà en place (spec-impact-monnaie §3.6), plus le coût unitaire |

### 2.1 Pourquoi ce n'est pas un compteur de plus

L'objection immédiate est la question 2 de la vision : *le joueur sait-il encore
quelle valeur regarder ?* La réponse tient à ceci : **les clients ne s'ajoutent
pas au Revenue, ils l'expliquent**. Le panneau montre une seule ligne :

```
💰 Revenue  1 240        ← le solde, la seule valeur jugée
   840 clients × 0,5     ← d'où vient ce qui rentre
   −22 /sprint           ← ce qui sort
```

On échange **une abstraction contre une image** : le churn devient « vous avez
perdu 34 clients », le ROI d'une feature devient « +12 clients », le niveau CSM
devient « combien vous en gardez ». Trois concepts opaques deviennent un concept
concret. Le solde net est meilleur, pas pire.

### 2.2 Ce que ça supprime par construction

Le carnet §31.9 documente un défaut : `recurring_roi` accumule le ROI des
livraisons et le **réinjecte dans la base à chaque sprint**, si bien qu'une
feature à ROI 3 pousse le revenu vers `3 ÷ churn = 75` au lieu de rapporter 3.

Ce bug **ne peut pas s'écrire** dans le modèle client : une feature amène des
clients *une fois*, et les clients paient *chaque sprint*. Il n'y a plus de
grandeur ambiguë entre « ce que la feature a apporté » et « ce que ça rapporte
par sprint ». C'est le meilleur argument pour ce modèle : il rend une classe
entière d'erreurs impossible plutôt que de la corriger.

---

## 3. Ce qui fait arriver et partir les clients

La liste doit rester **courte et fermée** — c'est ce qui garde le modèle
lisible. Chaque entrée existe déjà dans le moteur sous un autre nom.

### Ils arrivent

| Source | Aujourd'hui | Demain |
|---|---|---|
| Features livrées | `roi` d'un item de `backlog.json` | `clientsGagnes` — le nombre de clients que la feature amène, une fois |
| Équipe Sales | `salesMultipliers` sur la conversion | multiplicateur sur les clients gagnés |
| Événements, primes | clé `revenue` dans `effects` | clé `clients` — un gros compte signé, une vague d'inscriptions |
| Décisions stratégiques | `mrrMultiplier` | effet sur les arrivées, l'ARPU ou le churn, au choix de la carte |

### Ils partent

| Source | Aujourd'hui | Demain |
|---|---|---|
| Churn de base | `baseChurn` du modèle | le même taux, appliqué à la population |
| Équipe CSM | `csmMultipliers` | multiplicateur sur le churn |
| Produit qui se dégrade | `lowMoralDebt` (Moral < 30 et Dette ≥ 70 → churn 15 %) | inchangé, mais enfin lisible : « 120 clients partent ce sprint » |
| Features à impact client négatif | `clientImpact` négatif → Valeur perçue | **et** des clients qui partent |
| Décisions, événements | — | une décision peut coûter des clients, c'est tout l'intérêt |

---

## 4. Les modèles économiques deviennent des formes différentes

C'est le gain que Camille pointe, et il est probablement le plus important :
`businessModels` cesse d'être une table de coefficients pour devenir **trois
formes de courbe qu'on reconnaît en jouant**.

| Modèle | Population | ARPU | Churn | Ce que ça fait ressentir |
|---|---|---|---|---|
| **Freemium** | milliers d'utilisateurs | très bas | élevé | Beaucoup de monde, peu d'argent. Chaque point de churn coûte cher en volume. Grandir coûte en coût unitaire avant de rapporter. |
| **B2B / grands comptes** | dizaines de comptes | très haut | bas | Peu de clients, chacun énorme. Perdre **un** compte est une catastrophe lisible. Le Sales compte plus que le volume. |
| **Vente à la version** | pas de population | — | — | Pas de récurrent : de gros paliers ponctuels à la sortie d'une version. C'est `waterfall-release`, aujourd'hui déclaré et vide. |

### 4.1 L'échelle — le piège le plus concret

Les nombres réalistes que la demande cite (10 000 users, 5 000 €/user) sont dix
mille fois au-dessus des charges du jeu (16 à 22 par sprint). Les mettre tels
quels rend le Revenue incomparable à ce qu'il paie, et la faillite décorative.

**Proposition : les unités affichées restent réalistes, les ordres de grandeur
sont calibrés pour que `clients × ARPU` atterrisse dans la même bande que les
charges.** Concrètement :

| Modèle | Départ | Revenu/sprint | Charges/sprint |
|---|---|---|---|
| Freemium | 900 utilisateurs × 0,05 | 45 | 16 + 900 × 0,01 = 25 |
| B2B | 37 comptes × 1,5 | 55 | 16 + 37 × 0,2 = 23 |

Le joueur lit « 900 utilisateurs » ou « 37 comptes » — deux univers différents —
et le moteur compare des grandeurs comparables. Les chiffres ci-dessus sont
illustratifs : le calibrage se fait au banc.

### 4.2 Changer de modèle en cours de run

C'est l'exemple de la demande, et il devient enfin jouable : *passer en payant
uniquement, perdre 50 % des utilisateurs, garder son coût unitaire*.

```
décision "Fin du gratuit" :
  clients × 0,5      —  la moitié part, immédiatement et visiblement
  ARPU × 4           —  ceux qui restent paient vraiment
  coût par client    —  inchangé
```

Le calcul est faisable de tête par le joueur, le résultat est incertain (il ne
sait pas exactement qui part), et il se voit sur un seul écran. C'est un pari
lisible — exactement ce qu'on cherche. Le pivot de modèle économique, noté
comme idée depuis le carnet §15 et jamais implémenté faute de sens, en a un.

---

## 5. Les trois pièges

### 5.1 Le retour de la fuite, par un chemin plus long

Aujourd'hui `conversion.perceivedValue` fait monter la **Valeur perçue** à
partir de l'Impact (`impactPerPoint: 30`, plafonné à +6/sprint). Si la Valeur
perçue fait ensuite arriver des clients, alors :

```
Impact → Valeur perçue → clients → Revenue
```

…et on a reconstruit la fuite que `spec-impact-monnaie` §3.8 interdit, avec un
détour de plus. **C'est le piège principal de cette proposition.**

Deux issues, à trancher :

- **a.** Les clients n'arrivent que par les features, les événements et le
  Sales. La Valeur perçue reste une jauge de contexte (elle ouvre des
  événements, elle pèse sur les fins) sans jamais produire de clients.
- **b.** La Valeur perçue amène des clients, mais elle cesse d'être alimentée
  par l'Impact — elle ne vient plus que du `clientImpact` des features livrées.

**Recommandation : (b).** C'est plus riche — la Valeur perçue devient
« la réputation du produit », qui attire — et ça garde une seule règle à
retenir : *ce qui amène des clients, c'est ce qu'on livre, jamais ce qu'on
score*.

### 5.2 Deux nombres qui bougent

Si l'ARPU varie au fil de l'eau **et** que la population varie, le joueur a deux
leviers à suivre et le modèle redevient opaque. **L'ARPU est une constante du
run**, fixée par le modèle économique, et ne change que par une décision
explicite et rare (§4.2). Une prime d'événement donne des clients ou du Revenue
direct, jamais un ARPU modifié.

### 5.3 Les clients gratuits doivent coûter

Sans coût par client, une population qui grandit n'a aucun inconvénient et le
freemium n'est plus un pari. **Les charges gagnent un terme
`clients × coût_unitaire`** (support, infrastructure), au même titre que les
licences par siège. C'est ce qui rend « 10 000 utilisateurs gratuits »
dangereux, et donc le passage au payant intéressant.

---

## 6. Ce que ça change à l'écran

- Le panneau : une ligne Revenue, sa composition en dessous (§2.1).
- La Résolution : la ligne d'économie devient racontable — « 38 clients gagnés,
  12 partis, 864 payants × 0,5 = 432 ».
- La Roadmap : une feature annonce `+12 clients` au lieu de `ROI +3`. Le même
  masquage qu'aujourd'hui (la colonne reste cachée sans la pratique Discovery).
- Le Comité : une décision annonce son effet sur la population, pas sur un
  coefficient.

---

## 7. Ce que ça coûte

| Lot | Contenu | Risque |
|---|---|---|
| **1** | `clients` + `ARPU` + coût unitaire dans l'état et le resolver ; `roi` → `clientsGagnes` ; suppression de `recurring_roi` | Moyen — c'est le cœur, mais il remplace du code qui existe déjà |
| **2** | Les trois modèles économiques calibrés (§4), et le pivot de modèle (§4.2) | Moyen — c'est là que le contenu se décide |
| **3** | L'affichage (panneau, Résolution, Roadmap, Comité) | Faible |

Ce chantier **remplace la moitié de l'issue #42** : couper `impactToMrr` et
corriger le double comptage de `recurring_roi` deviennent des conséquences du
modèle client plutôt que deux correctifs séparés. Si cette spec est validée,
#42 doit être réécrite autour d'elle plutôt que livrée avant.

---

## 8. Ce qui reste à trancher

1. **Valeur perçue → clients : (a) ou (b) ?** (§5.1) — c'est le point qui décide
   si la séparation des deux économies tient. Recommandation : (b).
2. **L'échelle exacte par modèle** (§4.1) — à dériver du banc, pas à choisir à
   l'œil.
3. **Le coût unitaire par client est-il le même pour tous les modèles ?**
   Probablement non : un utilisateur freemium coûte peu et rapporte peu, un
   grand compte coûte du support. C'est une valeur par modèle.
4. **Que devient `clientImpact`** des features ? Deux lectures possibles : il
   *est* le nombre de clients gagnés (une seule valeur, plus simple), ou il
   reste la réputation et `clientsGagnes` s'ajoute (deux valeurs, plus fin).
   Recommandation : les fusionner — une feature a un effet client, point.
5. **Faut-il un plancher de population ?** Une entreprise à zéro client n'a
   aucun moyen de revenir — est-ce une fin de run à part entière (« plus
   personne n'utilise le produit ») ou juste un Revenue qui s'assèche jusqu'à la
   faillite ? Recommandation : pas de fin dédiée, la faillite suffit.
