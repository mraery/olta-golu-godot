extends Control
class_name MarketView

## Tatlı 2D Balık Pazarı tezgah sahnesi (çizgili tente, buzlu balık kasaları,
## animasyonlu NPC müşteriler ve satışta altın yağmuru!).

var mt: float = 0.0
var coins: Array[Dictionary] = []
var haggle_msg: String = ""
var haggle_msg_t: float = 0.0
var _font: Font = ThemeDB.fallback_font

func _ready() -> void:
	custom_minimum_size = Vector2(720, 178)

func trigger_sale_celebration(msg: String = "") -> void:
	for i in range(18):
		coins.append({
			"x": randf_range(210.0, 510.0),
			"y": randf_range(80.0, 130.0),
			"vx": randf_range(-90.0, 90.0),
			"vy": randf_range(-190.0, -90.0),
			"life": randf_range(0.9, 1.5),
		})
	if not msg.is_empty():
		haggle_msg = msg
		haggle_msg_t = 2.6

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var dt := minf(0.05, delta)
	mt += dt
	if haggle_msg_t > 0.0:
		haggle_msg_t = maxf(0.0, haggle_msg_t - dt)
	for c in coins:
		c["vy"] = float(c["vy"]) + 360.0 * dt
		c["x"] = float(c["x"]) + float(c["vx"]) * dt
		c["y"] = float(c["y"]) + float(c["vy"]) * dt
		c["life"] = float(c["life"]) - dt
	coins = coins.filter(func(c): return float(c["life"]) > 0.0)
	queue_redraw()

func _draw() -> void:
	var cw := size.x
	var ch := size.y
	if cw <= 2.0 or ch <= 2.0:
		return

	# Arka plan: tatlı gün ışığı + göl şeridi + taş pazar zemini
	draw_rect(Rect2(0, 0, cw, ch * 0.56), Color("#bce6ff"))
	draw_rect(Rect2(0, ch * 0.42, cw, ch * 0.16), Color("#4cb8e8"))
	draw_rect(Rect2(0, ch * 0.58, cw, ch * 0.42), Color("#e6d2b5"))
	# Taş doku çizgileri
	for x_i in range(0, int(cw), 48):
		draw_rect(Rect2(float(x_i) + 4.0, ch * 0.65, 38.0, 12.0), Color("#d9c2a3"))

	# Ahşap Pazar Tezgahı (sol-orta)
	var sx := 32.0
	var sw := 340.0
	var sy := 30.0
	# Direkler
	draw_rect(Rect2(sx + 10.0, sy + 20.0, 12.0, ch - sy - 28.0), Color("#6e4421"))
	draw_rect(Rect2(sx + sw - 22.0, sy + 20.0, 12.0, ch - sy - 28.0), Color("#6e4421"))
	# Kırmızı-beyaz çizgili tatlı tente
	var stripes := 10
	var st_w := sw / float(stripes)
	for i in range(stripes):
		var col := Color("#e63946") if i % 2 == 0 else Color("#fff8f0")
		draw_rect(Rect2(sx + float(i) * st_w, sy, st_w + 0.5, 28.0), col)
		draw_circle(Vector2(sx + (float(i) + 0.5) * st_w, sy + 28.0), st_w * 0.5, col)

	# Sallanan süs fenerleri
	for lx in [sx + 75.0, sx + sw - 75.0]:
		var sway := sin(mt * 2.4 + lx) * 3.0
		draw_line(Vector2(lx, sy + 28.0), Vector2(lx + sway, sy + 44.0), Color("#5c3a1e"), 2.0)
		draw_circle(Vector2(lx + sway, sy + 49.0), 8.0, Color("#ffe066"))
		draw_circle(Vector2(lx + sway, sy + 49.0), 13.0, Color(1.0, 0.88, 0.4, 0.25))

	# Tezgah masası & buz kasası
	var counter_y := ch - 68.0
	draw_rect(Rect2(sx, counter_y, sw, 56.0), Color("#a86e38"))
	draw_rect(Rect2(sx - 6.0, counter_y - 6.0, sw + 12.0, 10.0), Color("#c98b4e"))
	# Buzlu tepsi
	draw_rect(Rect2(sx + 24.0, counter_y - 14.0, sw - 48.0, 14.0), Color("#d8f3ff"))
	draw_rect(Rect2(sx + 26.0, counter_y - 12.0, sw - 52.0, 10.0), Color("#b3e5fc"))

	# Sepetteki ilk 5 balığı buzların üzerinde sergile!
	var basket: Array = SaveManager.data["basket"]
	var show_n := mini(5, basket.size())
	for i in range(show_n):
		var sp := GameData.get_species(str(basket[i]["sp_id"]))
		var tex := GameData.get_fish_texture(str(sp["spr"]))
		if tex != null:
			var sc := minf(44.0 / maxf(1.0, float(tex.get_width())), 24.0 / maxf(1.0, float(tex.get_height())))
			var sz := tex.get_size() * sc
			var fx := sx + 56.0 + float(i) * 56.0
			var fy := counter_y - 14.0 - sz.y * 0.3
			var tint := Color(str(sp["tint"])) if sp.has("tint") else Color.WHITE
			draw_texture_rect(tex, Rect2(Vector2(fx - sz.x * 0.5, fy), sz), false, tint)

	# Tabela: "OLTA PAZARI"
	draw_rect(Rect2(sx + 92.0, counter_y + 14.0, 156.0, 26.0), Color("#fff5d6"))
	draw_rect(Rect2(sx + 92.0, counter_y + 14.0, 156.0, 26.0), Color("#7a4d22"), false, 2.0)
	draw_string(_font, Vector2(sx + 92.0, counter_y + 32.0), "🐟 TAZE BALIK", HORIZONTAL_ALIGNMENT_CENTER, 156.0, 14, Color("#6e3b10"))

	# Sağ tarafta tatlı animasyonlu NPC Müşteri!
	var cust := SaveManager.get_market_customer()
	var cx := 455.0
	var bob := sin(mt * 3.2) * 2.5
	var cy := ch - 44.0 + bob
	var cid := str(cust["id"])

	# Gölge
	draw_circle(Vector2(cx, ch - 14.0), 22.0, Color(0, 0, 0, 0.14))
	# Gövde
	draw_rect(Rect2(cx - 18.0, cy - 30.0, 36.0, 42.0), cust["shirt"])
	# Kafa
	var head_c := Color("#ffad5c") if cid == "cat" else Color("#f7cfa8")
	draw_circle(Vector2(cx, cy - 46.0), 17.0, head_c)
	# Gözler & tatlı gülümseme
	draw_circle(Vector2(cx - 6.0, cy - 48.0), 2.5, Color("#222"))
	draw_circle(Vector2(cx + 6.0, cy - 48.0), 2.5, Color("#222"))
	draw_circle(Vector2(cx - 10.0, cy - 43.0), 3.0, Color(1.0, 0.55, 0.6, 0.5))
	draw_circle(Vector2(cx + 10.0, cy - 43.0), 3.0, Color(1.0, 0.55, 0.6, 0.5))
	draw_arc(Vector2(cx, cy - 43.0), 5.0, 0.2, PI - 0.2, 10, Color("#5c3a1e"), 2.0)

	# Karaktere özel şapka / kulak
	if cid == "cat":
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 15, cy - 56), Vector2(cx - 10, cy - 72), Vector2(cx - 2, cy - 60)]), head_c)
		draw_colored_polygon(PackedVector2Array([Vector2(cx + 15, cy - 56), Vector2(cx + 10, cy - 72), Vector2(cx + 2, cy - 60)]), head_c)
	elif cid == "chef":
		draw_rect(Rect2(cx - 14.0, cy - 76.0, 28.0, 16.0), Color.WHITE)
		draw_circle(Vector2(cx - 8.0, cy - 76.0), 8.0, Color.WHITE)
		draw_circle(Vector2(cx + 8.0, cy - 76.0), 8.0, Color.WHITE)
		draw_circle(Vector2(cx, cy - 80.0), 9.0, Color.WHITE)
	elif cid == "captain":
		draw_rect(Rect2(cx - 18.0, cy - 64.0, 36.0, 6.0), Color("#184e77"))
		draw_rect(Rect2(cx - 13.0, cy - 74.0, 26.0, 11.0), Color.WHITE)
		draw_circle(Vector2(cx, cy - 68.0), 3.0, Color("#ffd43b"))
	else:
		# Koleksiyoncu Leyla beresi & gözlüğü
		draw_arc(Vector2(cx - 6.0, cy - 48.0), 5.5, 0.0, TAU, 12, Color("#3b2a12"), 1.6)
		draw_arc(Vector2(cx + 6.0, cy - 48.0), 5.5, 0.0, TAU, 12, Color("#3b2a12"), 1.6)
		draw_circle(Vector2(cx, cy - 64.0), 14.0, cust["hat"])

	# Konuşma Balonu (Sağda)
	var bx := 494.0
	var by := 20.0
	var bw := cw - bx - 16.0
	var bh := 124.0
	draw_rect(Rect2(bx, by, bw, bh), Color.WHITE)
	draw_rect(Rect2(bx, by, bw, bh), Color("#d4b97a"), false, 2.5)
	draw_string(_font, Vector2(bx + 10.0, by + 22.0), "%s %s (%s!)" % [str(cust["icon"]), str(cust["name"]), str(cust["bonus_lbl"])], HORIZONTAL_ALIGNMENT_LEFT, bw - 20.0, 14, Color("#0d5c8f"))

	var quote_txt := haggle_msg if haggle_msg_t > 0.0 else str(cust["quote"])
	# Satır kaydırma (basit)
	var words := quote_txt.split(" ")
	var line := ""
	var ly := by + 46.0
	for w in words:
		var cand := (line + " " + w).strip_edges()
		if cand.length() > 27 and not line.is_empty():
			draw_string(_font, Vector2(bx + 10.0, ly), line, HORIZONTAL_ALIGNMENT_LEFT, bw - 20.0, 12, Color("#4d381a"))
			ly += 17.0
			line = w
		else:
			line = cand
	if not line.is_empty():
		draw_string(_font, Vector2(bx + 10.0, ly), line, HORIZONTAL_ALIGNMENT_LEFT, bw - 20.0, 12, Color("#4d381a"))

	# Altın yağmuru
	for c in coins:
		var cp := Vector2(float(c["x"]), float(c["y"]))
		draw_circle(cp, 6.0, Color("#ffd43b"))
		draw_circle(cp, 3.5, Color("#fff3b0"))
