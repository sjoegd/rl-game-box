extends Node3D
class_name Game

@onready var track: Track = $Track as Track
@onready var cars: Array = $Cars.get_children()
@onready var starting_grid: Array = $StartingGrid.get_children()

var car_latest_position: Dictionary = {}
var need_reset: bool = false

func _ready():
	for car in cars:
		car.finished.connect(_on_car_finish)
		car.need_reset.connect(_on_car_need_reset)
		car.init(self)
		car_latest_position[car] = car.global_position

func _process(_delta):
	if need_reset:
		reset()
	for car in cars:
		handle_car_rewards(car)

func handle_car_rewards(car: Car):
	# DISTANCE TRAVELED FORWARD
	var latest_position = car_latest_position[car]
	var new_position = car.global_position
	car_latest_position[car] = new_position
	var latest_distance = track.get_car_distance_to_next_checkpoint(car, latest_position)
	var new_distance = track.get_car_distance_to_next_checkpoint(car, new_position)
	var distance = latest_distance - new_distance
	car.controller.give_reward("DISTANCE_TRAVELED_FORWARD", pow(distance, 2))
	# GOING FORWARD
	var forward = track.is_car_going_to_next_checkpoint(car)
	car.controller.give_reward("GOING_FORWARD", forward)
	# SPEED
	var speed = car.get_speed() / car.speed_limit
	car.controller.give_reward("SPEED", speed)

func reset():
	need_reset = false
	track.reset()
	var grid = create_random_starting_grid()
	for i in range(len(cars)):
		cars[i].reset(grid[i])
		car_latest_position[cars[i]] = cars[i].global_position

func create_random_starting_grid():
	var grid = starting_grid.duplicate(true)
	grid.shuffle()
	return grid

func _on_car_need_reset():
	need_reset = true

func _on_car_finish(car: Car):
	car.game_over()
