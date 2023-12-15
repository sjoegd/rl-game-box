extends AIController3D
class_name CarController

@export var n_pieces: int = 3

@onready var sensors: Array = $Sensors.get_children()

var forward_action := 0
var backward_action := 0
var right_action := 0
var left_action := 0

func get_obs() -> Dictionary:
	# SENSOR OBS
	var sensor_obs = []
	for sensor in sensors:
		sensor_obs += sensor.get_observation()
	
	# EXTRAS
	var next_n_pieces = _player.game.track.get_future_n_track_parts(_player, n_pieces)
	var going_towards_next_checkpoint = bool_to_value(_player.game.track.is_car_going_to_future_checkpoint(_player))
	var speed = clamp_value((_player.get_speed() / _player.speed_limit) * bool_to_value(_player.is_going_forward()))
	var wheel_angle = clamp_value(_player.steering / _player.steer)
	var nose_angle_to_next_checkpoint = _player.game.track.get_car_nose_angle_to_future_checkpoint(_player)
	var player_rotation = _player.rotation
	var player_velocity = _player.linear_velocity.normalized()
	
	var obs = (
		sensor_obs + 
		next_n_pieces +
		[
			going_towards_next_checkpoint, 
			speed, 
			wheel_angle,
			sin(nose_angle_to_next_checkpoint),
			cos(nose_angle_to_next_checkpoint),
			sin(player_rotation.x),
			cos(player_rotation.x),
			sin(player_rotation.y),
			cos(player_rotation.y),
			sin(player_rotation.z),
			cos(player_rotation.z),
			player_velocity.x,
			player_velocity.y,
			player_velocity.z
		]
	)
	
	return {"obs": obs}

func get_reward() -> float:	
	return reward
	
func get_action_space() -> Dictionary:
	return {
		"forward": {
			"size": 2,
			"action_type": "discrete"
		},
		"backward": {
			"size": 2,
			"action_type": "discrete"
		},
		"right": {
			"size": 2,
			"action_type": "discrete"
		},
		"left": {
			"size": 2,
			"action_type": "discrete"
		}
	}

func set_action(action) -> void:
	forward_action = action["forward"]
	backward_action = action["backward"]
	right_action = action["right"]
	left_action = action["left"]

func clamp_value(value: float):
	return clamp(value, -1, 1)

func bool_to_value(b: bool) -> float:
	return 1.0 if b else -1.0

"""
REWARD FUNCTION:
	
	CARS_BEHIND - .1
	DISTANCE_TRAVELED_FORWARD - 1
	GOING_FORWARD - .25
	WALL_COLLISION - -5
	SPEED - .375
	
	TODO:
		SPEED
		PLAYER_COLLISION?
"""

func give_reward(reward_f: String, value: float):
	var multiplier: float
	match reward_f:
		"CARS_BEHIND":
			multiplier = .1
		"DISTANCE_TRAVELED_FORWARD": 
			multiplier = 1
		"GOING_FORWARD":
			multiplier = .25
		"WALL_COLLISION":
			multiplier = -5
		"SPEED":
			multiplier = .375
		_:
			multiplier = 0
	reward += multiplier * value
