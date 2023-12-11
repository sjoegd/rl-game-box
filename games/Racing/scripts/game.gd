extends Node3D
class_name Game

@export var human_overwrite_mode := false
@export var rebuild_track_mode := false

@onready var track: Track = $Track as Track
@onready var cars: Array = $Cars.get_children()
@onready var starting_grid: Array = $StartingGrid.get_children()

var car_latest_position: Dictionary = {}
var car_static_collision_count: Dictionary = {}
var needs_reset: bool = false

var car_camera_index: int = 0

func _ready():
	var grid = create_random_starting_grid()
	for i in range(len(cars)):
		var car = cars[i]
		car.init(self)
		car.needs_reset.connect(_on_car_need_reset)
		car.finished.connect(_on_car_finish)
		car.collision_with_static.connect(_on_car_collision_with_static)
		car.move_to_grid_position(grid[clamp(i, 0, grid.size() - 1)])
		car_latest_position[car] = car.global_position
		car_static_collision_count[car] = 0
	if human_overwrite_mode:
		cars[car_camera_index].human_overwrite = true

func _process(_delta):
	if needs_reset:
		return reset()
	handle_input()
	var cars_sorted = sort_car_positions()
	for pos in range(len(cars_sorted)):
		var car = cars_sorted[pos]
		handle_car_rewards(car, pos)

func sort_car_positions():
	var cars_sorted = cars.duplicate(true)
	cars_sorted.sort_custom(
		func(a: Car, b: Car): 
			var a_index = track.get_car_latest_track_index(a)
			var b_index = track.get_car_latest_track_index(b)
			
			if a_index == b_index:
				var a_distance = track.get_car_distance_to_future_checkpoint(a, a.global_position, false)
				var b_distance = track.get_car_distance_to_future_checkpoint(b, b.global_position, false)
				return a_distance < b_distance
			
			return a_index > b_index
	)
	return cars_sorted

func handle_car_rewards(car: Car, pos: int):
	# CARS BEHIND
	var cars_behind = cars.size() - (pos + 1)
	car.controller.give_reward("CARS_BEHIND", cars_behind)
	# DISTANCE TRAVELED FORWARD
	var latest_position = car_latest_position[car]
	var new_position = car.global_position
	car_latest_position[car] = new_position
	var latest_distance = track.get_car_distance_to_future_checkpoint(car, latest_position)
	var new_distance = track.get_car_distance_to_future_checkpoint(car, new_position)
	var distance = latest_distance - new_distance
	car.controller.give_reward("DISTANCE_TRAVELED_FORWARD", distance * abs(distance))
	# GOING FORWARD
	var forward = 1.0 if track.is_car_going_to_future_checkpoint(car) else -1.0
	car.controller.give_reward("GOING_FORWARD", forward)
	# WALL COLLISION
	var collisions = car_static_collision_count[car]
	car.controller.give_reward("WALL_COLLISION", collisions)
	car_static_collision_count[car] = 0

func handle_input():
	# CAMERA SWITCH
	if Input.is_action_just_pressed("ui_accept"):
		var current_mode = cars[car_camera_index].camera.get_mode()
		car_camera_index = (car_camera_index + 1) % len(cars)
		cars[car_camera_index].camera.set_mode(current_mode)
		cars[car_camera_index].camera.make_current()
	# MODE SWITCH
	if Input.is_action_just_pressed("ui_focus_next"):
		cars[car_camera_index].camera.next_mode()

func reset():
	needs_reset = false
	track.reset(rebuild_track_mode)
	var grid = create_random_starting_grid()
	for i in range(len(cars)):
		cars[i].reset(grid[clamp(i, 0, grid.size() - 1)])
		car_latest_position[cars[i]] = cars[i].global_position

func create_random_starting_grid():
	var grid = starting_grid.duplicate(true)
	grid.shuffle()
	return grid

func _on_car_need_reset():
	needs_reset = true

func _on_car_finish(car: Car):
	car.game_over()

func _on_car_collision_with_static(car: Car):
	car_static_collision_count[car] += 1
