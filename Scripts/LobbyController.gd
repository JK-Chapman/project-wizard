extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
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
	
	if (!GameManager.player_dicts.has(0)) && Input.is_action_just_released("start0"):
		var player_inst = player.instantiate()
		GameManager.player_dicts[0] = ["#a20303"]
		player_inst.init(0)
		player_inst.position.x = (randi() % int(size.x)) - (size.x/2) + centerpos.x
		player_inst.position.y = (randi() % int(size.y)) - (size.y/2) + centerpos.y
		camera.add_target(player_inst)
		get_parent().add_child(player_inst)
	elif GameManager.player_dicts.has(0) && Input.is_action_just_released("back0"):
		var p = get_parent().get_node("Player0")
		camera.remove_target(p)
		p.queue_free()
		GameManager.player_dicts.erase(0)
	
	if (!GameManager.player_dicts.has(1)) && Input.is_action_just_released("start1"):
		var player_inst = player.instantiate()
		GameManager.player_dicts[1] = ["#2f7b00"]
		player_inst.init(1)
		player_inst.position.x = (randi() % int(size.x)) - (size.x/2) + centerpos.x
		player_inst.position.y = (randi() % int(size.y)) - (size.y/2) + centerpos.y
		camera.add_target(player_inst)
		get_parent().add_child(player_inst)
	elif GameManager.player_dicts.has(1) && Input.is_action_just_released("back1"):
		var p = get_parent().get_node("Player1")
		camera.remove_target(p)
		p.queue_free()
		GameManager.player_dicts.erase(1)
		
	if (!GameManager.player_dicts.has(2)) && Input.is_action_just_released("start2"):
		var player_inst = player.instantiate()
		GameManager.player_dicts[2] = ["#1303a2"]
		player_inst.init(2)
		player_inst.position.x = (randi() % int(size.x)) - (size.x/2) + centerpos.x
		player_inst.position.y = (randi() % int(size.y)) - (size.y/2) + centerpos.y
		camera.add_target(player_inst)
		get_parent().add_child(player_inst)
	elif GameManager.player_dicts.has(2) && Input.is_action_just_released("back2"):
		var p = get_parent().get_node("Player2")
		camera.remove_target(p)
		p.queue_free()
		GameManager.player_dicts.erase(2)
		
	if (!GameManager.player_dicts.has(3)) && Input.is_action_just_released("start3"):
		var player_inst = player.instantiate()
		GameManager.player_dicts[3] = ["#ffffff"]
		player_inst.position.x = (randi() % int(size.x)) - (size.x/2) + centerpos.x
		player_inst.position.y = (randi() % int(size.y)) - (size.y/2) + centerpos.y
		player_inst.init(3)
		camera.add_target(player_inst)
		get_parent().add_child(player_inst)
	elif GameManager.player_dicts.has(3) && Input.is_action_just_released("back3"):
		var p = get_parent().get_node("Player3")
		camera.remove_target(p)
		p.queue_free()
		GameManager.player_dicts.erase(3)
		
	if (!GameManager.player_dicts.has(4)) && Input.is_action_just_released("start4"):
		var player_inst = player.instantiate()
		GameManager.player_dicts[4] = ["#6C1684"]
		player_inst.position.x = (randi() % int(size.x)) - (size.x/2) + centerpos.x
		player_inst.position.y = (randi() % int(size.y)) - (size.y/2) + centerpos.y
		player_inst.init(4)
		camera.add_target(player_inst)
		get_parent().add_child(player_inst)
	elif GameManager.player_dicts.has(4) && Input.is_action_just_released("back4"):
		var p = get_parent().get_node("Player4")
		camera.remove_target(p)
		p.queue_free()
		GameManager.player_dicts.erase(3)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_StartZone_body_entered(body):
	if body.is_in_group("Player"):
		num_players_ready += 1
		print("DEBUG: num_players_ready is " + str(num_players_ready))
		if num_players_ready == GameManager.player_dicts.keys().size():
			GameManager.load_random_level("DebugBladeLevel")


func _on_StartZone_body_exited(body):
	if body.is_in_group("Player"):
		num_players_ready -= 1
		print("DEBUG: num_players_ready is " + str(num_players_ready))
