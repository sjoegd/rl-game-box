class_name Player
extends CharacterBody2D

@onready var start_position = position

@export var speed: float = 300.0
@export var push_force: float = 25

var animator: AnimatedSprite2D
var last_direction_vector: Vector2

func _ready():
	set_motion_mode(CharacterBody2D.MOTION_MODE_FLOATING)

func _process(_delta):
	handle_player_input()

func _physics_process(_delta):
	move_and_slide()
	handle_rigid_collisions()
	
func handle_player_input():
	var direction_vector = Input.get_vector("left", "right", "up", "down")	
	velocity = direction_vector * speed
	set_direction(
		Input.is_action_pressed("left"),
		Input.is_action_pressed("right"),
		Input.is_action_pressed("up"),
		Input.is_action_pressed("down"),
		direction_vector
	)

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
		
	# TODO: Update names
	var right_r = right and not left
	var left_r  = left and not right
	var up_r    = up and not down
	var down_r  = down and not up
	
	if not up_r and not down_r:
		if right_r:
			animator.play("right")
		if left_r:
			animator.play("left")
	elif up_r:
		if right_r:
			animator.play("up_right")
		elif left_r:
			animator.play("up_left")
		else:
			animator.play("up")
	elif down_r:
		if right_r:
			animator.play("down_right")
		elif left_r:
			animator.play("down_left")
		else:
			animator.play("down")

func set_color(color: String):
	var sprite = $Sprite.get_node(color.capitalize())
	if sprite:
		animator = sprite
		reset()

func reset():
	animator.play("down")
	animator.pause()
	animator.visible = true
	position = start_position
