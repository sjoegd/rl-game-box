extends AIController2D

# TODO: Mirror actions for right team
# Also, check if sensors are working properly for both teams

# Reward Function:
#	1.00000 * Goal Reward (-1 | 0 | 1) 
#	0.00500 * Ball Touch (-1 | 0 | 1) 
#	0.00250 * Distance Player to Ball (0 -> 1) 
#	0.00750 * Distance Ball to Goal (0 -> 1) 
#	0.00125 * Ball Velocity (0 -> 1) 
const GOAL_REWARD_MULTIPLIER: float = 1
const BALL_TOUCH_REWARD_MULTIPLIER: float = 0.005
const DISTANCE_PLAYER_TO_BALL_REWARD_MULTIPLIER: float = 0.0025
const DISTANCE_BALL_TO_GOAL_REWARD_MULTIPLIER: float = 0.0075
const BALL_VELOCITY_REWARD_MULTIPLIER: float = 0.00125

var own_goal_sensor: RaycastSensor2D
var enemy_goal_sensor: RaycastSensor2D

var go_left: bool = false
var go_right: bool = false
var go_up: bool = false
var go_down: bool = false
var go_kick: bool = false

var new_reward: float = 0.0

func _ready():
	setup_goal_sensors()
	setup_other_sensors()
	super._ready()

func setup_goal_sensors():
	var goal_sensors = (
		$GoalSensorsLeft if $"..".is_left_team 
		else $GoalSensorsRight
	) 
	goal_sensors.process_mode = Node.PROCESS_MODE_INHERIT
	own_goal_sensor = goal_sensors.get_node("OwnGoalSensor") as RaycastSensor2D
	enemy_goal_sensor = goal_sensors.get_node("EnemyGoalSensor") as RaycastSensor2D

func setup_other_sensors():
	# If right team, rotate all sensors by 180 degrees (for mirror)
	if not $"..".is_left_team:
		for sensor in [$BallSensors, $PlayerSensors, $StaticSensors]:
			var right = sensor.get_node("Right")
			var left = sensor.get_node("Left")
			right.rotation += PI
			left.rotation += PI

func get_obs() -> Dictionary:
	var ball_sensor_right_obs = $BallSensors/Right.get_observation() 
	var ball_sensor_left_obs = $BallSensors/Left.get_observation()
	var player_sensor_right_obs = $PlayerSensors/Right.get_observation()
	var player_sensor_left_obs = $PlayerSensors/Left.get_observation()
	var static_sensor_right_obs = $StaticSensors/Right.get_observation()
	var static_sensor_left_obs = $StaticSensors/Left.get_observation()
	var own_goal_sensor_obs = own_goal_sensor.get_observation()
	var enemy_goal_sensor_obs = enemy_goal_sensor.get_observation()
	
	# Reverse all sensors if right team (for mirror)
	if not $"..".is_left_team:
		ball_sensor_right_obs.reverse()
		ball_sensor_left_obs.reverse()
		player_sensor_right_obs.reverse()
		player_sensor_left_obs.reverse()
		static_sensor_right_obs.reverse()
		static_sensor_left_obs.reverse()
		own_goal_sensor_obs.reverse()
		enemy_goal_sensor_obs.reverse()
	
	var obs = (
		ball_sensor_right_obs   +
		ball_sensor_left_obs    +
		player_sensor_right_obs +
		player_sensor_left_obs  +
		static_sensor_right_obs +
		static_sensor_left_obs  +
		own_goal_sensor_obs     +
		enemy_goal_sensor_obs   +
		[int($"..".is_kicking)]
	)

	return {"obs":obs}

func get_reward() -> float:
	var reward_now = new_reward
	new_reward = 0
	return reward_now

func get_action_space() -> Dictionary:
	return {
		"left_action": {
			"size": 2,
			"action_type": "discrete"
		},
		"right_action": {
			"size": 2,
			"action_type": "discrete"
		},
		"down_action": {
			"size": 2,
			"action_type": "discrete"
		},
		"up_action": {
			"size": 2,
			"action_type": "discrete"
		},
		"kick_action": {
			"size": 2,
			"action_type": "discrete"
		}
	}

func set_action(action) -> void:
	if $"..".is_left_team:
		go_left  = action["left_action"] == 1
		go_right = action["right_action"] == 1
		go_up    = action["up_action"] == 1
		go_down  = action["down_action"] == 1
		go_kick  = action["kick_action"] == 1
	else: # Mirror horizontally for right team
		go_left  = action["right_action"] == 1
		go_right = action["left_action"] == 1
		go_up    = action["up_action"] == 1
		go_down  = action["down_action"] == 1
		go_kick  = action["kick_action"] == 1

func reset():
	super.reset()
	done = false
	new_reward = 0
	go_left = false
	go_right = false
	go_up = false
	go_down = false
	go_kick = false

func call_goal_reward(value: float):
	new_reward += GOAL_REWARD_MULTIPLIER * value

func call_ball_touch_reward(value: float):
	new_reward += BALL_TOUCH_REWARD_MULTIPLIER * value

func call_distance_player_to_ball_reward(value: float):
	new_reward += DISTANCE_PLAYER_TO_BALL_REWARD_MULTIPLIER * value

func call_distance_ball_to_goal_reward(value: float):
	new_reward += DISTANCE_BALL_TO_GOAL_REWARD_MULTIPLIER * value

func call_ball_velocity_reward(value: float):
	new_reward += BALL_VELOCITY_REWARD_MULTIPLIER * value
