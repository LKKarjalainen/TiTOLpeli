extends Node2D

"""
Contains Jyväskylä game logic
"""

signal task_popup_closed(seconds: float)
signal new_game_requested

const TASKS_PATH := "res://assets/tasks/jyvaskyla.json"

var icon_paths = [
	"res://assets/player_icons/asteriski.png",
	"res://assets/player_icons/blanko.png",
	"res://assets/player_icons/dumppi.jpg",
	"res://assets/player_icons/infå.jpg",
	"res://assets/player_icons/linkki.svg",
	"res://assets/player_icons/luuppi.jpg",
	"res://assets/player_icons/serveri.jpg",
	"res://assets/player_icons/skripti.jpg",
	"res://assets/player_icons/tekis.png",
	"res://assets/player_icons/tukydata.jpg",
	"res://assets/player_icons/tutti.jpg",
	"res://assets/player_icons/ynnä.jpg"
	]

var turn: int = 0
var turn_player: Player = null
var turn_order: Array[Player] = []
var tasks: Array = []
var task_start_msec: int = 0
var task_timing: bool = false

@onready var players: Node2D = get_node("Players")
@onready var teams_info = get_node("../Teams") # Capture team_info from main for easy access.

func _validate_game_options(options: Dictionary):
	if not ("teams" in options and typeof(options["teams"] == TYPE_ARRAY)):
		push_error("Game options error: no teams defined or they are not defined as an array!")
		breakpoint
	for team in options["teams"]:
		if not ("name" in team and typeof(team["name"]) == TYPE_STRING):
			push_error("Game options error: team has no name or it is not defined as a string!")
			breakpoint

# In jyväskylä peli a team corresponds to one player. Architecture is setup so that other games can have an arbitrary amount of players per team.
func _setup_players():
	print_debug("Setupping players")
	for team in teams_info.get_children():
		var new_player := Player.new()
		new_player.name = team.name
		new_player.add_child(team.get_node("Size").duplicate())
		new_player.current_node = get_node("Route").get_child(0)
		new_player.global_position = new_player.current_node.global_position
		var icon := Sprite2D.new()
		icon.name = "Icon"
		icon_paths.shuffle()
		icon.texture = load(icon_paths.pop_back())
		icon.scale = Vector2(100, 100) / icon.texture.get_size()
		new_player.add_child(icon)
		print_debug("setup new player")
		players.add_child(new_player)
		turn_order.append(new_player)

func _load_tasks() -> void:
	var file := FileAccess.open(TASKS_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open %s: %s" % [TASKS_PATH, FileAccess.get_open_error()])
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("%s line %d: %s" % [TASKS_PATH, json.get_error_line(), json.get_error_message()])
		return
	if not (json.data is Dictionary and json.data.get("tasks") is Array):
		push_error("%s: expected an object with a \"tasks\" array" % TASKS_PATH)
		return
	tasks = json.data["tasks"]

func _format_hud():
	%NextTurn.pressed.connect(_next_turn)
	%PlayTurn.pressed.connect(_play_turn)
	%TaskStart.pressed.connect(_start_task_timer)
	%TaskDone.pressed.connect(_close_task_popup)
	%EndNewGame.pressed.connect(new_game_requested.emit)
	%EndQuit.pressed.connect(get_tree().quit)
	%TaskPopup.hide()
	%EndScreen.hide()
	_update_teams_hud.call_deferred() # Deferred: main.gd adds the team labels only after our _ready()

func _update_teams_hud() -> void:
	for player in players.get_children():
		var label: Label = %TeamsList.get_node(NodePath(player.name))
		label.text = "%s  %s" % [player.name, _format_time(player.task_time)]

# Formats as s.mmm, or m:ss.mmm once over a minute. ty Claude
func _format_time(seconds: float) -> String:
	seconds = snappedf(seconds, 0.001) # Round first so 59.9996 doesn't show as "60.000"
	var minutes := floori(seconds / 60)
	if minutes > 0:
		return "%d:%06.3f" % [minutes, seconds - minutes * 60]
	return "%.3f" % seconds

func _task_elapsed() -> float:
	return (Time.get_ticks_msec() - task_start_msec) / 1000.0

func _show_task_popup(task: Dictionary, player: Player) -> void:
	%TaskTeam.text = "Vuorossa: %s" % player.name
	%TaskTitle.text = task["id"]
	%TaskText.text = task["text"]
	var drinks: float = task.get("huurteiset", 0)
	drinks *= float(player.get_node("Size").text)
	%TaskDrinks.visible = drinks > 0.0
	%TaskDrinks.text = "Juo %s %s" % [String.num(drinks, 2).trim_suffix(".0"), "huurteinen" if drinks == 1 else "huurteista"]
	%TaskClock.text = _format_time(0)
	%TaskStart.visible = true
	%TaskDone.visible = false
	%TaskPopup.show()

func _start_task_timer() -> void:
	task_start_msec = Time.get_ticks_msec()
	task_timing = true
	%TaskStart.visible = false
	%TaskDone.visible = true

func _close_task_popup() -> void:
	task_timing = false
	%TaskPopup.hide()
	task_popup_closed.emit(_task_elapsed())

func _apply_effects(effects: Array, player: Player) -> void:
	for effect in effects:
		match [effect["type"], effect["target"]]: # Get creative with the implementation of the combination of effect and targets
			["extra_turn", "self"]:
				if player in turn_order:
					await _play_turn()
			_:
				push_error("Unknown task effect: %s" % effect["type"])

func _end_game() -> void:
	if %EndScreen.visible:
		return # Already ended, e.g. by a nested extra turn
	print_debug("Lopetetaan peli")
	%NextTurn.visible = false
	%PlayTurn.visible = false
	_show_end_screen()

# Ranks teams by total task time, fastest first. ty Claude
func _show_end_screen() -> void:
	var results: Array[Player] = []
	for player in players.get_children():
		if player is Player:
			results.append(player)
	results.sort_custom(func(a: Player, b: Player): return a.task_time < b.task_time)

	%EndWinner.text = "Voittaja: %s" % results[0].name
	for header in ["Sija", "Joukkue", "Tehtäväaika", "Ero"]:
		_add_result_cell(header, Color(0.6, 0.8, 1))
	var best := results[0].task_time
	for i in len(results):
		var player := results[i]
		var color := Color(1, 0.8, 0.2) if i == 0 else Color.WHITE
		_add_result_cell("%d." % (i + 1), color)
		_add_result_cell(player.name, color)
		_add_result_cell(_format_time(player.task_time), color)
		_add_result_cell("" if i == 0 else "+" + _format_time(player.task_time - best), color)
	%EndScreen.show()

func _add_result_cell(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	%EndResults.add_child(label)

func _goal(player: Player) -> void:
	print_debug("maaliin")
	turn_order.erase(player)

func _move_player(player: Player) -> void:
	var current := player.current_node
	var next_point: MapPoint = current.get_node(current.next_points[0])
	player.global_position = next_point.global_position
	player.current_node = next_point
	if next_point.next_points.is_empty():
		_goal(player)

func _play_task(player: Player) -> void:
	var task: Dictionary = tasks.pick_random()
	print_debug("pelataan tehtävä: ", task["text"])
	_show_task_popup(task, player)
	player.task_time += await task_popup_closed
	_update_teams_hud()
	await _apply_effects(task.get("effects", []), player)

func _next_turn() -> void:
	turn += 1
	turn_player = turn_order[turn % len(turn_order)]
	%VuoroNumero.text = str(turn)
	%NextTurn.visible = false
	%PlayTurn.visible = true

func _play_turn() -> void:
	%PlayTurn.visible = false
	_move_player(turn_player)
	await _play_task(turn_player)
	if turn_order.is_empty():
		_end_game()
	else:
		%NextTurn.visible = true

func start_game(options: Dictionary) -> void:
	# Check given game options
	if OS.is_debug_build():
		_validate_game_options(options)
	print_debug("Alotetaan peli")

func _ready() -> void:
	_load_tasks()
	_setup_players()
	_format_hud()

func _process(delta: float) -> void:
	if task_timing:
		%TaskClock.text = _format_time(_task_elapsed())

# Propagate mouse events to camera
func _input(event: InputEvent):
	if event is InputEventMouse or event is InputEventScreenTouch:
		$Camera._input(event)
