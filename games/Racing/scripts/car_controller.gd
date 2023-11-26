extends AIController3D
class_name CarController

@export var n_pieces: int = 3

@onready var sensors: Array = $Sensors.get_children()

var steer_action: float = 0
var power_action: float = 0

func get_obs() -> Dictionary:
	# SENSOR OBS
	var sensor_obs = []
	for sensor in sensors:
		sensor_obs += sensor.get_observation()
	
	# EXTRAS
	var next_n_pieces = _player.game.track.get_next_n_track_parts(_player, n_pieces)
	var going_towards_next_checkpoint = _player.game.track.is_car_going_to_next_checkpoint(_player)
	var speed = _player.get_speed() / _player.speed_limit
	var wheel_angle = _player.steering / _player.steer
	
	var obs = (
		sensor_obs + 
		next_n_pieces +
		[
			int(going_towards_next_checkpoint), 
			speed, 
			wheel_angle
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
	steer_action = clamp(action["steer_action"][0], -1.0, 1.0)
	power_action = clamp(action["power_action"][0], -1.0, 1.0)

"""
REWARD FUNCTION:
	
	DISTANCE_TRAVELED_FORWARD - 1
	GOING_FORWARD - 0.1
	SPEED - 0.5

"""

func give_reward(reward_f: String, value: float):
	var multiplier: float
	match reward_f:
		"DISTANCE_TRAVELED_FORWARD": 
			multiplier = 1
		"GOING_FORWARD":
			multiplier = 0.1
		"SPEED":
			multiplier = 0.5
		_:
			multiplier = 0
	reward += multiplier * value
