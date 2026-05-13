extends Node2D

var jkl = preload("res://scenes/jyväskylä.tscn")

@onready var menu = get_node("Menu")


func _on_start_pressed():
    var kaupunki = jkl.instantiate()
    add_child(kaupunki)
    menu.visible = false


func _ready():
    get_node("Menu/Start").pressed.connect(_on_start_pressed)

    # Multiply team info input for all teams
    var teams = get_node("Menu/Teams")
    var team = teams.get_child(0)
    for a in range(3):
        teams.add_child(team.duplicate())
