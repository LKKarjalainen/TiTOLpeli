extends Node2D

@export var starting_point: NodePath
@export var ending_point: NodePath

func _ready() -> void:
	# Validate map path
	if OS.is_debug_build():
		var starting_point_node = get_node_or_null(starting_point)
		if starting_point_node == null:
			push_error("Starting point not set!")
		var ending_point_node = get_node_or_null(ending_point)
		if ending_point_node == null:
			push_error("Ending point not set!")
		var current_node = get_node(starting_point)
		var walked = []
		while true:
			# WARNING! Does not check for diverging paths completion
			if current_node in walked:
				push_error("Cyclic path!")
			var next_node_path = current_node.next_points[0]
			walked.append(current_node)
			current_node = current_node.get_node(next_node_path)
			if current_node == ending_point_node:
				break

	# TODO: Draw path
