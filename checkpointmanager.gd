extends Node

var last_location
var player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	if player == null:
		push_error("Player not found! Check the group name.")
		return
	last_location = player.global_position
