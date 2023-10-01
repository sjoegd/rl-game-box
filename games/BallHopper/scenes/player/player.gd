extends CharacterBody2D
class_name Player

signal need_reset

const SPEED = 750.0
const ALIVE_TICK_REWARD = 1.0
const GAME_OVER_REWARD = -100

@onready var ai_controller = $AIController2D as AIController2D

func _ready():
	ai_controller.init(self)

func game_over():
	ai_controller.reward += GAME_OVER_REWARD
	ai_controller.done = true
	ai_controller.needs_reset = true

func reset(new_position: Vector2):
	position = new_position
	ai_controller.reset()

func _physics_process(_delta):
	if ai_controller.needs_reset:
		need_reset.emit()
		return
	
	if ai_controller.heuristic == "human":
		velocity.x = SPEED * calculate_player_input()
	else:
		velocity.x = SPEED * ai_controller.move_side
	move_and_slide()
	
	ai_controller.reward += ALIVE_TICK_REWARD

func calculate_player_input():
	var value = 0
	if Input.is_action_pressed("right"):
		value += 1
	if Input.is_action_pressed("left"):
		value -= 1
	return value

