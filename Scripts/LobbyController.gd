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
	if (!GameManager.player_array.filter(func(player): return player.index == 0) && Input.is_action_just_released("start0")):
		var player_vars = PlayerVars.new(0, "#a20303")
		GameManager.player_array.append(PlayerVars.new(0, "#a20303"))
		print(GameManager.player_array)
		SpawnPlayer(player_vars)
	elif (GameManager.player_array.filter(func(player): return player.index == 0) && Input.is_action_just_released("back0")):
		var player_vars = GameManager.player_array.filter(func(player): return player.index == 0)
		RemovePlayer(player_vars)
		
		
		# TODO: FINISH SPAWN HANDLERS FOR OTHER THREE PLAYERS!!!
		# Spawn / Remove Player1
	if (!GameManager.player_array.filter(func(player): return player.index == 1) && Input.is_action_just_released("start1")):
		var player_vars = PlayerVars.new(0, "#a20303")
		GameManager.player_array.append(PlayerVars.new(0, "#a20303"))
		print(GameManager.player_array)
		SpawnPlayer(player_vars)
	elif (GameManager.player_array.filter(func(player): return player.index == 1) && Input.is_action_just_released("back1")):
		var player_vars = GameManager.player_array.filter(func(player): return player.index == 0)
		RemovePlayer(player_vars)
		
		# Spawn / Remove Player2
	if (!GameManager.player_array.filter(func(player): return player.index == 2) && Input.is_action_just_released("start2")):
		var player_vars = PlayerVars.new(0, "#a20303")
		GameManager.player_array.append(PlayerVars.new(0, "#a20303"))
		print(GameManager.player_array)
		SpawnPlayer(player_vars)
	elif (GameManager.player_array.filter(func(player): return player.index == 0) && Input.is_action_just_released("back2")):
		var player_vars = GameManager.player_array.filter(func(player): return player.index == 0)
		RemovePlayer(player_vars)
		
		# Spawn / Remove Player3
	if (!GameManager.player_array.filter(func(player): return player.index == 0) && Input.is_action_just_released("start3")):
		var player_vars = PlayerVars.new(0, "#a20303")
		GameManager.player_array.append(PlayerVars.new(0, "#a20303"))
		print(GameManager.player_array)
		SpawnPlayer(player_vars)
	elif (GameManager.player_array.filter(func(player): return player.index == 0) && Input.is_action_just_released("back3")):
		var player_vars = GameManager.player_array.filter(func(player): return player.index == 0)
		RemovePlayer(player_vars)
		
	
	#if (!GameManager.player_dicts.has(1)) && Input.is_action_just_released("start1"):
		#SpawnPlayer("#2f7b00", 1)
	#elif GameManager.player_dicts.has(1) && Input.is_action_just_released("back1"):
		#RemovePlayer(1)
	#
	#if (!GameManager.player_dicts.has(2)) && Input.is_action_just_released("start2"):
		#SpawnPlayer("#1303a2", 2)
	#elif GameManager.player_dicts.has(2) && Input.is_action_just_released("back2"):
		#RemovePlayer(2)
	#
	#if (!GameManager.player_dicts.has(3)) && Input.is_action_just_released("start3"):
		#SpawnPlayer("#ffffff", 3)
	#elif GameManager.player_dicts.has(3) && Input.is_action_just_released("back3"):
		#RemovePlayer(3)
	#
	#if (!GameManager.player_dicts.has(4)) && Input.is_action_just_released("start4"):
		#SpawnPlayer("#6C1684", 4)
	#elif GameManager.player_dicts.has(4) && Input.is_action_just_released("back4"):
		#RemovePlayer(4)

func SpawnPlayer(player_vars):
	var player_inst = player.instantiate()
	player_inst.position.x = (randi() % int(size.x)) - (size.x/2) + centerpos.x
	player_inst.position.y = (randi() % int(size.y)) - (size.y/2) + centerpos.y
	player_inst.init(player_vars.index, player_vars.color_hex)
	camera.add_target(player_inst)
	add_child(player_inst)

func RemovePlayer(player_vars):
	var p = get_parent().get_node("Player" + str(player_vars.index))
	camera.remove_target(p)
	p.queue_free()
	GameManager.player_array.remove_at(GameManager.player_array.find(player_vars))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_start_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		num_players_ready += 1
		print("DEBUG: num_players_ready is " + str(num_players_ready))
		if num_players_ready == GameManager.player_array.size():
			print("All players are ready.")
			#GameManager.load_random_level("DebugBladeLevel")

func _on_start_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		num_players_ready -= 1
		print("DEBUG: num_players_ready is " + str(num_players_ready))
