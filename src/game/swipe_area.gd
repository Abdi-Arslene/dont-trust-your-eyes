class_name SwipeArea
extends Control
## Full-screen touch surface: turns swipes into directions and accepts
## items dragged out of the top bar. Uses mouse events, which Godot
## emulates from touch, so it works the same on phone and desktop.

signal swiped(dir: Vector2i)
signal item_dropped(item: String, global_point: Vector2)

const MIN_SWIPE := 40.0
const HOLD_DELAY := 0.35  # keep the finger down after a swipe: Pico keeps walking
const HOLD_REPEAT := 0.18

var can_drop: Callable  # (item: String, global_point: Vector2) -> bool

var _start := Vector2.ZERO
var _tracking := false
var _held := Vector2i.ZERO  # direction of the last swipe while the finger stays down
var _hold_timer := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_tracking = event.pressed
		_start = event.position
		_held = Vector2i.ZERO
	elif event is InputEventMouseMotion and _tracking:
		var d: Vector2 = event.position - _start
		if d.length() >= MIN_SWIPE:
			_tracking = false  # one step per swipe: puzzles need precision
			_held = Vector2i(signi(d.x), 0) if absf(d.x) > absf(d.y) else Vector2i(0, signi(d.y))
			_hold_timer = HOLD_DELAY
			swiped.emit(_held)


func stop_hold() -> void:
	_held = Vector2i.ZERO


func _process(delta: float) -> void:
	if _held == Vector2i.ZERO:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_held = Vector2i.ZERO
		return
	_hold_timer -= delta
	if _hold_timer <= 0.0:
		_hold_timer = HOLD_REPEAT
		swiped.emit(_held)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("item") and can_drop.call(data.item, get_global_transform() * at_position)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	item_dropped.emit(data.item, get_global_transform() * at_position)
