extends Node


func _ready() -> void:
	# Every trip back to the menu starts a fresh run.
	get_tree().paused = false
	GameManager.points = 0
	# Lets you pick a button with the keyboard / controller as well as the mouse.
	$Buttons/Button.grab_focus()


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://1st.tscn")



func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://2nd.tscn")


func _on_button_3_pressed() -> void:
	get_tree().change_scene_to_file("res://1st.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
