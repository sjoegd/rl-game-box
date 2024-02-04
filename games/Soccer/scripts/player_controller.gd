extends AIController3D
class_name PlayerController

var action_left := 0.0
var action_right := 0.0
var action_up := 0.0
var action_down := 0.0
var action_rotate_left := 0.0
var action_rotate_right := 0.0
var action_dash := 0.0

func init(player: Node3D):
	super.init(player)
	_update_player_sensors()
	if player.color == "blue":
		_swap_color_sensors()

func get_obs() -> Dictionary:
	
	var obs = []
	
	var sensor_obs = []
	for sensor in _get_sensors():
		sensor_obs += sensor.get_observation()
	
	var player_velocity = _player.velocity.normalized()
	
	if _player.color == "blue":
		player_velocity *= Vector3(-1, 1, -1)
	
	obs += sensor_obs
	obs += [
		float(_player.can_dash),
		float(_player.is_dashing),
		float(_player.input_left),
		float(_player.input_right),
		float(_player.input_up),
		float(_player.input_down),
		float(_player.input_rotate),
		float(_player.input_dash),
		player_velocity.x,
		player_velocity.z
	]
	
	return {"obs":obs}

func get_reward() -> float:	
	return reward
	
func get_action_space() -> Dictionary:
	return {
		"left" : {
			"size": 1,
			"action_type": "discrete"
		},
		"right" : {
			"size": 1,
			"action_type": "discrete"
		},
		"up" : {
			"size": 1,
			"action_type": "discrete"
		},
		"down" : {
			"size": 1,
			"action_type": "discrete"
		},
		"rotate_left" : {
			"size": 1,
			"action_type": "discrete"
		},
		"rotate_right" : {
			"size": 1,
			"action_type": "discrete"
		},
		"dash" : {
			"size": 1,
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
	action_dash = action["dash"]

func give_reward(type: String, value: float):
	var multiplier := 0.0
	match type:
		"goal_scored":          multiplier = 1000.0
		"ball_touch":           multiplier = 0.1
		"ball_distance_goal":   multiplier = 0.5
		"player_distance_ball": multiplier = 0.05
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
