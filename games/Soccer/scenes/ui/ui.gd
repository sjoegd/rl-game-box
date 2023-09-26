class_name UI
extends CanvasLayer

var do_countdown: bool = false
var countdown_timer: Timer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta):
	handle_countdown()

func set_score(left: int, right: int):
	$Scores/MarginContainer/Label.text = str(left) + " - " + str(right)

func start_countdown(timer: Timer):
	countdown_timer = timer
	do_countdown = true

func handle_countdown():
	if do_countdown:
		var time = countdown_timer.time_left
		set_countdown_time(time)

func set_countdown_time(time: float):
	var text = ""
	if time <= 0:
		do_countdown = false
	elif time <= 1:
		text = "GO!!!"
	else:
		text = str(int(time))
	$Countdown/Label.text = text
