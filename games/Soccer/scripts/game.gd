extends Node3D
class_name Game

@onready var field := $Field
@onready var ball := $Ball
@onready var red_team := $"Players/Left(RED)".get_children()
@onready var blue_team := $"Players/Right(BLUE)".get_children()

func _reset():
	ball.reset()
	for team in [red_team, blue_team]:
		for player in team:
			player.reset()

func _on_goal_scored(side: String):
	var team_color = _side_to_team_color(side)
	print(team_color)
	_reset()
	
func _side_to_team_color(side: String):
	return "red" if side == "left" else "blue"

func _get_enemy_team_color(team_color: String):
	return "blue" if team_color == "red" else "red"

func _team_color_to_team(team_color: String):
	if team_color == "red":
		return red_team
	if team_color == "blue":
		return blue_team

func _get_team_and_enemy(team_color: String):
	var enemy_team_color = _get_enemy_team_color(team_color)
	return [
		_team_color_to_team(team_color), 
		_team_color_to_team(enemy_team_color)
	]
