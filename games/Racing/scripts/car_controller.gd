extends AIController3D
class_name CarController

@export var n_pieces: int = 3

@onready var sensors: Array = $Sensors.get_children()

var steer_action: float = 0
var power_action: float = 0

# TODO: Better obs
# Update n_pieces to give information about how the piece is based on the cars transform
# Nose angle -> sin, cos?
func get_obs() -> Dictionary:
	# SENSOR OBS
	var sensor_obs = []
	for sensor in sensors:
		sensor_obs += sensor.get_observation()
	
	# EXTRAS
	var next_n_pieces = _player.game.track.get_next_n_track_parts(_player, n_pieces)
	var going_towards_next_checkpoint = bool_to_value(_player.game.track.is_car_going_to_next_checkpoint(_player))
	var is_going_forward = bool_to_value(_player.is_going_forward())
	var speed = clamp_value((_player.get_speed() / _player.speed_limit) * is_going_forward)
	var wheel_angle = clamp_value(_player.steering / _player.steer)
	var nose_angle_to_next_checkpoint = _player.game.track.get_car_nose_angle_to_next_checkpoint(_player)
	
	var obs = (
		sensor_obs + 
		next_n_pieces +
		[
			going_towards_next_checkpoint, 
			speed, 
			wheel_angle,
			sin(nose_angle_to_next_checkpoint),
			cos(nose_angle_to_next_checkpoint)
		]
	)
	
	return {"obs": obs}

func get_reward() -> float:	
	return reward
	
func get_action_space() -> Dictionary:
	return {
		"steer_action": {
			"size": 2,
			"action_type": "continuous"
		},
		"power_action": {
			"size": 2,
			"action_type": "continuous"
		}
	}
	
func set_action(action) -> void:
	steer_action = clamp_value(action["steer_action"][0])
	power_action = clamp_value(action["power_action"][0])

func clamp_value(value: float):
	return clamp(value, -1, 1)

func bool_to_value(b: bool) -> float:
	return 1.0 if b else -1.0

"""
REWARD FUNCTION:
	
	CARS_BEHIND - 0.1
	DISTANCE_TRAVELED_FORWARD - 2
	GOING_FORWARD - 1
	WALL_COLLISION - -5

"""

func give_reward(reward_f: String, value: float):
	var multiplier: float
	match reward_f:
		"CARS_BEHIND":
			multiplier = 0.1
		"DISTANCE_TRAVELED_FORWARD": 
			multiplier = 2
		"GOING_FORWARD":
			multiplier = 1
		"WALL_COLLISION":
			multiplier = -5
		_:
			multiplier = 0
	reward += multiplier * value
