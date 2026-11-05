extends CharacterBody2D
## An enemy that walks back and forth on the ground (or flies, if `flying` is on).
## Jump on its head to defeat it. Touching it any other way sends the player
## back to the last checkpoint.

@export var speed: float = 70.0
## -1 = start walking left, 1 = start walking right.
@export var start_direction: int = -1

@export_group("Flying")
@export var flying: bool = false
## How far a flyer travels from its start position (and back again), in pixels.
@export var fly_travel: Vector2 = Vector2(240, 0)
## Small up-and-down wobble while flying, in pixels.
@export var bob_height: float = 8.0

@export_group("Stomp")
## Upward speed given to the player after a stomp (held jump = higher bounce).
@export var stomp_bounce: float = -520.0
## Points given for defeating this enemy.
@export var points_for_stomp: int = 1
## How deep (in pixels) the player's feet may be inside the enemy's head and still count as a stomp.
@export var stomp_tolerance: float = 22.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var ledge_check: RayCast2D = get_node_or_null("LedgeCheck")

var direction: int = -1
var dead := false
var start_position: Vector2
var fly_time := 0.0


func _ready() -> void:
	direction = -1 if start_direction < 0 else 1
	start_position = global_position
	# The enemy should never physically push the player around; only the hitbox matters.
	for node in get_tree().get_nodes_in_group("Player"):
		if node is PhysicsBody2D:
			add_collision_exception_with(node)
			if ledge_check:
				ledge_check.add_exception(node)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	_update_ledge_check()


func _physics_process(delta: float) -> void:
	if dead:
		return
	if flying:
		_fly(delta)
	else:
		_walk(delta)
	sprite.flip_h = direction < 0


func _walk(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	velocity.x = direction * speed
	move_and_slide()

	if is_on_floor():
		if is_on_wall():
			direction = 1 if get_wall_normal().x > 0 else -1
			_update_ledge_check()
		elif ledge_check and not ledge_check.is_colliding():
			# No ground ahead: turn around instead of walking off the edge.
			direction = -direction
			_update_ledge_check()


func _update_ledge_check() -> void:
	if ledge_check:
		ledge_check.position.x = absf(ledge_check.position.x) * direction
		ledge_check.force_raycast_update()


func _fly(delta: float) -> void:
	var distance := fly_travel.length()
	if distance <= 0.0:
		return
	fly_time += delta
	# Smooth back-and-forth between start_position and start_position + fly_travel.
	var angle := fly_time * speed / distance * PI
	var progress := 0.5 - 0.5 * cos(angle)
	var bob := sin(fly_time * 5.0) * bob_height
	global_position = start_position + fly_travel * progress + Vector2(0, bob)
	if absf(fly_travel.x) > 1.0:
		var moving_forward := sin(angle) >= 0.0
		direction = int(signf(fly_travel.x)) * (1 if moving_forward else -1)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if dead or not body.is_in_group("Player") or not body is CharacterBody2D:
		return
	var player := body as CharacterBody2D
	var head_top := hitbox_shape.global_position.y - _shape_half_height(hitbox_shape)
	if player.velocity.y >= 0.0 and _feet_y(player) <= head_top + stomp_tolerance:
		_stomped_by(player)
	else:
		_hurt(player)


func _stomped_by(player: CharacterBody2D) -> void:
	dead = true
	var bounce := stomp_bounce
	if Input.is_action_pressed("jump"):
		bounce *= 1.25
	player.velocity.y = bounce
	for i in points_for_stomp:
		GameManager.add_points()

	hitbox.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if sprite.sprite_frames.has_animation("hit"):
		sprite.play("hit")

	var tween := create_tween()
	if flying:
		# Flyers drop out of the sky.
		tween.set_parallel(true)
		tween.tween_property(self, "global_position:y", global_position.y + 500.0, 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "modulate:a", 0.0, 0.8)
		tween.set_parallel(false)
	else:
		tween.tween_interval(0.35)
		tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)


func _hurt(player: CharacterBody2D) -> void:
	var checkpoint_manager := get_tree().get_first_node_in_group("checkpoint_manager")
	if checkpoint_manager and checkpoint_manager.last_location != null:
		player.global_position = checkpoint_manager.last_location
	player.velocity = Vector2.ZERO
	# Quick red flash so it's clear what happened.
	player.modulate = Color(1, 0.4, 0.4)
	var tween := player.create_tween()
	tween.tween_property(player, "modulate", Color.WHITE, 0.4)


func _feet_y(player: CharacterBody2D) -> float:
	var shape_node := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return player.global_position.y
	return shape_node.global_position.y + _shape_half_height(shape_node)


func _shape_half_height(shape_node: CollisionShape2D) -> float:
	var s := shape_node.shape
	var half := 0.0
	if s is CapsuleShape2D:
		half = s.height * 0.5
	elif s is RectangleShape2D:
		half = s.size.y * 0.5
	elif s is CircleShape2D:
		half = s.radius
	return half * absf(shape_node.global_scale.y)
