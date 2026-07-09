extends Node2D

var cities = ["Jyväskylä", "Tampere", "Helsinki", "Turku", "Oulu", "Kuopio", "Joensuu"]
var jkl = preload("res://scenes/jyväskylä.tscn")
var team_names: Array[String] = [] # Easy access to names

@onready var menu = get_node("Menu")
@onready var teams_info = get_node("Menu/Teams") # All info about teams lives here.

# Add new team. Later will be called with a UI button.
func instansiate_team():
	var team = teams_info.get_child(0)
	var new_team = team.duplicate()
	var label = new_team.get_node("Label")
	var new_label = label.text.substr(0, len(label.text) - 1) + str(teams_info.get_child_count()+1)
	label.text = new_label
	teams_info.add_child(new_team)


# Setup teams. Remove empty ones.
func setup_teams():
	for team in teams_info.get_children():
		var team_name = team.get_node("Name").text
		print(team_name)
		if team_name == "":
			teams_info.remove_child(team)
			continue
		team_names.append(team_name)
		print(teams_info)
		print(team_names)


func add_team_to_hud(hud_list: Control, team_name: String):
	var team = Label.new()
	team.text = team_name
	team.set_size(Vector2(200, 30))
	team.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	team.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	team.add_theme_font_size_override("font_size", 16)
	hud_list.add_child(team)


# Start first game
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
		instansiate_team()
