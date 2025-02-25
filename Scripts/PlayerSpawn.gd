extends Marker2D

var player = preload("res://GameObjects/Player/Player.tscn")
@onready var camera = get_parent().get_parent().get_node("ZoomCam")
#onready var minigame_manager = get_parent().get_parent().get_node("MinigameManager")
var player_inst
@export var player_index:int = -1

# Called when the node enters the scene tree for the first time. 
# Spawns the player whose index the spawner is assigned.
#func _ready():
	#pass

func revive_player():
	pass

#func _process(delta):
	#pass
	#if (minigame_manager.players_stopped or minigame_manager.game_over) and player_assigned != null:
		#$PointLabel.text = "P" + str(player_assigned.index + 1) + " Round Points: " + str(minigame_manager.players_score_dict[player_assigned.index]) + " \nMinigame Wins: " + str(GameManager.player_dicts[player_assigned.index][3])
	#else:
		#$PointLabel.text = ""

func _on_level_parent_ready() -> void:
	var matching_arr = GameManager.player_array.filter(func(p): return p.index == player_index)
	
	# don't load if player didn't join the game (thus no player vars exist for assigned index)
	# the length of this is always going to be 1, .find just doesn't work here for whatever stupid reason
	if matching_arr.size() == 0:
		return
	
	var player_vars = matching_arr[0]
	
	player_inst = player.instantiate()
	player_inst.init(player_vars.index, player_vars.color_hex)
	player_inst.position.x = self.position.x
	player_inst.position.y = self.position.y
	
	camera.add_target(player_inst)
	get_parent().get_parent().add_child(player_inst)
