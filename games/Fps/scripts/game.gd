extends Node3D
class_name Game

@onready var players = $Players.get_children()
@onready var player_transforms = players.map(func(p): return p.transform)

func _ready():
	for player in players:
		player.init(self)
		player.death.connect(_on_player_death)
		player.got_kill.connect(_on_player_got_kill)

func _on_player_death(player: Player):
	await get_tree().create_timer(1.0).timeout
	player._respawn()

func _on_player_got_kill(player: Player):
	pass

func get_bullet_container() -> Node3D:
	return $Bullets
