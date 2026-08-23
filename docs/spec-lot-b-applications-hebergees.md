# Lot B — applications hébergées et chrome hors contenu

> Spec de cadrage (23/08/2026), issue #10. À valider avant implémentation.
>
> Le bureau 3D et les hotfixes #61–#63 ont sécurisé la boucle de jeu. Ce lot
> ne change aucune règle : il donne à chaque interface la forme et les gestes
> de l'objet qui l'héberge.

## 1. Problème

Les écrans historiques ont été rendus dans le laptop, la tablette et le
parapheur sans être conçus pour ces cadres. Le hotfix a supprimé les callbacks
destructifs et la navigation en double, mais l'hôte adapte encore ses invités
par chemins de nœuds, et le bouton « Reposer » est peint dans la texture de
l'accessoire. L'interface fonctionne ; elle ne dit pas encore clairement ce
qui appartient au logiciel, à l'objet et au bureau.

La boîte mail en fil, les canaux, la Roadmap en tickets et sa gouttière sont
déjà présents dans `main`. Ils doivent être consolidés, pas réinventés.

## 2. Règle de partage

| Couche | Responsabilité | Exemples |
|---|---|---|
| Contenu métier | Décider et expliquer les conséquences | Répondre, déplacer un ticket, acheter, adopter |
| Chrome de l'hôte | Nommer et fermer l'application | Barre du laptop, geste pour reposer un accessoire |
| Bureau | Changer d'objet et conserver le contexte | Cliquer ailleurs, Échap, valeurs permanentes |

**Règle non négociable : le contenu invité ne porte aucun bouton de navigation
du tunnel historique.** « Accueil », « Retour », « Continuer » et « Reposer »
n'appartiennent pas aux applications. Les CTA métier restent dans leur contenu.

## 3. Expérience cible

### 3.1 Laptop

- La dalle porte une unique barre système avec le nom de l'application et
  « Retour au bureau » ; aucune seconde barre n'est rendue par l'Inbox ou la
  Roadmap.
- Échap ferme l'application ouverte et revient au lanceur du laptop.
- Les applications déclarent leur contrat d'hébergement (fin, mutation,
  dimensions utiles) ; l'hôte ne recherche plus leurs boutons par `NodePath`.
- Inbox et Roadmap tiennent dans 880×495 sans texte ou CTA coupé, à 100 % de
  l'échelle UI.

### 3.2 Accessoires (étal, Comité, clôture)

- Aucun bouton « Reposer » n'est peint dans le `SubViewport` de l'objet.
- Trois gestes ferment l'accessoire sans appliquer d'action métier : Échap,
  clic hors de l'objet ouvert, et une commande globale « Reposer » rendue dans
  le `CanvasLayer` du bureau — donc hors de sa texture.
- Les achats et décisions restent dans l'accessoire ; fermer ne valide, ne
  paie et ne choisit rien implicitement.
- Le contenu tient dans son cadre utile, avec scroll interne ; la commande
  globale ne masque jamais un CTA.

### 3.3 États et retours

- Impact, revenu et users se rafraîchissent à chaque mutation, sans fermeture.
- Un écran rouvert restitue son état : réponse du courrier, plan courant,
  offre et achats du sprint.
- Le focus clavier et Échap suivent l'objet au premier plan ; aucun écran caché
  ne reçoit d'entrée.

## 4. Périmètre

### P0 — indispensable

1. Extraire un contrat commun d'écran hébergé et supprimer l'adaptation par
   chemins de nœuds dans `workstation.gd` et `desk_prop.gd`.
2. Déplacer « Reposer » hors des textures des accessoires et câbler les trois
   gestes de fermeture.
3. Adapter les layouts Inbox, Roadmap, Investissements et Comité à leur taille
   réelle, y compris scrolls, états vides et textes longs.
4. Conserver les contrats métier livrés par #63 : Roadmap validée avant
   fermeture, courrier soldé une seule fois, compteurs rafraîchis en direct.
5. Ajouter des tests de bornes et de navigation pour chaque hôte.

### P1 — finition du lot

- Transition courte cohérente entre lanceur, application et retour au bureau.
- Indication discrète du raccourci Échap sur la commande globale.
- Focus visible et zones cliquables d'au moins 40×40 px.

### Hors périmètre

- Nouvelles règles de gameplay ou rééquilibrage.
- Refonte du scoring, de la Résolution ou des écrans de sélection.
- Matières, nouveaux modèles 3D, ambiance et caméra mobile.
- Gantt : le modèle ne porte toujours pas de features multi-sprints.

## 5. Critères de recette

- [ ] Zéro bouton `Accueil`, `Retour`, `Continuer` ou `Reposer` dans les scènes
      invitées lorsqu'elles sont hébergées.
- [ ] Une seule commande de sortie visible par objet ouvert.
- [ ] Échap et clic extérieur ferment sans mutation métier.
- [ ] Tous les CTA visibles restent dans le rectangle utile de leur
      `SubViewport` à 880×495 (laptop) et à la taille déclarée des accessoires.
- [ ] Le badge courrier tombe à zéro après réponse et ne remonte pas à la
      réouverture.
- [ ] « Terminé » valide le plan de Roadmap avant le retour au bureau.
- [ ] Impact, revenu et users changent à l'écran dans la même frame logique que
      l'achat ou l'acquisition.
- [ ] Les deux smoke tests, les cas `ScoreResolver`, un run visuel complet et
      la boucle de 40 runs passent.
- [ ] Le budget de prose UI de l'issue #10 est remesuré sur l'état actuel ; le
      lot ne revendique pas une baisse calculée depuis une baseline obsolète.

## 6. Découpage recommandé

1. **Socle d'hébergement** — contrat commun, fermeture globale, Échap et clic
   extérieur, tests de navigation.
2. **Laptop** — Inbox et Roadmap dans leur taille réelle, états et bornes.
3. **Accessoires** — Investissements, Comité et clôture, scrolls et CTA.
4. **Recette** — captures nominales/alertes, partie complète, carnet de règles.

## 7. Arbitrage à valider

La recommandation est une commande globale « Reposer · Échap » dans le
`CanvasLayer`, proche du bord de l'objet mais jamais dans sa texture. Elle rend
le geste découvrable tout en laissant le contenu intact. L'alternative est de
ne garder que clic extérieur + Échap : plus épurée, mais invisible au premier
run.

