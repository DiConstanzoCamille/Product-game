# Vision HUD — « Un bureau qui répond »

Prototype jouable du 07/09/2026, à valider. Branche :
`codex/prototype-hud-lisibilite`. Ce document distingue la direction globale
des morceaux effectivement développés. Il ne change aucune règle de gameplay.

## Intention globale

**Le décor situe. Le HUD oriente. Le geste laisse une trace.**

Le bureau doit rester un lieu, pas devenir un tableau de bord plein écran.
Les trois nombres permanents répondent à « comment va mon entreprise ? ».
Les objets répondent à « où agir ? ». L'application ouverte répond à
« qu'est-ce que je choisis, combien cela coûte et qu'ai-je prévu ? ».
La clôture puis la résolution expliquent l'engagement et ses conséquences.

L'identité papier, encre et accessoires demeure. Les couleurs portent un
sens stable : bleu = intention/choix, vert = résultat obtenu, ambre = risque.
Un symbole et du texte accompagnent toujours un état essentiel : une carte
bleue seule n'explique pas si elle est survolée, planifiée ou livrée.

## Rôle de chaque interface dans la vision globale

| Interface | Question à résoudre | Intention de présentation |
|---|---|---|
| Bureau / HUD | Où en suis-je ? | Trois ressources nommées, alertes par exception, énergie près de la tasse ; préserver le décor. |
| Roadmap | Qu'est-ce que j'engage ? | Cartes manipulables, intention persistante, capacité et validation explicites. |
| Inbox | Quel pari prendre ? | Situation, options, puis conséquence visible ; ne pas révéler l'information cachée en avance. |
| Boutique / Comité | Qu'est-ce qui change mon organisation ? | Effet principal, coût initial et coût récurrent comparables ; raisons d'indisponibilité nettes. |
| Équipe | Qui a besoin de moi ? | Personne sélectionnée distincte d'une personne indisponible ; signaux humains avant les actions. |
| Clôture | À quoi suis-je en train de m'engager ? | Résumé du vrai plan et des éléments laissés de côté, puis signature. |
| Résolution | Pourquoi ce résultat ? | Relier mes choix au score : contributions, Traction × Levier, Impact et variations des ressources. |

Cette table est une direction, pas une promesse que tous ces écrans ont été
refaits. Les morceaux ci-dessous servent à valider le langage avant diffusion.

## Morceaux développés pour juger sur pièce

1. **Roadmap** : carte neutre au repos, contour au survol ; sélection avec
   fond bleu clair, bande de 6 px et « ✓ PRÉVU CE SPRINT ». Le statut epic
   devient un préfixe textuel, sans bordure rouge confondue avec un danger.
   Le tampon vert de réussite est retiré de la planification. Une zone valide
   de dépôt reçoit un cadre renforcé pendant le glissement. Les animations
   de changement de colonne existantes sont conservées.
2. **Capacité** : « 3 / 7 pts engagés · 4 disponibles », nombre de tickets
   dans l'en-tête ; dépassement explicite. Aucun blocage de surcharge ajouté.
3. **HUD** : les trois ressources sont nommées (Impact, Trésorerie,
   Utilisateurs), avec leurs infobulles existantes. Même nombre de valeurs,
   aucun nouveau panneau permanent.
4. **Lecture** : effet d'écran conservé sur le lanceur mais retiré des apps
   pour comparer la netteté du texte. « Applications » nomme la vraie
   destination du retour ; « Enregistrer le plan » nomme l'action existante.

Les couleurs et le style des cartes sont regroupés dans `hud_language.gd`.
Ce sont des tokens visuels, pas des valeurs d'équilibrage. La démarche de
design system a guidé la séparation type / état et couleur / signification.

## Limites volontaires

Le prototype ne corrige pas encore la conservation du brouillon de roadmap.
**Il faut cliquer Enregistrer le plan avant de quitter.** Une infobulle le
précise ; l'arbitrage sauvegarde automatique / brouillon / confirmation reste
à valider, comme documenté dans `review-hud-lisibilite.md`.

Énergie contrastée, résumé de clôture, hiérarchie boutique/Comité, sélection
d'employé et récit de résolution appartiennent à la vision globale, pas aux
morceaux livrés ici. Aucun résultat caché n'est révélé et aucune monnaie ni
règle de validation n'est modifiée. Pas de push ni de merge de ce prototype.

## Comment juger le prototype

Lancer normalement le jeu depuis cette branche. Ouvrir Roadmap, déplacer
un ticket à droite puis le retirer avec « − Sprint ». Vérifier qu'une carte
prévue se reconnaît encore lorsque la souris la quitte. Ajouter plusieurs
tickets pour lire la surcharge, puis enregistrer via le bouton explicite.

Captures reproductibles : lancer `res://tests/hud_prototype_preview.tscn`
avec `SHOT_DIR` pointant vers un dossier absolu existant. Ce harnais met en
scène les vrais composants ; les interactions réelles sont couvertes par
`smoke_test_desk_input.tscn`, distinct du harnais de capture.

À valider avec Camille : le bleu exprime-t-il clairement une intention plutôt
qu'un succès ? Les noms du HUD prennent-ils trop de place ? Préfère-t-on
la netteté complète des apps ou un léger grain sans stries ? Une fois cette
direction approuvée, décliner le même langage sur les autres objets.

Le cadrage 1280×900 ne déborde pas mais les petites lignes restent denses :
le prototype n'est pas une validation d'accessibilité ni une solution finale
de taille de police. Un mode de lecture plus grand pourra faire l'objet du
prochain essai, sans toucher au cadrage d'observation du bureau.

## Tranche suivante : activité et repérage des objets

Développée après validation de Camille (« ok test », puis demande d'étiquettes
plus visibles). Les tuiles du lanceur indiquent le courrier restant, le plan
enregistré (tickets/points/capacité), les utilisateurs et l'Impact disponible.
Le plan vient exclusivement du rapport du sprint courant ; un brouillon ou
une prévision ne devient pas un résultat. Un epic terminé compte une seule
fois. Le nombre représente le plan de l'équipe pilotée, pas un total inventé
pour les équipes en pilotage automatique.

Boutique, Comité et Fin de sprint portent des étiquettes opaques cliquables,
à texte sombre, avec leur rôle ou leur état. Le contour bleu souligne le
survol sans changer leur taille. Elles suivent les objets, disparaissent en
lecture et reviennent en observation ; une marge protège les commandes du
bas de l'écran. La planche affiche le plan enregistré et le courrier restant.

Un petit retour transitoire affiche les variations réellement observées
d'Impact, trésorerie, utilisateurs ou énergie pendant la présence au bureau.
Maximum trois retours simultanés, puis disparition ; ni gain initial fictif,
ni répétition au rafraîchissement, ni rejeu des gains d'une autre scène.
Cette tranche ne remplace toujours pas le chantier de sauvegarde du brouillon.

Recette : `hud_activity_preview.tscn` avec ou sans rendu, captures dans
`docs/review-evidence/hud-activite/`, quatre suites de non-régression,
tour des écrans et deux parcours rendus. Les captures spécifiques comparent
les étiquettes en 1920×1080 et 1280×900, l'accueil enregistré et un −15 Énergie
provenant d'une vraie action d'investigation du jeu.
