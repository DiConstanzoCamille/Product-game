# Product Tycoon

> Un roguelike où vous incarnez le·la CPO fraîchement nommé·e d'une organisation que vous n'avez pas construite. Contexte tiré au sort, équipe héritée, décisions rarement réversibles. Chaque bonne pratique promet une amélioration théorique — son effet réel dépend de qui la reçoit.

Ce dépôt rassemble les documents de conception du jeu. **C'est un document de travail** : rien n'est encore équilibré ni final, l'objectif est de garder une base de réflexion partagée sur le concept et le gameplay.

## Contenu du dépôt

- [`docs/carnet-de-regles.md`](docs/carnet-de-regles.md) — le carnet de règles complet : structure temporelle, ressources, système de cartes, effets persistants, roadmap, recrutement, époques, fins de mandat, et les questions ouvertes encore à trancher.
- [`landing/index.html`](landing/index.html) — une page de présentation interactive du concept (maquette autonome en HTML/CSS/JS, sans dépendance externe) : cartes retournables, jauges de ressources, aperçu d'écrans de jeu (inbox, roadmap, recrutement), présentation des époques et des fins de mandat.

## Voir la landing page

La page est un fichier HTML autonome, sans build ni dépendances. Pour la consulter en local :

```bash
open landing/index.html        # macOS
xdg-open landing/index.html    # Linux
```

Ou ouvrez simplement le fichier dans un navigateur.

## Concept en une phrase

Chaque bonne pratique a un prix. Le·la joueur·se le découvre en le payant : une carte de décision (méthodologie, outil, recrutement) affiche une promesse théorique, mais son effet réel dépend du profil de l'équipe qui la reçoit, de l'époque du run, et des décisions déjà prises.

## Structure temporelle

| Échelle | Durée fictive | Rôle |
|---|---|---|
| **Sprint** | ~2 semaines | Unité de jeu de base — un tour complet |
| **Trimestre** | ~6 sprints | Point de contrôle : revue de board, événement "boss" |
| **Mandat** | Variable | Le run entier, de la nomination à la sortie |

## Les six ressources

💰 Trésorerie · 🫶 Moral & confiance d'équipe · 🧱 Dette organisationnelle · 🎯 Capital politique · 📈 Valeur perçue · 🎭 Cynisme

Aucune ne s'optimise seule — voir le détail des tensions entre ressources dans le [carnet de règles](docs/carnet-de-regles.md#5-tensions-entre-ressources).

## Statut du projet

Phase de conception. Les valeurs numériques (coûts, gains, seuils de déclenchement des fins de mandat) sont indicatives et seront ajustées en playtest. Plusieurs questions restent ouvertes (voir la [section 13 du carnet de règles](docs/carnet-de-regles.md#13-hypothèses-et-questions-ouvertes)).
