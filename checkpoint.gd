extends Area2D

var checkpoint_manager

func _ready() -> void:
	checkpoint_manager = get_tree().get_first_node_in_group("checkpoint_manager")

func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		checkpoint_manager.last_location = $Respawnpoint.global_position
