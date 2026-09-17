# Review des HUD et des états visuels — 07/09/2026

Statut : propositions à valider, aucune modification du jeu dans cette review.
Socle relu : `27971ef`, bureau FPS et interactions intégrés à main localement.
Méthode : critique design (première impression, utilisabilité, hiérarchie,
cohérence, lisibilité), captures rendues et lecture des chemins de code.
Ce n'est pas un audit WCAG ni une validation utilisateur : aucun ratio de
contraste mesuré, pas de test humain chronométré.

## Diagnostic

Le bureau donne une identité forte au jeu et la séparation ordinateur / objets
fonctionne. Les colonnes de roadmap et la jauge de capacité sont de bonnes
bases. En revanche, les états importants reposent trop sur de petits textes,
des tampons discrets et des couleurs qui servent plusieurs significations.
Il faut d'abord rendre évident **ce que j'ai choisi, ce qui est enregistré,
ce que cela coûte et ce qui arrivera au prochain clic**.

## Priorités et preuves

| Priorité | Constat vérifié | Conséquence | Proposition |
|---|---|---|---|
| P0 | Roadmap : `_on_next_pressed()` enregistre le plan ; `Workstation.close_app()` reconstruit le lanceur sans l'enregistrer. Les boutons recréés démarrent sans métadonnée `planned`. | Une sélection peut disparaître en quittant ; une réouverture ne restitue pas clairement le plan déjà validé. Le tampon « validé » est trompeur avant enregistrement. | Distinguer brouillon et enregistré. Charger le plan existant à l'ouverture ; garder le brouillon pendant le sprint ; bouton **Enregistrer le plan** et indicateur **Modifications non enregistrées**. Décider du comportement de sortie avant implémentation. |
| P1 | `_refresh_ticket_control()` change la colonne, le texte et le tampon, mais pas le style principal de la carte. | La sélection n'est pas assez reconnaissable après le mouvement. | Fond légèrement teinté, bande latérale, coche et badge textuel **Prévu ce sprint**. Ne pas dépendre de la couleur seule. |
| P1 | `_ticket_style()` réserve déjà une bordure marquée aux epics. | Réutiliser une bordure seule pour la sélection confondrait type et état. | Type en petit badge **Epic · étape 1/3** ; état en bande + coche. Garder le rouge pour les dangers plutôt que pour le type. |
| P1 | La capacité indique « Panier : 3 pts / 7 produits par l'équipe » ; la barre sature à sa borne. | Vocabulaire de boutique et dépassement peu lisible. | **3 / 7 pts engagés · 4 disponibles**, compteur des tickets ; en surcharge, texte explicite **+2 pts au-delà de la capacité**, sans interdire un pari autorisé. |
| P1 | `screen_glow.gdshader` superpose scanlines, halo et déformation au texte. Les captures Inbox/Roadmap montrent les stries dans les caractères. | La fiction d'écran concurrence la lecture des décisions. | Garder le caractère lumineux sur le lanceur ; atténuer fortement les effets pendant la lecture. Tester aux tailles de fenêtre usuelles. |
| P1 | HUD : icônes + nombres sans noms ; jauge de quota de 88×4 ; énergie en petit texte sur le bois. | Il faut mémoriser les symboles et chercher l'information critique. | Noms courts **Impact**, **Trésorerie**, **Utilisateurs** ; objectif chiffré au survol/focus ; pastille énergie contrastée près de la tasse. Garder seulement trois valeurs permanentes. |
| P1 | `get_closing_summary()` affiche capacité totale, courrier, énergie et portefeuille, pas le contenu du plan. Grande partie de la planche vide. | Dernière validation sans résumé de ce que l'on engage réellement. | Utiliser l'espace pour le plan enregistré : tickets, points engagés, capacité, courrier restant ; CTA **Lancer le sprint** avec conséquence irréversible explicite. Ne pas prédire les résultats cachés. |
| P2 | « Retour au bureau » ferme l'app mais laisse la caméra sur le lanceur ; « Quitter l'ordinateur » est distinct. | Deux sorties dont les noms ne décrivent pas les destinations. | **Applications** dans l'OS ; **Quitter l'ordinateur** hors dalle. Nommer chaque action par sa destination réelle. |
| P2 | Boutique : longs paragraphes, plusieurs lignes de coûts, action secondaire parfois plus visible que l'achat indisponible. | Comparaison lente et motif d'indisponibilité peu saillant. | Ordonner : effet principal → coût initial → charge récurrente → état/raison. Conserver les détails RP dans une lecture secondaire accessible. |
| P2 | Gestion d'équipe : la personne affichée apparaît grisée dans la liste sur la capture. | « Sélectionné » ressemble à « désactivé ». | Même traitement actif que la roadmap : fond/bande + libellé sélectionné, pas un style disabled. Clarifier les jauges, dont « Salaire /100 », distinct du salaire monétaire. |
| P2 | Résolution : beaucoup de lignes et des nombres/jauges peu nommés dans la bande inférieure. Certaines captures sont prises pendant le replay. | Le lien décision → résultat peut se perdre. | Faire ressortir les contributions et Traction × Levier = Impact ; nommer les jauges. Revoir la lisibilité à la fin réelle du replay avant de conclure sur les opacités transitoires. |

## Roadmap : langage d'états proposé

| État | Signal persistant | Retour du geste |
|---|---|---|
| Disponible | Carte papier neutre, coût bien détaché | Survol : contour/ombre modérés, curseur main |
| En déplacement | Aperçu lisible portant titre et coût | Destination valide mise en évidence, texte « Déposer ici » |
| Prévu dans le brouillon | Fond bleu très léger, bande bleue, coche, « Prévu ce sprint » | Flash unique court à l'arrivée + mise à jour de capacité |
| Plan enregistré | Confirmation au niveau du plan, pas un faux succès par ticket | « Plan enregistré · 2 tickets · 5 pts » |
| Surcharge | Avertissement ambre + nombre exact de points excédentaires | Aucun clignotement permanent, aucune interdiction nouvelle |
| Indisponible | Icône verrou et raison lisible | Pas de promesse de clic ni de drag valide |

**Sélectionné ne signifie ni livré ni réussi.** Le vert de réussite doit rester
distinct de la planification. Le badge reste lisible sans animation et en
niveaux de gris. Ne pas ajouter de calcul de règles aux composants visuels.

## Décision à valider

Recommandation : conserver un brouillon de roadmap pendant le sprint,
restaurer le plan enregistré à la première ouverture et avertir si l'on
quitte avec des changements non enregistrés. L'enregistrement reste explicite.
Alternative : enregistrement automatique à chaque geste, mais cela change
le moment de validation actuel et doit être arbitré, pas glissé dans le polish.
Dans les deux cas, revisiter le bureau ne doit pas perdre silencieusement
le travail du joueur. Ne pas déclencher le calcul des autres équipes à chaque drag.

## Lots proposés

1. **Confiance dans la roadmap** : conservation/validation du plan, états des
   tickets, capacité et destination de drop. Priorité au fonctionnement avant
   d'affiner les animations.
2. **Lisibilité de lecture** : effets d'écran, noms des ressources, énergie,
   libellés de navigation et résumé de clôture.
3. **Cohérence globale** : hiérarchie des cartes boutique/Comité, sélection
   d'employé, feedback des réponses Inbox et lecture finale de Résolution.

Recette future : clic et drag produisent le même état ; sélection visible
après animation ; aller-retour app sans perte ; annulation de brouillon
explicite ; plan de clôture identique au plan réellement résolu ; surcharge
encore possible ; informations cachées toujours masquées ; N=1 sans couche
squad ; captures 1920×1080 et 1280×900 ; quatre suites de tests existantes,
tests nouveaux de conservation et parcours visuel complet.

## Sources locales

- `game/scripts/screens/roadmap_screen.gd` : `_ticket_style`,
  `_refresh_ticket_control`, `_update_capacity`, `_on_next_pressed`.
- `game/scripts/components/workstation.gd` : `_os_bar`, `close_app`.
- `game/scripts/screens/desk_screen.gd` : `_refresh_vitals`, `_progress_bar`,
  `_refresh_anchored_labels`.
- `game/scripts/autoload/sprint_state.gd` : `get_closing_summary`.
- `game/resources/shaders/screen_glow.gdshader`.
- Captures : `review-evidence/interactions-bureau/`, notamment
  `roadmap_scroll_false.png`, `desk_calme.png`, `desk_shop.png`,
  `desk_closing.png`, `run_immersif_1_inbox.png`,
  `run_immersif_1_resolution.png`, `team_management_screen.png`.

La capture `roadmap_scroll_false.png` provient d'un fixture de molette avec
espace ajouté au backlog ; l'espace vide n'est pas retenu comme défaut du jeu.
