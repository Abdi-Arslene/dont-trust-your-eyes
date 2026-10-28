class_name Menu
extends Control
## Title screen: Pico, Filou telling fibs, the four ways to play
## (story, daily challenge, endless dreams, survival), levels, costumes, settings.

signal play_pressed
signal daily_pressed
signal dreams_pressed
signal survival_pressed
signal levels_pressed
signal collection_pressed

const LINES := [
	"~Ce jeu est super facile !",
	"Touche Pico, il adore ça !",
	"~Je ne mens jamais.",
	"Quand je mens, mon nez grandit. Hi hi !",
	"~Toutes mes portes sont des vraies.",
	"Bienvenue dans ma maison des farces !",
]
const TITLE := "DON'T TRUST\nYOUR EYES"
const TITLE_GLITCH := {"O": "0", "E": "3", "T": "7", "S": "5", "Y": "V", "R": "P"}
const MODES_AFTER := 6  # finishing the first 6 levels (act II) opens the daily challenge and the dreams
const C_DAILY := Color("ff8a3d")
const C_DREAM := Color("8e6bff")
const C_SURVIVAL := Color("2ec27e")

var _title := Label.new()
var _filou := Filou.new()
var _speech := Narrator.new()
var _line := 0
var _glitch_in := 2.0


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var levels := Levels.all()
	var done := levels.filter(func(l): return Save.is_done(l.id)).size()
	var modes_open := Save.is_done(levels[MODES_AFTER - 1].id)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	box.offset_left = 36
	box.offset_right = -36
	box.offset_top = 50
	box.offset_bottom = -44
	box.add_theme_constant_override("separation", 12)
	add_child(box)

	_title.text = TITLE
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_override("font", Look.font(700))
	_title.add_theme_font_size_override("font_size", 70)
	_title.add_theme_constant_override("line_spacing", -14)
	_title.add_theme_constant_override("outline_size", 22)
	_title.add_theme_color_override("font_outline_color", Color("4b2fb0"))
	box.add_child(_title)
	var tagline := Label.new()
	tagline.text = "Ne crois pas tes yeux !"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 32)
	tagline.add_theme_color_override("font_color", Look.GOLD)
	tagline.add_theme_constant_override("outline_size", 10)
	tagline.add_theme_color_override("font_outline_color", Color("4b2fb0"))
	box.add_child(tagline)

	var hero := HeroView.new()
	hero.size_flags_vertical = SIZE_EXPAND_FILL
	hero.custom_minimum_size.y = 150
	hero.poked.connect(_on_hero_poked)
	box.add_child(hero)

	var talk := HBoxContainer.new()
	talk.add_theme_constant_override("separation", 12)
	_filou.custom_minimum_size = Vector2(110, 120)
	talk.add_child(_filou)
	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = SIZE_EXPAND_FILL
	bubble.size_flags_vertical = SIZE_SHRINK_CENTER
	bubble.add_theme_stylebox_override("panel", Look.box(Look.CARD, 26, true, 16))
	_speech.glitch_lies = false
	_speech.custom_minimum_size.y = 40
	_speech.add_theme_font_size_override("font_size", 26)
	_speech.add_theme_color_override("font_color", Look.INK)
	_speech.started.connect(_filou.set_lying)
	bubble.add_child(_speech)
	talk.add_child(bubble)
	box.add_child(talk)
	_speech.say("Hi hi ! Je suis Filou. Ma maison est pleine de farces !" if done == 0 else "~Tu ne trouveras jamais la sortie !")

	var stats := Label.new()
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 26)
	var parts := ["%d / %d étoiles" % [Save.total_stars(), levels.size() * 3]]
	if Save.walls_revealed:
		parts.append("%d / %d secrets" % [Save.secrets.size(), Levels.secret_count()])
	if Save.current_streak() > 0:
		parts.append("série %d" % Save.current_streak())
	stats.text = "   ·   ".join(parts)
	box.add_child(stats)

	var story := ModeCard.new("door", Look.GOLD)
	var next: int = Save.first_unfinished()
	if done == levels.size():
		story.title = "Histoire"
		story.subtitle = "Finie ! Rejoue pour les étoiles"
	else:
		story.title = "Continuer" if done > 0 else "Jouer"
		story.subtitle = "%d. %s" % [next + 1, levels[next].title]
	story.badge = "%d / %d" % [done, levels.size()]
	story.progress = float(done) / levels.size()
	story.pressed.connect(_click.bind(play_pressed))
	box.add_child(story)

	var daily := ModeCard.new("daily", C_DAILY)
	daily.title = "Défi du jour"
	daily.locked = not modes_open
	if daily.locked:
		daily.subtitle = "Finis le niveau 6 pour l'ouvrir"
	elif Save.daily_done():
		daily.subtitle = "Réussi ! Reviens demain"
	else:
		daily.subtitle = "Un nouveau niveau chaque jour"
	if Save.current_streak() > 0:
		daily.badge = "série %d" % Save.current_streak()
	daily.pressed.connect(_on_mode.bind(daily, daily_pressed))
	box.add_child(daily)

	var dreams := ModeCard.new("dream", C_DREAM)
	dreams.title = "Rêves sans fin"
	dreams.locked = not modes_open
	dreams.subtitle = "Finis le niveau 6 pour l'ouvrir" if dreams.locked else "Des niveaux à l'infini, 3 cœurs"
	if Save.best_dreams > 0:
		dreams.badge = "record %d" % Save.best_dreams
	dreams.pressed.connect(_on_mode.bind(dreams, dreams_pressed))
	box.add_child(dreams)

	var survival := ModeCard.new("bolt", C_SURVIVAL)
	survival.title = "Survie"
	survival.locked = not modes_open
	survival.subtitle = "Finis le niveau 6 pour l'ouvrir" if survival.locked else "Chaque pas use ton énergie !"
	if Save.best_survival > 0:
		survival.badge = "record %d" % Save.best_survival
	survival.pressed.connect(_on_mode.bind(survival, survival_pressed))
	box.add_child(survival)
	for card in [story, daily, dreams, survival]:
		card.custom_minimum_size.y = 112

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	for entry in [["Niveaux", levels_pressed], ["Costumes", collection_pressed]]:
		var button := Button.new()
		button.text = entry[0]
		button.custom_minimum_size.y = 88
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 30)
		button.pressed.connect(_click.bind(entry[1]))
		row.add_child(button)
	var settings := IconButton.new("gear")
	settings.custom_minimum_size = Vector2(88, 88)
	settings.pressed.connect(_on_settings)
	row.add_child(settings)
	box.add_child(row)


func _process(delta: float) -> void:
	_filou.talking = _speech.is_typing()
	_glitch_in -= delta
	if _glitch_in <= 0.0:
		_glitch_in = randf_range(2.5, 6.0)
		var chars := TITLE.split("")
		for k in 2:
			var i := randi() % chars.size()
			chars[i] = TITLE_GLITCH.get(chars[i], chars[i])
		_title.text = "".join(chars)
		create_tween().tween_callback(func(): _title.text = TITLE).set_delay(0.12)


func _on_hero_poked() -> void:
	Sfx.play("boing", randf_range(0.9, 1.2))
	Sfx.vibrate(20)
	_speech.say(LINES[_line % LINES.size()])
	_line += 1


func _click(target: Signal) -> void:
	Sfx.play("ui")
	target.emit()


func _on_mode(card: ModeCard, target: Signal) -> void:
	if card.locked:
		Sfx.play("giggle")
		Sfx.vibrate(12)
		_filou.set_mood("laugh")
		_speech.say("Hi hi ! C'est fermé. Finis d'abord le niveau 6 !")
		return
	_click(target)


func _on_settings() -> void:
	Sfx.play("ui")
	add_child(SettingsPanel.new())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:  # Android back button quits from the menu
		if get_children().any(func(c): return c is SettingsPanel):
			return  # the panel closes itself
		get_tree().quit()
