# Refonte de l'expérience Product Tycoon

Direction précisée par Camille le 14 novembre 2026.

**Direction antérieure de l’interface existante.** La cible des prochains
développements est définie par le [contrat du rework](contrat-rework-bureau.md)
et son plan, avec les maquettes du bureau vu du dessus. Le cadrage mobile et
les décisions par sprint ci-dessous ne remplacent pas cette cible.

Ce document décrit le chantier d’interface du bureau existant. La conception
du prochain rework se poursuit désormais dans la
[vision du bureau et de l’organisation](vision-bureau-organisation.md), après
les essais du 15 novembre. Cette nouvelle direction n’est pas implémentée ici.

## Intention

Le bureau 3D est l'interface principale. Le regard reste posé. Le joueur touche
un objet, la caméra s'approche, il prend une décision puis revient voir son
entreprise évoluer. La lecture doit tenir à la distance de jeu sur téléphone
en paysage et sur ordinateur.

Le joueur doit pouvoir répondre à trois questions à tout instant.

1. Qu'est-ce que j'essaie d'accomplir maintenant ?
2. Quel choix concret puis-je faire et quel compromis comporte-t-il ?
3. Qu'est-ce que ce choix a changé et qu'est-ce qui m'attend ensuite ?

## Constats à corriger

Le bureau donne un accès simultané aux applications, aux ressources, aux alertes,
aux posters et aux objets. La présence de ces éléments ne fait pas ressortir
l'étape utile. Les applications héritent d'une interface dense réduite dans une
texture. Les cartes mélangent titre, état, attributs, diagnostic et actions.
Le bilan commence par les explications du moteur et présente beaucoup de valeurs
avant de faire ressortir une réussite ou un échec compréhensible.

Les écrans tactiles séparés ont amélioré la taille des textes mais ont cassé
l'unité de l'expérience avec les objets du bureau.

## Bureau et navigation

Un seul objectif du sprint apparaît au premier plan. Son bouton ouvre l'objet
correspondant en 3D. Tous les objets restent utilisables directement.

- Un message attend. L'objectif propose de prendre une décision.
- Le courrier est traité. L'objectif propose de préparer une livraison.
- Le plan est enregistré. L'objectif propose d'en découvrir le résultat.
- Le Comité est disponible. L'objectif signale le choix stratégique ouvert.

Une courte indication rappelle le prochain jalon réel du trimestre. Le quota se
consulte sans monopoliser la pièce. Les alertes remontent la menace la plus
urgente. Le détail de l'entreprise reste une consultation volontaire.

Le rapprochement de caméra conserve le cadre de l'objet et une partie du décor.
Les informations utiles sont plus grandes dans l'objet ouvert. Reposer ramène
toujours au même bureau. Aucun déplacement libre du regard n'est nécessaire.

## Messages

Le message présente un problème concret et trois réponses. Le canal, l'heure et
les en-têtes répétés deviennent secondaires. Après la réponse, le contexte
s'efface au profit du choix et de ses conséquences. Un détail repliable permet
de relire le contexte. Le joueur peut enchaîner vers sa planification.

## Roadmap

Le premier niveau présente le nom du ticket, son coût en capacité et sa commande
de planification. Les attributs cachés restent cachés. Le détail sert à comprendre
la portée d'une livraison et l'intérêt de dépenser de l'énergie pour enquêter.

Les tickets disponibles et le plan sont deux vues de travail. Leur comparaison
n'impose pas deux colonnes chargées. Le compteur de capacité reste visible.
L'enregistrement du plan matérialise un engagement et donne accès à son récapitulatif.

## Boutique et équipe

Le joueur parcourt les investissements individuellement. Chaque fiche fait
d'abord ressortir sa promesse, le prix d'achat et la charge récurrente. La
composition de l'offre et les comparaisons détaillées se consultent au besoin.

L'équipe se présente d'abord comme des personnes avec une situation concrète.
Le diagnostic complet et les actions apparaissent après avoir choisi quelqu'un.

## Résultat et envie de poursuivre

Le premier niveau du bilan met en avant les livraisons et l'Impact produit.
Le détail de la formule, les jauges et le journal se déplient volontairement.
Le texte explique un résultat nul et son origine. Le prochain jalon réel est
annoncé après le résultat.

Les premiers ressorts utilisent les systèmes existants. Ils montrent le prochain
Comité, l'amélioration du moteur et les synergies déjà découvertes. Les quotas
et les deux économies conservent leur sens.

## Progression à relire avant implémentation

Cette partie propose des changements de game design et attend la relecture
prévue par CLAUDE.md.

- Sprint 1. Une première livraison avec l'équipe héritée donne un résultat
  rapide et compréhensible. Le joueur découvre le rapport Traction × Levier.
- Sprint 2. Une occasion d'améliorer ce moteur rend la boutique pertinente.
  Le jeu annonce le bénéfice recherché et laisse le joueur accepter son coût.
- Sprint 3. Le premier verdict donne de la tension, puis le Comité ouvre une
  famille de décisions plus engageantes.
- Trimestre 2. Les chantiers longs et les besoins individuels prennent davantage
  de place. Le joueur retrouve des conséquences de ses décisions précédentes.

Le contenu doit rester rejouable. Les introductions sont des occasions
contextuelles, pas une suite de clics imposés. Un joueur expérimenté accède
directement à ses décisions.

Points à valider avant de changer les règles ou les tirages. Le niveau de
garantie d'une première livraison, le moment de présentation des achats,
la cadence des nouvelles familles de choix et le traitement des introductions
lors des parties suivantes.

## Critères de réussite

Une personne découvrant le jeu identifie sa prochaine action sans lire un écran
de règles. Une décision se prend et se relit sans sortir du cadre de l'objet.
Le résultat explique ce qui a été accompli. Le joueur peut nommer ce qu'il veut
essayer au sprint suivant.

La recette couvre le premier sprint au doigt, trois sprints jusqu'au Comité,
une situation d'alerte et une reprise de partie. Les tests du moteur protègent
les règles, les captures vérifient la densité et un playtest humain mesure
la compréhension et l'envie de continuer.
