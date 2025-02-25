extends Node

# player_dicts will manage players that are currently instanced and are in use.
# Keys are player controller index, values will be an array required to instance the player.
#
# format: player_dicts = {0: [0, 0]} -- Key is index. Array format: [index, instantiated_in_minigame, modulate]
# key references index.
# first value in dict references index as well, second value is whether player is instantiated in current level.
var player_array = Array([], TYPE_OBJECT, "Object", null)

func change_scene(next_scene):
	get_tree().call_deferred("change_scene_to_file", next_scene)
