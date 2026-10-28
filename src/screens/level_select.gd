class_name LevelSelect
extends Control
## All levels, grouped by chapter, with best stars and found secrets.

signal level_chosen(index: int)
signal back_pressed


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	column.offset_left = 32
	column.offset_right = -32
	column.offset_top = 40
	column.offset_bottom = -24
	column.add_theme_constant_override("separation", 16)
	add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	var back := IconButton.new("back")
	back.pressed.connect(_on_back)
	header.add_child(back)
	var title := Label.new()
	title.text = "Niveaux"
	title.add_theme_font_size_override("font_size", 48)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	var stars := Label.new()
	stars.text = "%d étoiles" % Save.total_stars()
	stars.add_theme_color_override("font_color", Look.GOLD)
	header.add_child(stars)
	column.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)

	for chapter in Levels.chapters():
		var label := Label.new()
		label.text = chapter[0]
		label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		list.add_child(label)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		for i in chapter[1]:
			var button := LevelButton.new(i)
			button.size_flags_horizontal = SIZE_EXPAND_FILL
			button.pressed.connect(_on_level.bind(i))
			row.add_child(button)
		for i in 4 - chapter[1].size():  # keep columns aligned between chapters
			var filler := Control.new()
			filler.custom_minimum_size.x = 130
			filler.size_flags_horizontal = SIZE_EXPAND_FILL
			row.add_child(filler)
		list.add_child(row)


func _on_level(index: int) -> void:
	Sfx.play("ui")
	level_chosen.emit(index)


func _on_back() -> void:
	Sfx.play("ui")
	back_pressed.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back_pressed.emit()
