extends Node3D
class_name Game

@onready var track: Track = $Track as Track
@onready var cars: Array = $Cars.get_children()
@onready var starting_grid: Array = $StartingGrid.get_children()

var car_latest_position: Dictionary = {}
var need_reset: bool = false

func _ready():
	var grid = create_random_starting_grid()
	for i in range(len(cars)):
		var car = cars[i]
		car.init(self)
		car.finished.connect(_on_car_finish)
		car.need_reset.connect(_on_car_need_reset)
		car.move_to_grid_position(grid[clamp(i, 0, grid.size() - 1)])
		car_latest_position[car] = car.global_position

func _process(_delta):
	if need_reset:
		reset()
	sort_car_positions()
	for pos in range(len(cars)):
		var car = cars[pos]
		handle_car_rewards(car, pos)

func sort_car_positions():
	cars.sort_custom(
		func(a: Car, b: Car): 
			var a_index = track.get_car_latest_track_index(a)
			var b_index = track.get_car_latest_track_index(b)
			
			if a_index == b_index:
				var a_distance = track.get_car_distance_to_next_checkpoint(a, a.global_position, false)
				var b_distance = track.get_car_distance_to_next_checkpoint(b, b.global_position, false)
				return a_distance < b_distance
			
			return a_index > b_index
	)

func handle_car_rewards(car: Car, pos: int):
	# CARS BEHIND
	var cars_behind = cars.size() - (pos + 1)
	car.controller.give_reward("CARS_BEHIND", cars_behind)
	# DISTANCE TRAVELED FORWARD
	var latest_position = car_latest_position[car]
	var new_position = car.global_position
	car_latest_position[car] = new_position
	var latest_distance = track.get_car_distance_to_next_checkpoint(car, latest_position)
	var new_distance = track.get_car_distance_to_next_checkpoint(car, new_position)
	var distance = latest_distance - new_distance
	car.controller.give_reward("DISTANCE_TRAVELED_FORWARD", pow(distance, 2))
	# GOING FORWARD
	var forward = 1.0 if track.is_car_going_to_next_checkpoint(car) else -1.0
	car.controller.give_reward("GOING_FORWARD", forward)
	# SPEED
	var speed = clamp(car.get_speed() / car.speed_limit, -1.0, 1.0)
	car.controller.give_reward("SPEED", speed)

func reset():
	need_reset = false
	track.reset()
	var grid = create_random_starting_grid()
	for i in range(len(cars)):
		cars[i].reset(grid[clamp(i, 0, grid.size() - 1)])
		car_latest_position[cars[i]] = cars[i].global_position

func create_random_starting_grid():
	var grid = starting_grid.duplicate(true)
	grid.shuffle()
	return grid

func _on_car_need_reset():
	need_reset = true

func _on_car_finish(car: Car):
	car.game_over()
