extends Camera2D

@export_range(0.001, 10.0) var min_zoom = 0.1
@export_range(0.001, 10.0) var max_zoom = 5.0
@export_range(0.0, 1.0) var zoom_snap_seconds = 0.4

var last_mouse_position = null
var zoom_tween: Tween = null
@onready var real_zoom = zoom:
	set(value):
		if zoom_tween:
			zoom_tween.kill()
		zoom_tween = create_tween() \
				.bind_node(self) \
				.set_ease(Tween.EASE_OUT) \
				.set_trans(Tween.TRANS_CUBIC)
		zoom_tween.tween_property(self, "zoom", value, zoom_snap_seconds)
		real_zoom = value

const ZOOM_STEP = Vector2.ONE / 8.0


func _ready() -> void:
	# Validate exported values
	if OS.is_debug_build():
		if min_zoom > max_zoom:
			push_error("Min camera zoom (%s) is greater than max zoom (%s)!" % [min_zoom, max_zoom])
		if zoom.x > max_zoom:
			push_error("Initial camera zoom (%s) is greater than max zoom (%s)!" % [zoom, max_zoom])
		elif zoom.x < min_zoom:
			push_error("Initial camera zoom (%s) is smaller than min zoom (%s)!" % [zoom, min_zoom])


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					last_mouse_position = event.position
				else:
					last_mouse_position = null
			MOUSE_BUTTON_WHEEL_UP:
				var next_zoom = real_zoom - ZOOM_STEP * zoom * event.factor
				if next_zoom.x >= min_zoom:
					real_zoom = next_zoom
			MOUSE_BUTTON_WHEEL_DOWN:
				var next_zoom = real_zoom + ZOOM_STEP * zoom * event.factor
				if next_zoom.x <= max_zoom:
					real_zoom = next_zoom

	elif event is InputEventMouseMotion and last_mouse_position:
		position += (last_mouse_position - event.position) * (Vector2.ONE / zoom)
		last_mouse_position = event.position
