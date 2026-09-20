extends RefCounted

## Tiny 2D particle helpers. GPUParticles2D plus a ParticleProcessMaterial:
## a soft puff texture, a lifetime, a color ramp that fades to empty, and
## gravity/velocity for rise or fall. Pen and serum smoke is stylized
## cotton-ball puffs: shaded spheres, a short flipbook, overlap into a
## billow, then fade. Bursts (dust, sparks, coins, poofs) are one-shot.
## Loops (exhaust, steam, lamp motes) stay emitting on their host.

enum Kind { DUST, SMOKE, STEAM, SPARK, GOLD, EMBER, SHOCK, CLOUD, HEART }

const PUFF_SIZE: int = 32
const CLOUD_SIZE: int = 80
const PUFF_FRAMES: int = 4

static var _puff: Texture2D
static var _speck: Texture2D
static var _cloud: Texture2D
static var _ground_shadow: Texture2D
static var _grow: CurveTexture
static var _billow: CurveTexture
static var _smoke_fade: GradientTexture1D
static var _mats: Dictionary = {}


static func puff_tex() -> Texture2D:
	if _puff == null:
		_puff = _blob(PUFF_SIZE, 0.92)
	return _puff


static func speck_tex() -> Texture2D:
	if _speck == null:
		_speck = _blob(16, 0.55)
	return _speck


static func cloud_tex() -> Texture2D:
	if _cloud == null:
		_cloud = _cloud_blob()
	return _cloud


static func ground_shadow_tex() -> Texture2D:
	if _ground_shadow != null:
		return _ground_shadow
	const W: int = 64
	const H: int = 32
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var mid := Vector2(float(W) * 0.5, float(H) * 0.5)
	for y in range(H):
		for x in range(W):
			var p := Vector2(
				(float(x) + 0.5 - mid.x) / (float(W) * 0.46),
				(float(y) + 0.5 - mid.y) / (float(H) * 0.44)
			)
			var t: float = clampf(1.0 - p.length(), 0.0, 1.0)
			if t <= 0.0:
				continue
			img.set_pixel(x, y, Color(0.07, 0.06, 0.04, t * t * 0.42))
	_ground_shadow = ImageTexture.create_from_image(img)
	return _ground_shadow


static func burst(host: Node2D, kind: int, local_pos: Vector2 = Vector2.ZERO, tint: Color = Color.WHITE) -> GPUParticles2D:
	if host == null or not is_instance_valid(host):
		return null
	var particles := make(kind, true, tint)
	host.add_child(particles)
	particles.position = local_pos
	particles.emitting = true
	particles.restart()
	_free_when_done(particles, host)
	return particles


static func loop(host: Node2D, kind: int, local_pos: Vector2 = Vector2.ZERO, tint: Color = Color.WHITE) -> GPUParticles2D:
	if host == null or not is_instance_valid(host):
		return null
	var particles := make(kind, false, tint)
	host.add_child(particles)
	particles.position = local_pos
	particles.emitting = true
	return particles


static func pen_poof(host: Node2D, size: Vector2) -> GPUParticles2D:
	if host == null or not is_instance_valid(host):
		return null
	var particles := make(Kind.CLOUD, true)
	particles.amount = 24
	particles.lifetime = 1.7
	particles.explosiveness = 1.0
	particles.randomness = 0.5
	particles.visibility_rect = Rect2(-size.x, -size.y * 1.4, size.x * 2.0, size.y * 2.6)
	var mat := particles.process_material as ParticleProcessMaterial
	if mat != null:
		mat.emission_sphere_radius = minf(size.x, size.y) * 0.26
		mat.spread = 70.0
		mat.initial_velocity_min = 18.0
		mat.initial_velocity_max = 48.0
		mat.scale_min = 1.35
		mat.scale_max = 2.45
		mat.color = Color(1.0, 1.0, 1.0, 1.0)
	host.add_child(particles)
	particles.position = size * 0.5
	particles.emitting = true
	particles.restart()
	_free_when_done(particles, host)
	return particles


static func conceal_change(host: Node2D, apply: Callable, local_pos: Vector2 = Vector2.ZERO) -> void:
	if not apply.is_valid():
		return
	if host == null or not is_instance_valid(host) or DisplayServer.get_name() == "headless":
		apply.call()
		return
	var tree := host.get_tree()
	if tree == null:
		apply.call()
		return
	var clouds := make(Kind.CLOUD, true)
	clouds.amount = 28
	clouds.lifetime = 1.8
	clouds.explosiveness = 0.9
	clouds.preprocess = 0.2
	clouds.randomness = 0.45
	clouds.local_coords = true
	clouds.z_index = 14
	clouds.visibility_rect = Rect2(-200.0, -260.0, 400.0, 440.0)
	var mat := clouds.process_material as ParticleProcessMaterial
	if mat != null:
		mat.emission_sphere_radius = 22.0
		mat.spread = 62.0
		mat.initial_velocity_min = 10.0
		mat.initial_velocity_max = 28.0
		mat.gravity = Vector3(0, -24.0, 0)
		mat.scale_min = 1.45
		mat.scale_max = 2.55
	host.add_child(clouds)
	clouds.position = local_pos
	clouds.emitting = true
	clouds.restart()
	_free_when_done(clouds, host)
	var apply_fn := apply
	tree.create_timer(0.34).timeout.connect(func() -> void:
		if apply_fn.is_valid():
			apply_fn.call()
	)


static func make(kind: int, one_shot: bool, tint: Color = Color.WHITE) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	if kind == Kind.GOLD or kind == Kind.EMBER or kind == Kind.SPARK:
		particles.texture = speck_tex()
	elif kind == Kind.CLOUD:
		particles.texture = cloud_tex()
	elif kind == Kind.HEART:
		particles.texture = load("res://art/ui/mood/heart.png")
	else:
		particles.texture = puff_tex()
	particles.one_shot = one_shot
	particles.local_coords = false
	particles.fixed_fps = 0
	particles.fract_delta = true
	particles.visibility_rect = Rect2(-72.0, -96.0, 144.0, 140.0)
	particles.z_index = 4
	var mat := _material(kind, tint)
	if kind == Kind.CLOUD:
		mat = mat.duplicate()
	particles.process_material = mat
	if kind == Kind.CLOUD:
		_soft_draw(particles, true)
	elif kind == Kind.SMOKE:
		_soft_draw(particles, false)
	match kind:
		Kind.DUST:
			particles.amount = 7 if one_shot else 10
			particles.lifetime = 0.45
			particles.explosiveness = 0.88 if one_shot else 0.12
			particles.randomness = 0.7
			particles.z_index = 2
		Kind.SMOKE:
			particles.amount = 16
			particles.lifetime = 2.0
			particles.explosiveness = 0.04
			particles.randomness = 0.65
			particles.preprocess = 0.7
			particles.z_index = 2
		Kind.STEAM:
			particles.amount = 10
			particles.lifetime = 1.1
			particles.explosiveness = 0.08 if not one_shot else 0.8
			particles.randomness = 0.6
			particles.preprocess = 0.4 if not one_shot else 0.0
			particles.z_index = 5
		Kind.SPARK:
			particles.amount = 18
			particles.lifetime = 0.55
			particles.explosiveness = 0.92
			particles.randomness = 0.55
			particles.z_index = 6
		Kind.GOLD:
			particles.amount = 12
			particles.lifetime = 0.7
			particles.explosiveness = 0.86
			particles.randomness = 0.5
			particles.z_index = 7
		Kind.EMBER:
			particles.amount = 8
			particles.lifetime = 2.2
			particles.explosiveness = 0.05
			particles.randomness = 0.8
			particles.preprocess = 1.1
			particles.z_index = 5
		Kind.SHOCK:
			particles.amount = 16
			particles.lifetime = 0.4
			particles.explosiveness = 0.95
			particles.randomness = 0.35
			particles.z_index = 6
		Kind.CLOUD:
			particles.amount = 20
			particles.lifetime = 1.65
			particles.explosiveness = 1.0 if one_shot else 0.06
			particles.randomness = 0.45
			particles.z_index = 8
			particles.visibility_rect = Rect2(-220.0, -280.0, 440.0, 460.0)
		Kind.HEART:
			particles.amount = 14
			particles.lifetime = 0.9
			particles.explosiveness = 0.82
			particles.randomness = 0.55
			particles.z_index = 8
		_:
			particles.amount = 8
			particles.lifetime = 0.6
	return particles


static func _material(kind: int, tint: Color) -> ParticleProcessMaterial:
	if tint == Color.WHITE and _mats.has(kind):
		return _mats[kind]
	var mat := _build_material(kind, tint)
	if tint == Color.WHITE:
		_mats[kind] = mat
	return mat


static func _build_material(kind: int, tint: Color) -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 5.0
	mat.spread = 40.0
	match kind:
		Kind.DUST:
			mat.direction = Vector3(0, -1, 0)
			mat.spread = 55.0
			mat.initial_velocity_min = 8.0
			mat.initial_velocity_max = 22.0
			mat.gravity = Vector3(0, 38.0, 0)
			mat.scale_min = 0.18
			mat.scale_max = 0.42
			mat.color = Color(0.62, 0.5, 0.32, 0.7) if tint == Color.WHITE else tint
			mat.color_ramp = _fade_ramp(mat.color, Color(0.45, 0.36, 0.22, 0.0))
			mat.damping_min = 4.0
			mat.damping_max = 10.0
		Kind.SMOKE:
			mat.direction = Vector3(-1, -0.45, 0)
			mat.spread = 18.0
			mat.initial_velocity_min = 12.0
			mat.initial_velocity_max = 26.0
			mat.gravity = Vector3(0, -30.0, 0)
			mat.damping_min = 3.0
			mat.damping_max = 7.0
			mat.scale_min = 0.28
			mat.scale_max = 0.55
			mat.scale_curve = _grow_curve()
			mat.color = Color(0.62, 0.62, 0.6, 0.55)
			mat.color_ramp = _smoke_ramp(Color(0.7, 0.7, 0.68, 0.55), 0.42)
			mat.angular_velocity_min = -50.0
			mat.angular_velocity_max = 50.0
		Kind.STEAM:
			mat.direction = Vector3(0, -1, 0)
			mat.spread = 22.0
			mat.initial_velocity_min = 14.0
			mat.initial_velocity_max = 28.0
			mat.gravity = Vector3(0, -32.0, 0)
			mat.scale_min = 0.22
			mat.scale_max = 0.5
			mat.color = Color(0.95, 0.94, 0.9, 0.45)
			mat.color_ramp = _fade_ramp(Color(1.0, 0.98, 0.94, 0.5), Color(1.0, 1.0, 1.0, 0.0))
		Kind.SPARK:
			mat.direction = Vector3(0, -1, 0)
			mat.spread = 180.0
			mat.emission_sphere_radius = 8.0
			mat.initial_velocity_min = 28.0
			mat.initial_velocity_max = 70.0
			mat.gravity = Vector3(0, 20.0, 0)
			mat.scale_min = 0.12
			mat.scale_max = 0.28
			mat.color = Color(0.42, 0.86, 0.5, 0.95) if tint == Color.WHITE else tint
			mat.color_ramp = _fade_ramp(mat.color, Color(mat.color.r, mat.color.g, mat.color.b, 0.0))
			mat.damping_min = 8.0
			mat.damping_max = 18.0
			mat.hue_variation_min = -0.08
			mat.hue_variation_max = 0.08
		Kind.GOLD:
			mat.direction = Vector3(0, -1, 0)
			mat.spread = 70.0
			mat.initial_velocity_min = 18.0
			mat.initial_velocity_max = 46.0
			mat.gravity = Vector3(0, 55.0, 0)
			mat.scale_min = 0.14
			mat.scale_max = 0.3
			mat.color = Color(0.96, 0.78, 0.22, 1)
			mat.color_ramp = _fade_ramp(Color(1.0, 0.92, 0.45, 1), Color(0.9, 0.6, 0.1, 0.0))
		Kind.EMBER:
			mat.direction = Vector3(0, -1, 0)
			mat.spread = 80.0
			mat.emission_sphere_radius = 7.0
			mat.initial_velocity_min = 4.0
			mat.initial_velocity_max = 12.0
			mat.gravity = Vector3(0, -8.0, 0)
			mat.scale_min = 0.08
			mat.scale_max = 0.18
			mat.color = Color(1.0, 0.82, 0.38, 0.7)
			mat.color_ramp = _fade_ramp(Color(1.0, 0.9, 0.5, 0.75), Color(1.0, 0.6, 0.2, 0.0))
		Kind.SHOCK:
			mat.direction = Vector3(0, -1, 0)
			mat.spread = 180.0
			mat.emission_sphere_radius = 12.0
			mat.initial_velocity_min = 40.0
			mat.initial_velocity_max = 90.0
			mat.gravity = Vector3(0, 10.0, 0)
			mat.scale_min = 0.2
			mat.scale_max = 0.45
			mat.color = Color(0.85, 0.78, 0.62, 0.7)
			mat.color_ramp = _fade_ramp(Color(0.95, 0.9, 0.75, 0.65), Color(0.5, 0.45, 0.35, 0.0))
			mat.damping_min = 12.0
			mat.damping_max = 28.0
		Kind.CLOUD:
			mat.direction = Vector3(0, -1, 0)
			mat.spread = 58.0
			mat.emission_sphere_radius = 20.0
			mat.initial_velocity_min = 12.0
			mat.initial_velocity_max = 34.0
			mat.gravity = Vector3(0, -26.0, 0)
			mat.damping_min = 4.0
			mat.damping_max = 9.0
			mat.scale_min = 1.15
			mat.scale_max = 2.15
			mat.scale_curve = _billow_curve()
			mat.color = Color(1.0, 1.0, 1.0, 1.0)
			mat.color_ramp = _smoke_ramp(Color(1.0, 1.0, 1.0, 0.94), 0.72)
			mat.angular_velocity_min = -40.0
			mat.angular_velocity_max = 40.0
			mat.anim_speed_min = 0.9
			mat.anim_speed_max = 1.45
			mat.anim_offset_min = 0.0
			mat.anim_offset_max = 0.7
		Kind.HEART:
			mat.direction = Vector3(0, -1, 0)
			mat.spread = 70.0
			mat.emission_sphere_radius = 18.0
			mat.initial_velocity_min = 18.0
			mat.initial_velocity_max = 42.0
			mat.gravity = Vector3(0, -48.0, 0)
			mat.damping_min = 2.0
			mat.damping_max = 6.0
			mat.scale_min = 0.22
			mat.scale_max = 0.42
			mat.color = Color(1.0, 0.55, 0.72, 1.0)
			mat.color_ramp = _fade_ramp(Color(1.0, 0.72, 0.82, 1.0), Color(1.0, 0.4, 0.6, 0.0))
		_:
			mat.gravity = Vector3(0, 20.0, 0)
	if tint != Color.WHITE and kind != Kind.DUST and kind != Kind.SPARK and kind != Kind.CLOUD:
		mat.color = tint
	return mat


static func _fade_ramp(start: Color, finish: Color) -> GradientTexture1D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	grad.colors = PackedColorArray([
		start,
		Color(start.r, start.g, start.b, start.a * 0.55),
		finish,
	])
	var tex := GradientTexture1D.new()
	tex.width = 64
	tex.gradient = grad
	return tex


static func _smoke_ramp(peak: Color, mid_alpha: float) -> GradientTexture1D:
	if _smoke_fade != null and peak.r >= 0.99 and mid_alpha >= 0.69:
		return _smoke_fade
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.12, 0.42, 1.0])
	grad.colors = PackedColorArray([
		Color(peak.r, peak.g, peak.b, peak.a * 0.4),
		peak,
		Color(peak.r * 0.93, peak.g * 0.93, peak.b * 0.95, mid_alpha),
		Color(peak.r * 0.82, peak.g * 0.82, peak.b * 0.85, 0.0),
	])
	var tex := GradientTexture1D.new()
	tex.width = 128
	tex.gradient = grad
	if peak.r >= 0.99 and mid_alpha >= 0.69:
		_smoke_fade = tex
	return tex


static func _grow_curve() -> CurveTexture:
	if _grow != null:
		return _grow
	var curve := Curve.new()
	curve.clear_points()
	curve.add_point(Vector2(0.0, 0.16), 0.0, 2.4)
	curve.add_point(Vector2(0.28, 0.82), 0.0, 0.0)
	curve.add_point(Vector2(1.0, 1.0), 0.35, 0.0)
	var tex := CurveTexture.new()
	tex.width = 64
	tex.curve = curve
	_grow = tex
	return _grow


static func _billow_curve() -> CurveTexture:
	if _billow != null:
		return _billow
	var curve := Curve.new()
	curve.clear_points()
	curve.add_point(Vector2(0.0, 0.42), 0.0, 1.6)
	curve.add_point(Vector2(0.22, 0.9), 0.0, 0.0)
	curve.add_point(Vector2(1.0, 1.0), 0.2, 0.0)
	var tex := CurveTexture.new()
	tex.width = 64
	tex.curve = curve
	_billow = tex
	return _billow


static func _soft_draw(particles: GPUParticles2D, animate: bool = false) -> void:
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var canvas := CanvasItemMaterial.new()
	canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	if animate:
		canvas.particles_animation = true
		canvas.particles_anim_h_frames = PUFF_FRAMES
		canvas.particles_anim_v_frames = 1
		canvas.particles_anim_loop = true
	particles.material = canvas


static func _free_when_done(particles: GPUParticles2D, host: Node) -> void:
	var id: int = particles.get_instance_id()
	if particles.one_shot:
		particles.finished.connect(func() -> void:
			_free_id(id)
		, CONNECT_ONE_SHOT)
	var tree := host.get_tree() if host != null else particles.get_tree()
	if tree == null:
		return
	tree.create_timer(particles.lifetime + 0.7).timeout.connect(func() -> void:
		_free_id(id)
	)


static func _free_id(id: int) -> void:
	var node := instance_from_id(id)
	if node != null and is_instance_valid(node):
		node.queue_free()


static func _blob(size: int, hardness: float) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var mid := Vector2(float(size) * 0.5, float(size) * 0.5)
	var radius: float = float(size) * 0.48
	for y in range(size):
		for x in range(size):
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(mid) / radius
			if d >= 1.0:
				continue
			var a: float = pow(1.0 - d, lerpf(1.8, 3.4, hardness))
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(img)


static func _cloud_blob() -> Texture2D:
	var frame: int = CLOUD_SIZE
	var img := Image.create(frame * PUFF_FRAMES, frame, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in range(PUFF_FRAMES):
		_paint_puff(img, i * frame, frame, float(i) * 1.65)
	return ImageTexture.create_from_image(img)


static func _paint_puff(img: Image, ox: int, size: int, seed: float) -> void:
	var mid := Vector2(float(size) * 0.5, float(size) * 0.52)
	var radius: float = float(size) * 0.44
	var light := Vector3(-0.4, -0.55, 0.73).normalized()
	var shadow := Color(0.58, 0.61, 0.66, 1.0)
	var hi := Color(1.0, 1.0, 1.0, 1.0)
	for y in range(size):
		for x in range(size):
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			var d := (p - mid) / radius
			var ang: float = atan2(d.y, d.x)
			var lump: float = 0.11 * sin(ang * 3.0 + seed) + 0.06 * sin(ang * 5.0 - seed * 0.8)
			var r: float = d.length() / (1.0 + lump)
			if r >= 1.0:
				continue
			var z: float = sqrt(maxf(0.0, 1.0 - r * r))
			var n := Vector3(d.x, d.y, z).normalized()
			var shade: float = pow(clampf(n.dot(light), 0.0, 1.0), 0.72)
			var col: Color = shadow.lerp(hi, shade)
			col = col.lerp(Color(0.52, 0.55, 0.6, 1.0), pow(r, 2.4) * 0.32)
			var a: float = 0.96
			if r > 0.78:
				a *= clampf((1.0 - r) / 0.22, 0.0, 1.0)
			img.set_pixel(ox + x, y, Color(col.r, col.g, col.b, a))
