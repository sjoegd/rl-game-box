extends AIController3D
class_name PlayerController

var action_forward := 0
var action_backward := 0
var action_right := 0
var action_left := 0
var action_jump := 0
var action_rotate := 0.0

func init(player: Node3D):
	super.init(player)
	setup_sensors()

func setup_sensors():
	if _player.color == "red":
		# SWAP RED AND BLUE SENSORS
		var red = $Sensors/Red
		var blue = $Sensors/Blue
		var red_index = red.get_index()
		var blue_index = blue.get_index()
		$Sensors.move_child(red, blue_index)
		$Sensors.move_child(blue, red_index)

"""
OBSERVATIONS:
	
	SENSORS:
		PLAYER -> 10
		STATIC -> 10
		BALL -> 10
		BALL_HIGH -> 10
		RED (GOAL) -> 20
		BLUE (GOAL) -> 20
	
	PLAYER:
		position -> /width /height /length -> x, y, z
		rotation.y -> sin, cos
		velocity -> normalized -> x, y, z
		on_floor -> float
	
	BALL:
		ball_position -> /width /height /length -> x, y, z
		ball_velocity -> normalized -> x, y, z
		ball_speed -> /speed_limit
	
	ENEMY:
		enemy_position -> /width /height /length -> x, y, z
		enemy_rotation -> sin, cos
		enemy_velocity -> normalized -> x, y, z
		enemy_on_floor -> float
	
"""

func get_obs() -> Dictionary:
	var sensors = $Sensors.get_children()
	var sensor_obs = []
	for sensor in sensors:
		sensor_obs += sensor.get_observation()
	
	var _position = Utility.normalize_position(_player.global_position, _player._game.arena)
	var _rotation = _player.rotation
	var _velocity = _player.velocity.normalized()
	var _on_floor = float(_player.is_on_floor())
	
	var ball = _player._game.ball
	
	var _ball_position = Utility.normalize_position(ball.global_position, _player._game.arena)
	var _ball_velocity = ball.linear_velocity.normalized()
	var _ball_speed = ball.linear_velocity.length() / ball.speed_limit
	
	var _enemy = _player._game.get_enemy_player(_player)
	
	var _enemy_position = Utility.normalize_position(_enemy.global_position, _enemy._game.arena)
	var _enemy_rotation = _enemy.rotation
	var _enemy_velocity = _enemy.velocity.normalized()
	var _enemy_on_floor = float(_enemy.is_on_floor())
	
	if _player.color == "red":
		var invert_x_z = Vector3(-1, 1, -1)
		var invert_y = Vector3(1, -1, 1)
		_position *= invert_x_z
		_rotation *= invert_y
		_velocity *= invert_x_z
		_ball_position *= invert_x_z
		_ball_velocity *= invert_x_z
		_enemy_position *= invert_x_z
		_enemy_rotation *= invert_y
		_enemy_velocity *= invert_x_z
	
	var obs = (
		sensor_obs + [
			_position.x,
			_position.y,
			_position.z,
			sin(_rotation.y),
			cos(_rotation.y),
			_velocity.x,
			_velocity.y,
			_velocity.z,
			_on_floor,
			_ball_position.x,
			_ball_position.y,
			_ball_position.z,
			_ball_velocity.x,
			_ball_velocity.y,
			_ball_velocity.z,
			_ball_speed,
			_enemy_position.x,
			_enemy_position.y,
			_enemy_position.z,
			sin(_enemy_rotation.y),
			cos(_enemy_rotation.y),
			_enemy_velocity.x,
			_enemy_velocity.y,
			_enemy_velocity.z,
			_enemy_on_floor
		].map(func(ob): return clamp(float(ob), -1.0, 1.0))
	)
	
	return {"obs": obs}

func get_reward() -> float:	
	return reward
	
func get_action_space() -> Dictionary:
	return {
		"forward": {
			"size": 1,
			"action_type": "discrete"
		},
		"backward": {
			"size": 1,
			"action_type": "discrete"
		},
		"right": {
			"size": 1,
			"action_type": "discrete"
		},
		"left": {
			"size": 1,
			"action_type": "discrete"
		},
		"jump": {
			"size": 1,
			"action_type": "discrete"
		},
		"rotate" : {
			"size": 1,
			"action_type": "continuous"
		}
	}
	
func set_action(action) -> void:
	action_forward = action["forward"]
	action_backward = action["backward"]
	action_right = action["right"]
	action_left = action["left"]
	action_jump = action["jump"]
	action_rotate = clamp_action(action["rotate"][0])

func clamp_action(action: float):
	return clamp(action, -1.0, 1.0)

"""
REWARD FUNCTIONS:
	
	GOAL - 1.0
	DISTANCE_BALL - 0.0005
	DISTANCE_BALL_GOAL - 0.001
	TOUCH_BALL - 0.000125
	
	MAX REWARD ~ 5.0
	
"""

func give_reward(reward_function: String, value: float):
	var multiplier: float
	match reward_function:
		"GOAL": multiplier = 1.0
		"DISTANCE_BALL": multiplier = 0.0005
		"DISTANCE_BALL_GOAL": multiplier = 0.001
		"TOUCH_BALL": multiplier = 0.000125
		_: multiplier = 0.0
	reward += multiplier * value
