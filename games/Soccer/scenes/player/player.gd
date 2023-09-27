class_name Player
extends CharacterBody2D

# TODO: Collision Animation
# - Animate CollisionShape together with the sprite
# - Maybe use AnimationSprite toget with AnimationPlayer?

@onready var start_position = position

@export var speed: float = 300.0
@export var push_force: float = 25.0
@export var kick_force: float = 200

var animator: AnimatedSprite2D
var last_direction_vector: Vector2
var last_animation: String

@export var is_kicking: bool = false
@export var can_kick: bool = true
@export var can_kick_ball: bool = true

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_motion_mode(CharacterBody2D.MOTION_MODE_FLOATING)

func _process(_delta):
	handle_player_input()

func _physics_process(_delta):
	move_and_slide()
	handle_rigid_collisions()
	
func handle_player_input():
	var direction_vector = Input.get_vector("left", "right", "up", "down")	
	velocity = direction_vector * speed
	
	if not is_kicking:
		set_direction(
			Input.is_action_pressed("left"),
			Input.is_action_pressed("right"),
			Input.is_action_pressed("up"),
			Input.is_action_pressed("down"),
			direction_vector
		)
	
	if last_animation and can_kick and Input.is_action_pressed("kick"):
		$Kick/KickAnimation.play("kick")

func handle_rigid_collisions():
	for i in get_slide_collision_count():
			var c = get_slide_collision(i)
			if c.get_collider() is RigidBody2D:
				var collider: RigidBody2D = c.get_collider() as RigidBody2D
				collider.apply_central_impulse(-c.get_normal()*push_force)
				collider.apply_impulse(-c.get_normal(), c.get_position()) # for angular velocity

func set_direction(left: bool, right: bool, up: bool, down: bool, direction_vector: Vector2):
	if(!animator):
		return
	
	if not (left or right or up or down):
		animator.set_frame_and_progress(0, 0)
		animator.pause()
	
	if direction_vector.length() > 0:
		last_direction_vector = direction_vector
		
	play_animation_direction(left, right, up, down)

func play_animation_direction(left: bool, right: bool, up: bool, down: bool):
	var right_r = right and not left
	var left_r  = left and not right
	var up_r    = up and not down
	var down_r  = down and not up
	
	var animation: String = ""
	
	if not up_r and not down_r:
		if right_r:
			animation = "right"
		if left_r:
			animation = "left"
	elif up_r:
		if right_r:
			animation = "up_right"
		elif left_r:
			animation = "up_left"
		else:
			animation = "up"
	elif down_r:
		if right_r:
			animation = "down_right"
		elif left_r:
			animation = "down_left"
		else:
			animation = "down"
	
	if animation != "":
		animator.play(animation)
		last_animation = animation

func set_color(color: String):
	var sprite = $Sprite.get_node(color.capitalize())
	if sprite:
		animator = sprite as AnimatedSprite2D
		reset()

func reset():
	animator.play("down")
	last_animation = "down"
	animator.pause()
	animator.visible = true
	position = start_position

func start_kick():
	animator.play(last_animation + "_kick")
	set_kick_direction()

func set_kick_direction():
	var angle = last_direction_vector.angle() - PI/2
	$Kick/Area2D.rotation = angle

func _on_kick_body_entered(body):
	if body is Ball and can_kick_ball:
		apply_ball_impulse(body)
		can_kick_ball = false

func apply_ball_impulse(ball: Ball):
	var vec = $Kick/Area2D/CollisionPolygon2D.global_position.direction_to(ball.position).normalized()
	ball.apply_central_impulse(vec*kick_force)

func on_kick_end():
	animator.play(last_animation)
	animator.pause()
