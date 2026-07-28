# Choix technique — moteur de jeu

**Décision : Godot 4 (GDScript).**

*Document de travail, révisable si les contraintes changent (équipe, budget, plateformes cibles).*

## Pourquoi ce choix

Product Tycoon n'a besoin d'aucun rendu 3D ni temps réel : chaque écran décrit dans le [carnet de règles](carnet-de-regles.md) — cartes qui se retournent, jauges, inbox à choix, shop de recrutement, plateau de fondations — est un écran de menus piloté par de la donnée. C'est exactement ce que démontre déjà la [landing page](../landing/index.html) : des `data/*.json` rendus en DOM avec de l'interaction légère (clic, hover, toggle). Un moteur pensé pour l'UI et le 2D convient mieux qu'un moteur de rendu 3D.

Godot 4 coche les cases pertinentes pour ce projet :

- **2D natif**, pas un système 3D adapté — plus rapide sur des scènes chargées en sprites/UI, et pensé dès le départ pour ce cas d'usage.
- **Nœuds `Control`** faits pour construire exactement ce dont on a besoin : cartes, jauges, listes de choix, panneaux — sans détourner un moteur de gameplay temps réel.
- **Gratuit, licence MIT**, aucun coût récurrent par siège ni royalties, quel que soit le succès commercial du jeu.
- **GDScript** a une courbe d'apprentissage douce pour une petite équipe ou un·e développeur·se solo — pas besoin de C++ ni d'un moteur de build lourd pour itérer.
- **Export multi-cibles** : desktop (Windows/Mac/Linux), et HTML5/WebAssembly si on veut aussi une version jouable dans le navigateur, sans changer de moteur.
- Système de sauvegarde, gestion audio, animations (utile pour le flip de carte, les transitions de sprint) fournis nativement — pas besoin de les réinventer comme sur la landing page actuelle.

## Alternatives écartées

| Option | Pourquoi écartée |
|---|---|
| **Three.js** | Lib de rendu 3D/WebGL. Aucun écran du jeu n'a besoin de 3D — hors sujet par rapport au concept. |
| **Unreal Engine** | Conçu pour la fidélité visuelle AAA (Nanite, Lumen, MetaHuman), pipeline C++ lourd. Très surdimensionné pour un jeu de menus et de cartes — le rapport effort d'apprentissage / besoin réel est mauvais. |
| **Unity** | Viable mais surdimensionné : son 2D est un système 3D adapté (pas natif), et Unity Pro coûte environ 2 310 $/siège/an. Pertinent si l'équipe grandit et vise du mobile natif poussé ou beaucoup d'assets animés — pas nécessaire au stade actuel. |
| **Stack web pure (React/Svelte + TypeScript)** | Sérieusement envisagée — elle aurait prolongé directement le travail déjà fait sur la landing page (même logique data → DOM), avec l'itération la plus rapide et un hébergement trivial. Écartée pour un jeu complet car il faudrait réimplémenter à la main ce qu'un moteur de jeu offre nativement (sauvegardes, animations, audio, packaging desktop via Electron/Tauri). Reste une option si la distribution navigateur devient un objectif non négociable. |

## Implications pour le dépôt

- Les fichiers `data/*.json` restent la source de vérité pour le contenu de jeu (ressources, cartes, époques, fins de mandat, etc.) — ils seront chargés par Godot au runtime (`FileAccess` + `JSON.parse_string`) exactement comme `landing/js/main.js` les charge aujourd'hui via `fetch`. Pas de duplication de contenu à prévoir entre la landing page et le jeu.
- La landing page HTML reste la maquette de présentation/pitch, pas la base du jeu — elle n'a pas vocation à devenir le jeu lui-même.
- Un futur dossier `game/` (projet Godot) sera ajouté à la racine du dépôt lors du démarrage du développement, en parallèle de `landing/`, `data/` et `docs/`.

## Questions ouvertes

- GDScript ou C# ? GDScript par défaut (plus simple, suffisant pour ce scope) sauf besoin de perf spécifique ou d'intégration .NET.
- Cible de sortie prioritaire : desktop (Steam/itch.io) et/ou export web ? À trancher avant de structurer les scènes (l'export web impose des contraintes supplémentaires, ex. taille des assets, absence de certains modules).
- Outil de narration pour les événements Inbox (branchements de dialogue) : à évaluer le moment venu — Godot a des plugins dédiés (ex. Dialogic) si le volume d'événements narratifs grossit.
