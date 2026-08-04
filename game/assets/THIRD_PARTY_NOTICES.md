# Licences des assets tiers

Tous les assets de ce dossier sont libres d'usage commercial. Le fichier de licence complet accompagne chaque source ci-dessous.

## Polices — `fonts/`

| Fichier | Police | Licence | Source |
|---|---|---|---|
| `SpaceGrotesk-Variable.ttf` | Space Grotesk (variable, wght) | [OFL 1.1](fonts/OFL-SpaceGrotesk.txt) | [Google Fonts](https://fonts.google.com/specimen/Space+Grotesk) |
| `IBMPlexSans-Variable.ttf` | IBM Plex Sans (variable, wdth+wght) | [OFL 1.1](fonts/OFL-IBMPlexSans.txt) | [Google Fonts](https://fonts.google.com/specimen/IBM+Plex+Sans) |
| `IBMPlexMono-Regular.ttf` / `-Medium.ttf` / `-SemiBold.ttf` | IBM Plex Mono | [OFL 1.1](fonts/OFL-IBMPlexMono.txt) | [Google Fonts](https://fonts.google.com/specimen/IBM+Plex+Mono) |
| `ProductIcons.ttf` | Font d'icônes vectorielles générée à partir de Lucide | [ISC](icons/LICENSE-lucide.txt) | [Lucide](https://lucide.dev/) |

Mêmes familles que la landing page (`landing/index.html`), pour cohérence visuelle entre les deux.

`ProductIcons.ttf` n'est pas une police de texte ni une police emoji tierce :
les tracés SVG Lucide sont compilés localement sur les codepoints déjà présents
dans les données du jeu. Elle est le fallback explicite des trois familles
typographiques. Les sélecteurs Unicode invisibles `U+FE0F` et `U+200D` ont une
avance nulle ; aucun système hôte n'est consulté pour dessiner les
pictogrammes.

**Cet asset se régénère.** Sa source vit dans
[`tools/icons/`](../../tools/icons/README.md) : `manifest.json` associe chaque
caractère au tracé qui le dessine, `lucide/` fige les SVG amont (Lucide
0.469.0, ISC), `extra/` contient les deux tracés écrits pour le jeu (`○` et
`●`), et `build_product_icons.py` reconstruit le binaire à l'octet près.
`--check` refuse une police qui ne correspond plus à son manifeste.

Deux contrôles mécaniques encadrent le tout : le smoke UI compare la police à
son manifeste, et il parcourt les **chaînes** de `game/` et `data/` pour exiger
que tout caractère non-ASCII affiché soit dessiné par au moins une des six
polices embarquées — sans liste blanche de pictogrammes, puisque c'est
précisément une liste blanche qui avait laissé passer `▸ ◂ ○ ● ✗`.

## Icônes — `icons/`

Set [Lucide](https://lucide.dev/), licence [ISC](icons/LICENSE-lucide.txt) (permissive, équivalente MIT). Trait recoloré en blanc (`stroke="#FFFFFF"`, remplace `currentColor` qui n'a pas de sens hors contexte CSS) pour permettre la teinte via `modulate` dans Godot.

| Fichier | Usage prévu |
|---|---|
| `wallet.svg` | Trésorerie |
| `heart-handshake.svg` | Moral & confiance d'équipe |
| `brick-wall.svg` | Dette organisationnelle |
| `target.svg` | Capital politique |
| `trending-up.svg` | Valeur perçue |
| `drama.svg` | Cynisme |
| `sprout.svg` | Équipe junior |
| `landmark.svg` | Équipe senior |
| `clock.svg` | Fondation en attente |
| `circle-check.svg` | Fondation active |
| `user-round.svg` | Avatar générique (candidats sans portrait dédié) |

## Avatars — `avatars/`

Générés localement avec [DiceBear](https://www.dicebear.com/) (style **Notionists**), sans appel réseau à l'exécution — SVG statiques commités dans le repo.

- Design (illustrations) : [CC0 1.0](avatars/LICENSE-dicebear-notionists.txt) — Zoish, [Notionists](https://heyzoish.gumroad.com/l/notionists). Domaine public, aucune attribution requise.
- Code du générateur (`@dicebear/core`) : [MIT](avatars/LICENSE-dicebear-core.txt) — Florian Körner. Utilisé uniquement pour générer les fichiers, ne fait pas partie du jeu.

| Fichier | Personnage | Seed utilisée |
|---|---|---|
| `priya.svg` | Priya, Lead Engineering (événement Inbox) | `priya` |
| `sofia.svg` | Sofia — PM Senior (recrutement) | `sofia` |
| `kevin.svg` | Kevin — Ops Junior (recrutement) | `kevin` |
| `lina.svg`, `marc.svg`, `théo.svg`, `aïcha.svg`, `hugo.svg`, `bertrand.svg`, `claire.svg`, `nadia.svg`, `yann.svg` | Candidats nommés du marché | prénom sans accent comme seed |
| `hervé.svg`, `danielle.svg`, `marek.svg`, `solange.svg`, `patrice.svg` | Roster initial de Meridia | prénom sans accent comme seed |
| `jade.svg`, `bilal.svg`, `emma.svg`, `nino.svg`, `lou.svg` | Roster initial de Karavel | prénom sans accent comme seed |
| `mckinsey-consultant.svg` | Contractuel / archétype consultant | `mckinsey-consultant` |
| `cpo-player.svg` | Le·la joueur·se (CPO), réservé usage futur | `cpo-player` |

Pour ajouter un personnage : `npm install @dicebear/core @dicebear/collection` puis générer avec `createAvatar(notionists, { seed: "nom-du-perso" })` — voir le script utilisé dans l'historique de commit, non conservé dans le repo (pas un outil de build du projet).

## Icônes d'objets — `items-kenney/`

[Generic Items](https://kenney.nl/assets/generic-items) par [Kenney](https://kenney.nl/), licence [CC0](items-kenney/LICENSE-kenney-generic-items.txt) — domaine public, aucune attribution requise. Téléchargé le 30/07/2026 : 160 objets du quotidien de bureau/tech en icônes vectorielles plates (laptop, écrans, mallette, dossier, clé USB, presse-papiers, stéthoscope, appareil photo, livre, café...), utilisés pour incarner le type d'un Actif (candidat / décision / pratique) sur sa carte.

- `PNG/Colored/` et `PNG/White/` — icônes individuelles (330 fichiers PNG au total, deux teintes).
- `Vector/` — les mêmes en SVG (couleur + blanc).
- `Spritesheet/` — tout en une planche + fichier `.xml` de découpe, si besoin d'un import groupé.

Utilisé en production par la carte d'Actif (`scenes/components/asset_card.tscn`) : une icône d'objet par grande décision et par pratique, mappée dans `scripts/asset_view.gd` → `DECISION_ICONS` / `PRACTICE_ICONS` (le choix d'icône est de la présentation, il n'a pas sa place dans `data/`). Le spike `scenes/prototype_2d/market_screen_proto.tscn` s'en sert aussi.

Le [UI Pack](https://kenney.nl/assets/ui-pack) du même auteur a été évalué le 30/07/2026 puis **écarté** : ses boutons ronds et colorés jurent avec le ton corporate/satirique du jeu. Ne pas le réintroduire comme chrome des écrans sans nouvelle validation.
