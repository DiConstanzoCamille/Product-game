# Proposition — Lot 4 : chaque écran son objet

> Document de proposition (30/07/2026), en réponse au retour de Camille sur le
> Lot 1 : « sur l'inbox je m'attendais à un visuel type boîte mail ou Slack, sur
> roadmap des blocs de Gantt chart ou des tickets Jira/Notion ».
>
> Le Lot 1 a livré une **grammaire** (thème clair, carte d'Actif, Panneau de
> bord) et l'a appliquée aux écrans d'acquisition. Les deux écrans qui ne
> manipulent pas des Actifs — l'Inbox et la Roadmap — ont hérité du thème mais
> pas d'une forme : ils restent une page de texte et une grille de boutons. Ce
> lot leur donne leur objet.
>
> Livré en avance de ce lot : le **cadre d'ordinateur portable** autour des
> écrans de choix (`scenes/components/device_frame.tscn`).

## 1. Le principe : un écran, un artefact de bureau

La direction « Post-it & Feutre » dit que le monde de jeu est fait d'objets
qu'on manipule. Le Lot 1 l'a tenu pour les Actifs (fiches, badges, post-it) et
pour l'état de l'entreprise (l'écran TV du standup). Il reste deux gestes sans
objet :

| Écran | Geste réel | Objet aujourd'hui | Objet proposé |
|---|---|---|---|
| Inbox | on subit un message | un paragraphe et trois boutons | **un fil de messagerie interne** |
| Roadmap | on remplit un sprint | une grille de boutons à bascule | **un board de tickets, capacité en gouttière** |
| Choix (accueil, scénario, entreprise, fin) | on consulte un outil | plein écran | **la dalle d'un portable** ✅ livré |

Règle de partage avec le Panneau de bord, inchangée : le panneau dit *où j'en
suis*, l'écran dit *ce que je décide maintenant*.

## 2. L'Inbox — la messagerie interne

Aujourd'hui : expéditeur, sujet, corps, trois boutons pleine largeur. C'est
lisible mais ça ne ressemble à rien de connu, alors que tout le monde sait à
quoi ressemble un message qui tombe mal.

Proposition — **un fil de conversation, pas une boîte de réception.** Une liste
de messages serait un mensonge : il n'y a qu'un événement par sprint, et le
tirage est déjà consommé quand l'écran s'ouvre. Ce qu'on veut, c'est le *poids*
d'un message reçu :

```
┌──────────────────────────────────────────────┐
│ 💬 #direction-produit          sprint 5 · 09:12│  ← en-tête de canal
├──────────────────────────────────────────────┤
│ (avatar) **Priya** · Lead Engineering  09:12  │
│ ┌──────────────────────────────────────────┐ │
│ │ On peut parler deux minutes ?            │ │  ← bulle de message
│ │ Un ingénieur senior très respecté…       │ │
│ └──────────────────────────────────────────┘ │
│                                    ✎ en train d'écrire…│
├──────────────────────────────────────────────┤
│ VOTRE RÉPONSE                                │
│ ▸ Négocier une augmentation                  │  ← réponses en brouillons
│ ▸ Lui promettre plus d'autonomie             │
│ ▸ Ne rien changer, temporiser                │
└──────────────────────────────────────────────┘
```

- **Bulle de message** : fond blanc, coin cassé côté avatar, horodatage. Le
  sujet devient la première ligne en gras, le corps suit — un seul bloc, comme
  un vrai message.
- **Le canal en en-tête** donne le contexte social gratuitement : `#direction-produit`,
  `#incidents`, `#rh-confidentiel` selon l'événement. Un champ `channel` à
  ajouter dans `inbox-events.json`, avec un repli par défaut.
- **Les choix deviennent des réponses** : puces alignées à gauche, pas des
  boutons pleine largeur. Au clic, le choix retenu **devient une bulle de
  réponse** de votre côté du fil, et la conséquence (`reveal`) arrive comme un
  message suivant. Le geste « j'ai répondu ça, voilà ce que ça a fait » est
  raconté par la forme.
- **Coût** : faible. Aucun asset, deux `StyleBoxFlat` et une réorganisation de
  `inbox_screen.gd`. Un champ de données optionnel.

## 3. La Roadmap — le board de tickets

C'est là qu'il y a un arbitrage de game design, pas seulement de décor.
Aujourd'hui : des boutons à bascule de 220×120 dans une grille, et une
`ProgressBar` de capacité au-dessus.

### Option A — Le board de tickets (recommandée)

Chaque feature est un **ticket** façon Jira/Notion : référence (`FEAT-014`),
titre, promesse, pastilles d'icônes, et un **badge de points** en haut à droite
(`4 pts`). Deux colonnes titrées au feutre : **« Backlog »** à gauche,
**« Ce sprint »** à droite. On compose le sprint en *déplaçant* les tickets —
clic pour envoyer à droite, clic pour renvoyer à gauche (le glisser-déposer
viendrait après, si le clic ne suffit pas).

La capacité devient une **gouttière verticale** le long de la colonne
« Ce sprint » : elle se remplit ticket par ticket, et passe au rouge quand le
panier dépasse ce que l'équipe produit. La surchauffe n'est plus un avertissement
en texte, c'est une colonne qui déborde.

- ✅ La forme dit la règle : ce qui est « pris » est physiquement ailleurs que ce
  qui est « pas pris ». Ça rend aussi le geste réversible et lisible.
- ✅ Prépare la roadmap profonde (Phase C) : les colonnes ROI/Impact/Risque des
  epics rentrent dans un ticket comme des lignes d'impact rentrent dans une
  carte d'Actif.
- ⚠️ Deux colonnes coûtent de la largeur, et le Panneau de bord en prend déjà
  320 px. À 1560 px de large ça passe ; à 1280 px il faudra rétrécir les
  tickets ou replier le panneau (le rail du §4.3 de la proposition UI devient
  alors nécessaire).

### Option B — Le Gantt

Une barre par feature, longueur proportionnelle au coût en points, posées sur
une frise de sprint. Séduisant sur le papier, mais il raconte une **durée** :
or une feature ne dure pas plusieurs sprints dans le modèle actuel, elle est
livrée ou non à la Résolution. Le Gantt promettrait une mécanique
d'étalement dans le temps qui n'existe pas — et que la Phase C n'a pas prévue.

**Recommandation : Option A.** Le Gantt redeviendra honnête le jour où une
feature pourra s'étaler sur plusieurs sprints ; c'est une décision de game
design, pas d'habillage, et elle appartient à la roadmap profonde.

## 4. Ce que ça touche

- `inbox_screen.gd` + `inbox_screen.tscn` : réorganisation, pas de règle touchée.
- `data/inbox-events.json` : champ `channel` optionnel (12 événements).
- `roadmap_screen.gd` + `roadmap_screen.tscn` : réorganisation en deux colonnes,
  nouveau composant `ticket_card.tscn`, capacité en gouttière.
- Aucun changement dans `EffectResolver` ni `SprintState` : les deux écrans
  produisent exactement les mêmes deltas qu'aujourd'hui, par les mêmes appels.
- Recette inchangée : les deux smoke tests doivent passer sans modification.

## 5. Questions à trancher

1. **Roadmap : option A (board de tickets) ou option B (Gantt) ?** La
   recommandation est A ; B demande d'abord de décider si une feature peut
   s'étaler sur plusieurs sprints.
2. **Inbox : le canal.** On ajoute `channel` aux 12 événements (un peu
   d'écriture, beaucoup de contexte gratuit), ou on se contente d'un canal
   générique `#direction-produit` ?
3. **Le rail replié du panneau** devient-il un prérequis ? Il l'est si tu joues
   parfois en fenêtre plus petite que ~1400 px de large.
4. **Le cadre d'écran** doit-il rester sur les seuls écrans de choix, ou aussi
   habiller la Résolution (qui est un bilan qu'on lit, pas un geste) ?
