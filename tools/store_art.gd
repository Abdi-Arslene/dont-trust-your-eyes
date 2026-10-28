extends SceneTree
## Renders the app icons and the Play Store feature graphic with the game's own drawing code.
## Needs a window (not --headless):
##   godot --path . --script res://tools/store_art.gd
## Writes assets/icon/*.png (launcher icons, used by the export) and docs/store/*.png.

const ICON_DIR := "res://assets/icon/"
const STORE_DIR := "res://docs/store/"
const BG := [Color("7b5cff"), Color("ff7eb6")]  # icon background: top, bottom
const HERO_TIME := 1.0  # a moment when Pico's eyes are open (he blinks every 3.7 s)
const LUMA_CUT := 0.3  # monochrome icon: darker pixels (pupils, mouth) become holes


class Art extends Control:
	var painter: Callable

	func _draw() -> void:
		painter.call(self)


func _initialize() -> void:
	_render_all.call_deferred()


func _render_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ICON_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STORE_DIR))

	var background := await _render(Vector2i(432, 432), _paint_background)
	var foreground := await _render(Vector2i(432, 432), _paint_foreground.bind(1.0))
	background.save_png(ICON_DIR + "background.png")
	foreground.save_png(ICON_DIR + "foreground.png")
	_monochrome(foreground).save_png(ICON_DIR + "monochrome.png")

	# Store icon and launcher fallback: full square, the art a bit bigger (no adaptive mask).
	var full := await _render(Vector2i(512, 512), func(ci: Control) -> void:
		_paint_background(ci)
		_paint_foreground(ci, 1.25))
	full.save_png(STORE_DIR + "icon-512.png")
	var launcher := full.duplicate()
	launcher.resize(192, 192, Image.INTERPOLATE_LANCZOS)
	launcher.save_png(ICON_DIR + "icon-192.png")

	var feature := await _render(Vector2i(1024, 500), _paint_feature, true)
	feature.convert(Image.FORMAT_RGB8)
	feature.save_png(STORE_DIR + "feature-graphic.png")
	print("store art written")
	quit()


## Draws `painter` (and any Labels it adds) into an offscreen image of `size`.
func _render(size: Vector2i, painter: Callable, with_text := false) -> Image:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var art := Art.new()
	art.size = size
	art.painter = painter
	viewport.add_child(art)
	if with_text:
		_add_title(art)
	for i in 3:
		await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	return image


func _gradient(ci: Control, top: Color, bottom: Color) -> void:
	var rect := Rect2(Vector2.ZERO, ci.size)
	ci.draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, 0), rect.end, Vector2(0, rect.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


func _paint_background(ci: Control) -> void:
	_gradient(ci, BG[0], BG[1])
	var c := ci.size / 2.0
	for k in 6:  # soft glow behind the door
		ci.draw_circle(c, ci.size.x * (0.42 - k * 0.05), Color(1, 1, 1, 0.05), true, -1.0, true)


## Pico eyeing a golden door, inside the adaptive-icon safe zone (scale 1 = 432 px canvas).
func _paint_foreground(ci: Control, scale: float) -> void:
	var u := ci.size.x / 432.0 * scale
	var c := ci.size / 2.0
	_door(ci, Rect2(c + Vector2(4, -98) * u, Vector2(104, 186) * u))
	for spark in [[Vector2(122, -92), 13.0], [Vector2(138, -40), 8.0], [Vector2(-8, -112), 9.0]]:
		_sparkle(ci, c + spark[0] * u, spark[1] * u)
	Skins.draw_hero(ci, c + Vector2(-42, 38) * u, 86.0 * u, Vector2(0.9, -0.35), Skins.get_skin("classic"), HERO_TIME)


## The golden arched door of the game, with its brown frame.
func _door(ci: Control, door: Rect2) -> void:
	var frame := door.size.x * 0.087
	for layer in [[Color("8a5a2b"), frame], [Color("ffc93c"), 0.0]]:
		var grow: float = layer[1]
		var top := door.position + Vector2(door.size.x / 2.0, door.size.x / 2.0)
		ci.draw_circle(top, door.size.x / 2.0 + grow, layer[0], true, -1.0, true)
		ci.draw_rect(Rect2(door.position + Vector2(-grow, door.size.x / 2.0), Vector2(door.size.x + grow * 2.0, door.size.y - door.size.x / 2.0 + grow)), layer[0])
	ci.draw_circle(door.position + door.size * Vector2(0.76, 0.6), door.size.x * 0.067, Color("8a5a2b"), true, -1.0, true)


func _sparkle(ci: Control, at: Vector2, r: float) -> void:
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -r), at + Vector2(r * 0.25, -r * 0.25), at + Vector2(r, 0), at + Vector2(r * 0.25, r * 0.25),
		at + Vector2(0, r), at + Vector2(-r * 0.25, r * 0.25), at + Vector2(-r, 0), at + Vector2(-r * 0.25, -r * 0.25)]), Color.WHITE)


## Themed icon (Android 13+): only the alpha counts, so dark details are cut out.
func _monochrome(image: Image) -> Image:
	var out := Image.create(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var p := image.get_pixel(x, y)
			out.set_pixel(x, y, Color(1, 1, 1, p.a if p.get_luminance() > LUMA_CUT else 0.0))
	return out


func _paint_feature(ci: Control) -> void:
	_gradient(ci, Look.SKY[0], Look.SKY[1])
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 40:
		ci.draw_circle(Vector2(rng.randf() * ci.size.x, rng.randf() * ci.size.y), rng.randf_range(2, 5), Color(1, 1, 1, rng.randf_range(0.25, 0.6)), true, -1.0, true)
	_door(ci, Rect2(150, 120, 110, 200))
	_sparkle(ci, Vector2(96, 118), 14.0)
	_sparkle(ci, Vector2(130, 150), 9.0)
	Skins.draw_hero(ci, Vector2(130, 300), 95.0, Vector2(0.8, -0.3), Skins.get_skin("classic"), HERO_TIME)


func _add_title(art: Control) -> void:
	var title := Label.new()
	title.text = "DON'T TRUST\nYOUR EYES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", Look.font(700))
	title.add_theme_font_size_override("font_size", 78)
	title.add_theme_constant_override("line_spacing", -16)
	title.add_theme_constant_override("outline_size", 24)
	title.add_theme_color_override("font_outline_color", Color("4b2fb0"))
	title.position = Vector2(270, 70)
	title.size = Vector2(500, 220)
	art.add_child(title)
	var tagline := Label.new()
	tagline.text = "Ne crois pas tes yeux !"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_override("font", Look.font(600))
	tagline.add_theme_font_size_override("font_size", 40)
	tagline.add_theme_color_override("font_color", Look.GOLD)
	tagline.add_theme_constant_override("outline_size", 12)
	tagline.add_theme_color_override("font_outline_color", Color("4b2fb0"))
	tagline.position = Vector2(270, 300)
	tagline.size = Vector2(500, 60)
	art.add_child(tagline)
	var filou := Filou.new()
	filou.position = Vector2(800, 210)
	filou.size = Vector2(200, 230)
	filou.set_lying(true)
	filou._nose = 1.0
	art.add_child(filou)
