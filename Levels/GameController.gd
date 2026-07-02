extends Node2D

const _ScoreboardScript = preload("res://UI/Scoreboard.gd")

var points_to_win = 3
var game_over = false
var processing_win = false
var _scoreboard: CanvasLayer

func _ready() -> void:
	_scoreboard = _ScoreboardScript.new()
	add_child(_scoreboard)
	_scoreboard.show_scoreboard("GAME STARTS IN...", points_to_win)

func _process(_delta: float) -> void:
	if not $StartTimer.is_stopped():
		_scoreboard.update_title("GAME STARTS IN " + str(int($StartTimer.time_left)))
	CheckForVictory()

func _on_start_timer_timeout() -> void:
	_scoreboard.hide()
	$GameMusic.play()
	get_tree().call_group("player", "set_player_state", Player.PlayerState.NORMAL)

func CheckForVictory() -> void:
	var alive_players = GameManager.player_array.filter(func(p): return p.player_dead == false)
	if alive_players.size() == 1 and not processing_win:
		processing_win = true
		alive_players[0].points += 1
		if alive_players[0].points == points_to_win:
			game_over = true
			_scoreboard.show_scoreboard("PLAYER " + str(alive_players[0].index + 1) + " WINS!", points_to_win)
			$GameEndTimer.start()
		else:
			_scoreboard.show_scoreboard("PLAYER " + str(alive_players[0].index + 1) + " SCORES!", points_to_win)
			$RoundEndTimer.start()

func GetPlayerVars(index):
	var matching_arr = GameManager.player_array.filter(func(p): return p.index == index)
	if matching_arr.size() > 0:
		return matching_arr[0].points
	else:
		return 0

func ResetGame():
	GameManager.SetPlayersIsDead(false)
	processing_win = false
	get_tree().reload_current_scene()

func _on_round_end_timer_timeout() -> void:
	$GameMusic.stop()
	ResetGame()

func _on_game_end_timer_timeout() -> void:
	GameManager.SetPlayersIsDead(false)
	GameManager.ResetPlayerPoints()
	GameManager.change_scene("Levels/base_scene.tscn")
