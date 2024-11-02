extends Node

enum ACTION {SIT, STAND}
signal state_changed(me)

var seated = false
@onready var current_player = null

func sit(player):
	current_player = player
	if seated:
		return false
	seated = true
	return true
	
func stand(player):
	current_player = null
	if not seated:
		return false
	seated = false
	return true
	

func get_possible_actions(player):
	if seated and player == current_player:
		return [ACTION.STAND]
	elif seated and not player == current_player:
		return []
	return [ACTION.SIT]
	
func get_player_action(action: ACTION) -> StringName:
	match action:
		ACTION.SIT: return "sit"
		ACTION.STAND: return "stand"
	return ""


func act(action: ACTION, player):
	var res = true
	match action:
		ACTION.SIT: 
			res =  sit(player)
		ACTION.STAND: 
			res = stand(player)
		
	state_changed.emit(self)
	return res
