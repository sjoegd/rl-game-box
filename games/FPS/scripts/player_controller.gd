extends AIController3D
class_name PlayerController

@onready var sensors = $Sensors

var action_shoot := 0.0
var action_sprint := 0.0
var action_left := 0.0
var action_right := 0.0
var action_forward := 0.0
var action_backward := 0.0
var action_rotate_x := 0.0
var action_rotate_y := 0.0

"""
--- OBS SPACE ---

- Raycasts
	- Enemy Player
	- Static
		- Wall + Objects
		- Floor
	- Bullet
- Position
- Rotation
- Head Rotation
- Velocity
- HP
- Is On Floor
? Previous Action Encoding
- Players Left
- Aiming at Enemy
- Aiming at Ground
- Aiming at Nothing

"""

func get_obs() -> Dictionary:
	
	var obs = []
	var sensor_obs = _get_sensor_obs()
	
	var player_position = _player.game.get_normalized_position(_player.position)
	var player_rotation = _player.rotation_degrees / 360
	var player_head_rotation = _player.head.rotation_degrees / 360
	var player_velocity = _player.velocity.normalized()
	var player_hp = _player.hp / _player.base_hp
	var player_is_on_floor = float(_player.is_on_floor())
	var players_left = _player.game.players_left / _player.game.get_player_amount()
	var is_aiming_at_enemy = float(_player.gun.is_aiming_at_enemy())
	var is_aiming_at_ground = float(_player.gun.is_aiming_at_ground())
	var is_aiming_at_nothing = float(_player.gun.is_aiming_at_nothing())
	
	obs += sensor_obs
	obs += [
		player_position.x,
		player_position.y,
		player_position.z,
		player_rotation.x,
		player_rotation.y,
		player_rotation.z,
		player_head_rotation.x,
		player_head_rotation.y,
		player_head_rotation.z,
		player_velocity.x,
		player_velocity.y,
		player_velocity.z,
		player_hp,
		player_is_on_floor,
		players_left,
		is_aiming_at_enemy,
		is_aiming_at_ground,
		is_aiming_at_nothing
	].map(func(x): return clamp(x, -1.0, 1.0))
	
	return {"obs":obs}

func get_reward() -> float:	
	return reward
	
func get_action_space() -> Dictionary:
	return {
		"shoot": {
			"size": 2,
			"action_type": "discrete"
		},
		"sprint": {
			"size": 2,
			"action_type": "discrete"
		},
		"left": {
			"size": 2,
			"action_type": "discrete"
		},
		"right": {
			"size": 2,
			"action_type": "discrete"
		},
		"forward": {
			"size": 2,
			"action_type": "discrete"
		},
		"backward": {
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
		}
	}

func set_action(action) -> void:	
	action_shoot = action["shoot"]
	action_sprint = action["sprint"]
	action_left = action["left"]
	action_right = action["right"]
	action_forward = action["forward"]
	action_backward = action["backward"]
	action_rotate_x = action["rotate_x"][0]
	action_rotate_y = action["rotate_y"][0]

func give_reward(type: String, value: float):
	var multiplier = 0.0
	match type:
		"win":            multiplier = 5.0
		"kill":           multiplier = 1.0
		"deal_damage":    multiplier = 0.2
		"aim_at_enemy":   multiplier = 0.1
		"timestep":       multiplier = -0.01
		"aim_at_ground":  multiplier = -0.05
		"aim_at_nothing": multiplier = -0.1
		"take_damage":    multiplier = -0.2
		"death":          multiplier = -1.0
	reward += multiplier * value

func _get_sensor_obs():
	var sensor_obs = []
	for sensor in sensors.get_children():
		sensor_obs += sensor.get_observation()
	return sensor_obs
