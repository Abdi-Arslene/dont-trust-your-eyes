class_name Collection
extends Control
## The costumes: every look of the hero, its goal, and the one you wear.

signal back_pressed

var _preview := HeroView.new()
var _name := Label.new()
var _cards := []


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var stats := Save.stats()
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	column.offset_left = 32
	column.offset_right = -32
	column.offset_top = 40
	column.offset_bottom = -24
	column.add_theme_constant_override("separation", 14)
	add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	var back := IconButton.new("back")
	back.pressed.connect(_on_back)
	header.add_child(back)
	var title := Label.new()
	title.text = "Costumes"
	title.add_theme_font_size_override("font_size", 48)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	var count := Label.new()
	count.text = "%d / %d" % [Skins.ALL.filter(func(s): return Skins.is_unlocked(s, stats)).size(), Skins.ALL.size()]
	count.add_theme_color_override("font_color", Look.GOLD)
	header.add_child(count)
	column.add_child(header)

	_preview.custom_minimum_size.y = 230
	column.add_child(_preview)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.add_theme_font_size_override("font_size", 30)
	column.add_child(_name)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)
	for skin in Skins.ALL:
		var card := SkinCard.new(skin, Skins.is_unlocked(skin, stats), Skins.progress(skin, stats))
		card.size_flags_horizontal = SIZE_EXPAND_FILL
		card.pressed.connect(_on_card.bind(card))
		grid.add_child(card)
		_cards.append(card)
	_refresh()


func _on_card(card: SkinCard) -> void:
	if not card.unlocked:
		Sfx.play("bump")
		_name.text = "Pour l'avoir : %s" % card.skin.goal.to_lower()
		return
	Save.set_skin(card.skin.id)
	Sfx.play("boing", randf_range(0.95, 1.1))
	Sfx.vibrate(15)
	_refresh()


func _refresh() -> void:
	_name.text = Skins.get_skin(Save.skin).name
	for card in _cards:
		card.queue_redraw()


func _on_back() -> void:
	Sfx.play("ui")
	back_pressed.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back_pressed.emit()


## One costume.
class SkinCard:
	extends Button

	var skin: Dictionary
	var unlocked: bool
	var _progress: String
	var _time := randf() * 10.0
	var _look := Vector2.ZERO
	var _target := Vector2.ZERO

	func _init(entry: Dictionary, is_unlocked: bool, progress_text: String) -> void:
		skin = entry
		unlocked = is_unlocked
		_progress = progress_text
		custom_minimum_size = Vector2(196, 236)
		focus_mode = FOCUS_NONE
		mouse_filter = MOUSE_FILTER_PASS  # lets the scroll container scroll from a card too

	func _process(delta: float) -> void:
		_time += delta
		if randf() < delta * 0.6:
			_target = Vector2.from_angle(randf() * TAU) * randf() * 0.8
		_look = _look.lerp(_target, minf(1.0, delta * 6.0))
		if unlocked:
			queue_redraw()

	func _draw() -> void:
		var font := get_theme_default_font()
		var c := Vector2(size.x / 2.0, 82)
		if skin.id == Save.skin:
			var ring := StyleBoxFlat.new()
			ring.draw_center = false
			ring.border_color = Look.GOLD
			ring.set_border_width_all(6)
			ring.set_corner_radius_all(18)
			draw_style_box(ring, Rect2(Vector2.ZERO, size))
		if unlocked:
			Skins.draw_hero(self, c + Vector2(0, 8), 52, _look, skin, _time)
			draw_string(font, Vector2(0, 182), skin.name, HORIZONTAL_ALIGNMENT_CENTER, size.x, 27, Look.INK)
			if skin.id == Save.skin:
				draw_string(font, Vector2(0, 214), "Porté", HORIZONTAL_ALIGNMENT_CENTER, size.x, 21, Color("e08a00"))
			return
		Skins.ellipse(self, c + Vector2(0, 8), Vector2(49, 45), Color(Look.INK, 0.12))
		draw_string(font, Vector2(0, c.y + 22), "?", HORIZONTAL_ALIGNMENT_CENTER, size.x, 56, Color(Look.INK, 0.35))
		draw_multiline_string(font, Vector2(10, 170), skin.goal, HORIZONTAL_ALIGNMENT_CENTER, size.x - 20, 20, 3, Color(Look.INK, 0.6))
		if _progress != "":
			draw_string(font, Vector2(0, size.y - 12), _progress, HORIZONTAL_ALIGNMENT_CENTER, size.x, 21, Color("e08a00"))
