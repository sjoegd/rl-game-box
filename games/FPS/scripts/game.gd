extends Node3D

@onready var players = $Players.get_children()
@onready var bullet_container = $Bullets

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	for player in players:
		player.init(bullet_container)
