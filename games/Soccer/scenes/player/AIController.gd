extends AIController2D

@export var right_goal_collision_mask = 16
@export var left_goal_collision_mask  = 8

@onready var ball_sensor   = $BallSensor as RaycastSensor2D
@onready var player_sensor = $PlayerSensor as RaycastSensor2D
@onready var static_sensor = $StaticSensor as RaycastSensor2D
@onready var own_goal_sensor  = $OwnGoalSensor as RaycastSensor2D
@onready var enemy_goal_sensor = $EnemyGoalSensor as RaycastSensor2D

var go_left: bool = false
var go_right: bool = false
var go_up: bool = false
var go_down: bool = false

var new_reward: float = 0.0

func _ready():
	if not $"..".is_left_team:
		own_goal_sensor.rotation += PI
		enemy_goal_sensor.rotation += PI
	super._ready()

func get_obs() -> Dictionary:	
	var obs = (
		player_sensor.get_observation()   +
		ball_sensor.get_observation()     +
		static_sensor.get_observation()   +
		own_goal_sensor.get_observation() +
		enemy_goal_sensor.get_observation()
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
		}
	}

func set_action(action) -> void:
	go_left  = action["left_action"] == 1
	go_right = action["right_action"] == 1
	go_up    = action["up_action"] == 1
	go_down  = action["down_action"] == 1
