extends CanvasLayer
## The in-game HUD (points, pause button, level title) and the pause menu.
## Pause with Esc, P, the controller Start button, or the pause button in the corner.

## Shown big in the middle of the screen when the level starts. Leave empty for none.
@export var level_name: String = ""
@export_file("*.tscn") var main_menu_scene: String = "res://Main Menu.tscn"

@onready var points_box: Control = %PointsBox
@onready var points_label: Label = %PointsLabel
@onready var pause_button: Button = %PauseButton
@onready var level_title: Label = %LevelTitle
@onready var pause_menu: Control = %PauseMenu
@onready var pause_panel: Control = %PausePanel
@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton

var points_at_level_start := 0
var shown_points := -1


func _ready() -> void:
	# Keep the HUD running while the rest of the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	points_at_level_start = GameManager.points
	pause_menu.hide()
	pause_button.pressed.connect(pause)
	resume_button.pressed.connect(resume)
	restart_button.pressed.connect(restart_level)
	menu_button.pressed.connect(go_to_main_menu)
	_update_points(false)
	_show_level_title()


func _process(_delta: float) -> void:
	if GameManager.points != shown_points:
		_update_points(true)


func _unhandled_input(event: InputEvent) -> void:
	if _is_pause_key(event):
		if get_tree().paused:
			resume()
		else:
			pause()
		get_viewport().set_input_as_handled()


func _is_pause_key(event: InputEvent) -> bool:
	if event.is_echo():
		return false
	if event.is_action_pressed("ui_cancel"):
		return true
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_P:
		return true
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		return true
	return false


func pause() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	pause_menu.show()
	pause_button.hide()
	resume_button.grab_focus()
	# Small pop-in animation.
	pause_panel.pivot_offset = pause_panel.size / 2.0
	pause_panel.scale = Vector2(0.85, 0.85)
	pause_menu.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(pause_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(pause_menu, "modulate:a", 1.0, 0.12)


func resume() -> void:
	get_tree().paused = false
	pause_menu.hide()
	pause_button.show()


func restart_level() -> void:
	get_tree().paused = false
	# Undo any points collected during this attempt.
	GameManager.points = points_at_level_start
	get_tree().reload_current_scene()


func go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_scene)


func _update_points(animate: bool) -> void:
	shown_points = GameManager.points
	points_label.text = "x %d" % shown_points
	if animate:
		points_box.pivot_offset = points_box.size / 2.0
		points_box.scale = Vector2(1.25, 1.25)
		create_tween().tween_property(points_box, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_level_title() -> void:
	if level_name.is_empty():
		level_title.hide()
		return
	level_title.text = level_name
	level_title.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(level_title, "modulate:a", 1.0, 0.4)
	tween.tween_interval(1.4)
	tween.tween_property(level_title, "modulate:a", 0.0, 0.6)
	tween.tween_callback(level_title.hide)
