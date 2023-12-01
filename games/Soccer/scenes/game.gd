extends Node3D
class_name Game

@onready var players := $Players.get_children()
@onready var ball: Ball = $Ball
@onready var player_transforms: Array = players.map(func(p: Player): return p.transform)
@onready var ball_transform: Transform3D = ball.transform

@onready var resolution = get_viewport().get_visible_rect().size
@onready var center_mouse_position := Vector2(resolution.x/2, resolution.y/2)

var needs_reset := false

var mouse_modes := [Input.MOUSE_MODE_HIDDEN, Input.MOUSE_MODE_VISIBLE]
var mouse_mode := 0

var camera_index := 0

func _ready():
	Input.set_mouse_mode(mouse_modes[mouse_mode])
	for player in players:
		player.init(self)
	players[camera_index].camera.make_current()

func reset():
	needs_reset = false
	for i in range(len(players)):
		players[i].reset(player_transforms[i])
	ball.reset(ball_transform)

func _physics_process(_delta):
	if needs_reset:
		return reset()
	handle_input()

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

func can_get_mouse_input() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_HIDDEN

func get_mouse_x_movement() -> float:
	var new_mouse_position := get_viewport().get_mouse_position()
	Input.warp_mouse(center_mouse_position)
	return new_mouse_position.x - center_mouse_position.x

func _on_arena_goal_scored(_side):
	needs_reset = true
