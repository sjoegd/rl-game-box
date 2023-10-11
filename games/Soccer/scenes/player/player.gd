extends CharacterBody2D
class_name Player

signal needs_reset
signal touched_ball

@export var velocity_damp: float = 0.25
@export var speed_multiplier: float = 1.25
@export var push_force: float = 2.5
@export var dash_force_multiplier: float = 2.0
@export var own_force_multiplier: float = 25.0
@export var speed: float = 300.0
@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5
@export var color: String = "red"
@export var is_left_team: bool = true
@export var human_overwrite: bool = false
@export var disable_input: bool = false

var sprite: AnimatedSprite2D
@onready var starting_animation: String = "right" if is_left_team else "left"
@onready var last_animation = starting_animation
@onready var controller: Controller = $AIController2D as Controller
@onready var starting_position: Vector2 = position

var can_dash: bool = true
var is_dashing: bool = false
var last_direction: Vector2 = Vector2.RIGHT

var input_up: bool = false
var input_down: bool = false
var input_right: bool = false
var input_left: bool = false
var input_dash: bool = false

var my_game: Game

func init(game: Game):
	my_game = game

func _ready():
	setup_sprite()
	controller.init(self)
	
func setup_sprite():
	sprite = $Sprites.get_node(color.capitalize()) as AnimatedSprite2D
	sprite.process_mode = Node.PROCESS_MODE_INHERIT
	sprite.visible = true
	start_sprite()

func start_sprite():
	sprite.play(starting_animation)
	sprite.pause()

func game_over():
	controller.done = true
	controller.needs_reset = true

func reset(position_overwrite: Vector2 = Vector2.ZERO):
	if position_overwrite.length() > 0:
		position = position_overwrite
	else:
		position = starting_position
	velocity = Vector2.ZERO
	controller.reset()
	start_sprite()

func _physics_process(_delta):
	if controller.needs_reset:
		needs_reset.emit()
		return
	
	if not disable_input:
		if controller.heuristic == "human":
			input_up = Input.is_action_pressed("up")
			input_down = Input.is_action_pressed("down")
			input_right = Input.is_action_pressed("right")
			input_left = Input.is_action_pressed("left")
			input_dash = Input.is_action_pressed("dash")
		else:
			input_up = controller.action_up
			input_down = controller.action_down
			input_right = controller.action_right
			input_left = controller.action_left
			input_dash = controller.action_dash
		
		if human_overwrite:
			var pressed = ["up", "down", "right", "left", "dash"].map(	
				func(action):
					return Input.is_action_pressed(action)
			)

			if pressed.any(
				func(p):
					return p
			):
				input_up = Input.is_action_pressed("up") 
				input_down = Input.is_action_pressed("down") 
				input_right = Input.is_action_pressed("right") 
				input_left = Input.is_action_pressed("left") 
				input_dash = Input.is_action_pressed("dash")
			else:
				input_up = controller.action_up
				input_down = controller.action_down
				input_right = controller.action_right
				input_left = controller.action_left
				input_dash = controller.action_dash
	
	if not is_dashing:
		var direction = calculate_direction_vector(input_up, input_down, input_right, input_left)
		if direction.length() > 0:
			last_direction = direction
		velocity += direction * speed * speed_multiplier
		handle_animation(input_up, input_down, input_right, input_left, velocity.length())
	
	handle_dash(input_dash)
	handle_velocity()
	move_and_slide()
	handle_collisions()

func calculate_direction_vector(up: bool, down: bool, right: bool, left: bool) -> Vector2:
	var vec = Vector2.ZERO
	if up:
		vec.y -= 1
	if down:
		vec.y += 1
	if right:
		vec.x += 1
	if left:
		vec.x -= 1
	return vec.normalized()

func handle_velocity():
	# Cap velocity
	var max_velocity = (dash_speed if is_dashing else speed) * speed_multiplier
	if velocity.length() > max_velocity:
		velocity = velocity.normalized() * max_velocity

	# Damp velocity
	if not is_dashing:
		velocity = velocity.lerp(Vector2.ZERO, velocity_damp)

func handle_dash(dash: bool):
	if is_dashing:
		velocity = last_direction * dash_speed * speed_multiplier
		return

	if dash and can_dash:
		start_dash()

func start_dash():
	can_dash = false
	is_dashing = true
	sprite.play(last_animation)
	sprite.set_frame_and_progress(0, 0)
	sprite.pause()
	var timer = get_tree().create_timer(dash_duration, true, true)
	timer.connect("timeout", end_dash)

func end_dash():
	is_dashing = false
	var timer = get_tree().create_timer(dash_cooldown, true, true)
	timer.connect("timeout", reset_dash)

func reset_dash():
	can_dash = true

func handle_animation(up: bool, down: bool, right: bool, left: bool, current_speed: float):	
	if not (up or down or right or left) or current_speed == 0:
		sprite.play(last_animation)
		sprite.set_frame_and_progress(0, 0)
		sprite.pause()
		return
	
	var new_animation = ""
	
	if up and not down:
		new_animation = "up"
	if down and not up:
		new_animation = "down"
	if right and not left:
		new_animation += "_right" if new_animation.length() > 0 else "right"
	if left and not right:
		new_animation += "_left" if new_animation.length() > 0 else "left"
	
	sprite.play(new_animation)
	last_animation = new_animation

func handle_collisions():
	var force = push_force * dash_force_multiplier if is_dashing else push_force
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var collider = c.get_collider()
		if collider is Ball:
			collider.apply_central_impulse(-c.get_normal()*force)
			touched_ball.emit()
		if collider is Player:
			collider.apply_impulse(-c.get_normal()*force)

func apply_impulse(impulse: Vector2):
	velocity += impulse * own_force_multiplier
