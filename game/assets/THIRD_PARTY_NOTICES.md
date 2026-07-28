# Licences des assets tiers

Tous les assets de ce dossier sont libres d'usage commercial. Le fichier de licence complet accompagne chaque source ci-dessous.

## Polices — `fonts/`

| Fichier | Police | Licence | Source |
|---|---|---|---|
| `SpaceGrotesk-Variable.ttf` | Space Grotesk (variable, wght) | [OFL 1.1](fonts/OFL-SpaceGrotesk.txt) | [Google Fonts](https://fonts.google.com/specimen/Space+Grotesk) |
| `IBMPlexSans-Variable.ttf` | IBM Plex Sans (variable, wdth+wght) | [OFL 1.1](fonts/OFL-IBMPlexSans.txt) | [Google Fonts](https://fonts.google.com/specimen/IBM+Plex+Sans) |
| `IBMPlexMono-Regular.ttf` / `-Medium.ttf` / `-SemiBold.ttf` | IBM Plex Mono | [OFL 1.1](fonts/OFL-IBMPlexMono.txt) | [Google Fonts](https://fonts.google.com/specimen/IBM+Plex+Mono) |

Mêmes familles que la landing page (`landing/index.html`), pour cohérence visuelle entre les deux.

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
| `mckinsey-consultant.svg` | Contractuel / archétype consultant | `mckinsey-consultant` |
| `cpo-player.svg` | Le·la joueur·se (CPO), réservé usage futur | `cpo-player` |

Pour ajouter un personnage : `npm install @dicebear/core @dicebear/collection` puis générer avec `createAvatar(notionists, { seed: "nom-du-perso" })` — voir le script utilisé dans l'historique de commit, non conservé dans le repo (pas un outil de build du projet).
