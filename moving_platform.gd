extends AnimatableBody2D
## A platform that slides back and forth between its start position and start + `travel`.

## How far the platform moves (in pixels). Use a negative y to move up.
@export var travel: Vector2 = Vector2(480, 0)
## Seconds to move from one end to the other.
@export var move_time: float = 3.0
## Seconds to wait at each end.
@export var pause_time: float = 0.6
## Start part-way through the cycle (0 to 1) so platforms don't all move in sync.
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
