extends Node2D

@export var starting_point_path: NodePath
@export var ending_point_path: NodePath

@onready var starting_point = get_node_or_null(starting_point_path)
@onready var ending_point = get_node_or_null(ending_point_path)

func _ready() -> void:
	# Validate map path
	if OS.is_debug_build():
		if starting_point == null:
			push_error("Starting point not set!")
		if ending_point == null:
			push_error("Ending point not set!")
		var current_node = starting_point
		var walked = []
		while true:
			# WARNING! Does not check for diverging paths completion
			if current_node in walked:
				push_error("Cyclic path!")
			var next_node_path = current_node.next_points[0]
			walked.append(current_node)
			current_node = current_node.get_node(next_node_path)
			if current_node == ending_point:
				break

	# Build path
	_draw_path(starting_point)


var map_path = preload("res://scenes/map_path.tscn")


func _draw_path(current_node):
	if current_node == ending_point:
		return
	for next_point in current_node.next_points:
		var next_node = current_node.get_node(next_point);
		var path = map_path.instantiate()
		path.set_start_and_end_point(current_node.position, next_node.position)
		add_child(path)
		_draw_path(next_node)
