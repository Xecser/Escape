extends CanvasLayer

@export var level_name: String = ""
@export var show_controls: bool = false
@export var controls_timeout: float = 20.0
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
@onready var touch_controls: Control = %TouchControls
@onready var pause_hint: Label = %PauseHint
@onready var controls_help: Control = %ControlsHelp
@onready var keyboard_help: Control = %KeyboardHelp
@onready var touch_help: Control = %TouchHelp

var points_at_level_start := 0
var shown_points := -1
var has_moved := false
var has_jumped := false
var controls_time := 0.0
var controls_closing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	points_at_level_start = GameManager.points
	pause_menu.hide()
	pause_button.pressed.connect(pause)
	resume_button.pressed.connect(resume)
	restart_button.pressed.connect(restart_level)
	menu_button.pressed.connect(go_to_main_menu)
	_update_points(false)
	_show_level_title()
	_setup_controls_help()
	get_tree().quit_on_go_back = false
	if DisplayServer.is_touchscreen_available():
		pause_hint.text = "Tap Resume to keep playing"


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if get_tree().paused:
			resume()
		else:
			pause()


func _process(delta: float) -> void:
	if GameManager.points != shown_points:
		_update_points(true)
	_update_controls_help(delta)


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
	touch_controls.hide()
	for action in ["left", "right", "jump"]:
		Input.action_release(action)
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
	touch_controls.show()


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


func _setup_controls_help() -> void:
	if not show_controls:
		controls_help.hide()
		return
	var touch := DisplayServer.is_touchscreen_available()
	keyboard_help.visible = not touch
	touch_help.visible = touch
	controls_help.modulate.a = 0.0
	create_tween().tween_property(controls_help, "modulate:a", 1.0, 0.5).set_delay(0.4)


func _update_controls_help(delta: float) -> void:
	if not controls_help.visible or controls_closing or get_tree().paused:
		return
	controls_time += delta
	if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
		has_moved = true
	if Input.is_action_pressed("jump"):
		has_jumped = true
	if (has_moved and has_jumped) or controls_time > controls_timeout:
		controls_closing = true
		var tween := create_tween()
		tween.tween_interval(1.5)
		tween.tween_property(controls_help, "modulate:a", 0.0, 0.6)
		tween.tween_callback(controls_help.hide)
