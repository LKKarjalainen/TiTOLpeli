extends Node2D

"""
Contains main game logic
"""

# Propagate mouse events to camera
func _input(event: InputEvent):
	if event is InputEventMouse:
		$Camera._input(event)
