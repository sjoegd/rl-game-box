class_name HumanPlayer
extends Player

func _process(_delta):
	input_left = Input.is_action_pressed("left")
	input_right = Input.is_action_pressed("right")
	input_up = Input.is_action_pressed("up")
	input_down = Input.is_action_pressed("down")
	input_kick = Input.is_action_pressed("kick")
	super._process(_delta)
