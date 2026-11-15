# Formalise la cible du rework et ses assets

La direction du bureau, des cartes et des ressources validée en maquette
restait séparée des consignes de développement, qui mettaient encore les
anciennes interfaces au premier plan. Ce changement donne une entrée commune
dans `AGENTS.md` et `CLAUDE.md`, un contrat de cible, un plan R0–R5 et un
manifeste d’assets. Les anciennes specs sont identifiées selon leur rôle actuel.

Le `.pen`, ses assets sources et 44 aperçus JPEG deviennent les références de
revue. Les PNG en double, ZIP et anciens prototypes restent des sorties locales.
Le prochain lot recommandé est R0 : composants, cartes, compteurs et interactions.
Les décisions de simulation encore ouvertes sont attachées aux lots concernés.

Validation : liens du paquet, inventaire / empreintes / régions des assets,
44 états du `.pen` et leurs aperçus, références de composants, absence de valeurs
de gameplay dans le manifeste et contrôle du diff. Le rapport natif des
maquettes est conservé. Aucun comportement du jeu n’est modifié dans cette PR.

Base : `main` à jour. Appliquer seulement le périmètre de
`docs/rework-merge-files.txt` ; la branche de travail actuelle porte aussi deux
commits de code qu’il faut traiter séparément pour cette PR de conception.
