extends AIController3D
class_name PlayerController

@export var goal_sensors_length := 32
var goal_sensors_setup := false

var action_straight := 0.0
var action_side := 0.0
var action_rotate := 0.0
var action_jump := 0
var action_dash := 0

func init(player: Node3D):
	super.init(player)
	setup_goal_sensors()
	
func setup_goal_sensors():
	var my_color = _player.color
	var enemy_color = _player.get_enemy_team()
	var my_goal_sensor = $GoalSensors.get_node(my_color.capitalize())
	var enemy_goal_sensor = $GoalSensors.get_node(enemy_color.capitalize())
	$GoalSensors.remove_child(my_goal_sensor)
	$GoalSensors.remove_child(enemy_goal_sensor)
	$Sensors.add_child(my_goal_sensor)
	$Sensors.add_child(enemy_goal_sensor)
	goal_sensors_setup = true

func get_obs() -> Dictionary:
	# SENSOR OBS
	var sensor_obs = []
	for sensor in $Sensors.get_children():
		sensor_obs += sensor.get_observation()
	
	if not goal_sensors_setup:
		sensor_obs += create_empty_observation(goal_sensors_length)
		
	var p = _player as Player
	
	# EXTRAS
	var movement_locked = float(p.movement_locked)
	var is_on_floor = float(p.is_on_floor())
	var can_dash = float(p.can_dash)
	var player_velocity = p.velocity.normalized()
	var player_rotation = p.rotation
	var ball_velocity = p._game.arena.get_ball_velocity().normalized()
	var ball_speed = p._game.arena.get_ball_speed()
		
	return {"obs":(
		sensor_obs + [
			movement_locked,
			is_on_floor,
			can_dash,
			player_velocity.x,
			player_velocity.y,
			player_velocity.z,
			sin(player_rotation.y),
			cos(player_rotation.y),
			ball_velocity.x,
			ball_velocity.y,
			ball_velocity.z,
			ball_speed
		]
	)}

func get_reward() -> float:	 
	return reward
	
func get_action_space() -> Dictionary:
	return {
		"action_straight": {
			"size": 1,
			"action_type": "continuous"
		},
		"action_side": {
			"size": 1,
			"action_type": "continuous"
		},
		"action_rotate": {
			"size": 1,
			"action_type": "continuous"
		},
		"action_jump": {
			"size": 2,
			"action_type": "discrete"
		},
		"action_dash": {
			"size": 2,
			"action_type": "discrete"
		}
	}
	
func set_action(action) -> void:
	action_straight = clamp_continuous_action(action["action_straight"][0])
	action_side = clamp_continuous_action(action["action_side"][0])
	action_rotate = clamp_continuous_action(action["action_rotate"][0])
	action_jump = clamp_discrete_action(action["action_jump"])
	action_dash = clamp_discrete_action(action["action_dash"])
	
func clamp_continuous_action(action: float):
	return clamp(action, -1.0, 1.0)

func clamp_discrete_action(action: int):
	return clamp(action, 0, 1)

func create_empty_observation(length: int):
	var empty_obs = []
	for i in range(length):
		empty_obs.append(0)
	return empty_obs

"""
REWARD FUNCTIONS:
	GOAL_SCORED - 500.0
	BALL_TOUCH - 0.25
	DISTANCE_PLAYER_BALL - 0.5
	DISTANCE_BALL_ENEMY_GOAL - 2.0
	BALL_SPEED - 0.25
"""

func give_reward(reward_f: String, value: float):
	var multiplier
	match(reward_f):
		"GOAL_SCORED": multiplier = 500.0
		"BALL_TOUCH": multiplier = 0.25
		"DISTANCE_PLAYER_BALL": multiplier = 0.5
		"DISTANCE_BALL_ENEMY_GOAL": multiplier = 2.0
		"BALL_SPEED": multiplier = 0.25
		_: multiplier = 0.0
	reward += multiplier * value
