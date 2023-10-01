extends CharacterBody2D
class_name Player

@export var push_force: float = 5.0
@export var kick_force: float = 50.0
@export var speed: float = 300.0
@export var starting_direction: String = "right"
@export var turning_cooldown_sec: float = 0.05
@export var color: String = "red"

var sprite: AnimatedSprite2D

@onready var current_direction_index = direction_cycle.find(starting_direction)
var direction_cycle = ["down", "down_left", "left", "up_left", "up", "up_right", "right", "down_right"]
var direction_to_vector = {
	"down": Vector2(0, 1),
	"down_left": Vector2(-1, 1).normalized(),
	"down_right": Vector2(1, 1).normalized(),
	"up": Vector2(0, -1),
	"up_left": Vector2(-1, -1).normalized(),
	"up_right": Vector2(1, -1).normalized(),
	"left": Vector2(-1, 0),
	"right": Vector2(1, 0)
}

var can_turn: bool = true

var input_forward: bool = false
var input_backward: bool = false
var input_right: bool = false
var input_left: bool = false

func _ready():
	sprite = $Sprites.get_node(color.capitalize()) as AnimatedSprite2D
	sprite.process_mode = Node.PROCESS_MODE_INHERIT
	sprite.visible = true

func _physics_process(_delta):
	
	var speed_d = 0
	var direction_d = 0
	
	# TODO: For human heuristic, parse direction from input, no turning
	
	if Input.is_action_pressed("forward"):
		speed_d += 1
	if Input.is_action_pressed("backward"):
		speed_d -= 0.5
	
	if can_turn:
		if Input.is_action_pressed("right"):
			direction_d += 1
		if Input.is_action_pressed("left"):
			direction_d -= 1
		
		if direction_d != 0:
			can_turn = false
			var turn_timer = get_tree().create_timer(turning_cooldown_sec, true, true)
			turn_timer.connect("timeout", _on_turn_timer_timeout)
	
	current_direction_index = (current_direction_index + direction_d) % direction_cycle.size()
	var current_direction = direction_cycle[current_direction_index]
	var current_direction_vector = direction_to_vector[current_direction]
	velocity = current_direction_vector * speed * speed_d
	
	move_and_slide()
	handle_ball_collisions()
	
	sprite.play(current_direction, speed_d)
	if speed_d == 0:
		sprite.set_frame_and_progress(0, 0)

func handle_ball_collisions():
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var collider = c.get_collider()
		if collider is Ball:
			collider.apply_central_impulse(-c.get_normal()*push_force)

func _on_turn_timer_timeout():
	can_turn = true
