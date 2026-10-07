extends Node2D

"""
Contains Jyväskylä game logic
"""


@onready var players: Node2D = get_node("Pelaajat")
@onready var teams_info = get_node("../Teams") # Capture team_info from main for easy access.


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


# In jyväskylä peli a team corresponds to one player. Architecture is setup so that other games can have an arbitrary amount of players per team.
func setup_players():
	print_debug("Setupping players")
	for team in teams_info.get_children():
		var new_player = CharacterBody2D.new()
		new_player.add_child(team.get_node("Name").duplicate())
		new_player.add_child(team.get_node("Size").duplicate())
		players.add_child(new_player)


func start_game(options: Dictionary) -> void:
	# Check given game options
	if OS.is_debug_build():
		_validate_game_options(options)
	print_debug("Alotetaan peli")


func format_hud():
	print_debug("Kattellaa syssymmällä")


func _ready() -> void:
	format_hud()
	setup_players()
