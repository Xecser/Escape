extends Area2D

var checkpoint_manager
var player

func _ready() -> void:
	checkpoint_manager = get_tree().get_first_node_in_group("checkpoint_manager")
	player = get_tree().get_first_node_in_group("Player")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	



func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		killPLayer()
func killPLayer():
	player.position = checkpoint_manager.last_location
