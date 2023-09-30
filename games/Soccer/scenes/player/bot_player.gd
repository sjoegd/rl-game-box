class_name BotPlayer
extends Player

signal need_reset
signal touched_ball

@onready var controller = $AIController
@export var is_left_team: bool = true

func _process(_delta):
	if controller.needs_reset:
		need_reset.emit()
	input_left = controller.go_left
	input_right = controller.go_right
	input_up = controller.go_up
	input_down = controller.go_down
	input_kick = controller.go_kick
	super._process(_delta)

func _physics_process(_delta):
	super._physics_process(_delta)
	handle_ball_touch_reward()

func handle_ball_touch_reward():
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is Ball:
			touched_ball.emit()

func reset():
	super.reset()
	controller.reset()
