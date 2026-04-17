extends Node2D

var points_to_win = 3
var game_over = false
var processing_win = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$ZoomCam/TimerLabel.text = "Game Will Start In: " + str(int($StartTimer.time_left))
	$ZoomCam/PlayerPoints1.text = "P1: " + str(GetPlayerVars(0))
	$ZoomCam/PlayerPoints2.text = "P2: " + str(GetPlayerVars(1))
	$ZoomCam/PlayerPoints3.text = "P3: " + str(GetPlayerVars(2))
	$ZoomCam/PlayerPoints4.text = "P4: " + str(GetPlayerVars(3))
	$ZoomCam/PlayerPoints5.text = "P5: " + str(GetPlayerVars(4))
	CheckForVictory()


func _on_start_timer_timeout() -> void:
	$ZoomCam/TimerLabel.hide()
	$ZoomCam/PlayerPoints1.hide()
	$ZoomCam/PlayerPoints2.hide()
	$ZoomCam/PlayerPoints3.hide()
	$ZoomCam/PlayerPoints4.hide()
	$ZoomCam/PlayerPoints5.hide()
	$GameMusic.play()
	get_tree().call_group("player", "set_player_state", Player.PlayerState.NORMAL)

func CheckForVictory():
	var alive_players = GameManager.player_array.filter(func(p): return p.player_dead == false)
	
	if (alive_players.size() == 1 && processing_win == false):
		processing_win = true
		alive_players[0].points += 1
		
		if (alive_players[0].points == points_to_win):
			game_over = true
			$ZoomCam/VictoryLabel.show()
			$ZoomCam/VictoryLabel.text = "PLAYER " + str(alive_players[0].index + 1) + " HAS WON THE GAME, WHAT A GAMER"
			$GameEndTimer.start()
		else:
			$ZoomCam/ScoredLabel.show()
			$ZoomCam/ScoredLabel.text = "PLAYER " + str(alive_players[0].index + 1) + " HAS SCORED A POINT"
			$RoundEndTimer.start()

func GetPlayerVars(index):
	var matching_arr = GameManager.player_array.filter(func(p): return p.index == index)
	if (matching_arr.size() > 0):
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
