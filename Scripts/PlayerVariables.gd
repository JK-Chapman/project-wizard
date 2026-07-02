class_name PlayerVars extends Object

var index:int
var color_hex
var instanced = false
var player_dead = false
var points = 0

func _init(_index, _color_hex):
	self.index = _index
	self.color_hex = _color_hex
