extends AIController3D
class_name PlayerController

var action_straight := 0.0
var action_side := 0.0
var action_rotate := 0.0
var action_jump := false

"""
OBSERVATIONS:
	
	IDEAS:
		look at RL examples
		invert obs for red side
	
	PLAYER:
		position -> /width /height /length -> x, y, z
		rotation.y -> sin, cos
		velocity -> normalized -> x, y, z
		on_floor -> float
	BALL:
		ball_position -> /width /height /length -> x, y, z
		ball_position_diff -> /width /height /length -> x, y, z
		distance_to_ball -> /max_distance
		velocity_to_ball -> normalized -> x, y, z
		speed_to_ball -> /speed -> clamp
		ball_velocity -> normalized -> x, y, z
		ball_speed -> /speed_limit
	OTHER PLAYER:
		other_player_position -> /width /height /length -> x, y, z
		other_player_rotation -> sin, cos
		other_player_velocity -> normalized -> x, y, z
		other_player_on_floor -> float
		other_player_position_diff -> /width /height /length -> x, y, z
		other_player_velocity_diff -> normalized -> x, y, z
	
"""

func get_obs() -> Dictionary:
	
	var _p := _player as Player
	
	var _position = Utility.normalize_position(_p.global_position, _p._game.arena)
	var _rotation = _p.rotation
	var _velocity = _p.velocity.normalized()
	var _on_floor = float(_p.is_on_floor())
	
	var ball := _p._game.ball
	
	var _ball_position = Utility.normalize_position(ball.global_position, _p._game.arena)
	var _ball_position_diff = _ball_position - _position
	var _distance_to_ball = Utility.calculate_distance_player_ball(_p, ball) / _p._game.max_distance_player_ball
	var _velocity_to_ball = Vector3.ZERO
	var _speed_to_ball = 0.0
	var _ball_velocity = ball.linear_velocity.normalized()
	var _ball_speed = ball.linear_velocity.length() / ball.speed_limit
	
	var _p_enemy = _p._game.get_enemy_player(_player)
	
	var _enemy_position = Utility.normalize_position(_p_enemy.global_position, _p._game.arena)
	var _enemy_rotation = _p_enemy.rotation
	var _enemy_velocity = _p_enemy.velocity.normalized()
	var _enemy_on_floor = float(_p_enemy.is_on_floor())
	var _enemy_position_diff = _enemy_position - _position
	var _enemy_velocity_diff = _enemy_velocity - _velocity
	
	if _player.color == "red":
		# INVERT
		var invert_x_z = Vector3(-1, 1, -1)
		_position *= invert_x_z
		_velocity *= invert_x_z
		_ball_position *= invert_x_z
		_ball_position_diff *= invert_x_z
		_velocity_to_ball *= invert_x_z
		_ball_velocity *= invert_x_z
		_enemy_position *= invert_x_z
		_enemy_velocity *= invert_x_z
		_enemy_position_diff *= invert_x_z
		_enemy_velocity_diff *= invert_x_z
	
	var obs = [
		_position.x,
		_position.y,
		_position.z,
		_rotation.y,
		_velocity.x,
		_velocity.y,
		_velocity.z,
		_on_floor,
		_ball_position.x,
		_ball_position.y,
		_ball_position.z,
		_ball_position_diff.x,
		_ball_position_diff.y,
		_ball_position_diff.z,
		_distance_to_ball,
		_velocity_to_ball.x,
		_velocity_to_ball.y,
		_velocity_to_ball.z,
		_speed_to_ball,
		_ball_velocity.x,
		_ball_velocity.y,
		_ball_velocity.z,
		_ball_speed,
		_enemy_position.x,
		_enemy_position.y,
		_enemy_position.z,
		_enemy_rotation.y,
		_enemy_velocity.x,
		_enemy_velocity.y,
		_enemy_velocity.z,
		_enemy_on_floor,
		_enemy_position_diff.x,
		_enemy_position_diff.y,
		_enemy_position_diff.z,
		_enemy_velocity_diff.x,
		_enemy_velocity_diff.y,
		_enemy_velocity_diff.z
	].map(
		func(ob): return clamp(float(ob), -1.0, 1.0)
	)
	
	return {"obs": obs}

func get_reward() -> float:	
	return reward
	
func get_action_space() -> Dictionary:
	return {
		"direction" : {
			"size": 2,
			"action_type": "continuous"
		},
		"rotate" : {
			"size": 1,
			"action_type": "continuous"
		},
		"jump": {
			"size": 1,
			"action_type": "discrete"
		}
	}
	
func set_action(action) -> void:
	action_straight = clamp_action(action["direction"][0])
	action_side = clamp_action(action["direction"][1])
	action_rotate = clamp_action(action["rotate"][0])
	action_jump = bool(action["jump"])

func clamp_action(action: float):
	return clamp(action, -1.0, 1.0)
	
"""
REWARD FUNCTIONS:
	
	GOAL - 1.0
	DISTANCE_BALL - 0.05
	DISTANCE_BALL_GOAL - 0.1
	TOUCH_BALL - 0.025
	
"""

func give_reward(reward_function: String, value: float):
	var multiplier: float
	match reward_function:
		"GOAL": multiplier = 1.0
		"DISTANCE_BALL": multiplier = 0.05
		"DISTANCE_BALL_GOAL": multiplier = 0.1
		"TOUCH_BALL": multiplier = 0.025
		_: multiplier = 0.0
	reward += multiplier * value
