class_name Ending
extends Control
## After the last door: Pico celebrates, Filou sulks, then admits defeat.

signal done


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	box.offset_left = 48
	box.offset_right = -48
	box.offset_top = 120
	box.offset_bottom = -80
	box.add_theme_constant_override("separation", 30)
	add_child(box)

	var hero := HeroView.new()
	hero.mood = "win"
	hero.custom_minimum_size.y = 300
	box.add_child(hero)
	var talk := HBoxContainer.new()
	talk.add_theme_constant_override("separation", 12)
	var filou := Filou.new()
	filou.set_mood("grumpy", 99.0)
	talk.add_child(filou)
	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = SIZE_EXPAND_FILL
	bubble.size_flags_vertical = SIZE_SHRINK_CENTER
	bubble.add_theme_stylebox_override("panel", Look.box(Look.CARD, 28, true, 20))
	var narrator := Narrator.new()
	narrator.glitch_lies = false
	narrator.custom_minimum_size.y = 120
	narrator.add_theme_color_override("font_color", Look.INK)
	narrator.started.connect(filou.set_lying)
	bubble.add_child(narrator)
	talk.add_child(bubble)
	box.add_child(talk)
	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	box.add_child(spacer)
	var menu := Button.new()
	menu.text = "Menu"
	menu.custom_minimum_size.y = 110
	menu.modulate.a = 0.0
	menu.pressed.connect(done.emit)
	box.add_child(menu)

	var lines := [
		"Grrr... Tu as franchi ma dernière porte !",
		"~Bon. Je n'ai jamais menti, de toute façon.",
		"%d étoiles sur %d. %d passages secrets sur %d." % [Save.total_stars(), Levels.all().size() * 3, Save.secrets.size(), Levels.secret_count()],
		"Mes vieux niveaux cachent encore des passages secrets... Hi hi !",
		"Et mes rêves sans fin t'attendent. Reviens jouer !",
	]
	var t := create_tween()
	for line in lines:
		t.tween_callback(narrator.say.bind(line))
		t.tween_interval(3.4)
	t.tween_callback(filou.set_mood.bind("laugh", 99.0))
	t.tween_property(menu, "modulate:a", 1.0, 0.6)
	Sfx.play("secret")
