extends AIController2D
class_name Controller

@onready var mirrored: bool = not ($".." as Player).is_left_team

var player_sensor: Raycaster
var ball_sensor: Raycaster
var static_sensor: Raycaster
var goal_sensor_own: Raycaster
var goal_sensor_enemy: Raycaster

var action_up: bool = false
var action_down: bool = false
var action_right: bool = false
var action_left: bool = false
var action_dash: bool = false

func _ready():
	setup_sensors()
	super._ready()

func setup_sensors():
	player_sensor = $PlayerSensor as Raycaster
	ball_sensor = $BallSensor as Raycaster
	static_sensor = $StaticSensor as Raycaster
	var goal_sensors = $GoalSensorRight if mirrored else $GoalSensorsLeft
	goal_sensor_own = goal_sensors.get_node("OwnSensor") as Raycaster
	goal_sensor_enemy = goal_sensors.get_node("EnemySensor") as Raycaster
	
	player_sensor.init(mirrored)
	ball_sensor.init(mirrored)
	static_sensor.init(mirrored)
	goal_sensor_own.init(mirrored)
	goal_sensor_enemy.init(mirrored)

func get_obs() -> Dictionary:
	
	var ball = (_player as Player).my_game.ball
	var ball_velocity = ball.linear_velocity.length() / ball.max_velocity
	
	var obs = (
		player_sensor.get_observation() +
		ball_sensor.get_observation()   +
		static_sensor.get_observation() +
		goal_sensor_own.get_observation() +
		goal_sensor_enemy.get_observation() +
		[
			# Previous Action Observations
			float(action_up),
			float(action_down),
			float(action_right),
			float(action_left),
			float(action_dash)
		] +
		[
			# Dash Observations
			float((_player as Player).can_dash),
			float((_player as Player).is_dashing),
		] +
		[
			# Ball Observations
			float(ball_velocity)
		]
	)
	
	return {
		"obs":obs
	}

func get_reward() -> float:	
	return reward
	
func get_action_space() -> Dictionary:
	return {
		"up" : {
			"size": 2,
			"action_type": "discrete"
		},
		"down" : {
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
		},
		"dash": {
			"size": 2,
			"action_type": "discrete"
		}
	}
	
func set_action(action) -> void:
	action_up = action["up"] == 1
	action_down = action["down"] == 1
	if not mirrored:
		action_right = action["right"] == 1
		action_left = action["left"] == 1
	else:
		action_right = action["left"] == 1
		action_left = action["right"] == 1
	action_dash = action["dash"] == 1

func reset():
	action_up = false
	action_down = false
	action_right = false
	action_left = false
	action_dash = false
	super.reset()

"""
REWARD FUNCTION:
	
	GOAL_SCORED:
		100.0 x (1 | 0 | -1)
	
	BALL_TOUCHED:
		0.025 x (1 | 0 | -1)
	
	BALL_VELOCITY: 
		0.05 x (0 -> 1)
	
	MIN_BALL_VELOCITY:
		0.1 x (0 | -1)
	
	DISTANCE_BALL_GOAL:
		0.5 x (-1 -> 1)
	
	DISTANCE_PLAYER_BALL: 
		0.1 x (-1 -> 1)
"""

"""
TODO:
	- Maybe increase the ray count for obs
		- Allows for more accurate obs
			- Makes the models bigger and more expensive though
"""

var GOAL_SCORED_REWARD: float = 100.0
var BALL_TOUCHED_REWARD: float = 0.025
var BALL_VELOCITY_REWARD: float = 0.05
var MIN_BALL_VELOCITY_REWARD: float = 0.1
var DISTANCE_BALL_GOAL_REWARD: float = 0.5
var DISTANCE_PLAYER_BALL_REWARD: float = 0.1

func on_goal_scored_reward(value: float):
	reward += GOAL_SCORED_REWARD * value

func on_ball_touched_reward(value: float):
	reward += BALL_TOUCHED_REWARD * value

func on_ball_velocity_reward(value: float):
	reward += BALL_VELOCITY_REWARD * value

func on_min_ball_velocity_reward(value: float):
	reward += MIN_BALL_VELOCITY_REWARD * value

func on_distance_ball_goal_reward(value: float):
	reward += DISTANCE_BALL_GOAL_REWARD * value

func on_distance_player_ball_reward(value: float):
	reward += DISTANCE_PLAYER_BALL_REWARD * value
