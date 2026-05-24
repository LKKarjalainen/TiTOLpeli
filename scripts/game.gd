extends Node2D

"""
Contains main game logic
"""

# Propagate mouse events to camera
func _input(event: InputEvent):
	if event is InputEventMouse or event is InputEventScreenTouch:
		$Camera._input(event)


func _validate_game_options(options: Dictionary):
	if not ("teams" in options and typeof(options["teams"] == TYPE_ARRAY)):
		push_error("Game options error: no teams defined or they are not defined as an array!")
		breakpoint
	for team in options["teams"]:
		if not ("name" in team and typeof(team["name"]) == TYPE_STRING):
			push_error("Game options error: team has no name or it is not defined as a string!")
			breakpoint

func start_game(options: Dictionary) -> void:
	# Check given game options
	if OS.is_debug_build():
		_validate_game_options(options)
