extends AIController3D
class_name PlayerController

var action_left := 0.0
var action_right := 0.0
var action_up := 0.0
var action_down := 0.0
var action_rotate_left := 0.0
var action_rotate_right := 0.0
var action_sprint := 0.0

func init(player: Node3D):
	super.init(player)
	_update_player_sensors()
	if player.color == "blue":
		_swap_color_sensors()

"""
--- OBS SPACE ---

Current problems:
	- Player looses track of the ball
		? Raycast radius to 360deg

- Raycasts
	- Teammate
	- Enemies
	- Static
	- Ball
	- Own Goal
	- Enemy Goal
- Previous Action Encoding
- Is Sprinting
- Ball Position
- Ball Velocity
- Ball Speed
- Player Velocity
- Player Position
- Player Rotation
- Distance to Ball

"""

func get_obs() -> Dictionary:
	
	var obs = []
	
	var sensor_obs = []
	for sensor in _get_sensors():
		sensor_obs += sensor.get_observation()
	
	var game = _player.game as Game

	var ball_position = game.field.get_normalized_position(game.ball.global_position)
	var ball_velocity = game.ball.linear_velocity.normalized()
	var ball_speed = game.ball.linear_velocity.length() / game.ball.linear_speed_limit
	
	var player_position = game.field.get_normalized_position(_player.global_position)
	var player_velocity = _player.velocity.normalized()
	var player_rotation = _player.rotation_degrees / 360

	var distance_to_ball = ball_position.distance_to(player_position)
	
	if _player.color == "blue":
		ball_position *= Vector3(-1, 1, -1)
		ball_velocity *= Vector3(-1, 1, -1)
		player_position *= Vector3(-1, 1, -1)
		player_velocity *= Vector3(-1, 1, -1)
		player_rotation *= -1
	
	obs += sensor_obs
	obs += [
		float(_player.input_left),
		float(_player.input_right),
		float(_player.input_up),
		float(_player.input_down),
		float(_player.input_rotate),
		float(_player.input_sprint),
		float(_player.is_sprinting),
		ball_position.x,
		ball_position.y,
		ball_position.z,
		ball_velocity.x,
		ball_velocity.y,
		ball_velocity.z,
		ball_speed,
		player_position.x,
		player_position.y,
		player_position.z,
		player_velocity.x,
		player_velocity.y,
		player_velocity.z,
		player_rotation.x,
		player_rotation.y,
		player_rotation.z,
		distance_to_ball
	].map(func(x): return clamp(x, -1.0, 1.0))
	
	return {"obs":obs}

func get_reward() -> float:	
	return reward

func get_action_space() -> Dictionary:
	return {
		"left" : {
			"size": 2,
			"action_type": "discrete"
		},
		"right" : {
			"size": 2,
			"action_type": "discrete"
		},
		"up" : {
			"size": 2,
			"action_type": "discrete"
		},
		"down" : {
			"size": 2,
			"action_type": "discrete"
		},
		"rotate_left" : {
			"size": 2,
			"action_type": "discrete"
		},
		"rotate_right" : {
			"size": 2,
			"action_type": "discrete"
		},
		"sprint" : {
			"size": 2,
			"action_type": "discrete"
		}
	}

func set_action(action) -> void:	
	action_left = action["left"]
	action_right = action["right"]
	action_up = action["up"]
	action_down = action["down"]
	action_rotate_left = action["rotate_left"]
	action_rotate_right = action["rotate_right"]
	action_sprint = action["sprint"]

func give_reward(type: String, value: float):
	var multiplier := 0.0
	match type:
		"goal_scored":          multiplier = 10.0
		"ball_touch":           multiplier = 0.5
		"ball_distance_goal":   multiplier = 0.05
		"player_distance_ball": multiplier = 0.0125
		"time_step":            multiplier = -0.0125
	reward += multiplier * value

func _swap_color_sensors():
	_swap_sensors($Sensors/RedGoal, $Sensors/BlueGoal)
	_swap_sensors($Sensors/RedPlayer, $Sensors/BluePlayer)
	
func _swap_sensors(sensor1, sensor2):
	var sensors = $Sensors
	var sensor1_index = sensor1.get_index()
	var sensor2_index = sensor2.get_index()
	sensors.move_child(sensor1, sensor2_index)
	sensors.move_child(sensor2, sensor1_index)

func _update_player_sensors():
	var raycast
	var index = _player.number
	if _player.color == "red":
		raycast = $Sensors/RedPlayer
		index += 5
	else:
		raycast = $Sensors/BluePlayer
		index += 7
	var mask_value = pow(2, index)
	raycast.collision_mask -= mask_value
	raycast._spawn_nodes()

func _get_sensors():
	return $Sensors.get_children()
