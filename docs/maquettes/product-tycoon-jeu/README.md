# Product Tycoon — cible d’interface de jeu

**44 vues et états éditables**, accompagnés d’aperçus natifs pen.dev et d’un guide
de revue. Le bureau et son ambiance sont la direction validée. Cette déclinaison
complète reste un document de conception à affiner avant développement.

**Cible visuelle des prochains développements :** lire le
[contrat du rework](../../contrat-rework-bureau.md) et le
[plan d’intégration](../../plan-integration-rework.md). Les actifs à reprendre
sont identifiés dans [le manifeste](assets-manifest.json). Les PNG natifs et
ZIP sont des sorties locales ; les JPEG sont les aperçus versionnables.

## Ouvrir

- [Fichier `.pen`](product-tycoon-direction-jeu.pen), à conserver avec `assets/`.
- [Assets sources](assets/) à conserver à côté du `.pen`. Le ZIP de distribution est une sortie locale régénérable.
- [Vue d’ensemble des 44 états](apercus-natifs/vue-ensemble.jpg).
- [Scénario et cohérence des ressources](scenario.md).
- [Gestes, fermeture et intentions d’animation](interactions.md).
- [Plan des vues et parcours](plan-des-vues.json).
- [Famille de ressources et compositions harmonisées](ressources-visuelles.md).

## Harmonisation des ressources et des écrans secondaires

Les compteurs ont désormais leurs emblèmes en volume : étoile d’Impact, bourse
et calendrier. Leurs valeurs restent éditables et reposent sur des composants
partagés. Prix, gains, bilans et quotas réemploient cette même famille.

J43 est recomposé autour des vendeurs actifs et du flux de caisse. Les bilans,
combos, écrans de fin de trimestre, achats impossibles, recrutement, menus et
files de travail ont également été harmonisés. Les compteurs ne changent pas
l’économie : un seul solde d’Impact et une trésorerie indépendante.

- [J43 — clients, revenus et charges](apercus-natifs/J43.jpg).
- [J21 — capacité livrée et gain d’Impact](apercus-natifs/J21.jpg).
- [J25 — mouvements des ressources](apercus-natifs/J25.jpg).
- [Planche des emblèmes et compteurs](apercus-natifs/02-emblemes.jpg).

## Dernière passe : retirer les codes web

Les écrans de choix principaux ne sont plus des grilles dans une grande fenêtre.
Les cartes sont posées sur le bureau, avec une identité de couleur et une
illustration ou un emblème, un nom et l’enjeu essentiel. Les paragraphes,
consignes et en-têtes génériques sont retirés. Le détail apparaît à la demande.
L’équipe se sélectionne directement dans la scène.

À regarder d’abord :

- [J02 — choisir des sujets](apercus-natifs/J02.jpg).
- [J14 — choisir un objet](apercus-natifs/J14.jpg).
- [J16 — voir l’effet et le coût d’un objet](apercus-natifs/J16.jpg).
- [J44 — déplier une carte au survol](apercus-natifs/J44.jpg).
- [J11 — sélectionner les personnes dans le bureau](apercus-natifs/J11.jpg).

Les boutons de retour qui doublaient la croix ont été retirés. Croix et Échap
ferment le contexte courant. Un achat explicite peut partir de l’objet
sélectionné : pas de seconde fenêtre de confirmation imposée dans le parcours
principal. Les détails de coût sont disponibles avant l’action.

Certains résultats et contextes conservent un nom utile — capacité livrée,
combo, personne — plutôt qu’un titre de fenêtre et son sous-titre explicatif.
Les intentions de survol et de mouvement ne sont pas animées par le fichier.

## Revoir par parcours

| Parcours | Planche |
|---|---|
| Préparer, observer, livrer, passer au lendemain | [Journée](apercus-natifs/01-journee.jpg) |
| Choisir les sujets, prioriser, ouvrir leurs descendants | [Produit](apercus-natifs/02-produit.jpg) |
| Parcours de travail, pratiques, files et bonus | [Organisation](apercus-natifs/03-organisation.jpg) |
| Personnes, recrutement et absence | [Équipe](apercus-natifs/04-equipe.jpg) |
| Atelier, achat, installation et contraintes | [Investir](apercus-natifs/05-investir.jpg) |
| Produit livré, économie et trimestre | [Progression](apercus-natifs/06-progression.jpg) |
| Accueil, aide, réglages, enquête et combo | [Entrée et détails](apercus-natifs/07-aide.jpg) |

## Toutes les vues

| Repère | Situation | Aperçu natif |
|---|---|---|
| J01 | Préparer la journée — scène plein écran | [Voir](apercus-natifs/J01.jpg) |
| J02 | Choisir les sujets — cartes sur le plateau | [Voir](apercus-natifs/J02.jpg) |
| J03 | Sélectionner Lina — commande contextuelle | [Voir](apercus-natifs/J03.jpg) |
| J04 | Ordonner la roadmap | [Voir](apercus-natifs/J04.jpg) |
| J05 | Comprendre un sujet et ses descendants | [Voir](apercus-natifs/J05.jpg) |
| J06 | Choisir une solution pour le connecteur | [Voir](apercus-natifs/J06.jpg) |
| J07 | Lire et transformer l’organisation | [Voir](apercus-natifs/J07.jpg) |
| J08 | Investir dans une pratique | [Voir](apercus-natifs/J08.jpg) |
| J09 | Ouvrir la file de conception | [Voir](apercus-natifs/J09.jpg) |
| J10 | Comprendre la file de réalisation | [Voir](apercus-natifs/J10.jpg) |
| J11 | Examiner son équipe | [Voir](apercus-natifs/J11.jpg) |
| J12 | Choisir une recrue | [Voir](apercus-natifs/J12.jpg) |
| J13 | Préparer un poste de travail | [Voir](apercus-natifs/J13.jpg) |
| J14 | Choisir une amélioration dans l’atelier | [Voir](apercus-natifs/J14.jpg) |
| J15 | Examiner un objet et son effet | [Voir](apercus-natifs/J15.jpg) |
| J16 | Voir le coût d’un objet sélectionné | [Voir](apercus-natifs/J16.jpg) |
| J17 | Installer le tableau dans le bureau | [Voir](apercus-natifs/J17.jpg) |
| J18 | Observer un bonus actif | [Voir](apercus-natifs/J18.jpg) |
| J19 | Regarder la journée se dérouler | [Voir](apercus-natifs/J19.jpg) |
| J20 | Mettre en pause et comprendre une attente | [Voir](apercus-natifs/J20.jpg) |
| J21 | Célébrer une livraison concrète | [Voir](apercus-natifs/J21.jpg) |
| J22 | Lire le bilan de journée | [Voir](apercus-natifs/J22.jpg) |
| J23 | Préparer le lendemain avec une absence | [Voir](apercus-natifs/J23.jpg) |
| J24 | Retrouver ce qui existe dans le produit | [Voir](apercus-natifs/J24.jpg) |
| J25 | Lire les dépenses et les revenus | [Voir](apercus-natifs/J25.jpg) |
| J26 | Terminer un trimestre réussi | [Voir](apercus-natifs/J26.jpg) |
| J27 | Comprendre un objectif manqué | [Voir](apercus-natifs/J27.jpg) |
| J28 | Préparer un nouveau trimestre | [Voir](apercus-natifs/J28.jpg) |
| J29 | Commencer ou reprendre une partie | [Voir](apercus-natifs/J29.jpg) |
| J30 | Découvrir les premières interactions | [Voir](apercus-natifs/J30.jpg) |
| J31 | Mettre le jeu en pause et régler sa lisibilité | [Voir](apercus-natifs/J31.jpg) |
| J32 | Comprendre un achat impossible | [Voir](apercus-natifs/J32.jpg) |
| J33 | N’avoir encore aucun sujet engagé | [Voir](apercus-natifs/J33.jpg) |
| J34 | Déplier le calcul d’une récompense | [Voir](apercus-natifs/J34.jpg) |
| J35 | Transformer une enquête en décision | [Voir](apercus-natifs/J35.jpg) |
| J36 | Confirmer un changement de pratique | [Voir](apercus-natifs/J36.jpg) |
| J37 | Confirmer une arrivée dans l’équipe | [Voir](apercus-natifs/J37.jpg) |
| J38 | Adapter le travail à une absence | [Voir](apercus-natifs/J38.jpg) |
| J39 | Clore et comprendre un mandat | [Voir](apercus-natifs/J39.jpg) |
| J40 | Voir une trésorerie sous tension | [Voir](apercus-natifs/J40.jpg) |
| J41 | Voir une priorité modifiée | [Voir](apercus-natifs/J41.jpg) |
| J42 | Mettre un sujet en réserve | [Voir](apercus-natifs/J42.jpg) |
| J43 | Comprendre les clients et les charges | [Voir](apercus-natifs/J43.jpg) |
| J44 | Voir le détail d’une carte au survol | [Voir](apercus-natifs/J44.jpg) |

## Ce qui est éditable et ce qui est illustré

Textes, chiffres, commandes, positions de cartes, sélections, flux et panneaux
sont des calques séparés. Le décor, les illustrations de cartes et les emblèmes
sont des bitmaps de référence. Le cadre bois antérieur est conservé comme asset
historique. Les triptyques sont
recadrés dans les cartes par les remplissages du `.pen` ; ils n’intègrent aucun
texte ou bouton. Ils ne représentent pas les assets animés finaux.

Les assets et leurs prompts sont documentés dans [assets-prompts.md](assets-prompts.md)
et [assets-prompts-ressources.md](assets-prompts-ressources.md).
Le [manifeste d’intégration](assets-manifest.json) distingue les cinq sources
actives, les régions d’atlas, le décor de référence et l’ancien cadre à écarter
de l’import runtime. R0 traite également l’import de Fredoka avec sa notice.
Le fichier utilise le schéma `.pen` 2.22. Les scripts JavaScript de `sources/`
sont un historique local d’édition, exclu du paquet versionné. L’outil Python
versionné de ce dossier produit les aperçus, pas les écrans du jeu.

## Vérification et limites

Les 44 vues ont été rendues et exportées dans **pen.dev**, puis relues en
planches et sur des vues détaillées. Le contrôle natif ne signale aucun élément
hors cadre ; [rapport](apercus-natifs/verification.json). Les vérifications
structurelles portent aussi sur les identifiants, les références et les assets.
Les anciens aperçus locaux dans `apercus/` sont conservés comme historique ; les
liens de ce guide pointent vers les exports natifs actuels.

Les JPEG sont des dérivés des exports natifs à inclure dans Git. Les masters
PNG restent disponibles localement pour les comparaisons fines et peuvent être
réexportés depuis le `.pen`. Le script `sources/export-apercus.py` fabrique les
JPEG et les planches à partir de ces PNG ; il ne génère pas les écrans du jeu.

Ce sont des maquettes statiques : les liens documentent la navigation cible,
ils ne déclenchent pas une simulation. Les états d’accueil, les variantes et les
trimestres sont des références de moments distincts. Les montants sont
illustratifs ; ils ne valident ni le catalogue, ni les prix, ni la progression.
La conséquence d’un quota manqué et les règles exactes de la journée restent
à arbitrer. Aucun code Godot ni prototype HTML n’a été modifié.

La prochaine revue doit porter sur la lisibilité des décisions, les informations
révélées à la sélection et la réaction des cartes, puis confirmer les règles
avant une future implémentation.
