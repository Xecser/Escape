extends AnimatableBody2D
@export var travel: Vector2 = Vector2(480, 0)
@export var move_time: float = 3.0
@export var pause_time: float = 0.6
@export_range(0.0, 1.0) var start_offset: float = 0.0

var start_position: Vector2
var time := 0.0


func _ready() -> void:
	start_position = position
	time = start_offset * _cycle_length()


func _physics_process(delta: float) -> void:
	time = fmod(time + delta, _cycle_length())
	position = start_position + travel * _progress(time)


func _cycle_length() -> float:
	return 2.0 * (move_time + pause_time)


func _progress(t: float) -> float:
	if t < pause_time:
		return 0.0
	t -= pause_time
	if t < move_time:
		return _ease(t / move_time)
	t -= move_time
	if t < pause_time:
		return 1.0
	t -= pause_time
	return 1.0 - _ease(t / move_time)


func _ease(x: float) -> float:
	return 0.5 - 0.5 * cos(x * PI)
