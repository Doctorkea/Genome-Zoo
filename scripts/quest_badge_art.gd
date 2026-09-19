extends RefCounted
class_name QuestBadgeArt

## Small enamel badges for the Quests button.
## Red ! = you have a job. Gold ribbon medal = a reward is waiting.
## Same language as MMO quest markers (WoW gold ! / turn-in) and
## prize-ribbon achievement badges.

const SIZE: int = 48

static var _exclaim: Texture2D
static var _ribbon: Texture2D


static func exclaim() -> Texture2D:
	if _exclaim == null:
		_exclaim = _texture(_draw_exclaim())
	return _exclaim


static func ribbon() -> Texture2D:
	if _ribbon == null:
		_ribbon = _texture(_draw_ribbon())
	return _ribbon


static func _texture(img: Image) -> Texture2D:
	var tex := ImageTexture.create_from_image(img)
	tex.resource_name = "QuestBadge"
	return tex


static func _blank() -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func _draw_exclaim() -> Image:
	var img := _blank()
	var c := Vector2(SIZE * 0.5, SIZE * 0.5)
	_disk(img, c, 22.0, Color(0.42, 0.07, 0.08, 1))
	_disk(img, c, 19.5, Color(0.84, 0.16, 0.14, 1))
	_disk(img, c + Vector2(-5.0, -6.0), 8.0, Color(1.0, 0.55, 0.45, 0.28))
	_capsule(img, Vector2(c.x, 14.0), Vector2(c.x, 28.5), 3.2, Color(0.99, 0.95, 0.88, 1))
	_disk(img, Vector2(c.x, 35.5), 3.4, Color(0.99, 0.95, 0.88, 1))
	return img


static func _draw_ribbon() -> Image:
	var img := _blank()
	var gold := Color(0.93, 0.72, 0.16, 1)
	var gold_dark := Color(0.62, 0.38, 0.05, 1)
	var gold_deep := Color(0.78, 0.5, 0.08, 1)
	var cream := Color(1.0, 0.93, 0.62, 1)
	# Tails sit behind the medallion, prize-ribbon style.
	_tri(img, Vector2(18, 28), Vector2(7, 46), Vector2(22, 46), gold_deep)
	_tri(img, Vector2(18, 28), Vector2(22, 46), Vector2(24, 32), gold)
	_tri(img, Vector2(30, 28), Vector2(41, 46), Vector2(26, 46), gold_deep)
	_tri(img, Vector2(30, 28), Vector2(26, 46), Vector2(24, 32), cream)
	var c := Vector2(24.0, 20.0)
	_disk(img, c, 16.5, gold_dark)
	_disk(img, c, 14.2, gold)
	_disk(img, c + Vector2(-4.5, -5.0), 6.5, Color(1.0, 0.96, 0.72, 0.4))
	_disk(img, c, 6.2, gold_dark)
	_disk(img, c, 4.4, cream)
	return img


static func _disk(img: Image, center: Vector2, radius: float, color: Color) -> void:
	var x0: int = clampi(int(floor(center.x - radius - 1.0)), 0, SIZE - 1)
	var y0: int = clampi(int(floor(center.y - radius - 1.0)), 0, SIZE - 1)
	var x1: int = clampi(int(ceil(center.x + radius + 1.0)), 0, SIZE)
	var y1: int = clampi(int(ceil(center.y + radius + 1.0)), 0, SIZE)
	for y in range(y0, y1):
		for x in range(x0, x1):
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(center)
			var cover: float = clampf(radius - d + 0.5, 0.0, 1.0)
			if cover > 0.0:
				_put(img, x, y, color, cover)


static func _capsule(img: Image, a: Vector2, b: Vector2, radius: float, color: Color) -> void:
	_disk(img, a, radius, color)
	_disk(img, b, radius, color)
	var x0: int = clampi(int(floor(minf(a.x, b.x) - radius - 1.0)), 0, SIZE - 1)
	var y0: int = clampi(int(floor(minf(a.y, b.y) - radius - 1.0)), 0, SIZE - 1)
	var x1: int = clampi(int(ceil(maxf(a.x, b.x) + radius + 1.0)), 0, SIZE)
	var y1: int = clampi(int(ceil(maxf(a.y, b.y) + radius + 1.0)), 0, SIZE)
	var ab: Vector2 = b - a
	var len_sq: float = maxf(ab.length_squared(), 0.0001)
	for y in range(y0, y1):
		for x in range(x0, x1):
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			var t: float = clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
			var d: float = p.distance_to(a + ab * t)
			var cover: float = clampf(radius - d + 0.5, 0.0, 1.0)
			if cover > 0.0:
				_put(img, x, y, color, cover)


static func _tri(img: Image, a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	var x0: int = clampi(int(floor(minf(a.x, minf(b.x, c.x)) - 1.0)), 0, SIZE - 1)
	var y0: int = clampi(int(floor(minf(a.y, minf(b.y, c.y)) - 1.0)), 0, SIZE - 1)
	var x1: int = clampi(int(ceil(maxf(a.x, maxf(b.x, c.x)) + 1.0)), 0, SIZE)
	var y1: int = clampi(int(ceil(maxf(a.y, maxf(b.y, c.y)) + 1.0)), 0, SIZE)
	for y in range(y0, y1):
		for x in range(x0, x1):
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			if _inside_tri(p, a, b, c):
				_put(img, x, y, color, 1.0)


static func _inside_tri(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var v0 := c - a
	var v1 := b - a
	var v2 := p - a
	var dot00: float = v0.dot(v0)
	var dot01: float = v0.dot(v1)
	var dot02: float = v0.dot(v2)
	var dot11: float = v1.dot(v1)
	var dot12: float = v1.dot(v2)
	var inv: float = 1.0 / maxf((dot00 * dot11 - dot01 * dot01), 0.0001)
	var u: float = (dot11 * dot02 - dot01 * dot12) * inv
	var v: float = (dot00 * dot12 - dot01 * dot02) * inv
	return u >= 0.0 and v >= 0.0 and (u + v) <= 1.0


static func _put(img: Image, x: int, y: int, color: Color, cover: float) -> void:
	var src_a: float = color.a * cover
	if src_a <= 0.0:
		return
	var dst: Color = img.get_pixel(x, y)
	var out_a: float = src_a + dst.a * (1.0 - src_a)
	if out_a <= 0.0:
		return
	var keep: float = dst.a * (1.0 - src_a)
	img.set_pixel(x, y, Color(
		(color.r * src_a + dst.r * keep) / out_a,
		(color.g * src_a + dst.g * keep) / out_a,
		(color.b * src_a + dst.b * keep) / out_a,
		out_a
	))
