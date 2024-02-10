extends Node3D
class_name Game

@export var player_override := false

@onready var players = $Players.get_children()
@onready var tagger_spawn = $Markers/Spawns/Tagger.transform
@onready var rest_spawns = $Markers/Spawns/Other.get_children().map(func(x): return x.transform)

@onready var width = $Markers/Width.position.length() * 2
@onready var height = $Markers/Height.position.length()
@onready var length = $Markers/Length.position.length() * 2

@onready var max_distance = Vector3(0, 0, 0).distance_to(Vector3(width, height, length))

var needs_reset := false
var tagger: Player
var taggables: Array[Player]

func _ready():
	if player_override:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	for player in players:
		player.init(self)
		player.needs_reset.connect(_on_player_needs_reset)
		player.player_override = player_override
	_spawn_players()

func _physics_process(_delta):
	_calculate_tagger_and_taggables()
	for player in players:
		_handle_extra_player_rewards(player)
	if needs_reset:
		_reset()

func _handle_extra_player_rewards(player: Player):
	if player.is_tagger:
		for taggable in taggables:
			# Distance From Taggable
			var distance = player.position.distance_to(taggable.position) / max_distance
			player.controller.give_reward("distance_from_taggable", 2*exp(-distance) - 1)
	else:
		# Distance From Tagger
		var distance = 1 - player.position.distance_to(tagger.position) / max_distance
		player.controller.give_reward("distance_from_tagger", 2*exp(-distance) - 1)
	# Timestep
	player.controller.give_reward("timestep", -1 if player.is_tagger else 1)

func _reset():
	needs_reset = false
	tagger = null
	taggables.clear()
	_reset_players()
	_spawn_players()

func _reset_players():
	for player in players:
		player.reset()

func _spawn_players():
	var shuffled_players = _get_shuffled_players()
	shuffled_players[0].spawn(tagger_spawn)
	shuffled_players[0].make_tagger()
	for i in range(1, len(shuffled_players)):
		shuffled_players[i].spawn(rest_spawns[i-1])
	
func _get_shuffled_players():
	var _players = players.duplicate()
	_players.shuffle()
	return _players

func _calculate_tagger_and_taggables():
	tagger = null
	taggables.clear()
	for player in players:
		if player.is_tagger:
			tagger = player
		else:
			taggables.append(player)

func _on_player_needs_reset():
	needs_reset = true

func get_normalized_position(_position: Vector3):
	var x = _position.x / width
	var y = _position.y / height
	var z = _position.z / length
	return Vector3(x, y, z)
