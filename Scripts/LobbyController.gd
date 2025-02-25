extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const PlayerVars = preload("res://Scripts/PlayerVariables.gd")
var camera
var player = preload("res://GameObjects/Player/Player.tscn")
var num_players_ready = 0
var centerpos
var size


# Called when the node enters the scene tree for the first time.
func _ready():
	centerpos = get_node("SpawnZone/SpawnArea").get_position() + get_node("SpawnZone").get_position()
	size = get_node("SpawnZone/SpawnArea").get_shape().size
	camera = get_node("ZoomCam")
	randomize()
	
func _process(_delta):
	# Spawn / Remove Player0
	if (!GameManager.player_array.filter(func(p): return p.index == 0) && Input.is_action_just_released("start0")):
		var player_vars = PlayerVars.new(0, "#a20303")
		GameManager.player_array.append(player_vars)
		SpawnPlayer(player_vars)
	elif (GameManager.player_array.filter(func(p): return p.index == 0) && Input.is_action_just_released("back0")):
		var player_vars = GameManager.player_array[GameManager.player_array.find(func(p): return p.index == 0)]
		RemovePlayer(player_vars)
	
	#Spawn / Remove Player1
	if (!GameManager.player_array.filter(func(p): return p.index == 1) && Input.is_action_just_released("start1")):
		var player_vars = PlayerVars.new(1, "#1a2ac8")
		GameManager.player_array.append(player_vars)
		SpawnPlayer(player_vars)
	elif (GameManager.player_array.filter(func(p): return p.index == 1) && Input.is_action_just_released("back1")):
		var player_vars = GameManager.player_array[GameManager.player_array.find(func(p): return p.index == 1)]
		RemovePlayer(player_vars)
		
		# Spawn / Remove Player2
	if (!GameManager.player_array.filter(func(p): return p.index == 2) && Input.is_action_just_released("start2")):
		var player_vars = PlayerVars.new(2, "#c81ac0")
		GameManager.player_array.append(player_vars)
		SpawnPlayer(player_vars)
	elif (GameManager.player_array.filter(func(p): return p.index == 2) && Input.is_action_just_released("back2")):
		var player_vars = GameManager.player_array[GameManager.player_array.find(func(p): return p.index == 2)]
		RemovePlayer(player_vars)
		
		# Spawn / Remove Player3
	if (!GameManager.player_array.filter(func(p): return p.index == 3) && Input.is_action_just_released("start3")):
		var player_vars = PlayerVars.new(3, "#1fc81a")
		GameManager.player_array.append(player_vars)
		SpawnPlayer(player_vars)
	elif (GameManager.player_array.filter(func(p): return p.index == 3) && Input.is_action_just_released("back3")):
		var player_vars = GameManager.player_array[GameManager.player_array.find(func(p): return p.index == 3)]
		RemovePlayer(player_vars)
		
	# Spawn / Remove Player4
	if (!GameManager.player_array.filter(func(p): return p.index == 4) && Input.is_action_just_released("start4")):
		var player_vars = PlayerVars.new(4, "#c88e1a")
		GameManager.player_array.append(player_vars)
		SpawnPlayer(player_vars)
	elif (GameManager.player_array.filter(func(p): return p.index == 4) && Input.is_action_just_released("back4")):
		var player_vars = GameManager.player_array[GameManager.player_array.find(func(p): return p.index == 4)]
		RemovePlayer(player_vars)

func SpawnPlayer(player_vars):
	var player_inst = player.instantiate()
	player_inst.position.x = (randi() % int(size.x)) - (size.x/2) + centerpos.x
	player_inst.position.y = (randi() % int(size.y)) - (size.y/2) + centerpos.y
	player_inst.init(player_vars.index, player_vars.color_hex)
	camera.add_target(player_inst)
	add_child(player_inst)

func RemovePlayer(player_vars):
	var p = get_node("Player" + str(player_vars.index))
	camera.remove_target(p)
	p.queue_free()
	GameManager.player_array.remove_at(GameManager.player_array.find(player_vars))

func _on_start_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		num_players_ready += 1
		print("DEBUG: num_players_ready is " + str(num_players_ready))
		if num_players_ready == GameManager.player_array.size():
			print("All players are ready.")
			GameManager.change_scene("Levels/FFADefault.tscn")
			#GameManager.load_random_level("DebugBladeLevel")

func _on_start_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		num_players_ready -= 1
		print("DEBUG: num_players_ready is " + str(num_players_ready))
