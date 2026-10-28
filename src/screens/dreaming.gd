class_name Dreaming
extends Control
## Shown while a level is being generated: Filou builds a new trap, then `done` fires.

signal done

var check: Callable  # returns true once the level is ready
var _fired := false
var _waited := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 30)
	add_child(box)
	var filou := Filou.new()
	filou.custom_minimum_size = Vector2(0, 240)
	filou.talking = true
	filou.set_mood("laugh", 99.0)
	box.add_child(filou)
	var label := Narrator.new()
	label.custom_minimum_size.y = 80
	box.add_child(label)
	label.say("Filou prépare un nouveau piège...")


func _process(delta: float) -> void:
	_waited += delta
	if not _fired and _waited > 0.6 and check.call():  # the fade in must be over before the next screen swap
		_fired = true
		done.emit()
