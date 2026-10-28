class_name SettingsPanel
extends Control
## Settings over the menu: sound, music, vibrations. Tap outside to close.

const C_ON := Color("2ec27e")
const SETTINGS := [["sound", "Son"], ["music", "Musique"], ["haptics", "Vibrations"]]


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.05, 0.25, 0.45)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 560
	panel.add_theme_stylebox_override("panel", Look.box(Look.CARD, 36, true, 36))
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Réglages"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("8e6bff"))
	box.add_child(title)
	for setting in SETTINGS:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = setting[1]
		label.size_flags_horizontal = SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", Look.INK)
		row.add_child(label)
		var toggle := Switch.new()
		toggle.button_pressed = Save.get(setting[0])
		toggle.toggled.connect(_on_toggled.bind(setting[0]))
		row.add_child(toggle)
		box.add_child(row)
	var credits := Label.new()
	credits.text = "Don't Trust Your Eyes · tout est dessiné et joué en code."
	credits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	credits.add_theme_font_size_override("font_size", 20)
	credits.add_theme_color_override("font_color", Color(Look.INK, 0.5))
	box.add_child(credits)
	var close := Button.new()
	close.text = "Fermer"
	close.pressed.connect(_close)
	close.add_theme_stylebox_override("normal", Look.box(Look.GOLD, 26))
	box.add_child(close)

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)


func _on_toggled(on: bool, setting: String) -> void:
	Save.set_setting(setting, on)
	if setting == "music":
		Sfx.update_music()
	Sfx.play("ui")
	if setting == "haptics" and on:
		Sfx.vibrate(40)


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close()


func _close() -> void:
	Sfx.play("ui")
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.12)
	t.tween_callback(queue_free)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_close()


## An on/off pill.
class Switch:
	extends Button

	var _knob := 0.0

	func _init() -> void:
		toggle_mode = true
		focus_mode = FOCUS_NONE
		custom_minimum_size = Vector2(104, 60)
		flat = true

	func _ready() -> void:
		_knob = 1.0 if button_pressed else 0.0

	func _process(delta: float) -> void:
		var goal := 1.0 if button_pressed else 0.0
		if _knob != goal:
			_knob = move_toward(_knob, goal, delta * 8.0)
			queue_redraw()

	func _draw() -> void:
		var r := size.y / 2.0
		var track := StyleBoxFlat.new()
		track.bg_color = Color(Look.INK, 0.15).lerp(SettingsPanel.C_ON, _knob)
		track.set_corner_radius_all(int(r))
		draw_style_box(track, Rect2(Vector2.ZERO, size))
		draw_circle(Vector2(lerpf(r, size.x - r, _knob), r), r - 7.0, Color("f5f5f5"), true, -1.0, true)
