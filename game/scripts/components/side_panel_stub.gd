extends Control
## Le Panneau de bord n'existe plus dans le bureau (#54) — mais les écrans de
## phase l'appellent encore (`refresh()`, `state_changed`). Ce nœud vide honore
## ce contrat pendant qu'ils sont hébergés, pour que le Lot A n'ait pas à
## rouvrir les neuf écrans : c'est le Lot B (#10) qui les refera.
##
## Il n'affiche rien et ne prend aucune place : les quinze valeurs qu'il portait
## sont devenues trois zones et une remontée par exception.

signal state_changed


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2.ZERO


func refresh() -> void:
	# Le bureau relit SprintState de lui-même à chaque fermeture d'application :
	# rien à propager ici.
	pass
