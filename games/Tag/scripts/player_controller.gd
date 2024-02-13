extends AIController3D
class_name PlayerController

@onready var sensors := $Sensors.get_children()

var action_sprint := 0.0
var action_jump := 0.0
var action_left := 0.0
var action_right := 0.0
var action_forward := 0.0
var action_backward := 0.0
var action_rotate_x := 0.0
var action_rotate_y := 0.0

"""
--- OBS SPACE ---

- Sensors
	- Player
	- Tagger
	- Static
	- Object
	- Floor (Static + Object)
- is_tagger
- can_tag
- is_on_floor
- Previous Action Encoding

"""

func get_obs() -> Dictionary:	
	var obs = []
	var sensor_obs = _get_sensor_obs()
	
	obs += sensor_obs
	obs += [
		float(_player.is_tagger),
		float(_player.can_tag),
		float(_player.is_on_floor()),
		action_sprint,
		action_jump,
		action_left,
		action_right,
		action_forward,
		action_backward,
		action_rotate_x,
		action_rotate_y
	]
	
	return {"obs":obs}

func get_reward() -> float:	
	return reward
	
func get_action_space() -> Dictionary:
	return {
		"sprint" : {
			"size": 2,
			"action_type": "discrete"
		},
		"jump" : {
			"size": 2,
			"action_type": "discrete"
		},
		"left" : {
			"size": 2,
			"action_type": "discrete"
		},
		"right" : {
			"size": 2,
			"action_type": "discrete"
		},
		"forward" : {
			"size": 2,
			"action_type": "discrete"
		},
		"backward" : {
			"size": 2,
			"action_type": "discrete"
		},
		"rotate_x" : {
			"size": 1,
			"action_type": "continuous"
		},
		"rotate_y" : {
			"size": 1,
			"action_type": "continuous"
		},
	}
	
func set_action(action) -> void:
	action_sprint   = action["sprint"]
	action_jump     = action["jump"]
	action_left     = action["left"]
	action_right    = action["right"]
	action_forward  = action["forward"]
	action_backward = action["backward"]
	action_rotate_x = action["rotate_x"][0]
	action_rotate_y = action["rotate_y"][0]
	
func give_reward(type: String, value: float):
	var multiplier = 0.0
	match type:
		"lost_tagger":            multiplier = 10.0
		"distance_from_tagger":   multiplier = 0.00625
		"distance_from_taggable": multiplier = 0.025
		"became_tagger":          multiplier = -5.0
		"tagger_timestep":        multiplier = -0.03
	reward += multiplier * value

func _get_sensor_obs():
	var sensor_obs = []
	for sensor in sensors:
		sensor_obs += sensor.get_observation()
	return sensor_obs
