extends AIController2D

# TODO: Find a better way to mirror own|enemy goal sensors
# So that the agent knows which goal is his own and thus where to score

# TODO: Implement the needs_reset checking and handling (maybe in train scene)

# Reward Function:
#	TODO - 10.0000 * Goal Reward (-1 | 0 | 1) 
#	TODO - 0.00500 * Ball Touch (-1 | 0 | 1) 
#	TODO - 0.00125 * Distance Player to Ball (0 -> 1) 
#	TODO - 0.01000 * Distance Ball to Goal (0 -> 1) 
#	TODO - 0.00250 * Ball Velocity (0 -> 1) 
const GOAL_REWARD_MULTIPLIER: float = 10
const BALL_TOUCH_REWARD_MULTIPLIER: float = 0.005
const DISTANCE_PLAYER_TO_BALL_REWARD_MULTIPLIER: float = 0.00125
const DISTANCE_BALL_TO_GOAL_REWARD_MULTIPLIER: float = 0.01
const BALL_VELOCITY_REWARD_MULTIPLIER: float = 0.0025

@onready var ball_sensor   = $BallSensor as RaycastSensor2D
@onready var player_sensor = $PlayerSensor as RaycastSensor2D
@onready var static_sensor = $StaticSensor as RaycastSensor2D
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
	super._ready()

func setup_goal_sensors():
	var goal_sensors = (
		$GoalSensorsLeft if $"..".is_left_team 
		else $GoalSensorsRight
	) 
	goal_sensors.process_mode = Node.PROCESS_MODE_INHERIT
	own_goal_sensor = goal_sensors.get_node("OwnGoalSensor") as RaycastSensor2D
	enemy_goal_sensor = goal_sensors.get_node("EnemyGoalSensor") as RaycastSensor2D

func get_obs() -> Dictionary:	
	var obs = (
		player_sensor.get_observation()     +
		ball_sensor.get_observation()       +
		static_sensor.get_observation()     +
		own_goal_sensor.get_observation()   +
		enemy_goal_sensor.get_observation() +
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
	go_left  = action["left_action"] == 1
	go_right = action["right_action"] == 1
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
