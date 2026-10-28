class_name HeroView
extends Control
## The hero, big: on the menu, in the collection, at the end. Its eyes follow
## your finger; poke it and it jumps for joy.

signal poked

var skin_id := ""  # "" = the costume chosen in the collection
var mood := "idle"

var _look := Vector2.ZERO
var _target := Vector2.ZERO
var _wander := 1.0
var _jump := 0.0
var _time := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(0, 220)
	mouse_filter = MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_jump = 1.0
		poked.emit()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_target = ((event.position - get_global_rect().get_center()) / 300.0).limit_length(1.0)
		_wander = 2.5


func _process(delta: float) -> void:
	_time += delta
	_wander -= delta
	if _wander <= 0.0:
		_wander = randf_range(1.2, 3.0)
		_target = Vector2.from_angle(randf() * TAU) * randf_range(0.0, 0.9)
	_look = _look.lerp(_target, minf(1.0, delta * 8.0))
	_jump = move_toward(_jump, 0.0, delta * 1.8)
	queue_redraw()


func _draw() -> void:
	var s := minf(size.y * 0.36, size.x * 0.3)
	var bob := sin(_time * 2.4) * s * 0.04
	var hop := sin(_jump * PI) * s * 0.7
	var c := size / 2.0 + Vector2(0, s * 0.1 + bob - hop)
	var skin := Skins.get_skin(skin_id if skin_id != "" else Save.skin)
	Skins.draw_hero(self, c, s, _look, skin, _time, "win" if _jump > 0.3 else mood)
