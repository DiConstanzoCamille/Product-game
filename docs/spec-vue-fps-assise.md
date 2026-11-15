# Vue FPS assise — caméra, visée et focus d'interface

**Cadrage du jeu existant, conservé comme historique technique.** La cible du
prochain rework est le bureau vu du dessus du [contrat](contrat-rework-bureau.md).
Ne pas réintroduire la visée FPS pour un nouvel écran du rework sur la seule
base de cette ancienne spec.

> Spec de cadrage du 23/08/2026, mise en œuvre autorisée par Camille le
> 05/09/2026 avec la refonte globale des assets. Lot implémenté et recette
> automatisée terminée le 07/09/2026 ; détails et limites au §11.
>
> Ce lot prolonge `spec-bureau-3d.md` sans modifier les règles du jeu. Il rend
> la pièce habitable depuis le fauteuil du ou de la CPO, tout en conservant le
> contrat fondamental : le monde est en 3D, ce qui se lit reste net en 2D.

## 1. Problème

Le bureau est une vraie scène 3D mais sa caméra fixe se comporte encore comme
le cadrage d'une maquette. Le joueur peut cliquer des volumes, sans avoir la
sensation de regarder autour de lui ni de choisir vers quoi porter son
attention. Une caméra totalement libre résoudrait ce manque d'incarnation,
mais dégraderait la lecture des applications et ajouterait une navigation sans
valeur dans un jeu de décisions.

La cible est donc une **première personne assise** : tête mobile, corps fixe,
visée centrale dans le monde, puis focus automatique et curseur libre dès
qu'une interface doit être lue.

## 2. Objectifs

1. Faire ressentir que le joueur occupe le fauteuil du CPO et regarde les
   objets de son bureau, sans transformer le jeu en simulateur de déplacement.
2. Permettre d'atteindre chaque objet interactif par une visée centrale claire,
   avec un retour de survol avant le clic.
3. Garantir que toute interface lisible retrouve automatiquement son angle et
   son échelle de référence avant de recevoir une entrée.
4. Ne créer aucun état où la souris est capturée, le curseur perdu ou la sortie
   inaccessible.

## 3. Non-objectifs

- **Pas de déplacement WASD**, de collisions de personnage ni d'exploration de
  la pièce : le poste de travail est le niveau, pas un couloir.
- **Pas de head bob**, roulis, motion blur ou inertie longue : ils n'apportent
  rien à la décision et augmentent l'inconfort.
- **Pas de règle de gameplay liée à l'orientation** : regarder ailleurs ne
  consomme ni temps, ni Énergie, et ne cache aucune information de façon
  punitive.
- **Pas de passage des interfaces en 3D** : les applications restent des
  `Control` rendus dans leurs `SubViewport`.
- **Périmètre étendu le 05/09/2026 :** refonte artistique de la pièce et des
  accessoires dans la direction du nouveau laptop, demandée avec la vue FPS.

## 4. Expérience cible

### 4.1 Mode Observation — première personne

- Au chargement, une pose assise plus reculée montre le clavier et le plateau.
  Le cadrage de référence historique devient la pose de lecture du laptop.
- La souris est capturée après un clic explicite dans la scène ; son mouvement
  oriente la tête dans des bornes confortables déclarées dans
  `data/balance.json → desk.camera`.
- Un réticule discret indique le centre de visée. Le premier `Area3D` atteint
  par le rayon reçoit le même état de survol que la souris aujourd'hui : objet
  soulevé, étiquette accentuée, info-bulle éventuelle.
- Le clic gauche active la cible visée. Une zone vide ne déclenche rien.
- Échap libère la souris au repos. Le prochain clic dans la scène la recapture.
- Les valeurs permanentes restent en 2D et lisibles quelle que soit
  l'orientation.

### 4.2 Mode Focus — lire et décider

Quand une application, un accessoire ou un poster est activé :

1. les interactions du monde sont verrouillées selon le contrat modal du
   carnet §38 ;
2. la caméra effectue une transition courte vers l'ancre de lecture propre à
   l'objet ;
3. l'ancre place la caméra quasi perpendiculairement au quad lisible et restaure
   sa taille projetée de référence ;
4. seulement à la fin de la transition, le curseur devient visible et libre
   dans l'interface.

Le clic extérieur, « Reposer » ou Échap ferment le focus. La caméra revient à
la dernière orientation d'observation, puis la souris est recapturée si elle
l'était avant l'ouverture. Une transition interrompue converge toujours vers
le dernier état demandé ; deux tweens de caméra ne peuvent pas se battre.

### 4.3 Trois natures de focus

| Cible | Entrée | Focus | Sortie |
|---|---|---|---|
| Laptop | Viser la dalle, clic | Dalle de face, curseur dans le logiciel | Retour au lanceur puis au regard libre |
| Accessoire | Viser sa couverture, clic | Panneau présenté de face, monde verrouillé | Reposer l'objet puis retrouver le regard |
| Poster / tasse | Viser l'objet, clic ou survol | Geste existant, détail 2D si nécessaire | Clic extérieur ou Échap |

Le laptop constitue deux niveaux : fermer une application revient d'abord au
lanceur sans quitter le focus écran ; quitter le lanceur rend le regard libre.

## 5. États d'entrée — contrat non négociable

```text
OBSERVATION_CAPTURÉE
  ├─ Échap ───────────────→ OBSERVATION_CURSEUR_LIBRE
  └─ activer une cible ───→ TRANSITION_FOCUS

TRANSITION_FOCUS
  └─ arrivée à l'ancre ───→ FOCUS_INTERFACE

FOCUS_INTERFACE
  ├─ retour interne ──────→ FOCUS_INTERFACE (ex. app → lanceur)
  └─ Reposer / Échap ─────→ TRANSITION_RETOUR

TRANSITION_RETOUR
  └─ arrivée ─────────────→ état OBSERVATION précédent
```

- Un seul contrôleur possède `Input.mouse_mode`.
- Un seul état accepte la rotation de caméra.
- Un seul objet peut posséder le focus.
- Le changement de scène et la perte de focus de la fenêtre rendent toujours
  le curseur visible ; aucune capture fantôme n'est permise.

## 6. Exigences

### P0 — prototype livrable

1. **Contrôleur de caméra assise.** Yaw et pitch bornés, sans translation
   libre. Toutes les amplitudes, sensibilités et durées vivent dans
   `balance.json`, jamais dans le script.
2. **Visée centrale.** Un rayon physique unique choisit la cible la plus proche
   et pilote son hover. Les anciennes interactions directes restent disponibles
   dans le mode confort décrit ci-dessous.
3. **Machine à états explicite.** Observation, transition, focus interface et
   retour sont testables sans souris réelle.
4. **Ancres de lecture calculées.** La dalle et chaque panneau d'accessoire
   déclarent une position et une base de focus ; le contrôleur ne connaît pas
   leur géométrie interne.
5. **Curseur et Échap sans impasse.** Chaque état possède une sortie mécanique
   et couverte par un test.
6. **Mode confort.** Une option désactive la capture permanente : maintenir le
   clic droit fait regarder autour, relâcher rend le curseur. Le gameplay et
   les cibles sont identiques dans les deux modes.
7. **Compatibilité avec le verrou modal.** En focus, aucun élément extérieur ne
   reçoit hover, clic ou raccourci destiné à l'objet actif.

### P1 — finition après validation du prototype

- Accélération très légère du regard, désactivable.
- Transition de focus avec courbe et durée propres à la distance, sans dépassement.
- Réglages de sensibilité X/Y et inversion de l'axe vertical.
- Indication contextuelle « Cliquer pour regarder » / « Échap : libérer la souris ».
- Navigation clavier ou manette entre cibles, sans dépendre d'un pixel précis.

### P2 — assurance architecturale, hors lot

- Support manette complet avec stick droit et aim assist discret.
- Petites animations d'ambiance indépendantes de la caméra.
- Changement de fauteuil ou seconde pièce, uniquement si une règle future le
  justifie.

## 7. Critères de recette

- [ ] Depuis le cadrage initial, chaque cible P0 est atteignable sans déplacer
      le corps et montre un hover avant activation.
- [ ] Yaw et pitch ne permettent jamais de voir hors de la pièce construite.
- [ ] Ouvrir le laptop replace sa dalle à moins de 6 % de `SCREEN_PIXELS` en
      taille projetée avant de libérer le curseur.
- [ ] Le texte du laptop et des accessoires n'est ni flou ni incliné en focus.
- [ ] Clic extérieur, Reposer et Échap respectent la priorité du premier plan.
- [ ] Perdre puis reprendre le focus de la fenêtre ne laisse jamais la souris
      capturée sans contrôle de caméra.
- [ ] Fermer une application revient au lanceur sans mouvement de caméra ;
      quitter le lanceur revient à l'orientation précédente.
- [ ] Les modes immersif et confort permettent la même partie complète.
- [ ] Les deux smoke tests headless passent et couvrent toutes les transitions
      de la machine à états.
- [ ] Un run visuel complet est relu à 16:9 et dans une fenêtre redimensionnée.

## 8. Mesure du succès

### Indicateurs immédiats

- 100 % des cibles interactives activables par le rayon dans le banc UI.
- 0 entrée reçue par le monde pendant un focus modal.
- 0 transition caméra concurrente après 100 alternances focus/retour.
- 100 % des sorties Échap rendent le mode souris attendu.

### Validation humaine du prototype

- Une partie de cinq minutes sans perte de curseur ni clic attribué au mauvais
  objet.
- Tous les textes de décision restent lisibles sans correction manuelle de la
  caméra.
- Le regard libre donne une sensation d'incarnation sans ralentir l'accès à la
  Roadmap, à la Boutique et à la clôture.

## 9. Découpage recommandé

1. **Spike caméra** — contrôleur, bornes et deux modes de souris sur la pièce
   actuelle, sans transition ni modification des objets.
2. **Visée** — rayon central, réticule et adaptation du contrat de hover.
3. **Focus** — ancres de lecture, transitions, curseur et verrou modal.
4. **Recette** — tests de la machine à états, cent alternances, captures et run
   complet.

## 10. Arbitrages proposés à valider

1. **Mode par défaut : immersif.** Clic dans la scène pour capturer la souris,
   Échap pour la libérer. Le mode « maintenir clic droit » reste disponible
   dans les options de confort.
2. **Bornes initiales :** environ ±18° horizontalement et ±10° verticalement,
   puis ajustement sur le spike afin que tous les objets restent atteignables
   sans montrer les bords vides de la pièce.
3. **Retour d'orientation :** après un focus, retrouver exactement le regard
   précédent plutôt que recentrer systématiquement le joueur.
4. **Aucune oscillation de tête**, même décorative. L'incarnation vient du
   contrôle et du focus des objets, pas d'un mouvement permanent.

## 11. État livré — 07/09/2026

Le mode immersif est le défaut. Le bouton de confort, en bas à gauche du
bureau, permet de passer au clic droit maintenu. Ce choix est conservé durant
la session, pas dans un fichier de préférences. Le curseur est libre à
l'arrivée ; le premier clic capture le regard, le suivant active la cible.
Échap quitte d'abord l'application, puis le focus du laptop. Le bouton
« Quitter l'ordinateur » et un clic hors écran permettent aussi de sortir.

`DeskViewController` possède la caméra, son tween et `Input.mouse_mode`.
Les bornes effectivement retenues sont ±42° horizontalement, +24° vers le
haut et −32° vers le bas : les valeurs initialement proposées ne suffisaient
pas à viser tous les accessoires. Pose, FOV, bornes, sensibilité, inversion Y,
longueur du rayon et durée de transition sont dans `balance.json → desk.camera`.
Il n'y a ni déplacement libre, ni head bob, ni inertie de tête.

En observation, un rayon sélectionne la première zone interactive visible.
En lecture, les autres zones sont neutralisées. Le laptop retrouve sa pose
et sa taille de référence ; les accessoires rejoignent cette pose avant de
se présenter de face. Leurs entrées restent bloquées durant le déplacement
du panneau. Un Échap durant la transition annule l'entrée et rend le curseur.
Une perte de focus de fenêtre ou une sortie de scène rend toujours la souris.

Le FOV de lecture s'adapte au canevas logique lors d'un redimensionnement,
sans refaire le modèle ni décaler le routage des clics. La pièce comporte
désormais des murs latéraux et un plafond pour couvrir les limites du regard.

Recette exécutée : suites logique, UI et FPS ; visée de toutes les cibles,
100 alternances focus/retour, interruption de tween, perte de focus, deux
parcours rendus jusqu'à une fin de run (modes immersif et confort), clics
3D sur les réponses du courrier et la signature, et lecture/clics après
redimensionnement en 1280×900. Les captures nominales des écrans, les quatre
limites du regard et les vues de lecture sont dans
`docs/review-evidence/bureau-fps/`.

Limites : il s'agit de parties automatisées, pas d'une validation humaine du
confort pendant cinq minutes. Les réglages fins ne sont pas encore exposés
dans une UI dédiée ; la navigation clavier/manette entre cibles et les autres
finitions P1/P2 ne sont pas livrées. Le comportement métier historique du
Comité (dossier consommé quand on le repose) est conservé par ce lot visuel.

### Correctif de recette — 07/09/2026

Le premier clic libre sur un objet l'ouvre directement ; seul un clic dans
le décor capture le regard. Le clavier est aussi une cible du portable.
En lecture, un relais de surface maintient les déplacements et relâchements
hors dalle, notifie le survol et préserve le curseur visible. Échap annule
d'abord un glissement actif avant de fermer une application. Voir carnet §41
et la recette `smoke_test_desk_input.tscn` pour les cas vérifiés.
