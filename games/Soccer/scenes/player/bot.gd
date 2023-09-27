class_name Bot
extends Player

# TODO: Better extension of Player, maybe a base PlayerController class that they both extend from?

@onready var controller = $AIController
@export var is_left_team: bool = true

func _process(_delta):
	if controller.needs_reset:
		controller.reset()
	handle_player_input()

func _physics_process(_delta):
	super._physics_process(_delta)
	# TODO: handle collision detection rewards here?

func handle_player_input():
	var direction_vector = calculate_direction_vector(
		controller.go_left, 
		controller.go_right, 
		controller.go_up, 
		controller.go_down
	)
	velocity = direction_vector * speed
	set_direction(
		controller.go_left,
		controller.go_right,
		controller.go_up,
		controller.go_down,
		direction_vector
	)
	update_sensor_directions(direction_vector)

func calculate_direction_vector(left: bool, right: bool, up: bool, down: bool):
	var direction_vector = Vector2.ZERO
	
	if left:
		direction_vector.x -= 1
	if right:
		direction_vector.x += 1
	if up:
		direction_vector.y -= 1
	if down:
		direction_vector.y += 1
		
	return direction_vector.normalized()

func update_sensor_directions(direction_vector: Vector2):
	var offset = PI/2
	var sensor_angle = direction_vector.angle() + offset
	$AIController/BallSensor.rotation = sensor_angle
	$AIController/PlayerSensor.rotation = sensor_angle
	$AIController/StaticSensor.rotation = sensor_angle

func add_reward(reward: float):
	controller.new_reward += reward

func reset():
	super.reset()
	controller.done = true
	controller.needs_reset = true

