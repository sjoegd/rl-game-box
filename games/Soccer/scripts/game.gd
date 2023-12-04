extends Node3D
class_name Game

@export var human_overwrite_mode := false
@export var random_ball_reset := false
@export var random_player_reset := false

@onready var arena := $Arena as Arena
@onready var players := $Players.get_children()
@onready var player_transforms: Array = players.map(func(p: Player): return p.transform)
@onready var resolution = get_viewport().get_visible_rect().size
@onready var center_mouse_position := Vector2(resolution.x/2, resolution.y/2)

var needs_reset := false

var mouse_modes := [Input.MOUSE_MODE_HIDDEN, Input.MOUSE_MODE_VISIBLE]
var mouse_mode := 0
var camera_index := 0

var _goals: Array[String] = []
var _ball_touches: Dictionary = {}

func _ready():
	Input.set_mouse_mode(mouse_modes[mouse_mode])
	Input.warp_mouse(center_mouse_position)
	arena.init(self)
	for player in players:
		player.init(self)
		player.needs_reset.connect(_on_player_needs_reset)
		_ball_touches[player] = 0
	players[camera_index].camera.make_current()
	if human_overwrite_mode:
		players[camera_index].human_overwrite = true

func reset():
	needs_reset = false
	for i in range(len(players)):
		var _player_transform = player_transforms[i] as Transform3D
		if random_player_reset:
			_player_transform = create_random_player_transform(_player_transform)
		players[i].reset(_player_transform)
	arena.reset()

func _physics_process(_delta):
	handle_input()
	for player in players:
		handle_player_rewards(player, _goals, _ball_touches[player])
		_ball_touches[player] = 0
	_goals.clear()
	if needs_reset:
		return reset()

func handle_input():
	# Toggle Mouse Cursor
	if Input.is_action_just_pressed("ui_cancel"):
		Input.warp_mouse(center_mouse_position)
		mouse_mode = (mouse_mode + 1) % len(mouse_modes)
		Input.set_mouse_mode(mouse_modes[mouse_mode])
	# Next Player Camera
	if Input.is_action_just_pressed("ui_focus_next"):
		camera_index = (camera_index + 1) % len(players)
		players[camera_index].camera.make_current()

func handle_player_rewards(player: Player, goals: Array[String], ball_touches: int):
	# GOALS SCORED
	for goal in goals:
		var goal_scored = -1 if player.color == goal else 1
		player.controller.give_reward("GOAL_SCORED", goal_scored)
	# BALL TOUCH
	player.controller.give_reward("BALL_TOUCH", ball_touches)
	# DISTANCE PLAYER BALL
	var distance_player_ball = arena.calculate_distance_player_to_ball(player.global_position)
	player.controller.give_reward("DISTANCE_PLAYER_BALL", 1 - distance_player_ball)
	# DISTANCE BALL ENEMY GOAL
	var enemy_color = player.get_enemy_team()
	var distance_ball_enemy_goal = arena.calculate_distance_ball_to_enemy_goal(enemy_color)
	player.controller.give_reward("DISTANCE_BALL_ENEMY_GOAL", 1 - distance_ball_enemy_goal)
	# BALL SPEED
	var ball_speed = arena.get_ball_speed()
	player.controller.give_reward("BALL_SPEED", ball_speed)

func can_get_mouse_input() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_HIDDEN

func get_mouse_x_movement() -> float:
	var new_mouse_position := get_viewport().get_mouse_position()
	Input.warp_mouse(center_mouse_position)
	return new_mouse_position.x - center_mouse_position.x

func create_random_player_transform(old_transform: Transform3D) -> Transform3D:
	var offset = arena.get_random_offset()
	var _player_transform = Transform3D.IDENTITY
	_player_transform.origin = Vector3(0, old_transform.origin.y, 0) + offset
	_player_transform = _player_transform.rotated(Vector3(0, 1, 0), randf_range(-PI, PI))
	return _player_transform

func _on_arena_goal_scored(side):
	_goals.append(side)
	for player in players:
		player.game_over()

func _on_player_needs_reset():
	needs_reset = true

func _on_player_ball_touch(player):
	_ball_touches[player] += 1
