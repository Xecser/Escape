extends Area2D

@export var required_score: int = 4

@export_file("*.tscn") var next_scene: String = "res://2nd.tscn"

func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	print("body: ", body.name, " | points: ", GameManager.points, " | required: ", required_score)
	if body.name == "CharacterBody2D" and GameManager.points >= required_score:
		get_tree().change_scene_to_file.call_deferred(next_scene)
