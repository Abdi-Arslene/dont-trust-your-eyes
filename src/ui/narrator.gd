class_name Narrator
extends Label
## Types lines out. Lines written with a leading "~" are lies: in the game,
## Filou's nose grows (see `started`); elsewhere the letters glitch now and then.
## Players learn the sign of a lie... until the game uses it against them.

signal started(lie: bool)

const GLITCH := {"a": "@", "e": "3", "i": "1", "o": "0", "s": "5", "t": "7", "u": "v", "r": "?"}

var _line := ""
var _glitchy := false
var _typed := 0
var _glitch_in := 0.0
var _tween: Tween
var glitch_lies := true  # false when Filou shows the lies instead


func _ready() -> void:
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mouse_filter = MOUSE_FILTER_IGNORE


func say(line: String) -> void:
	_glitchy = line.begins_with("~")
	_line = line.trim_prefix("~")
	text = _line
	modulate = Color.WHITE
	visible_ratio = 0.0
	_typed = 0
	_glitch_in = 0.5
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "visible_ratio", 1.0, 0.025 * _line.length())
	started.emit(_glitchy)


func is_typing() -> bool:
	return visible_ratio < 1.0


func _process(delta: float) -> void:
	var shown := int(visible_ratio * _line.length())
	if shown >= _typed + 3:
		_typed = shown
		Sfx.play("type", randf_range(0.9, 1.15), -8.0)
	if _glitchy and glitch_lies and visible_ratio >= 1.0:
		_glitch_in -= delta
		if _glitch_in <= 0.0:
			_glitch_in = randf_range(1.0, 2.4)
			_glitch()


func _glitch() -> void:
	var chars := _line.split("")
	if chars.is_empty():
		return
	for k in 3:
		var i := randi() % chars.size()
		chars[i] = GLITCH.get(chars[i].to_lower(), chars[i])
	text = "".join(chars)
	modulate = Color(1.0, 0.55, 0.6)
	create_tween().tween_callback(_unglitch).set_delay(0.09)


func _unglitch() -> void:
	text = _line
	modulate = Color.WHITE
