extends CharacterBody2D
class_name Player

signal needs_reset
signal touched_ball

@export var push_force: float = 5.0
@export var kick_force: float = 50.0
@export var speed: float = 300.0
@export var color: String = "red"
@export var is_left_team: bool = true
@export var human_overwrite: bool = false

var sprite: AnimatedSprite2D
@onready var starting_animation: String = "right" if is_left_team else "left"
@onready var last_animation = starting_animation
@onready var controller: Controller = $AIController2D as Controller
@onready var starting_position: Vector2 = position

var input_up: bool = false
var input_down: bool = false
var input_right: bool = false
var input_left: bool = false

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

func reset():
	position = starting_position
	velocity = Vector2.ZERO
	controller.reset()
	start_sprite()

func _physics_process(_delta):
	if controller.needs_reset:
		needs_reset.emit()
		return
	
	if controller.heuristic == "human" or human_overwrite:
		input_up = Input.is_action_pressed("up")
		input_down = Input.is_action_pressed("down")
		input_right = Input.is_action_pressed("right")
		input_left = Input.is_action_pressed("left")
	else:
		input_up = controller.action_up
		input_down = controller.action_down
		input_right = controller.action_right
		input_left = controller.action_left
	
	velocity = calculate_direction_vector(input_up, input_down, input_right, input_left) * speed
	set_animation(input_up, input_down, input_right, input_left, velocity.length())
	move_and_slide()
	handle_ball_collisions()

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

func set_animation(up: bool, down: bool, right: bool, left: bool, current_speed: float):
	if not (up or down or right or left) or current_speed == 0:
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

func handle_ball_collisions():
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var collider = c.get_collider()
		if collider is Ball:
			collider.apply_central_impulse(-c.get_normal()*push_force)
			touched_ball.emit()
