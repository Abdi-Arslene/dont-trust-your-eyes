class_name Look
extends RefCounted
## The colours and the font of the whole game. Kid style: bright, round, friendly.

const INK := Color("2b2d42")  # text and icons on light surfaces
const CARD := Color("ffffff")
const SHADOW := Color(0.16, 0.1, 0.36, 0.22)
const GOLD := Color("ffb703")
const PINK := Color("ff6b9d")
const SKY := [Color("8e7dff"), Color("4fc3f7")]  # menus: top, bottom
const FONT_PATH := "res://assets/fonts/Fredoka.ttf"

## One theme per act of the story; daily challenges and dreams pick one too.
## bg: background top/bottom. floor: two tones (checkerboard). wall: top face, front face.
const THEMES := [
	{"name": "maison", "bg": [Color("ffe3c2"), Color("ffb4a2")], "floor": [Color("fff6e9"), Color("ffeedd")], "wall": [Color("a78bfa"), Color("7c5fd6")], "ink": INK},
	{"name": "jardin", "bg": [Color("d9f99d"), Color("86efac")], "floor": [Color("f7fee7"), Color("ecfccb")], "wall": [Color("34c26e"), Color("15803d")], "ink": INK},
	{"name": "château", "bg": [Color("c7d2fe"), Color("93c5fd")], "floor": [Color("f8fafc"), Color("e8edf5")], "wall": [Color("9aa8bd"), Color("64748b")], "ink": INK},
	{"name": "grenier", "bg": [Color("fde68a"), Color("fdba74")], "floor": [Color("fffbeb"), Color("fef3c7")], "wall": [Color("e08a3c"), Color("b45309")], "ink": INK},
	{"name": "forêt", "bg": [Color("a7f3d0"), Color("5eead4")], "floor": [Color("f0fdfa"), Color("d5f8ee")], "wall": [Color("19907f"), Color("115e59")], "ink": INK},
	{"name": "nuit", "bg": [Color("312e81"), Color("1e1b4b")], "floor": [Color("4a479a"), Color("434090")], "wall": [Color("8b93f8"), Color("6366f1")], "ink": Color("f5f3ff")},
	{"name": "palais", "bg": [Color("fbcfe8"), Color("c4b5fd")], "floor": [Color("fdf2f8"), Color("fbe6f1")], "wall": [Color("f05aa0"), Color("be185d")], "ink": INK},
]

static var _font: Font


## Fredoka (rounded, easy to read), with the system font behind it for any missing glyph.
static func font(weight := 600) -> Font:
	if _font == null:
		var file: FontFile = load(FONT_PATH)
		file.fallbacks = [SystemFont.new()]
		_font = file
	var variation := FontVariation.new()
	variation.base_font = _font
	variation.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return variation


## A rounded box, for cards and buttons.
static func box(color: Color, radius := 28, shadow := true, margin := 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	style.anti_aliasing = true
	if shadow:
		style.shadow_color = SHADOW
		style.shadow_size = 0
		style.shadow_offset = Vector2(0, 7)
		style.expand_margin_bottom = 0
		style.border_width_bottom = 6
		style.border_color = color.darkened(0.18)
	return style


## A vertical gradient filling the screen, behind everything.
static func gradient_rect(top: Color, bottom: Color) -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, top)
	gradient.set_color(1, bottom)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect
