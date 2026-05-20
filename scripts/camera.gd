extends Camera2D

@export_range(0.001, 10.0) var min_zoom = 0.01
@export_range(0.0, 1.0) var zoom_snap_seconds = 0.4
@export var bounds: Rect2
var _last_mouse_position = null
var _zoom_tween: Tween = null
var max_zoom = 10.0
# Indicates the real desired camera zoom. Changing it will smoothly interpolate Camrea2D's zoom.
@onready var real_zoom = zoom:
	set(value):
		if _zoom_tween:
			_zoom_tween.kill()
		_zoom_tween = create_tween() \
				.bind_node(self) \
				.set_ease(Tween.EASE_OUT) \
				.set_trans(Tween.TRANS_CUBIC)
		# Start processing node for the duration of the tween
		set_process(true)
		var stop_processing = func ():
			set_process(false)
		_zoom_tween.finished.connect(stop_processing)

		_zoom_tween.tween_property(self, "zoom", value, zoom_snap_seconds)
		real_zoom = value

const ZOOM_STEP = Vector2.ONE / 8.0


func _ready() -> void:
	# Await for parent to finish _ready()
	await get_parent().ready

	_fit_view_in_bounds()
	min_zoom = zoom.x

	set_process(false)


var multitouch_positions = {}
var last_multitouch_positions = {}


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_last_mouse_position = event.position
				else:
					_last_mouse_position = null
			MOUSE_BUTTON_WHEEL_UP:
				var next_zoom = real_zoom - ZOOM_STEP * zoom * event.factor
				if next_zoom.x >= min_zoom:
					real_zoom = next_zoom
				else:
					real_zoom = Vector2(min_zoom, min_zoom)
			MOUSE_BUTTON_WHEEL_DOWN:
				var next_zoom = real_zoom + ZOOM_STEP * zoom * event.factor
				if next_zoom.x <= max_zoom:
					real_zoom = next_zoom
				else:
					real_zoom = Vector2(max_zoom, max_zoom)

	elif event is InputEventMouseMotion and _last_mouse_position:
		var amount = (_last_mouse_position - event.position) * (Vector2.ONE / zoom)
		_move_view(amount)
		_last_mouse_position = event.position

	elif event is InputEventScreenTouch:
		print("Multitouch event, index %s" % event.index)
		if event.pressed:
			multitouch_positions[event.index] = event.position
		else:
			multitouch_positions.erase(event.index)
		
		# Zoom
		if multitouch_positions.size() >= 2:
			var finger1 = multitouch_positions.get(0)
			var finger2 = multitouch_positions.get(1)
			var last_finger1 = last_multitouch_positions.get(0)
			var last_finger2 = last_multitouch_positions.get(1)
			if not finger1 or not finger2 or not last_finger1 or not last_finger2:
				# TODO: Support more than 2 fingers at a time
				return
			var finger_distance = finger1.distance_to(finger2)
			var last_finger_distance = last_finger1.distance_to(last_finger2)

			real_zoom *= finger_distance / last_finger_distance

		# Movement
		if multitouch_positions.size() >= 1:
			if len(multitouch_positions) == len(last_multitouch_positions):
				var sum = func(a,b): return a + b
				var positions = len(multitouch_positions)
				var average_position = multitouch_positions.values().reduce(sum, Vector2.ZERO) / Vector2(positions, positions)
				var last_average_position = last_multitouch_positions.values().reduce(sum, Vector2.ZERO) / Vector2(positions, positions)
				_move_view(average_position - last_average_position)
		
		last_multitouch_positions = multitouch_positions


func _process(_delta: float) -> void:
	_move_view(Vector2.ZERO)


# Moves camera keeping the view in bounds
func _move_view(amount: Vector2) -> void:
	# Get camera bounds
	var viewport_size := get_viewport_rect().size
	var zoomed_viewport_size := viewport_size * (Vector2.ONE / zoom)
	var next_position = position + amount
	var next_view_rect := Rect2(
		next_position.x - (zoomed_viewport_size.x / 2.0),
		next_position.y - (zoomed_viewport_size.y / 2.0),
		zoomed_viewport_size.x,
		zoomed_viewport_size.y
	)
	if not bounds.encloses(next_view_rect):
		var a = bounds.position.x - next_view_rect.position.x
		if a > 0:
			next_position.x += a
		a = bounds.position.y - next_view_rect.position.y
		if a > 0:
			next_position.y += a
		a = bounds.end.x - next_view_rect.end.x
		if a < 0:
			next_position.x += a
		a = bounds.end.y - next_view_rect.end.y
		if a < 0:
			next_position.y += a

	position = next_position


# Fits view to bounds
func _fit_view_in_bounds() -> void:
	var bounds_center = bounds.position + 0.5 * bounds.size
	position = bounds_center

	var viewport_size := get_viewport_rect().size
	var ratio := viewport_size / bounds.size
	var maximum := ratio.max(Vector2(ratio.y, ratio.x))
	zoom = maximum
	real_zoom = maximum

	#var zoomed_viewport_size := viewport_size * (Vector2.ONE / zoom)
