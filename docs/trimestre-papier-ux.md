# Trimestre sur papier — support de discussion UX

**Exercice historique, antérieur au bureau simulé.** Pour la conception à
poursuivre, lire la [vision du bureau et de l’organisation](vision-bureau-organisation.md).
Les sprints, cartes et valeurs de cet exercice ne sont pas une règle validée
du prochain rework.

15 novembre 2026. Maquette de navigation, pas un nouvel équilibre ni une
modification du jeu. Les cartes, prix et formules ci-dessous sont des fixtures
illustratives. Le tirage fixe sert à comparer des parcours, pas à remplacer
l’aléatoire du roguelike. Aucun score futur exact n’est annoncé avant livraison.

## Le cadre validé

Un seul solde d’Impact, dépensable et comparé au quota. Les investissements
font reculer sa progression vers l’objectif. La trésorerie finance les charges
et demeure indépendante du score. La priorité est l’UX/UI et la navigation ;
aucune fusion de ressource ou suppression de système n’est validée.

## Ce que l’on cherche à éprouver

- Peut-on préparer sa livraison sans visiter plusieurs applications ?
- Comprend-on les contributions en les voyant se déclencher ?
- Comprend-on qu’un achat coûte de l’Impact et parfois aussi de l’argent ?
- Sait-on revenir à sa livraison après avoir consulté un détail ?
- Une opportunité donne-t-elle une intention pour le sprint suivant ?

## Carte de navigation

Le bureau cadre le plateau ; une approche caméra permet la lecture.

    Préparer une livraison → Dérouler ses effets → Voir le résultat
              ↑                                      ↓
              └───────── Sprint suivant ← Opportunités

Depuis la préparation : une fiche projet, l’équipe, les outils, la trésorerie
et le contrat s’ouvrent en contexte. Un retour explicite ramène à la sélection
intacte. Ces accès ne sont pas des étapes à accomplir pour continuer.

Depuis une opportunité : examiner → voir le coût et le solde après achat →
investir ou revenir. Le refus reste possible ; pas de dépense par simple
consultation. Un bonus découvert est reconnaissable au sprint suivant.

## État initial fictif

Sprint 1 sur 3. Contrat : conserver au moins 150 Impact à la fin du trimestre.
Impact 0 ; trésorerie 80 ; 12 clients payant 2 par sprint ; charges 20.
Capacité 6 ; équipe donnant un multiplicateur de base ×1,5.

La maquette simplifie volontairement le calcul. Elle ne prétend pas simuler
les risques, caractères, événements, impôts, ou autres règles du moteur réel.

## Trois sprints à comparer

| Sprint | Projet technique | Projet commercial | Projet qualité |
|---|---|---|---|
| 1 | Synchroniser les factures : 3 capacité, 18 production, 0 client | Abonnement Pro : 3, 14, +3 clients | Inscription simplifiée : 2, 12, +1 client |
| 2 | Automatisation : 3, 24, 0 | Parrainage : 3, 20, +3 | Correction mobile : 2, 16, +1 |
| 3 | Nouveau moteur : 3, 32, 0 | Offre Équipe : 3, 26, +3 | Finition produit : 2, 22, +1 |

Ces chiffres sont des valeurs de résolution. Avant la livraison, la carte
présente le coût, la famille et l’intérêt du projet ; les détails accessibles
ne promettent pas une production future chiffrée.

Deux opportunités fictives :

- Pipeline de livraison : 25 Impact, 4 trésorerie de licence par sprint ;
  ×1,4 sur la livraison si elle contient un projet technique.
- Renfort développeuse : 35 Impact, 8 de salaire par sprint ;
  +2 capacité et +0,25 au multiplicateur d’équipe.

Les achats se font ici entre deux livraisons. C’est une hypothèse de parcours
à discuter, car déplacer les achats réels change leur utilité et le timing
du quota. Le Comité reste un sujet de conception ultérieur, pas une seconde
boutique ajoutée à ce test.

## Parcours de référence : comprendre un investissement

1. Sprint 1 : Synchroniser les factures + Abonnement Pro, capacité 6/6.
2. Résolution : 18 + 14 = 32 production ; équipe ×1,5 = 48 Impact.
3. Les clients passent à 15 ; trésorerie 80 + 30 revenus − 20 charges = 90.
4. Examiner le Pipeline : coût 25 ; solde 48 → 23 / 150 ; licence +4/sprint.
5. Investir : la même progression d’Impact recule. L’outil rejoint le plateau.
6. Sprint 2 : Automatisation + Correction mobile, capacité 5/6.
7. Résolution : 40 × 1,5 × 1,4 = 84 ; solde 23 + 84 = 107.
8. 16 clients ; trésorerie 90 + 32 − 24 = 98.
9. Refuser une autre dépense ; sprint 3 : Nouveau moteur + Offre Équipe.
10. Résolution : plancher(58 × 1,5 × 1,4) = 121 ; solde 228 / 150.
11. 19 clients ; trésorerie 98 + 38 − 24 = 112. Contrat tenu.

Le résultat n’est pas une démonstration d’équilibrage. Ce parcours vérifie
seulement que le coût, l’activation et la contribution sont compréhensibles.

## Parcours contrastés

- **Ne pas investir** : garder son Impact, comparer ce qui manque en puissance.
- **Acheter puis éviter les projets techniques** : l’outil reste présent mais
  ne s’active pas ; la fiche explique sa condition. Pas de bonus silencieux.
- **Recruter** : la capacité augmente, le salaire apparaît dans les charges.
- **Choisir deux projets puis ouvrir les finances** : retrouver sa sélection.
- **Ne sélectionner aucun projet** : le lancement est indisponible dans cette
  maquette. La possibilité de livrer à vide dans le vrai jeu reste à trancher.
- **Rater le quota** : cause visible dans le contrat et le résultat. Aucun
  score de production parallèle ne vient faire croire que l’objectif est tenu.

## Ce que chaque vue doit montrer

| Vue | Visible immédiatement | Sur demande |
|---|---|---|
| Préparation | Solde/objectif, échéance, capacité, projets, action Livrer | Projets, membres, conditions des outils, finances |
| Résolution | Contribution en cours et compteur résultant | Replay et calcul complet |
| Résultat | Gain, nouveau solde face au quota, bilan financier court | Historique du calcul, composition des finances |
| Opportunité | Effet principal et coût d’Impact | Charges, condition, solde après achat avant confirmation |

## Débrief à faire ensemble

Commencer sans expliquer les règles : « prépare une livraison ». Observer où
le regard et les gestes se portent. Après l’achat, demander quel nombre a
baissé et pourquoi. Après le bonus, demander quelle pièce l’a déclenché.

Noter les hésitations de navigation, les informations cherchées et les textes
qui ont vraiment été lus. Ne pas prendre la réussite du quota pour une preuve
de compréhension. Vérifier la densité et la taille tactile sur un vrai iPhone.

Avant implémentation, il reste à décider : cadrage mobile, densité des cartes,
présence des objets d’équipe autour du plateau, rythme des opportunités et
traitement des événements humains dans ce parcours. Les changements de règles
ou de technique éventuels viennent après cet alignement.
