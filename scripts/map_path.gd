extends Node2D


func set_start_and_end_point(start: Vector2, end: Vector2) -> void:
	position = start
	rotation = start.angle_to_point(end)
	var length = start.distance_to(end)
	$MeshInstance2D.position.x = length / 2.0
	$MeshInstance2D.scale = Vector2(length, 20.0)
