extends StaticBody3D
class_name Arena

signal goal_scored(side: String)
signal ball_touch(player: Player)

@onready var ball := $Ball as Ball
@onready var ball_transform := ball.transform
@onready var goals := $Goals

var max_distance_ball_goal: float
var max_distance_player_ball: float

func _ready():
	calculate_max_distances()
	
func calculate_max_distances():
	var side_distance = $Markers/Side.position.length()
	var goal_distance = $Goals/Red.position.length()
	max_distance_ball_goal = Vector2.ZERO.distance_to(Vector2(side_distance/2, 2*goal_distance))
	max_distance_player_ball = Vector2.ZERO.distance_to(Vector2(side_distance, 2*goal_distance))

func reset():
	ball.reset(ball_transform)

func _on_red_goal_entered(body):
	if body is Ball:
		goal_scored.emit("red")

func _on_blue_goal_entered(body):
	if body is Ball:
		goal_scored.emit("blue")

func calculate_distance_ball_to_enemy_goal(enemy_color: String):
	var enemy_goal = get_goal(enemy_color)
	return clamp(ball.position.distance_to(enemy_goal.position) / max_distance_ball_goal, -1, 1)

func calculate_distance_player_to_ball(player_position: Vector3):
	return clamp(player_position.distance_to(ball.position) / max_distance_player_ball, -1, 1)

func get_ball_velocity():
	return ball.linear_velocity

func get_ball_speed():
	return clamp(ball.linear_velocity.length() / ball.speed_limit, 0, 1)

func get_goal(color: String):
	return goals.get_node(color.capitalize())

func _on_ball_touch(player):
	ball_touch.emit(player)
