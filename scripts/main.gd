extends Node2D

var cities = ["Jyväskylä", "Tampere", "Helsinki", "Turku", "Oulu", "Kuopio", "Joensuu"]
var jkl = preload("res://scenes/Jyväskylä.tscn")
var tampere = preload("res://scenes/Tampere.tscn")
var team_names: Array[String] = [] # Easy access to names, mostly for debugging.

@onready var menu = get_node("Menu")
@onready var teams_info = get_node("Teams") # All info about teams lives here.


# Later will be called with a UI button.
func instansiate_menu_teams():
	var team = get_node("Menu/Teams").get_child(0)
	var new_team = team.duplicate()
	var label = new_team.get_node("Label")
	var new_label = label.text.substr(0, len(label.text) - 1) + str(get_node("Menu/Teams").get_child_count()+1)
	label.text = new_label
	get_node("Menu/Teams").add_child(new_team)


# Setup teams. Ignore empty ones.
func setup_teams():
	for team in get_node("Menu/Teams").get_children():
		var team_name = team.get_node("Name")
		var team_size = team.get_node("Size")
		if team_name.text == "" or int(team_size.text) < 1:
			continue
		team_names.append(team_name.text)
		var new_team: Node = Node.new()
		new_team.add_child(team_name.duplicate())
		new_team.add_child(team_size.duplicate())
		teams_info.add_child(new_team)
	print_debug("Setup teams:", team_names)


func add_team_to_hud(hud_list: Control, team_name: String):
	# TODO: Polish HUD to look good.
	var team = Label.new()
	team.text = team_name
	team.set_size(Vector2(200, 30))
	team.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	team.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	team.add_theme_font_size_override("font_size", 16)
	hud_list.add_child(team)


# Start first game. TODO: Choose city randomly and option to choose how many games are played.
func _on_start_pressed():
	setup_teams()
	
	var kaupunki = jkl.instantiate()
	add_child(kaupunki)
	
	var hud_teamslist = kaupunki.get_node("HUD/TeamsList")
	for team_name in team_names:
		add_team_to_hud(hud_teamslist, team_name)
	
	menu.visible = false


func _ready():
	get_node("Menu/Start").pressed.connect(_on_start_pressed)

	for i in range(3): #TODO:Change team instansiation to button
		instansiate_menu_teams()
