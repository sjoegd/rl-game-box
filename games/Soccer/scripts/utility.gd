class_name Utility

static func color_to_hex(color: String) -> String:
	match color:
		"blue": return "#b4e8ee"
		"red": return "#f55f75"
		_: return "white"

static func get_enemy_color(color: String) -> String:
	return "red" if color == "blue" else "blue"

static func calculate_max_distance_player_ball(arena: Arena) -> float:
	var width = arena.get_width()
	var length = arena.get_length()
	var height = arena.get_height()
	return Vector3.ZERO.distance_to(Vector3(width, height, length*2))

static func calculate_max_distance_ball_goal(arena: Arena) -> float:
	var width = arena.get_width()
	var length = arena.get_length()
	var height = arena.get_height()
	return Vector3.ZERO.distance_to(Vector3(width/2, height/2, length*2))

static func calculate_distance_player_ball(player: Player, ball: Ball) -> float:
	var player_position = player.global_position
	var ball_position = ball.global_position
	return player_position.distance_to(ball_position)

static func calculate_distance_ball_goal(ball: Ball, arena: Arena, goal: String) -> float:
	var goal_position = arena.get_goal_position(goal)
	var ball_position = ball.global_position
	return ball_position.distance_to(goal_position)

static func normalize_position(position: Vector3, arena: Arena) -> Vector3:
	var width = arena.get_width()
	var height = arena.get_height()
	var length = arena.get_length()
	return Vector3(
		position.x / width,
		position.y / height,
		position.z / length
	)


