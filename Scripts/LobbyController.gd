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
		SpawnPlayer("#a20303", 0)
	elif GameManager.player_dicts.has(0) && Input.is_action_just_released("back0"):
		RemovePlayer(0)
	
	if (!GameManager.player_dicts.has(1)) && Input.is_action_just_released("start1"):
		SpawnPlayer("#2f7b00", 1)
	elif GameManager.player_dicts.has(1) && Input.is_action_just_released("back1"):
		RemovePlayer(1)
	
	if (!GameManager.player_dicts.has(2)) && Input.is_action_just_released("start2"):
		SpawnPlayer("#1303a2", 2)
	elif GameManager.player_dicts.has(2) && Input.is_action_just_released("back2"):
		RemovePlayer(2)
	
	if (!GameManager.player_dicts.has(3)) && Input.is_action_just_released("start3"):
		SpawnPlayer("#ffffff", 3)
	elif GameManager.player_dicts.has(3) && Input.is_action_just_released("back3"):
		RemovePlayer(3)
	
	if (!GameManager.player_dicts.has(4)) && Input.is_action_just_released("start4"):
		SpawnPlayer("#6C1684", 4)
	elif GameManager.player_dicts.has(4) && Input.is_action_just_released("back4"):
		RemovePlayer(4)

func SpawnPlayer(color, index):
	var player_inst = player.instantiate()
	GameManager.player_dicts[index] = [color, "Player" + str(index)]
	player_inst.position.x = (randi() % int(size.x)) - (size.x/2) + centerpos.x
	player_inst.position.y = (randi() % int(size.y)) - (size.y/2) + centerpos.y
	player_inst.init(index)
	camera.add_target(player_inst)
	add_child(player_inst)

func RemovePlayer(index):
	var p = get_parent().get_node("Player" + str(index))
	camera.remove_target(p)
	p.queue_free()
	GameManager.player_dicts.erase(index)


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
