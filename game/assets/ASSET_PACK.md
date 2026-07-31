# Pack visuel à intégrer

Le lot est intégré aux trois écrans de décision : Inbox, Roadmap et
Investissements. Les éléments décoratifs sont placés derrière les contrôles et
ignorent la souris : ils ne peuvent jamais intercepter une action.

| Fichier | Usage envisagé |
|---|---|
| `decor/macbook-decision-frame.svg` | Première piste de cadre vectoriel, conservée comme référence mais non utilisée. Le poste de travail intégré est désormais dessiné par `scripts/components/decision_desk.gd` afin de garder une dalle opaque et correctement dimensionnée. |
| `stamps/*.svg` | `URGENT` est visible sur les messages critiques ; `VALIDÉ` marque une réponse envoyée et un ticket planifié ; `RISQUE` apparaît quand une dette élevée a été révélée ; `BLOQUÉ` marque les décisions à prérequis. |
| `sender-badges/*.svg` | Portraits d'expéditeurs collectifs dans l'Inbox : board, juridique, technique, commercial, RH et veille. |
| `decor/desk-*.svg` | Props de bureau (café, post-it, trombone) autour du portable, placés derrière les zones de décision. |

Tous les nouveaux fichiers sont des SVG originaux du projet, sans dépendance ni
attribution tierce. Ils gardent les couleurs de `UIHelpers` et sont prévus pour
être teintés ou redimensionnés par Godot sans perte.
