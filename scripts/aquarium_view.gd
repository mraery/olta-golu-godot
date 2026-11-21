extends Control
class_name AquariumView

## Canlı kişisel akvaryum çizim ve besleme motoru.

signal fed()

var entities: Array[Dictionary] = []
var pellets: Array[Dictionary] = []
var hearts: Array[Dictionary] = []
var bubbles: Array[Dictionary] = []
var aqua_t: float = 0.0
var _font: Font = ThemeDB.fallback_font

func _ready() -> void:
	custom_minimum_size = Vector2(720, 230)
	mouse_filter = Control.MOUSE_FILTER_STOP
	sync_entities()

func sync_entities() -> void:
	var cw := maxf(400.0, size.x if size.x > 10.0 else 720.0)
	var ch := maxf(180.0, size.y if size.y > 10.0 else 230.0)
	var existing: Dictionary = {}
	for e in entities:
		existing[e["uid"]] = e
	entities.clear()
	for item in SaveManager.data["aquarium"]:
		var uid := str(item["uid"])
		if existing.has(uid):
			entities.append(existing[uid])
			continue
		var sp := GameData.get_species(str(item["sp_id"]))
		var dir := 1.0 if randf() < 0.5 else -1.0
		entities.append({
			"uid": uid, "item": item, "sp": sp,
			"x": randf_range(60.0, cw - 60.0), "y": randf_range(40.0, ch - 50.0),
			"vx": randf_range(28.0, 56.0) * dir, "vy": randf_range(-8.0, 8.0),
			"dir": dir, "sc": clampf(float(sp.get("sc", 0.55)) * 0.9, 0.42, 0.95),
			"ph": randf_range(0.0, TAU),
		})

func drop_food(at_pos: Vector2 = Vector2(-1, -1)) -> void:
	if (SaveManager.data["aquarium"] as Array).is_empty():
		SaveManager.toast_requested.emit("🐠 Önce akvaryuma bir balık koy!")
		return
	var cw := maxf(400.0, size.x if size.x > 10.0 else 720.0)
	var bx := at_pos.x if at_pos.x >= 0.0 else randf_range(120.0, cw - 120.0)
	var by := clampf(at_pos.y, 14.0, 150.0) if at_pos.y >= 0.0 else 24.0
	for i in range(6):
		pellets.append({
			"x": clampf(bx + randf_range(-28.0, 28.0), 24.0, cw - 24.0),
			"y": by + randf_range(-6.0, 8.0),
			"vy": randf_range(26.0, 44.0), "eaten": false,
		})
	SaveManager.aqua_fed_until_msec = Time.get_ticks_msec() + 60000
	AudioManager.play("splash")
	SaveManager.toast_requested.emit("🍤 Balıklar beslendi! 60 sn boyunca 2x Akvaryum Geliri!")
	fed.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		drop_food(event.position)

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var dt := minf(0.05, delta)
	aqua_t += dt
	var cw := maxf(400.0, size.x)
	var ch := maxf(180.0, size.y)

	if randf() < dt * 9.0:
		bubbles.append({"x": cw * 0.5 + randf_range(-10.0, 10.0), "y": ch - 24.0, "r": randf_range(2.0, 5.0), "vy": randf_range(35.0, 68.0)})
	for b in bubbles:
		b["y"] = float(b["y"]) - float(b["vy"]) * dt
		b["x"] = float(b["x"]) + sin(aqua_t * 4.0 + float(b["y"]) * 0.06) * 0.5
	bubbles = bubbles.filter(func(b): return float(b["y"]) > 6.0)

	for p in pellets:
		p["y"] = float(p["y"]) + float(p["vy"]) * dt
		p["x"] = float(p["x"]) + sin(aqua_t * 3.0 + float(p["y"]) * 0.08) * 6.0 * dt
	pellets = pellets.filter(func(p): return not bool(p["eaten"]) and float(p["y"]) < ch - 18.0)

	for e in entities:
		e["ph"] = float(e["ph"]) + dt * 3.0
		var target: Dictionary = {}
		var best_d := 240.0
		for p in pellets:
			if bool(p["eaten"]):
				continue
			var d := Vector2(float(p["x"]) - float(e["x"]), float(p["y"]) - float(e["y"])).length()
			if d < best_d:
				best_d = d
				target = p
		if not target.is_empty():
			var dx := float(target["x"]) - float(e["x"])
			var dy := float(target["y"]) - float(e["y"])
			var d := maxf(1.0, sqrt(dx * dx + dy * dy))
			e["vx"] = lerpf(float(e["vx"]), (dx / d) * 115.0, dt * 4.0)
			e["vy"] = lerpf(float(e["vy"]), (dy / d) * 95.0, dt * 4.0)
			if d < 16.0:
				target["eaten"] = true
				hearts.append({"x": float(e["x"]), "y": float(e["y"]) - 14.0, "life": 1.1})
				AudioManager.play("click")
		elif randf() < dt * 0.35:
			e["vx"] = randf_range(24.0, 58.0) * (1.0 if randf() < 0.5 else -1.0)
			e["vy"] = randf_range(-14.0, 14.0)
		e["x"] = float(e["x"]) + float(e["vx"]) * dt
		e["y"] = float(e["y"]) + float(e["vy"]) * dt + sin(float(e["ph"])) * 0.25
		if float(e["x"]) < 42.0: e["x"] = 42.0; e["vx"] = absf(float(e["vx"]))
		elif float(e["x"]) > cw - 42.0: e["x"] = cw - 42.0; e["vx"] = -absf(float(e["vx"]))
		if float(e["y"]) < 30.0: e["y"] = 30.0; e["vy"] = absf(float(e["vy"]))
		elif float(e["y"]) > ch - 44.0: e["y"] = ch - 44.0; e["vy"] = -absf(float(e["vy"]))
		e["dir"] = 1.0 if float(e["vx"]) >= 0.0 else -1.0

	for h in hearts:
		h["y"] = float(h["y"]) - 28.0 * dt
		h["life"] = float(h["life"]) - dt
	hearts = hearts.filter(func(h): return float(h["life"]) > 0.0)
	queue_redraw()

func _draw() -> void:
	var cw := size.x
	var ch := size.y
	if cw <= 2.0 or ch <= 2.0:
		return

	# Su gradyanı
	for i in range(10):
		var k := float(i) / 10.0
		var col := Color("#37c8e8").lerp(Color("#0b466e"), k)
		draw_rect(Rect2(0.0, k * ch, cw, ch / 10.0 + 1.0), col)

	# Işık hüzmeleri
	for i in range(5):
		var rx := fmod(float(i) * 165.0 + sin(aqua_t * 0.6 + float(i)) * 28.0, cw)
		draw_colored_polygon(PackedVector2Array([Vector2(rx, 0), Vector2(rx + 36, 0), Vector2(rx + 92, ch), Vector2(rx + 24, ch)]), Color(0.82, 0.98, 1.0, 0.14))

	# Kum tabanı
	draw_rect(Rect2(0.0, ch - 24.0, cw, 24.0), Color("#e6c98a"))
	draw_rect(Rect2(0.0, ch - 10.0, cw, 10.0), Color("#cfa963"))

	# Yosun & kayalar
	var props := [
		["seaweed_green_a", 0.08, 0.58], ["seaweed_pink_b", 0.2, 0.52], ["rock_a", 0.34, 0.5],
		["seaweed_orange_a", 0.52, 0.55], ["seaweed_green_c", 0.72, 0.58], ["rock_b", 0.84, 0.48], ["seaweed_pink_a", 0.94, 0.55]
	]
	for p in props:
		var tex := GameData.get_env_texture(str(p[0]))
		if tex != null:
			var sz := tex.get_size() * float(p[2])
			draw_texture_rect(tex, Rect2(Vector2(cw * float(p[1]) - sz.x * 0.5, ch - 16.0 - sz.y), sz), false)

	# Hava taşı & kabarcıklar
	draw_rect(Rect2(cw * 0.5 - 12.0, ch - 22.0, 24.0, 9.0), Color("#5c6b78"))
	for b in bubbles:
		draw_arc(Vector2(float(b["x"]), float(b["y"])), float(b["r"]), 0.0, TAU, 12, Color(1, 1, 1, 0.65), 1.4)

	# Yem tanecikleri
	for p in pellets:
		draw_circle(Vector2(float(p["x"]), float(p["y"])), 4.0, Color("#ffae42"))

	# Balıklar
	for e in entities:
		var sp: Dictionary = e["sp"]
		var tex := GameData.get_fish_texture(str(sp["spr"]))
		if tex == null:
			continue
		var tint := Color(str(sp["tint"])) if sp.has("tint") else Color.WHITE
		var sz := tex.get_size() * float(e["sc"])
		draw_set_transform(Vector2(float(e["x"]), float(e["y"])), 0.0, Vector2(-1.0 if float(e["dir"]) < 0.0 else 1.0, 1.0))
		draw_texture_rect(tex, Rect2(-sz * 0.5, sz), false, tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for h in hearts:
		draw_string(_font, Vector2(float(h["x"]) - 10.0, float(h["y"])), "❤️", HORIZONTAL_ALIGNMENT_CENTER, 20.0, 15, Color(1, 1, 1, clampf(float(h["life"]), 0.0, 1.0)))

	draw_rect(Rect2(2, 2, cw - 4, ch - 4), Color(1, 1, 1, 0.35), false, 3.0)
