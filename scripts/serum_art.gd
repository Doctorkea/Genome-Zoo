extends RefCounted
class_name SerumArt

## One flask drawing, with the liquid recolored per serum.
## Cute peach, majestic gold, weird teal, scary crimson — paper-zoo inks.

const FLASK := preload("res://art/ui/serum/flask.png")

const LIQUID: Dictionary = {
	"cute": Color(0.93, 0.55, 0.48, 1),
	"majestic": Color(0.82, 0.64, 0.18, 1),
	"weird": Color(0.22, 0.55, 0.52, 1),
	"scary": Color(0.70, 0.22, 0.18, 1),
	"bulky": Color(0.55, 0.36, 0.18, 1),
	"gross": Color(0.45, 0.62, 0.18, 1),
	"apex": Color(0.42, 0.08, 0.10, 1),
	"chimera": Color(0.48, 0.28, 0.62, 1),
	"linger": Color(0.38, 0.30, 0.52, 1),
	"poster": Color(0.78, 0.38, 0.55, 1),
}

static var _cache: Dictionary = {}


static func texture(vial_id: String) -> Texture2D:
	if _cache.has(vial_id):
		return _cache[vial_id]
	var liquid: Color = LIQUID.get(vial_id, Color(0.55, 0.46, 0.28, 1))
	var tinted: Texture2D = _tint_liquid(FLASK, liquid)
	_cache[vial_id] = tinted
	return tinted


static func _tint_liquid(src: Texture2D, liquid: Color) -> Texture2D:
	if src == null:
		return src
	var img: Image = src.get_image()
	if img == null or img.is_empty():
		return src
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var pixel: Color = img.get_pixel(x, y)
			if pixel.a < 0.2:
				continue
			var brightest: float = maxf(pixel.r, maxf(pixel.g, pixel.b))
			var dullest: float = minf(pixel.r, minf(pixel.g, pixel.b))
			var sat: float = 0.0 if brightest <= 0.001 else (brightest - dullest) / brightest
			var chroma_purple: float = (pixel.r + pixel.b) * 0.5 - pixel.g
			var is_liquid: bool = (sat >= 0.28 and brightest >= 0.28) \
				or (chroma_purple > 0.08 and sat >= 0.10 and brightest >= 0.22)
			if not is_liquid:
				continue
			var lum: float = pixel.r * 0.3 + pixel.g * 0.5 + pixel.b * 0.2
			var tinted: Color = liquid.lightened(clampf((lum - 0.42) * 0.9, -0.22, 0.38))
			tinted.a = pixel.a
			img.set_pixel(x, y, tinted)
	return ImageTexture.create_from_image(img)
