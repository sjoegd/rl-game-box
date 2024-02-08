extends Node3D
class_name Game

@export var player_override := false
@export var instant_respawn := false

@onready var spawns = $Spawns.get_children()
@onready var players = $Players.get_children()
@onready var bullet_container = $Bullets
@onready var width = $Markers/Width.position.length()*2
@onready var length = $Markers/Length.position.length()*2
@onready var height = $Markers/Height.position.length()

const mouse_modes = [Input.MOUSE_MODE_CAPTURED, Input.MOUSE_MODE_VISIBLE]
var mouse_mode_index := 0

var needs_reset := false
@onready var players_left := players.size()

func _ready():
	_update_mouse_mode()
	for player in players:
		player = player as Player
		player.init(self, bullet_container)
		player.death.connect(_on_player_death)
		player.kill.connect(_on_player_kill)
		player.needs_reset.connect(_on_player_needs_reset)
		player.player_override = player_override
	_spawn_players()

func _update_mouse_mode():
	Input.set_mouse_mode(mouse_modes[mouse_mode_index])

func _physics_process(_delta):
	# Handle Menu
	if Input.is_action_just_pressed("menu"):
		mouse_mode_index += 1
		mouse_mode_index = mouse_mode_index % mouse_modes.size()
		_update_mouse_mode()
	for player in players:
		_handle_extra_player_rewards(player)
	if needs_reset:
		_reset()

func _handle_extra_player_rewards(player: Player):
	# Aim At Enemy
	var aim_at_enemy = player.gun.is_aiming_at_enemy()
	player.controller.give_reward("aim_at_enemy", float(aim_at_enemy))
	# Aim At Ground
	var aim_at_ground = player.gun.is_aiming_at_ground()
	player.controller.give_reward("aim_at_ground", float(aim_at_ground))
	# Aim At Nothing
	var aim_at_nothing = player.gun.is_aiming_at_nothing()
	player.controller.give_reward("aim_at_nothing", float(aim_at_nothing))
	# Timestep
	player.controller.give_reward("timestep", 1)

func _spawn_players():
	var random_spawns = _get_random_spawns()
	for i in range(len(players)):
		players[i].spawn(random_spawns[i])

func _get_random_spawns():
	var random_spawns = spawns.duplicate()
	random_spawns.shuffle()
	random_spawns = random_spawns.map(func(spawn): return spawn.transform)
	return random_spawns

func _check_for_winner():
	if players_left <= 1:
		var alive_players = players.filter(func(p): return p.is_alive)
		var winner = alive_players[0] if alive_players.size() > 0 else null
		_game_over(winner)

func _game_over(winner: Player):
	if winner:
		winner.controller.give_reward("win", 1)
	for player in players:
		player.game_over()

func _reset():
	needs_reset = false
	players_left = players.size()
	for player in players:
		player.reset()
	for bullet in bullet_container.get_children():
		bullet.queue_free()
	_spawn_players()

func _on_player_death():
	players_left -= 1
	_check_for_winner()

func _on_player_kill(player: Player, killed: Player):
	player.controller.give_reward("kill", 1)
	killed.controller.give_reward("death", 1)
	if killed.is_main_player and instant_respawn:
		_game_over(null)

func _on_player_needs_reset():
	needs_reset = true

func get_normalized_position(_position: Vector3):
	var x = _position.x/width
	var y = _position.y/height
	var z = _position.z/length
	return Vector3(x, y, z)

func get_player_amount():
	return players.size()
