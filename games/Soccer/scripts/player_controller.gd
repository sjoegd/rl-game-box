extends AIController3D
class_name PlayerController

var action_left := 0.0
var action_right := 0.0
var action_up := 0.0
var action_down := 0.0
var action_rotate := 0.0
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
	
	obs += sensor_obs
	obs += [
		float(_player.can_dash),
		float(_player.is_dashing),
		float(_player.input_left),
		float(_player.input_right),
		float(_player.input_up),
		float(_player.input_down),
		float(_player.input_rotate),
		float(_player.input_dash)
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
		"rotate" : {
			"size": 1,
			"action_type": "continuous"
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
	action_rotate = action["rotate"][0]
	action_dash = action["dash"]

func give_reward(type: String, value: float):
	var multiplier := 0.0
	match type:
		"goal_scored":          multiplier = 1000.0
		"ball_touched":         multiplier = 0.125
		"ball_distance_goal":   multiplier = 0.5
		"player_distance_ball": multiplier = 0.125
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
