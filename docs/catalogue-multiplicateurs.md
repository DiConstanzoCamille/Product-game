# Catalogue — les multiplicateurs qui cassent le jeu

**Statut : propositions de contenu, en attente de relecture.** Annexe à
[`spec-impact-monnaie.md`](spec-impact-monnaie.md) §5, qui pose la couche
technique. Ce document propose ce qu'on met dedans.

Rien n'est implémenté. Les chiffres sont des points de départ à caler au banc
de trajectoires (spec §7), pas des valeurs validées.

---

## 1. Le principe : trois degrés de puissance

Tous les multiplicateurs ne se valent pas, et c'est voulu. Trois familles, du
plus sage au plus cassé.

### Degré 1 — le multiplicateur fixe

`×1,4`, tout le temps. Simple, lisible, borné. C'est le pain quotidien : il
double éventuellement la fin de partie, il ne l'explose pas.

### Degré 2 — le multiplicateur conditionnel

`×1,6` **si** une condition d'organisation est remplie. Il ne se contente pas de
donner de la puissance : il **impose une forme d'équipe**. C'est lui qui crée
les archétypes de run — « la boîte 100 % senior », « la boîte sans PM ».

### Degré 3 — le multiplicateur qui scale

`×1,1 **par** outil possédé`. **C'est celui qui casse le jeu**, et il n'y en a
que quelques-uns.

La raison est arithmétique : il transforme une accumulation linéaire en courbe
exponentielle. Six outils donnent ×1,77 ; dix outils donnent ×2,59. Et comme il
se compose avec les autres multiplicateurs, deux effets qui scalent en même
temps font décoller la partie d'un coup. C'est le moment « j'ai trouvé quelque
chose » — celui qu'on raconte à quelqu'un après coup.

**Règle de conception** : un effet de degré 3 doit toujours dépendre d'un
compteur que le joueur peut faire monter *par ses décisions*, jamais d'un
compteur qui monte tout seul avec le temps. Sinon ce n'est pas un combo, c'est
une rente.

---

## 2. Outils internes (achat au Comité, occupent un slot)

| Item | Effet | Condition / prix |
|---|---|---|
| 🤖 **Plateforme d'automatisation** | `×1,5` Levier global | Seulement si **aucune décision stratégique n'a été prise ce trimestre**. L'automatisation demande de la stabilité — et prive le joueur d'un autre levier fort. |
| 📐 **Design system** | `×1,4` Levier local de la squad | La squad compte **au moins 2 designers**. Récompense la spécialisation, punie ailleurs. |
| 🧪 **Plateforme d'expérimentation** | `×1,3`, et `×1,8` si Valeur perçue > 70 | Deux paliers : il devient fort quand le produit marche déjà. Riche-devient-plus-riche assumé. |
| 🧰 **Socle technique commun** | **`×1,08` par outil possédé** *(degré 3)* | Cher, et sans effet quand on n'a rien. Avec 8 outils : `×1,85`. C'est la pièce autour de laquelle on construit un run. |
| 📚 **Documentation vivante** | `×1,05` par employé senior *(degré 3)* | Se marie avec les builds « tout senior » — qui coûtent une fortune en Revenue. |

---

## 3. Recrutements porteurs (les profils rares du pool)

L'idée : quelques candidats rares portent un multiplicateur. Ils sont chers en
salaire, donc ils pèsent sur le **Revenue** — c'est là que les deux économies se
parlent.

| Profil | Effet | Le pari |
|---|---|---|
| 🛠️ **Staff Engineer** | `×1,5` Levier local | Seulement si la squad **ne compte aucun junior**. Forcer une équipe 100 % senior coûte très cher tous les sprints. |
| 🦄 **Le PM qui a fait scaler une licorne** | `×1,4` Levier global | Salaire **×3**. Un mauvais trimestre et il coule l'entreprise à lui seul. |
| 🎨 **Designer-fondateur** | `×2` Levier local | **Part au bout de 4 sprints** — il s'ennuie. Une fenêtre de tir, pas une acquisition. |
| 🧙 **L'ancien CTO devenu IC** | `×1,3`, et annule le malus de dette organisationnelle | Refuse de travailler avec plus de 2 autres personnes dans sa squad. |

Le **Designer-fondateur** mérite un mot : un multiplicateur qui expire crée une
décision de tempo (« je le prends maintenant ou j'attends d'avoir le reste du
combo ? ») qu'aucun bonus permanent ne produit.

---

## 4. Décisions stratégiques (1 par trimestre, irréversible)

C'est le bon endroit pour les effets les plus violents : le joueur n'en prend
qu'une par trimestre et ne peut pas revenir dessus.

| Décision | Effet | Contrepartie |
|---|---|---|
| 🚀 **Product-led growth** | `×1,6` Levier global | Revenue `×0,6` pendant 2 trimestres. Le gamble pur : on scie la branche pour aller plus vite. |
| 🏴 **Tout miser sur une verticale** | `×1,8` Levier | Le pool de backlog est réduit de moitié — moins de choix, plus de risque de tirage stérile. |
| 🤝 **Racheter le concurrent** | `×1,5` Levier, +1 employé | Dette organisationnelle massive, différée d'un trimestre. |
| 🧘 **Réduire la voilure** | `×0,8` Levier | Revenue `×1,5`. L'anti-combo : sauver l'entreprise en renonçant à la performance. Il en faut. |

---

## 5. Combos d'organisation (jamais achetés — construits)

Les `organizationCombos` sont aujourd'hui tous additifs (`0.3`, `0.6`…). En
faire passer quelques-uns — **les plus difficiles seulement** — en multiplicatif
change la nature de la construction d'équipe.

| Combo | Aujourd'hui | Proposition |
|---|---|---|
| **L'équipe complète** (les 6 rôles présents) | — | `×1,5` — très dur à réunir, et incompatible avec les builds spécialisés |
| **La squad 100 % senior** | — | `×1,4` — le coût est dans le Revenue, pas dans l'Impact |
| **Standardisation** (≥3 squads même archétype) | `+0,4` | `×1,3` — récompense enfin le jeu à grande échelle |
| **Trio produit** (PM + Dev + Designer) | `+0,3` | rester additif — c'est le combo d'entrée, il doit rester accessible |

---

## 6. Deux exemples de runs cassés

Pour vérifier que la structure produit bien ce qu'on veut, voici ce à quoi
ressemblerait une partie qui décolle.

### « La boîte de vieux singes »

Staff Engineer + squad 100 % senior + Documentation vivante (`×1,05` par
senior). Avec 6 seniors : `1,5 × 1,4 × 1,34 = ×2,81`, sur un Levier additif déjà
monté à 3,5 → **Levier final ≈ 9,8**. Le Revenue s'effondre sous les salaires :
la course est de franchir l'objectif avant la faillite.

### « L'accumulateur »

Socle technique commun (`×1,08` par outil) + slots d'outillage rachetés en
priorité. Avec 10 outils : `×2,16`, et chaque outil apporte en plus son additif.
Le run est lent à démarrer et devient absurde en fin de mandat — à condition de
survivre aux deux premiers trimestres, où on n'a rien.

Ces deux lignes doivent être **jouables mais pas évidentes**, et surtout **pas
les meilleures à tous les coups** : c'est le rôle du banc de trajectoires
(spec §7) de vérifier qu'aucune ne domine.

---

## 7. Les garde-fous

- **Peu de degré 3.** Deux ou trois dans tout le jeu. C'est leur rareté qui fait
  l'événement.
- **Jamais un multiplicateur sans contrepartie.** Chaque item ci-dessus coûte
  quelque chose : du Revenue, un slot, une condition d'équipe, une expiration.
- **Tout en données.** `leverMultiplier`, la condition et le compteur associé
  vivent dans `scoring.json` / `investments.json`. Rééquilibrer ne doit pas
  toucher au script (convention du `CLAUDE.md`).
- **Rien de tout ça n'est jouable avant** la couche `Levier = (base + Σ) × Π` de
  la spec §5. Écrire ces items avant cette couche, c'est écrire des additifs
  déguisés.
