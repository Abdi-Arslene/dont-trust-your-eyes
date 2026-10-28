class_name TopBar
extends VBoxContainer
## Level header. Row 1: levels, title, hint eye, restart.
## Row 2: the items you can drag into the level, and the move counter.

signal menu_pressed
signal hint_pressed
signal restart_pressed

const HEIGHT := 84.0 + 10.0 + 76.0

var _title := Label.new()
var _moves := Label.new()
var _items := HBoxContainer.new()
var _hint := IconButton.new("hint")
var _pulse: Tween
var _lives := Control.new()  # dreams: one heart per life; survival: the energy gauge
var _life_count := 0
var _life_max := 0
var _energy := -1  # survival only
var _energy_full := 1
var _time := 0.0


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var menu := IconButton.new("levels")
	menu.pressed.connect(menu_pressed.emit)
	row.add_child(menu)
	_title.size_flags_horizontal = SIZE_EXPAND_FILL
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.add_theme_font_size_override("font_size", 30)
	row.add_child(_title)
	_hint.pressed.connect(hint_pressed.emit)
	row.add_child(_hint)
	var restart := IconButton.new("restart")
	restart.pressed.connect(restart_pressed.emit)
	row.add_child(restart)
	add_child(row)

	var row2 := HBoxContainer.new()
	row2.custom_minimum_size.y = ItemChip.SIZE.y
	_items.add_theme_constant_override("separation", 8)
	_items.size_flags_horizontal = SIZE_EXPAND_FILL
	row2.add_child(_items)
	_lives.custom_minimum_size = Vector2(0, ItemChip.SIZE.y)
	_lives.draw.connect(_draw_lives)
	row2.add_child(_lives)
	_moves.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_moves.add_theme_font_size_override("font_size", 26)
	_moves.modulate = Color(1, 1, 1, 0.75)
	row2.add_child(_moves)
	add_child(row2)


func set_title(text: String) -> void:
	_title.text = text


func set_ink(color: Color) -> void:
	_title.add_theme_color_override("font_color", color)
	_moves.add_theme_color_override("font_color", color)


func set_hint_visible(on: bool) -> void:
	_hint.visible = on


func set_energy(energy: int, full: int) -> void:
	_energy = energy
	_energy_full = maxi(full, 1)
	_lives.custom_minimum_size.x = 250.0
	_lives.queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _energy >= 0 and _energy <= 5:
		_lives.queue_redraw()  # blinking when nearly empty


func set_lives(lives: int, most: int) -> void:
	_life_count = lives
	_life_max = most
	_lives.custom_minimum_size.x = most * 46.0 + 16.0
	_lives.queue_redraw()


func _draw_lives() -> void:
	if _energy >= 0:
		_draw_energy()
		return
	for i in _life_max:
		var c := Vector2(22.0 + i * 46.0, _lives.size.y / 2.0)
		var color := Look.PINK if i < _life_count else Color(_moves.get_theme_color("font_color"), 0.25)
		for side in [-1, 1]:
			_lives.draw_circle(c + Vector2(side * 8.5, -5), 10.5, color, true, -1.0, true)
		_lives.draw_colored_polygon(PackedVector2Array([c + Vector2(-18.5, -2), c + Vector2(18.5, -2), c + Vector2(0, 17)]), color)


## A lightning bolt, a bar that empties, and the number left.
func _draw_energy() -> void:
	var mid := _lives.size.y / 2.0
	var k := clampf(float(_energy) / _energy_full, 0.0, 1.0)
	var color := Color("2ec27e") if k > 0.5 else (Color("ff9f1c") if k > 0.25 else Color("ef233c"))
	if _energy <= 5:
		color.a = 0.55 + 0.45 * sin(_time * 10.0)
	var bolt := PackedVector2Array([Vector2(16, mid - 20), Vector2(4, mid + 3), Vector2(13, mid + 3), Vector2(8, mid + 20), Vector2(24, mid - 4), Vector2(15, mid - 4), Vector2(20, mid - 20)])
	_lives.draw_colored_polygon(bolt, Look.GOLD)
	var bar := Rect2(34, mid - 13, 140, 26)
	_lives.draw_style_box(Look.box(Color(_moves.get_theme_color("font_color"), 0.15), 13, false, 0), bar)
	if k > 0.0:
		_lives.draw_style_box(Look.box(color, 13, false, 0), Rect2(bar.position, Vector2(maxf(bar.size.y, bar.size.x * k), bar.size.y)))
	_lives.draw_string(get_theme_default_font(), Vector2(bar.end.x + 10, mid + 11), str(_energy), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(color, 1.0) if _energy <= 5 else _moves.get_theme_color("font_color"))


func set_moves(moves: int, par: int) -> void:
	_moves.text = "%d pas · objectif %d" % [moves, par]


func set_items(items: Array) -> void:
	for chip in _items.get_children():
		chip.queue_free()
	for item in items:
		_items.add_child(ItemChip.new(item))


func highlight_item(item: String) -> void:
	for chip in _items.get_children():
		chip.highlighted = chip.item == item


func clear_highlights() -> void:
	for chip in _items.get_children():
		chip.highlighted = false


func pulse_hint(on: bool) -> void:
	if _pulse:
		_pulse.kill()
	_hint.modulate = Color.WHITE
	if on:
		_pulse = create_tween().set_loops()
		_pulse.tween_property(_hint, "modulate", Color(0.5, 0.85, 1.0), 0.45)
		_pulse.tween_property(_hint, "modulate", Color.WHITE, 0.45)
