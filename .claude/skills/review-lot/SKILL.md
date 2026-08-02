---
name: review-lot
description: Relit un lot de Product Tycoon avant merge — rejoue les trois bancs, mesure la stabilité sur 40 runs, capture les écrans, vérifie chaque affirmation de la PR et confronte le lot à la vision du jeu. À utiliser dès qu'une PR de ce dépôt est prête à être relue, ou quand on demande de valider/reviewer un lot avant de le merger.
---

# Relire un lot avant merge

## Le principe : ne rien croire, tout vérifier

Une PR de ce dépôt affirme des choses — « les bancs passent », « ce paramètre
n'avait pas d'effet », « le catalogue liste 15 combos ». **Chaque affirmation
factuelle se vérifie, aucune ne se croit.** Les auteurs sont de bonne foi ; ils
se trompent quand même. Trois exemples réels de ce dépôt :

- un dev a diagnostiqué un test instable comme venant du burn-out : c'était le
  catalogue de décisions stratégiques ;
- une relecture a validé un lot dont un écran affichait le mot « squad », parce
  que le grep ne couvrait que les `.gd` et les `.tscn`, pas les JSON ;
- un test « corrigé » exigeait un résultat qui dépendait d'un tirage aléatoire,
  et tombait une fois sur dix.

Aucun des trois n'aurait été attrapé par une lecture attentive. Tous les trois
l'ont été par une commande.

## 1. Préparer un worktree isolé

Ne jamais relire dans le répertoire de travail de quelqu'un d'autre, et ne
jamais lancer de test dans un worktree où un dev travaille encore — le cache
`.godot` est partagé et les résultats deviennent ininterprétables.

```bash
git worktree add --detach <chemin>/wt-review <sha-de-la-PR>
```

Puis vérifier que rien ne traîne : `git status --short` doit être vide.

## 2. Les vérifications mécaniques — toutes obligatoires

### Les trois bancs

Depuis `game/`, avec `G` = le binaire Godot 4.7 :

```bash
$G --headless --path . res://tests/smoke_test_logic.tscn
$G --headless --path . res://tests/smoke_test_ui.tscn
$G --headless --path . -s res://tests/score_resolver_cases.gd
```

Marqueurs de succès, littéralement :

```
=== SMOKE TEST LOGIQUE : OK ===
=== SMOKE TEST UI : OK — N écrans instanciés, gestes Roadmap/Investissements joués ===
ScoreResolver: tous les cas sont passes.
```

### La stabilité — le point le plus important

**Un run unique ne prouve rien.** `smoke_test_logic` coûte 0,8 s et le jeu est
aléatoire : un défaut à 10-20 % passe inaperçu sur un run.

```bash
ok=0; for i in $(seq 1 40); do
  $G --headless --path . res://tests/smoke_test_logic.tscn 2>&1 \
    | grep -q "SMOKE TEST LOGIQUE : OK" && ok=$((ok+1))
done; echo "$ok / 40"
```

**Exiger 40/40.** Si le compte est inférieur, mesurer la même chose sur `main`
avant de conclure : c'est ce qui distingue « ce lot a introduit un défaut » de
« le défaut préexistait ». Puis capturer le message d'assertion réel plutôt que
de deviner — boucler jusqu'à l'échec et lire la sortie.

### Les captures d'écran

`--headless` ne dessine rien, mais `xvfb` est disponible :

```bash
SHOT_DIR=<dossier> xvfb-run -a $G --path game --display-driver x11 \
    --resolution 1600x900 res://tests/screenshot_screens.tscn
```

**1600×900 est la résolution réelle du viewport** — capturer plus petit invente
des troncatures qui n'existent pas. Puis **regarder les images**, en priorité
les écrans que le lot a touchés. Ça attrape les fautes de texte, les
débordements, les troncatures ; pas les enchaînements ni les transitions.

### Les vérifications de fichiers

```bash
# Aucun .uid manquant — le piège le plus répétitif du dépôt
for f in $(git ls-files '*.gd'); do
  git ls-files --error-unmatch "$f.uid" >/dev/null 2>&1 || echo "MANQUE: $f.uid"
done

# Le carnet est en pure addition, aucune section existante touchée
git diff <base>..<head> -- docs/carnet-de-regles.md | grep "^-" | grep -v "^---"

# Aucune valeur d'équilibrage en dur
# Aucune branche par entreprise ni par niveau dans le moteur
grep -rn "meridia\|karavel\|career_level ==" game/scripts/ | grep -v tests/
```

## 3. Vérifier les affirmations de la PR

Lire la description, **lister ses affirmations factuelles**, et en vérifier
chacune par une commande. Typiquement :

- « ce paramètre n'avait aucun effet avant » → le chercher sur la base :
  `git show <base>:<fichier> | grep <param>`
- « il y a N éléments » → les recompter :
  `python3 -c "import json; ..."`
- « ces valeurs sont conformes à l'issue » → comparer au chiffre près
- « la fonction X n'était pas branchée » → `grep -rn "X" game/scripts/`

Et vérifier que **les tests ajoutés ne sont pas vacuous** : un test qui passe
parce qu'il n'assert rien de contraignant est pire qu'aucun test. Relire les
assertions, chercher les branches qui ne peuvent jamais échouer.

## 4. Confronter le lot à la vision

Les bancs peuvent être verts et le lot rester à refuser. Les questions sont dans
le `CLAUDE.md` (« La vision — les questions qui invalident un lot ») — les poser
toutes, et signaler celles dont la réponse est gênante :

1. Ne rien faire peut-il gagner ?
2. Le joueur sait-il encore quelle valeur regarder ?
3. Existe-t-il un chemin qui fait décoller une partie, et plusieurs ?
4. A-t-on promis un gain futur quelque part ?
5. A-t-on réduit l'aléatoire ?
6. Un réglage est-il devenu un trait de contexte ?
7. Reste-t-il une valeur d'équilibrage dans un script ?
8. À N=1, la couche multi-équipe est-elle invisible — `.gd`, `.tscn` **et**
   `data/*.json` ?

Et la question de clôture : **qu'est-ce qui est meilleur à jouer maintenant ?**
Si la seule réponse est « la fonctionnalité existe », le dire.

## 5. Rendre la review

Structure attendue, en français :

- **Ce que j'ai fait tourner moi-même** — les résultats bruts, avec les
  chiffres. La mesure de stabilité en premier.
- **Les affirmations vérifiées** — chacune, avec ce qui la confirme ou
  l'infirme. Dire quand l'auteur avait raison est aussi utile que le contraire.
- **Le contrat d'architecture** — squads, tables indexées, logique hors UI,
  valeurs en données.
- **Ce que je n'ai pas pu vérifier** — toujours présent, jamais enterré. Les
  captures ne remplacent pas un run joué.

Ne jamais écrire qu'un test passe sans l'avoir lancé. Ne jamais approuver en
espérant que quelqu'un d'autre vérifiera : sur ce dépôt il n'y a **aucun CI**,
cette review est la seule barrière avant le tronc.

## Ce que cette relecture ne peut pas faire

Un agent qui relit partage les biais de celui qui a écrit : même documentation,
même raisonnement, mêmes angles morts. Il attrape les incohérences internes, les
oublis, les contradictions entre documents — **pas** les erreurs de vision, ni ce
qui ne se voit qu'en jouant. Le dire explicitement dans la review plutôt que de
laisser croire à une validation complète.
