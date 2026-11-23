extends Node2D
class_name WorldCanvas

## Olta Gölü 2D oyun dünyası simülasyonu ve çizim motoru.

signal state_changed(new_state: String)
signal hint_changed(text: String)
signal cast_meter_changed(visible: bool, power: float)
signal fight_started(title: String, lo: float, hi: float)
signal fight_updated(tension: float, progress: float, warn: bool)
signal fight_ended()
signal fish_landed(catch_info: Dictionary)
signal treasure_landed(tr_info: Dictionary)
signal boss_changed(active: bool, label: String)
signal frenzy_changed(seconds_left: float)
signal tourney_changed(active: bool, title: String, prog_text: String, pct: float, secs_left: int)
signal hud_dirty()
## Çekişmenin anlık durumu: phase, zone_lo, zone_hi, stamina, pull, hook_left, beh
signal fight_state(d: Dictionary)
signal hookset_result(quality: String)

const W := GameData.W
const H := GameData.H
const SURF := GameData.SURF
const PPM := GameData.PPM
const ROD_TIP := Vector2(352.0, SURF - 118.0)

var state: String = "menu" # menu | idle | charging | sinking | rising | fight | catch | treasure | panel
var cam_y: float = 0.0
var t: float = 0.0

var fishes: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var treasures: Array[Dictionary] = []
var decor: Array[Dictionary] = []
var bubbles: Array[Dictionary] = []
var ripples: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var rain_drops: Array[Dictionary] = []
var ambient_parts: Array[Dictionary] = []
var float_texts: Array[Dictionary] = []
var confetti: Array[Dictionary] = []
var birds: Array[Dictionary] = []
var hotspots: Array[Dictionary] = []
var jumpers: Array[Dictionary] = []
var jellies: Array[Dictionary] = []
var shooting_stars: Array[Dictionary] = []

var hook: Dictionary = {
	"x": ROD_TIP.x, "y": SURF - 40.0, "tx": ROD_TIP.x,
	"tip": ROD_TIP, "fish": {}, "treasure": {}, "bait": true, "at_max": false
}
var fight: Dictionary = {}
var last_fight: Dictionary = {}

var input_left: bool = false
var input_right: bool = false
var input_hold: bool = false
var pointer_x: float = -1.0
var pointer_down_x: float = -1.0
var dragging: bool = false
var pending_tap: bool = false

var cast_power: float = 0.0
var cast_dir: float = 1.0
var perfect_cast: bool = false
var hotspot_cast: bool = false
var boat_x: float = 270.0
var combo: int = 0
var frenzy_left: float = 0.0
var active_tourney: Dictionary = {}
var boss_ref: Dictionary = {}
var next_hotspot_t: float = 4.0
var next_jumper_t: float = 5.0
var next_star_t: float = 7.0
var screen_shake: float = 0.0
var lightning_alpha: float = 0.0
var next_lightning: float = 6.0

var _font: Font = ThemeDB.fallback_font

func _ready() -> void:
	build_decor()
	populate()

func bottom_y() -> float:
	return SURF + float(SaveManager.max_world_depth()) * PPM

func rod_tip_pos() -> Vector2:
	if int(SaveManager.data["lv"].get("boat", 0)) > 0:
		return Vector2(boat_x + 86.0, SURF - 110.0)
	return ROD_TIP

func rebuild_world() -> void:
	cam_y = 0.0
	boss_ref = {}
	boss_changed.emit(false, "")
	build_decor()
	populate()
	queue_redraw()

func build_decor() -> void:
	decor.clear()
	var bot := bottom_y()
	var fg := ["seaweed_green_a", "seaweed_green_b", "seaweed_green_c", "seaweed_green_d",
		"seaweed_pink_a", "seaweed_pink_b", "seaweed_pink_c", "seaweed_pink_d",
		"seaweed_orange_a", "seaweed_orange_b", "seaweed_grass_a", "seaweed_grass_b", "rock_a", "rock_b"]
	var x := 10.0
	while x < W:
		decor.append({"kind": "fg", "spr": fg[randi() % fg.size()], "x": x, "y": bot + 6.0, "s": randf_range(0.45, 0.85), "ph": randf_range(0.0, TAU)})
		x += randf_range(38.0, 80.0)
	var bg := ["background_seaweed_a", "background_seaweed_c", "background_seaweed_e", "background_seaweed_g", "background_rock_a", "background_rock_b"]
	x = 0.0
	while x < W:
		decor.append({"kind": "bg", "spr": bg[randi() % bg.size()], "x": x, "y": bot - 4.0, "s": randf_range(0.9, 1.5), "ph": randf_range(0.0, TAU)})
		x += randf_range(52.0, 105.0)
	var drift_n := int(round(float(SaveManager.max_world_depth()) / 5.5))
	for i in range(drift_n):
		decor.append({"kind": "drift", "spr": bg[randi() % 4], "x": randf_range(0.0, W), "y": randf_range(SURF + 200.0, bot - 150.0), "s": randf_range(0.5, 1.05), "ph": randf_range(0.0, TAU)})

	birds.clear()
	for i in range(4):
		birds.append({"x": randf_range(0.0, W), "y": randf_range(26.0, 95.0), "vx": randf_range(16.0, 32.0) * (1.0 if randf() < 0.5 else -1.0), "ph": randf_range(0.0, TAU)})

	jellies.clear()
	var jcols := [Color("#4dffdf"), Color("#ff77e9"), Color("#80bfff"), Color("#b388ff")]
	for i in range(6):
		jellies.append({
			"x": randf_range(60.0, W - 60.0),
			"y": randf_range(SURF + 62.0 * PPM, bot - 60.0),
			"ph": randf_range(0.0, TAU),
			"vx": randf_range(-10.0, 10.0),
			"r": randf_range(11.0, 17.0),
			"color": jcols[i % jcols.size()],
		})

func pick_species(depth_m: float) -> Dictionary:
	var bait_lv := float(SaveManager.up("bait"))
	var bait_obj := SaveManager.active_bait()
	var biome := SaveManager.current_biome()
	var night := SaveManager.is_night()
	var w := SaveManager.get_weather()
	var eff_d := minf(depth_m, 148.0)

	var cands: Array[Dictionary] = []
	for s in GameData.species:
		if s.get("boss", false):
			continue
		if eff_d >= float(s["d"][0]) - 4.0 and eff_d <= float(s["d"][1]) + 4.0:
			cands.append(s)
	if cands.is_empty():
		return GameData.species[0]

	var boat_lv := int(SaveManager.data["lv"].get("boat", 0))
	var boat_rare := 1.35 if boat_lv >= 3 else (1.15 if boat_lv >= 2 else 1.0)
	var rare_boost := bait_lv * float(bait_obj["rare_mul"]) * float(biome["rare_mul"]) * float(w["rare_mul"]) * boat_rare * (1.25 if perfect_cast else 1.0) * (2.4 if hotspot_cast else 1.0) * (1.5 if frenzy_left > 0.0 else 1.0)

	var weights: Array[float] = []
	var total_w := 0.0
	for s in cands:
		var r_idx := int(s["r"])
		var wt := float(GameData.RARITIES[r_idx]["w"])
		if r_idx >= 2:
			wt *= rare_boost
		if night and r_idx >= 2:
			wt *= 1.55
		if night and s.has("night"):
			wt *= float(s["night"])
		if depth_m > 150.0 and r_idx >= 2:
			wt *= 1.6
		if s.has("home"):
			wt *= GameData.BIOME_HOME_MUL if (s["home"] as Array).has(str(biome["id"])) else GameData.BIOME_AWAY_MUL
		weights.append(wt)
		total_w += wt

	var pick := randf() * total_w
	for i in range(cands.size()):
		pick -= weights[i]
		if pick <= 0.0:
			return cands[i]
	return cands[cands.size() - 1]

func spawn_fish(initial: bool = false) -> void:
	var max_m := float(SaveManager.max_world_depth())
	var depth_m := randf_range(2.0, max_m - 2.0)
	var sp := pick_species(depth_m)
	var dm := randf_range(maxf(float(sp["d"][0]), 95.0), max_m - 3.0) if depth_m > 145.0 else clampf(depth_m, float(sp["d"][0]), float(sp["d"][1]))
	var dir := 1.0 if randf() < 0.5 else -1.0
	var kg_t := pow(randf(), 1.55)
	var weight_mul := float(SaveManager.current_biome()["weight_mul"]) * float(SaveManager.active_bait()["weight_mul"])
	var kg := lerpf(float(sp["kg"][0]), float(sp["kg"][1]), kg_t) * weight_mul
	var sc := GameData.fish_draw_scale(sp, kg_t)
	fishes.append({
		"sp": sp, "kg": kg, "scale": sc, "dir": dir,
		"base_y": SURF + dm * PPM, "y": SURF + dm * PPM,
		"x": randf_range(40.0, W - 40.0) if initial else (-80.0 if dir > 0.0 else W + 80.0),
		"vx": randf_range(float(sp["spd"][0]), float(sp["spd"][1])) * dir,
		"ph": randf_range(0.0, TAU), "amp": randf_range(4.0, 14.0),
		"hooked": false, "cool": 0.0, "alerted": 0.0, "is_boss": false,
	})

func spawn_boss() -> void:
	if not boss_ref.is_empty() and fishes.has(boss_ref):
		return
	var sp := GameData.get_boss_for_biome(str(SaveManager.data["biome"]))
	if sp.is_empty():
		return
	var md := float(SaveManager.max_depth())
	var dm := clampf(randf_range(minf(float(sp["d"][0]), md - 4.0), minf(float(sp["d"][1]), md + 6.0)), 18.0, float(SaveManager.max_world_depth()) - 5.0)
	var dir := 1.0 if randf() < 0.5 else -1.0
	var kg := lerpf(float(sp["kg"][0]), float(sp["kg"][1]), randf())
	var boss := {
		"sp": sp, "kg": kg, "scale": GameData.fish_draw_scale(sp, 1.0), "dir": dir,
		"base_y": SURF + dm * PPM, "y": SURF + dm * PPM,
		"x": -90.0 if dir > 0.0 else W + 90.0,
		"vx": randf_range(float(sp["spd"][0]), float(sp["spd"][1])) * dir,
		"ph": randf_range(0.0, TAU), "amp": 8.0,
		"hooked": false, "cool": 0.0, "alerted": 0.0, "is_boss": true,
	}
	fishes.append(boss)
	boss_ref = boss
	boss_changed.emit(true, "%s (~%dm)" % [str(sp["name"]), int(round(dm))])
	AudioManager.play("boss")
	screen_shake = 9.0
	SaveManager.toast_requested.emit("⚠️ %s %dm derinlikte görüldü!" % [str(sp["name"]), int(round(dm))])

func spawn_hazard(initial: bool = false) -> void:
	var max_m := float(SaveManager.max_world_depth())
	var dm := randf_range(50.0, max_m - 4.0)
	var dir := 1.0 if randf() < 0.5 else -1.0
	hazards.append({
		"spr": GameData.HAZARD_SPRITES[randi() % GameData.HAZARD_SPRITES.size()],
		"y": SURF + dm * PPM, "base_y": SURF + dm * PPM, "dir": dir,
		"x": randf_range(40.0, W - 40.0) if initial else (-80.0 if dir > 0.0 else W + 80.0),
		"vx": randf_range(32.0, 72.0) * dir, "ph": randf_range(0.0, TAU), "scale": randf_range(0.5, 0.75),
	})

func spawn_treasure() -> void:
	var max_m := minf(float(SaveManager.max_world_depth()) - 4.0, maxf(30.0, float(SaveManager.max_depth()) + 18.0))
	var t_type: Dictionary = GameData.TREASURE_TYPES[randi() % GameData.TREASURE_TYPES.size()]
	var dm := randf_range(minf(float(t_type["min_d"]), max_m - 5.0), max_m)
	treasures.append({
		"type": t_type, "x": randf_range(90.0, W - 90.0),
		"y": SURF + dm * PPM, "base_y": SURF + dm * PPM,
		"ph": randf_range(0.0, TAU), "vx": randf_range(-8.0, 8.0), "hooked": false,
	})

func spawn_hotspot() -> void:
	if hotspots.size() >= 2:
		return
	var min_x := 130.0 if int(SaveManager.data["lv"].get("boat", 0)) > 0 else 340.0
	hotspots.append({"x": randf_range(min_x, W - 90.0), "life": randf_range(16.0, 24.0), "ph": randf_range(0.0, TAU)})

func populate() -> void:
	fishes.clear()
	hazards.clear()
	treasures.clear()
	var target := int(round(24.0 + float(SaveManager.max_world_depth()) / 16.0))
	for i in range(target):
		spawn_fish(true)
	for i in range(7):
		spawn_hazard(true)
	for i in range(3):
		spawn_treasure()

# ---------------- Oyun Akışı ----------------
func set_game_state(new_state: String) -> void:
	state = new_state
	state_changed.emit(state)

func start_charge() -> void:
	if state != "idle":
		return
	set_game_state("charging")
	cast_power = 8.0
	cast_dir = 1.0
	cast_meter_changed.emit(true, cast_power)
	hint_changed.emit("Yeşil bölgede bırak: Mükemmel Atış!")

func release_charge() -> void:
	if state != "charging":
		return
	cast_meter_changed.emit(false, cast_power)
	var is_perf := cast_power >= 68.0 and cast_power <= 88.0
	cast(is_perf)

func action() -> void:
	if state == "idle":
		cast(false)
	elif state == "sinking":
		set_game_state("rising")
		hint_changed.emit("Sarılıyor… iğneyi yönlendirmeye devam edebilirsin")

func cast(is_perfect: bool = false) -> void:
	set_game_state("sinking")
	perfect_cast = is_perfect
	var tip := rod_tip_pos()
	var dist := 85.0 if is_perfect else (25.0 + cast_power * 0.6)
	hook["x"] = clampf(tip.x + dist, 30.0, W - 30.0)
	hook["tx"] = hook["x"]
	hook["y"] = SURF - 30.0
	hook["bait"] = true
	hook["fish"] = {}
	hook["treasure"] = {}
	hook["at_max"] = false
	SaveManager.data["casts"] = int(SaveManager.data["casts"]) + 1

	hotspot_cast = false
	for i in range(hotspots.size() - 1, -1, -1):
		if absf(float(hook["x"]) - float(hotspots[i]["x"])) < 78.0:
			hotspot_cast = true
			hotspots.remove_at(i)
			add_float_text(float(hook["x"]), SURF - 68.0, "✨ BALIK SÜRÜSÜ! x2.4 Nadir", Color("#ffd43b"), 18)
			AudioManager.play("perfect")
			break

	var casts := int(SaveManager.data["casts"])
	if boss_ref.is_empty() and casts >= 4 and (casts % 7 == 0 or randf() < 0.14):
		spawn_boss()

	AudioManager.play("whoosh")
	add_ripple(float(hook["x"]))
	splash_particles(float(hook["x"]), 22 if is_perfect else 14)

	if is_perfect:
		SaveManager.data["stats"]["perfect_casts"] = int(SaveManager.data["stats"].get("perfect_casts", 0)) + 1
		SaveManager.progress_missions("perfect", 1.0)
		AudioManager.play("perfect")
		add_float_text(float(hook["x"]), SURF - 42.0, "🎯 MÜKEMMEL ATIŞ!", Color("#7aff9e"), 20)
		SaveManager.check_achievements()
	SaveManager.save_game()
	hint_changed.emit("İğne batıyor — ← → ile yönlendir • tekrar bas: sar")

func start_fight(f: Dictionary) -> void:
	set_game_state("fight")
	f["hooked"] = true
	hook["fish"] = f
	var sp: Dictionary = f["sp"]
	var beh_id := GameData.fish_behavior(sp)
	var beh: Dictionary = GameData.BEHAVIORS[beh_id]
	var tol := float(SaveManager.up("line")) / 100.0
	var width := (40.0 + tol * 30.0) * float(beh["width"])
	var center := 48.0 + float(beh["bias"])
	fight = {
		"f": f, "beh": beh_id, "tension": 34.0, "progress": 0.0, "slack": 0.0,
		"surge": 0.0, "warn_t": 0.0, "surge_t": randf_range(1.5, 2.6),
		"width": width, "center": center, "lo": center - width * 0.5, "hi": center + width * 0.5,
		"shake": 0.0, "phase": "hook", "hook_t": 0.0, "hook_win": 0.62 if beh_id == "kacak" else 0.8,
		"stamina": 100.0, "pull": 0, "pull_t": randf_range(2.2, 4.0), "pull_left": 0.0,
		"time": 0.0, "zone_time": 0.0, "slack_lim": 2.5, "hook_q": "", "tired_said": false,
		"seed": randf() * 10.0,
	}
	var r_idx := int(sp["r"])
	var title := "👑 EFSANEVİ CANAVAR!" if r_idx >= 4 else ("⚡ Güçlü bir şey vurdu!" if r_idx >= 3 else "🐟 Balık vurdu!")
	title += "  %s %s" % [str(beh["icon"]), str(beh["name"])]
	hint_changed.emit("")
	fight_started.emit(title, float(fight["lo"]), float(fight["hi"]))
	_emit_fight_state()
	AudioManager.play("bite")
	screen_shake = maxf(screen_shake, 4.0)

## Oyuncu çekişme sırasında tuşa/fareye BASTIĞI an (kanca atma için)
func on_fight_press() -> void:
	if state == "fight" and not fight.is_empty() and str(fight["phase"]) == "hook":
		var ht := float(fight["hook_t"])
		_resolve_hookset("perfect" if ht <= 0.28 else "good")

func _resolve_hookset(q: String) -> void:
	fight["phase"] = "fight"
	fight["hook_q"] = q
	var f: Dictionary = fight["f"]
	var fx := float(f["x"])
	var fy := float(f["y"]) - 26.0
	match q:
		"perfect":
			fight["progress"] = 0.18
			fight["stamina"] = 88.0
			fight["tension"] = 46.0
			var st: Dictionary = SaveManager.data["stats"]
			st["perfect_hooks"] = int(st.get("perfect_hooks", 0)) + 1
			add_float_text(fx, fy, "🎯 KUSURSUZ KANCA!", Color("#7dffb0"), 18)
			AudioManager.play("perfect")
		"good":
			fight["progress"] = 0.07
			fight["tension"] = 42.0
			add_float_text(fx, fy, "👍 Kanca oturdu", Color("#e8f6ff"), 16)
		_:
			fight["progress"] = 0.0
			fight["tension"] = 24.0
			fight["slack_lim"] = 1.6
			fight["surge_t"] = 0.35
			add_float_text(fx, fy, "😬 Kanca zayıf tuttu!", Color("#ffb4a2"), 16)
			AudioManager.play("warn")
	hookset_result.emit(q)

func _emit_fight_state() -> void:
	if fight.is_empty():
		return
	fight_state.emit({
		"phase": str(fight["phase"]), "zone_lo": float(fight["lo"]), "zone_hi": float(fight["hi"]),
		"stamina": float(fight["stamina"]), "pull": int(fight["pull"]),
		"hook_left": maxf(0.0, float(fight["hook_win"]) - float(fight["hook_t"])), "beh": str(fight["beh"]),
		"surging": float(fight["surge"]) > 0.0,
	})

func end_fight(ok: bool, why: String = "") -> void:
	fight_ended.emit()
	var f: Dictionary = fight["f"]
	last_fight = {
		"hook_q": str(fight.get("hook_q", "")), "secs": float(fight.get("time", 0.0)),
		"zone_pct": float(fight.get("zone_time", 0.0)) / maxf(0.01, float(fight.get("time", 0.0))),
		"beh": str(fight.get("beh", "")),
	}
	fight = {}
	if ok:
		set_game_state("rising")
		hook["fish"] = f
		hook["bait"] = false
		hint_changed.emit("Yakaladın! Yüzeye çekiliyor…")
	else:
		f["hooked"] = false
		f["cool"] = 3.5
		f["vx"] = absf(float(f["vx"])) * 1.9 * (1.0 if randf() < 0.5 else -1.0)
		hook["fish"] = {}
		hook["bait"] = false
		combo = 0
		SaveManager.consume_bait()
		set_game_state("rising")
		screen_shake = 10.0
		if why == "snap":
			SaveManager.toast_requested.emit("💥 Misina koptu! (Kombo sıfırlandı)")
			AudioManager.play("snap")
		else:
			SaveManager.toast_requested.emit("💨 Balık kaçtı…")
			AudioManager.play("escape")
		hint_changed.emit("Yemin gitti, yüzeye dönülüyor")

func land_catch() -> void:
	var f: Dictionary = hook["fish"]
	hook["fish"] = {}
	fishes.erase(f)

	combo += 1
	if combo > int(SaveManager.data["stats"].get("max_combo", 0)):
		SaveManager.data["stats"]["max_combo"] = combo

	var sp: Dictionary = f["sp"]
	var kg := float(f["kg"])
	var depth_m := maxi(1, int(round((float(f["base_y"]) - SURF) / PPM)))
	var hot := SaveManager.is_hot_demand(sp)
	var value := SaveManager.calc_fish_value(sp, kg, depth_m, combo, frenzy_left > 0.0, true)
	var base_val := SaveManager.calc_fish_value(sp, kg, depth_m, combo, frenzy_left > 0.0, false)
	var xp_gain := int(round(14.0 + float(sp["r"]) * 16.0 + float(depth_m) * 0.25 + kg * 2.0))
	if str(last_fight.get("hook_q", "")) == "perfect":
		xp_gain = int(round(float(xp_gain) * 1.15))

	var book: Dictionary = SaveManager.data["book"]
	var sp_id := str(sp["id"])
	var is_new := not book.has(sp_id)
	var prev: Dictionary = book.get(sp_id, {})
	var is_record := (not is_new) and kg > float(prev.get("max", 0.0))
	book[sp_id] = {
		"n": int(prev.get("n", 0)) + 1,
		"max": maxf(float(prev.get("max", 0.0)), kg),
		"deep": maxi(int(prev.get("deep", 0)), depth_m),
	}

	var st: Dictionary = SaveManager.data["stats"]
	if kg > float(st.get("heaviest", 0.0)):
		st["heaviest"] = snappedf(kg, 0.01)
	if depth_m > int(st.get("deepest", 0)):
		st["deepest"] = depth_m
	if SaveManager.is_night():
		st["night_catches"] = int(st.get("night_catches", 0)) + 1
	if bool(SaveManager.get_weather()["rain"]):
		st["rain_catches"] = int(st.get("rain_catches", 0)) + 1
	if int(sp["r"]) >= 4:
		st["legendaries"] = int(st.get("legendaries", 0)) + 1

	if bool(f.get("is_boss", false)) or bool(sp.get("boss", false)):
		st["bosses"] = int(st.get("bosses", 0)) + 1
		SaveManager.data["baits"]["golden"] = int(SaveManager.data["baits"].get("golden", 0)) + 3
		boss_ref = {}
		boss_changed.emit(false, "")
		SaveManager.toast_requested.emit("👑 BÖLGE BOSSU YAKALANDI! (+3 Altın Yem ödülü!)")
		spawn_confetti(W * 0.5, H * 0.35, 60)
		AudioManager.play("tourney")

	if not active_tourney.is_empty():
		var def: Dictionary = active_tourney["def"]
		var add := kg if str(def["goal_kind"]) == "kg" else float(value)
		active_tourney["prog"] = snappedf(float(active_tourney["prog"]) + add, 0.01)
		if float(active_tourney["prog"]) >= float(def["goal"]):
			finish_tournament(true)

	SaveManager.progress_missions("catch_any", 1.0)
	SaveManager.progress_missions("catch_kg", kg)
	if int(sp["r"]) >= 2:
		SaveManager.progress_missions("catch_rare", 1.0)
	SaveManager.progress_missions("catch_deep", 1.0, depth_m)
	if SaveManager.is_night():
		SaveManager.progress_missions("catch_night", 1.0)

	SaveManager.consume_bait()
	SaveManager.add_xp(xp_gain)

	if frenzy_left <= 0.0 and combo >= 3 and randf() < 0.28:
		frenzy_left = 35.0
		SaveManager.toast_requested.emit("✨ ALTIN BALIK AKINI BAŞLADI! 35 sn boyunca 2x Altın!")
		AudioManager.play("level_up")

	SaveManager.data["minutes"] = int(SaveManager.data["minutes"]) + 20
	SaveManager.ensure_market()
	SaveManager.check_achievements()
	SaveManager.save_game()

	if int(sp["r"]) >= 2 or is_new or is_record:
		spawn_confetti(W * 0.5, H * 0.4, 42 if int(sp["r"]) >= 3 else 22)
	AudioManager.play("catch")

	set_game_state("catch")
	fish_landed.emit({
		"sp": sp, "kg": kg, "depth_m": depth_m, "value": value, "base_val": base_val,
		"xp_gain": xp_gain, "is_new": is_new, "is_record": is_record, "hot": hot,
		"combo_snap": combo, "frenzy_snap": frenzy_left > 0.0, "fight": last_fight.duplicate(),
	})
	last_fight = {}

func land_treasure() -> void:
	var tr: Dictionary = hook["treasure"]
	hook["treasure"] = {}
	treasures.erase(tr)

	var t_type: Dictionary = tr["type"]
	var biome := SaveManager.current_biome()
	var gold := int(round(randf_range(float(t_type["gold"][0]), float(t_type["gold"][1])) * float(biome["val_mul"])))
	var xp_gain := int(t_type["xp"])
	var bonus_bait: Dictionary = {}
	if randf() < 0.55:
		var paid_baits: Array[Dictionary] = []
		for b in GameData.BAITS:
			if not b["infinite"]:
				paid_baits.append(b)
		bonus_bait = paid_baits[randi() % paid_baits.size()]
		var bid := str(bonus_bait["id"])
		SaveManager.data["baits"][bid] = int(SaveManager.data["baits"].get(bid, 0)) + 2

	SaveManager.data["money"] = int(SaveManager.data["money"]) + gold
	SaveManager.data["total"] = int(SaveManager.data["total"]) + gold
	SaveManager.data["stats"]["treasures"] = int(SaveManager.data["stats"].get("treasures", 0)) + 1
	SaveManager.progress_missions("treasure", 1.0)
	SaveManager.add_xp(xp_gain)
	SaveManager.consume_bait()
	SaveManager.data["minutes"] = int(SaveManager.data["minutes"]) + 15
	SaveManager.check_achievements()
	SaveManager.save_game()

	var desc := str(t_type.get("desc", ""))
	if t_type.has("notes"):
		var notes: Array = t_type["notes"]
		desc = str(notes[randi() % notes.size()])

	spawn_confetti(W * 0.5, H * 0.42, 34)
	AudioManager.play("treasure")
	set_game_state("treasure")
	treasure_landed.emit({"type": t_type, "gold": gold, "xp_gain": xp_gain, "bonus_bait": bonus_bait, "desc": desc})

func return_empty() -> void:
	SaveManager.data["minutes"] = int(SaveManager.data["minutes"]) + 15
	SaveManager.ensure_market()
	SaveManager.save_game()
	set_game_state("idle")
	hint_changed.emit(_idle_hint())

func _idle_hint() -> String:
	if int(SaveManager.data["lv"].get("boat", 0)) > 0:
		return "← → tekneyi sür • Boşluk: basılı tut & bırak"
	return "Atmak için basılı tut (Mükemmel Atış!) veya tıkla 🎣"

# ---------------- Turnuva ----------------
func start_tournament(id: String) -> bool:
	if not active_tourney.is_empty():
		return false
	for tr in GameData.TOURNAMENTS:
		if str(tr["id"]) == id:
			active_tourney = {"def": tr, "left": float(tr["duration"]), "prog": 0.0}
			AudioManager.play("tourney")
			SaveManager.toast_requested.emit("🏁 %s başladı! 90 saniyen var!" % str(tr["name"]))
			tourney_changed.emit(true, str(tr["name"]), "0 / %d" % int(tr["goal"]), 0.0, int(tr["duration"]))
			return true
	return false

func finish_tournament(won: bool) -> void:
	if active_tourney.is_empty():
		return
	var def: Dictionary = active_tourney["def"]
	active_tourney = {}
	tourney_changed.emit(false, "", "", 0.0, 0)
	if won:
		var rew_gold := int(def["reward_gold"])
		SaveManager.data["money"] = int(SaveManager.data["money"]) + rew_gold
		SaveManager.data["total"] = int(SaveManager.data["total"]) + rew_gold
		SaveManager.data["stats"]["tourney_wins"] = int(SaveManager.data["stats"].get("tourney_wins", 0)) + 1
		var tid := str(def["id"])
		SaveManager.data["tourney_best"][tid] = int(SaveManager.data["tourney_best"].get(tid, 0)) + 1
		var rb := str(def.get("reward_bait", ""))
		if not rb.is_empty():
			SaveManager.data["baits"][rb] = int(SaveManager.data["baits"].get(rb, 0)) + 3
		SaveManager.add_xp(int(def["reward_xp"]))
		SaveManager.check_achievements()
		SaveManager.save_game()
		spawn_confetti(W * 0.5, H * 0.36, 55)
		AudioManager.play("tourney")
		SaveManager.toast_requested.emit("🏆 %s KAZANILDI! +%d altın & +3 özel yem!" % [str(def["name"]), rew_gold])
		add_float_text(W * 0.5, H * 0.42, "🏆 TURNUVA ŞAMPİYONU!", Color("#ffd43b"), 24, true)
	else:
		AudioManager.play("escape")
		SaveManager.toast_requested.emit("⏱️ Turnuva süresi doldu! Tekrar deneyebilirsin (T)")

# ---------------- Ana Döngü ----------------
func _process(delta: float) -> void:
	var dt := minf(0.05, delta)
	t += dt
	if state != "menu":
		SaveManager.tick_aquarium_income(dt)
		SaveManager.tick_play_time(dt)

	if state in ["idle", "charging", "sinking", "rising", "fight"]:
		_update_gameplay(dt)
	else:
		for f in fishes:
			if not bool(f["hooked"]):
				f["x"] = float(f["x"]) + float(f["vx"]) * dt * 0.6
				f["ph"] = float(f["ph"]) + dt * 2.0
				f["y"] = float(f["base_y"]) + sin(float(f["ph"])) * float(f["amp"])
		fishes = fishes.filter(func(f): return bool(f["hooked"]) or (float(f["x"]) > -140.0 and float(f["x"]) < W + 140.0))
		while fishes.size() < 26:
			spawn_fish()
		_update_particles(dt)

	hud_dirty.emit()
	queue_redraw()

func _update_gameplay(dt: float) -> void:
	if screen_shake > 0.0:
		screen_shake = maxf(0.0, screen_shake - dt * 28.0)

	if frenzy_left > 0.0:
		frenzy_left = maxf(0.0, frenzy_left - dt)
		frenzy_changed.emit(frenzy_left)

	if not active_tourney.is_empty():
		active_tourney["left"] = float(active_tourney["left"]) - dt
		var def: Dictionary = active_tourney["def"]
		var pct := clampf(float(active_tourney["prog"]) / float(def["goal"]), 0.0, 1.0)
		var unit := "kg" if str(def["goal_kind"]) == "kg" else "altın"
		var p_txt := ("%.1f" % float(active_tourney["prog"])) if str(def["goal_kind"]) == "kg" else str(int(round(float(active_tourney["prog"]))))
		tourney_changed.emit(true, str(def["name"]), "%s / %d %s" % [p_txt, int(def["goal"]), unit], pct, maxi(0, int(ceil(float(active_tourney["left"])))))
		if float(active_tourney["left"]) <= 0.0:
			finish_tournament(false)

	var steer := (-1.0 if input_left else 0.0) + (1.0 if input_right else 0.0)
	var boat_lv := int(SaveManager.data["lv"].get("boat", 0))
	if state == "idle" and boat_lv > 0 and steer != 0.0:
		var spds := [0.0, 125.0, 195.0, 260.0]
		boat_x = clampf(boat_x + steer * spds[clampi(boat_lv, 0, 3)] * dt, 120.0, W - 140.0)
		if randf() < dt * 7.0:
			add_ripple(boat_x - steer * 24.0)

	next_hotspot_t -= dt
	if next_hotspot_t <= 0.0:
		spawn_hotspot()
		next_hotspot_t = randf_range(11.0, 18.0)
	for hs in hotspots:
		hs["life"] = float(hs["life"]) - dt
		hs["ph"] = float(hs["ph"]) + dt * 4.0
		if randf() < dt * 2.5:
			add_ripple(float(hs["x"]) + randf_range(-24.0, 24.0))
	hotspots = hotspots.filter(func(hs): return float(hs["life"]) > 0.0)

	if state == "charging":
		cast_power += cast_dir * 135.0 * dt
		if cast_power >= 100.0:
			cast_power = 100.0
			cast_dir = -1.0
		elif cast_power <= 0.0:
			cast_power = 0.0
			cast_dir = 1.0
		cast_meter_changed.emit(true, cast_power)

	var bait := SaveManager.active_bait()
	var attract_r := 68.0 * float(bait["attract_r"]) * (1.45 if frenzy_left > 0.0 else 1.0) * (1.35 if not active_tourney.is_empty() else 1.0) * (1.3 if hotspot_cast else 1.0)
	var can_lure := (state == "sinking" or state == "rising") and bool(hook["bait"]) and float(hook["y"]) > SURF + 12.0

	for f in fishes:
		if bool(f["hooked"]):
			continue
		f["cool"] = maxf(0.0, float(f["cool"]) - dt)
		f["alerted"] = maxf(0.0, float(f["alerted"]) - dt)
		var dx := float(hook["x"]) - float(f["x"])
		var dy := float(hook["y"]) - float(f["y"])
		var dist := sqrt(dx * dx + dy * dy)
		if can_lure and float(f["cool"]) <= 0.0 and dist < attract_r and dist > 12.0:
			f["alerted"] = 0.5
			f["dir"] = 1.0 if dx >= 0.0 else -1.0
			var pull_spd := maxf(absf(float(f["vx"])), 65.0) * 1.25
			f["x"] = float(f["x"]) + (dx / dist) * pull_spd * dt
			f["y"] = float(f["y"]) + (dy / dist) * pull_spd * 0.65 * dt
			f["base_y"] = lerpf(float(f["base_y"]), float(f["y"]), dt * 1.5)
		else:
			f["x"] = float(f["x"]) + float(f["vx"]) * dt
			f["ph"] = float(f["ph"]) + dt * 2.0
			f["y"] = float(f["base_y"]) + sin(float(f["ph"])) * float(f["amp"])

	var fish_target := int(round((24.0 + float(SaveManager.max_world_depth()) / 16.0) * (1.3 if not active_tourney.is_empty() else 1.0)))
	fishes = fishes.filter(func(f): return bool(f["hooked"]) or (float(f["x"]) > -140.0 and float(f["x"]) < W + 140.0))
	if not boss_ref.is_empty() and not fishes.has(boss_ref):
		boss_ref = {}
		boss_changed.emit(false, "")
	while fishes.size() < fish_target:
		spawn_fish()

	for h in hazards:
		if can_lure and bool(bait["anti_hazard"]):
			var dx := float(h["x"]) - float(hook["x"])
			var dy := float(h["y"]) - float(hook["y"])
			var dist := sqrt(dx * dx + dy * dy)
			if dist < 110.0 and dist > 1.0:
				h["dir"] = 1.0 if dx >= 0.0 else -1.0
				h["x"] = float(h["x"]) + (dx / dist) * 110.0 * dt
			else:
				h["x"] = float(h["x"]) + float(h["vx"]) * dt
		else:
			h["x"] = float(h["x"]) + float(h["vx"]) * dt
		h["ph"] = float(h["ph"]) + dt * 1.5
		h["y"] = float(h["base_y"]) + sin(float(h["ph"])) * 10.0
	hazards = hazards.filter(func(h): return float(h["x"]) > -140.0 and float(h["x"]) < W + 140.0)
	while hazards.size() < 7:
		spawn_hazard()

	for tr in treasures:
		if bool(tr["hooked"]):
			continue
		tr["ph"] = float(tr["ph"]) + dt * 1.8
		tr["x"] = float(tr["x"]) + float(tr["vx"]) * dt
		if float(tr["x"]) < 60.0 or float(tr["x"]) > W - 60.0:
			tr["vx"] = -float(tr["vx"])
		tr["y"] = float(tr["base_y"]) + sin(float(tr["ph"])) * 5.0
	var desired_tr := 6 if float(bait["treasure_mul"]) > 2.0 else 3
	while treasures.size() < desired_tr:
		spawn_treasure()

	var max_y := SURF + float(SaveManager.max_depth()) * PPM
	if pointer_x >= 0.0 and dragging:
		hook["tx"] = pointer_x
	elif steer != 0.0 and (state == "sinking" or state == "rising"):
		hook["tx"] = clampf(float(hook["x"]) + steer * 155.0, 20.0, W - 20.0)

	if state == "sinking" or state == "rising":
		hook["x"] = clampf(float(hook["x"]) + clampf(float(hook["tx"]) - float(hook["x"]), -300.0 * dt, 300.0 * dt), 16.0, W - 16.0)

	if state == "sinking":
		if int(SaveManager.up("sonar")) > 0 and randf() < dt * 0.75:
			AudioManager.play("sonar")
		var sink_boost := 1.32 if perfect_cast else 1.0
		hook["y"] = float(hook["y"]) + (155.0 + float(SaveManager.max_depth()) * 0.65) * sink_boost * dt
		if float(hook["y"]) >= max_y:
			hook["y"] = max_y
			if not bool(hook["at_max"]):
				hook["at_max"] = true
				SaveManager.toast_requested.emit("Misinanın sonu: %d m" % SaveManager.max_depth())
				hint_changed.emit("Daha derin için oltanı geliştir • bas: sar")
		else:
			hook["at_max"] = false

	if state == "rising":
		var has_load := (not (hook["fish"] as Dictionary).is_empty()) or (not (hook["treasure"] as Dictionary).is_empty())
		var sp := (350.0 if has_load else 270.0) * (1.0 + float(SaveManager.up("reel")) / 100.0)
		hook["y"] = float(hook["y"]) - sp * dt
		var tip := rod_tip_pos()
		if float(hook["y"]) < SURF + 80.0:
			hook["x"] = float(hook["x"]) + (tip.x + 20.0 - float(hook["x"])) * dt * 3.0
		if float(hook["y"]) <= SURF - 30.0:
			hook["y"] = SURF - 30.0
			add_ripple(float(hook["x"]))
			AudioManager.play("splash")
			if not (hook["fish"] as Dictionary).is_empty():
				land_catch()
			elif not (hook["treasure"] as Dictionary).is_empty():
				land_treasure()
			else:
				return_empty()

	if state == "idle" or state == "charging":
		var tip := rod_tip_pos()
		hook["x"] = float(hook["x"]) + (tip.x + 20.0 - float(hook["x"])) * dt * 6.0
		hook["y"] = SURF - 34.0 + sin(t * 2.0) * 3.0

	# Çarpışmalar
	if (state == "sinking" or state == "rising") and bool(hook["bait"]) and float(hook["y"]) > SURF + 6.0:
		for tr in treasures:
			if bool(tr["hooked"]):
				continue
			var grab_r := 42.0 if float(bait["treasure_mul"]) > 2.0 else 26.0
			if Vector2(float(tr["x"]) - float(hook["x"]), float(tr["y"]) - float(hook["y"])).length() < grab_r:
				tr["hooked"] = true
				hook["treasure"] = tr
				hook["bait"] = false
				set_game_state("rising")
				AudioManager.play("coin")
				add_float_text(float(tr["x"]), float(tr["y"]) - 20.0, "✨ HAZİNE BULUNDU!", Color("#ffe066"), 18)
				hint_changed.emit("Batık hazine yüzeye çekiliyor!")
				break

		if bool(hook["bait"]) and not bool(bait["anti_hazard"]):
			for h in hazards:
				if absf(float(h["x"]) - float(hook["x"])) < 32.0 * float(h["scale"]) + 6.0 and absf(float(h["y"]) - float(hook["y"])) < 20.0 * float(h["scale"]) + 6.0:
					hook["bait"] = false
					set_game_state("rising")
					combo = 0
					SaveManager.consume_bait()
					screen_shake = 8.0
					SaveManager.toast_requested.emit("🦴 Kemik Balık yemini çaldı!")
					AudioManager.play("steal")
					hint_changed.emit("Yemsiz iğne yüzeye dönüyor")
					break

		if bool(hook["bait"]):
			for f in fishes:
				if float(f["cool"]) > 0.0 or bool(f["hooked"]):
					continue
				var tex := GameData.get_fish_texture(str(f["sp"]["spr"]))
				var iw := (float(tex.get_width()) if tex != null else 100.0) * float(f["scale"])
				var ih := (float(tex.get_height()) if tex != null else 50.0) * float(f["scale"])
				var nx := float(f["x"]) + float(f["dir"]) * iw * 0.36
				if absf(nx - float(hook["x"])) < 12.0 + iw * 0.14 and absf(float(f["y"]) - float(hook["y"])) < ih * 0.42 + 9.0:
					start_fight(f)
					break

	# Çekme mini-oyunu
	if state == "fight" and not fight.is_empty():
		_update_fight(dt, max_y)

	if not (hook["fish"] as Dictionary).is_empty() and state == "rising":
		var f: Dictionary = hook["fish"]
		f["x"] = hook["x"]
		f["y"] = float(hook["y"]) + 14.0
		f["dir"] = 1.0 if sin(t * 9.0) > 0.0 else -1.0
	if not (hook["treasure"] as Dictionary).is_empty() and state == "rising":
		hook["treasure"]["x"] = hook["x"]
		hook["treasure"]["y"] = float(hook["y"]) + 14.0

	var want := 0.0 if state in ["idle", "charging", "menu", "catch", "treasure"] else float(hook["y"]) - H * 0.42
	cam_y = lerpf(cam_y, clampf(want, 0.0, bottom_y() + 70.0 - H), minf(1.0, dt * 5.0))

	_update_particles(dt)

func _update_fight(dt: float, max_y: float) -> void:
	var f: Dictionary = fight["f"]
	var sp: Dictionary = f["sp"]
	var beh: Dictionary = GameData.BEHAVIORS[str(fight["beh"])]
	var str_val := float(sp["str"]) * (0.85 + clampf(GameData.size_ratio(sp, float(f["kg"])), 0.0, 1.4) * 0.35)

	# 1) Kanca atma anı: balık vurdu, oyuncunun hemen basması gerekir
	if str(fight["phase"]) == "hook":
		fight["hook_t"] = float(fight["hook_t"]) + dt
		f["x"] = float(hook["x"]) + sin(t * 30.0) * 5.0
		f["y"] = float(hook["y"]) + 10.0
		fight["shake"] = 1.0
		if float(fight["hook_t"]) >= float(fight["hook_win"]):
			_resolve_hookset("miss")
		_emit_fight_state()
		fight_updated.emit(float(fight["tension"]), float(fight["progress"]), false)
		return

	fight["time"] = float(fight["time"]) + dt
	var stamina := float(fight["stamina"])
	var tired := stamina < 25.0
	if tired and not bool(fight["tired_said"]):
		fight["tired_said"] = true
		add_float_text(float(f["x"]), float(f["y"]) - 28.0, "😮‍💨 Balık yoruldu!", Color("#ffe066"), 16)

	# 2) Hareketli yeşil bölge (balığın karakterine göre)
	var tm := float(fight["time"]) * float(beh["freq"])
	var sd := float(fight["seed"])
	var amp := float(beh["amp"]) * (0.5 if tired else 1.0)
	var width := float(fight["width"]) * (1.25 if tired else 1.0)
	var center := 48.0 + float(beh["bias"]) + amp * (0.7 * sin(tm * 2.1 + sd) + 0.3 * sin(tm * 5.3 + sd * 1.7))
	if int(fight["pull"]) != 0:
		center += 6.0
	center = clampf(center, width * 0.5 + 6.0, 91.0 - width * 0.5)
	fight["center"] = center
	fight["lo"] = center - width * 0.5
	fight["hi"] = center + width * 0.5

	# 3) Hamle (surge) — zıplayan balık sudan fırlar, dalgıç dibe çeker
	if float(fight["warn_t"]) > 0.0:
		fight["warn_t"] = float(fight["warn_t"]) - dt
		if float(fight["warn_t"]) <= 0.0:
			fight["surge"] = randf_range(0.45, 0.85)
			if str(fight["beh"]) == "ziplayan":
				splash_particles(float(f["x"]), 10)
	elif float(fight["surge"]) <= 0.0:
		fight["surge_t"] = float(fight["surge_t"]) - dt
		if float(fight["surge_t"]) <= 0.0:
			fight["warn_t"] = 0.5
			fight["surge_t"] = randf_range(1.4, 2.9) / (0.62 + str_val * 0.14) * (1.6 if tired else 1.0)
			AudioManager.play("warn")
	var surging := float(fight["surge"]) > 0.0
	fight["surge"] = maxf(0.0, float(fight["surge"]) - dt)

	# 4) Yan çekiş: balık sağa/sola kaçar, ters yöne bas!
	if int(fight["pull"]) == 0:
		fight["pull_t"] = float(fight["pull_t"]) - dt
		if float(fight["pull_t"]) <= 0.0 and not surging:
			if randf() < float(beh["pull"]) + 0.15:
				fight["pull"] = -1 if randf() < 0.5 else 1
				fight["pull_left"] = randf_range(1.3, 2.1)
				AudioManager.play("warn")
			fight["pull_t"] = randf_range(2.4, 4.6)
	else:
		fight["pull_left"] = float(fight["pull_left"]) - dt
		if float(fight["pull_left"]) <= 0.0:
			fight["pull"] = 0
	var pull := int(fight["pull"])
	var drag := (pointer_x - pointer_down_x) if (input_hold and pointer_x >= 0.0) else 0.0
	var go_right := (input_right and not input_left) or drag > 30.0
	var go_left := (input_left and not input_right) or drag < -30.0
	var countering := (pull < 0 and go_right) or (pull > 0 and go_left)

	var reel_mul := 1.0 + float(SaveManager.up("reel")) / 100.0
	var in_zone := float(fight["tension"]) >= float(fight["lo"]) and float(fight["tension"]) <= float(fight["hi"])

	if input_hold:
		fight["tension"] = float(fight["tension"]) + (25.0 + str_val * 7.8) * dt
		var gain := (0.21 if in_zone else 0.07) * reel_mul / (0.55 + str_val * 0.17)
		if tired:
			gain *= 1.35
		fight["progress"] = float(fight["progress"]) + gain * dt
		if randf() < dt * 13.0:
			AudioManager.play("click")
	else:
		fight["tension"] = float(fight["tension"]) - 42.0 * dt
		fight["progress"] = float(fight["progress"]) - 0.014 * str_val * dt

	if in_zone:
		fight["zone_time"] = float(fight["zone_time"]) + dt
		stamina -= 7.0 / (0.6 + str_val * 0.12) * dt
	else:
		stamina -= 1.2 * dt

	if pull != 0:
		if countering:
			fight["tension"] = float(fight["tension"]) - 9.0 * dt
			fight["progress"] = float(fight["progress"]) + 0.045 * dt
			stamina -= 6.0 * dt
		else:
			fight["tension"] = float(fight["tension"]) + (8.0 + str_val * 3.0) * dt
			fight["progress"] = float(fight["progress"]) - 0.02 * dt
		hook["x"] = clampf(float(hook["x"]) + float(pull) * (8.0 if countering else 38.0) * dt, 30.0, W - 30.0)

	if surging:
		var power := str_val * 21.0 * float(beh["surge_mul"]) * (0.45 + 0.55 * clampf(stamina / 100.0, 0.0, 1.0))
		fight["tension"] = float(fight["tension"]) + power * dt
		fight["progress"] = float(fight["progress"]) - 0.025 * str_val * dt
		if str(fight["beh"]) == "ziplayan" and input_hold:
			fight["tension"] = float(fight["tension"]) + 32.0 * dt
		if str(fight["beh"]) == "dalgic":
			hook["y"] = minf(max_y, float(hook["y"]) + 26.0 * dt)
			fight["progress"] = float(fight["progress"]) - 0.015 * dt
		fight["shake"] = 1.0
		screen_shake = maxf(screen_shake, 6.0 if int(sp["r"]) >= 3 else 3.0)

	fight["stamina"] = clampf(stamina, 0.0, 100.0)
	fight["tension"] = clampf(float(fight["tension"]), 0.0, 110.0)
	fight["progress"] = clampf(float(fight["progress"]), 0.0, 1.0)
	fight["shake"] = maxf(0.0, float(fight["shake"]) - dt * 3.0)
	if float(fight["tension"]) < 15.0:
		fight["slack"] = float(fight["slack"]) + dt
	else:
		fight["slack"] = maxf(0.0, float(fight["slack"]) - dt * 2.0)

	f["dir"] = float(pull) if pull != 0 else (1.0 if sin(t * 3.0) > 0.0 else -1.0)
	var jump := 0.0
	if surging and str(fight["beh"]) == "ziplayan":
		jump = -sin(clampf(float(fight["surge"]) / 0.85, 0.0, 1.0) * PI) * 34.0
	f["x"] = float(hook["x"]) + sin(t * (15.0 if surging else 5.0)) * (15.0 if surging else 6.0)
	f["y"] = float(hook["y"]) + 10.0 + jump
	hook["y"] = clampf(float(hook["y"]) - (14.0 * reel_mul if input_hold else -4.0) * dt, SURF + 20.0, max_y)

	_emit_fight_state()
	fight_updated.emit(float(fight["tension"]), float(fight["progress"]), float(fight["warn_t"]) > 0.0)
	if float(fight["tension"]) >= 100.0:
		end_fight(false, "snap")
	elif float(fight["slack"]) > float(fight["slack_lim"]):
		end_fight(false, "escape")
	elif float(fight["progress"]) >= 1.0:
		end_fight(true)

func _update_particles(dt: float) -> void:
	for b in birds:
		b["x"] = float(b["x"]) + float(b["vx"]) * dt
		b["ph"] = float(b["ph"]) + dt * 7.0
		if float(b["x"]) < -40.0: b["x"] = W + 40.0
		elif float(b["x"]) > W + 40.0: b["x"] = -40.0

	next_jumper_t -= dt
	if next_jumper_t <= 0.0 and cam_y < SURF:
		next_jumper_t = randf_range(6.0, 13.0)
		var jx := randf_range(360.0, W - 80.0)
		var jdir := 1.0 if randf() < 0.5 else -1.0
		var j_sprs := ["fish_pink", "fish_orange", "fish_blue"]
		jumpers.append({"x": jx, "y": SURF + 4.0, "vx": randf_range(45.0, 80.0) * jdir, "vy": randf_range(-210.0, -155.0), "spr": j_sprs[randi() % j_sprs.size()], "done": false})
		add_ripple(jx)
	for j in jumpers:
		j["vy"] = float(j["vy"]) + 460.0 * dt
		j["x"] = float(j["x"]) + float(j["vx"]) * dt
		j["y"] = float(j["y"]) + float(j["vy"]) * dt
		if float(j["y"]) > SURF + 6.0 and float(j["vy"]) > 0.0:
			add_ripple(float(j["x"]))
			splash_particles(float(j["x"]), 6)
			j["done"] = true
	jumpers = jumpers.filter(func(j): return not bool(j["done"]))

	for jl in jellies:
		jl["ph"] = float(jl["ph"]) + dt * 2.2
		jl["x"] = float(jl["x"]) + float(jl["vx"]) * dt
		jl["y"] = float(jl["y"]) + sin(float(jl["ph"])) * 14.0 * dt
		if float(jl["x"]) < 30.0 or float(jl["x"]) > W - 30.0:
			jl["vx"] = -float(jl["vx"])

	if SaveManager.is_night() and cam_y < SURF:
		next_star_t -= dt
		if next_star_t <= 0.0:
			next_star_t = randf_range(7.0, 16.0)
			shooting_stars.append({"x": randf_range(80.0, W - 80.0), "y": randf_range(16.0, 75.0), "vx": randf_range(240.0, 380.0) * (1.0 if randf() < 0.5 else -1.0), "vy": randf_range(60.0, 120.0), "life": 0.7})
	for ss in shooting_stars:
		ss["x"] = float(ss["x"]) + float(ss["vx"]) * dt
		ss["y"] = float(ss["y"]) + float(ss["vy"]) * dt
		ss["life"] = float(ss["life"]) - dt
	shooting_stars = shooting_stars.filter(func(ss): return float(ss["life"]) > 0.0)

	if randf() < dt * 6.5:
		var b_sprs := ["bubble_a", "bubble_b", "bubble_c"]
		bubbles.append({"x": randf_range(0.0, W), "y": cam_y + H + 10.0, "s": randf_range(0.15, 0.4), "v": randf_range(25.0, 60.0), "spr": b_sprs[randi() % 3]})
	if (state == "sinking" or state == "rising") and float(hook["y"]) > SURF and randf() < dt * 9.0:
		bubbles.append({"x": float(hook["x"]) + randf_range(-4.0, 4.0), "y": float(hook["y"]), "s": randf_range(0.12, 0.25), "v": randf_range(40.0, 80.0), "spr": "bubble_a"})
	for b in bubbles:
		b["y"] = float(b["y"]) - float(b["v"]) * dt
		b["x"] = float(b["x"]) + sin(t * 2.0 + float(b["y"]) * 0.05) * 0.3
	bubbles = bubbles.filter(func(b): return float(b["y"]) > SURF + 4.0 and float(b["y"]) > cam_y - 20.0)

	for r in ripples:
		r["t"] = float(r["t"]) + dt
	ripples = ripples.filter(func(r): return float(r["t"]) < 1.4)

	for p in particles:
		p["vy"] = float(p["vy"]) + 500.0 * dt
		p["x"] = float(p["x"]) + float(p["vx"]) * dt
		p["y"] = float(p["y"]) + float(p["vy"]) * dt
		p["t"] = float(p["t"]) + dt
	particles = particles.filter(func(p): return float(p["t"]) < 1.0 and float(p["y"]) < SURF + 12.0)

	var w_cur := SaveManager.get_weather()
	if bool(w_cur["rain"]) and cam_y < SURF + 40.0:
		var cnt := 7 if bool(w_cur["storm"]) else 4
		for i in range(cnt):
			rain_drops.append({"x": randf_range(0.0, W + 80.0), "y": -20.0, "vy": randf_range(480.0, 700.0), "len": randf_range(12.0, 22.0)})
		if randf() < dt * (9.0 if bool(w_cur["storm"]) else 4.0):
			add_ripple(randf_range(20.0, W - 20.0))
	for r in rain_drops:
		r["y"] = float(r["y"]) + float(r["vy"]) * dt
		r["x"] = float(r["x"]) - (150.0 if bool(w_cur["storm"]) else 80.0) * dt
	rain_drops = rain_drops.filter(func(r): return float(r["y"]) < SURF + 2.0)

	if bool(w_cur["storm"]):
		next_lightning -= dt
		if next_lightning <= 0.0:
			lightning_alpha = 0.65
			next_lightning = randf_range(5.0, 13.0)
			AudioManager.play("thunder")
	if lightning_alpha > 0.0:
		lightning_alpha = maxf(0.0, lightning_alpha - dt * 2.4)

	var biome := SaveManager.current_biome()
	var amb := str(biome["ambient"])
	if amb == "snow" and randf() < dt * 10.0:
		ambient_parts.append({"kind": "snow", "x": randf_range(0.0, W), "y": cam_y - 10.0, "vx": randf_range(-18.0, 18.0), "vy": randf_range(35.0, 65.0), "r": randf_range(1.5, 3.2), "life": 6.0})
	elif amb == "sakura" and cam_y < SURF + 30.0 and randf() < dt * 11.0:
		ambient_parts.append({"kind": "sakura", "x": randf_range(0.0, W + 40.0), "y": -10.0, "vx": randf_range(-38.0, -14.0), "vy": randf_range(24.0, 44.0), "r": randf_range(2.6, 4.4), "life": 6.5})
	elif amb == "embers" and randf() < dt * 12.0:
		ambient_parts.append({"kind": "ember", "x": randf_range(0.0, W), "y": bottom_y() - randf_range(0.0, 60.0), "vx": randf_range(-14.0, 14.0), "vy": randf_range(-55.0, -25.0), "r": randf_range(1.5, 3.5), "life": 5.0})
	elif (amb == "fireflies" or SaveManager.is_night()) and cam_y < 100.0 and randf() < dt * 4.0:
		ambient_parts.append({"kind": "firefly", "x": randf_range(20.0, W - 20.0), "y": randf_range(35.0, SURF - 25.0), "vx": randf_range(-15.0, 15.0), "vy": randf_range(-8.0, 8.0), "r": randf_range(1.8, 3.2), "life": 4.5})
	for a in ambient_parts:
		a["x"] = float(a["x"]) + float(a["vx"]) * dt
		a["y"] = float(a["y"]) + float(a["vy"]) * dt
		a["life"] = float(a["life"]) - dt
	ambient_parts = ambient_parts.filter(func(a): return float(a["life"]) > 0.0)

	for ft in float_texts:
		ft["y"] = float(ft["y"]) - 38.0 * dt
		ft["life"] = float(ft["life"]) - dt
	float_texts = float_texts.filter(func(ft): return float(ft["life"]) > 0.0)

	for c in confetti:
		c["vy"] = float(c["vy"]) + 320.0 * dt
		c["x"] = float(c["x"]) + float(c["vx"]) * dt
		c["y"] = float(c["y"]) + float(c["vy"]) * dt
		c["life"] = float(c["life"]) - dt
	confetti = confetti.filter(func(c): return float(c["life"]) > 0.0)

# ---------------- Efekt Yardımcıları ----------------
func add_ripple(x: float) -> void:
	ripples.append({"x": x, "t": 0.0})

func splash_particles(x: float, count: int = 14) -> void:
	for i in range(count):
		particles.append({"x": x, "y": SURF, "vx": randf_range(-100.0, 100.0), "vy": randf_range(-270.0, -110.0), "t": 0.0, "r": randf_range(2.0, 4.0)})

func add_float_text(x: float, y: float, text: String, color: Color = Color("#ffe066"), size: int = 18, screen_space: bool = false) -> void:
	float_texts.append({"x": x, "y": y, "text": text, "color": color, "size": size, "life": 1.4, "screen": screen_space})

func spawn_confetti(x: float, y: float, count: int = 24) -> void:
	var cols := [Color("#ffd43b"), Color("#ff6b6b"), Color("#51cf66"), Color("#339af0"), Color("#cc5de8"), Color("#ff922b")]
	for i in range(count):
		confetti.append({
			"x": x, "y": y, "vx": randf_range(-180.0, 180.0), "vy": randf_range(-260.0, -80.0),
			"w": randf_range(5.0, 9.0), "h": randf_range(4.0, 7.0), "color": cols[i % cols.size()], "life": randf_range(1.1, 1.9),
		})

# ---------------- Çizim ----------------
func _sky_colors() -> Array:
	var h := fmod(float(SaveManager.data["minutes"]) / 60.0, 24.0)
	var keys := [
		[0.0, Color("#0b1030"), Color("#1d2350")],
		[5.0, Color("#1b2050"), Color("#4a3a6a")],
		[6.5, Color("#ff9e7a"), Color("#ffd9a0")],
		[8.0, Color("#5fb7ff"), Color("#bfe6ff")],
		[17.0, Color("#4aa8ff"), Color("#cdeaff")],
		[19.0, Color("#ff8a5c"), Color("#ffd08a")],
		[20.5, Color("#2a2a60"), Color("#6a4a7a")],
		[22.0, Color("#0b1030"), Color("#1d2350")],
		[24.0, Color("#0b1030"), Color("#1d2350")],
	]
	var i := 0
	while i < keys.size() - 2 and h >= float(keys[i + 1][0]):
		i += 1
	var k := (h - float(keys[i][0])) / maxf(0.001, float(keys[i + 1][0]) - float(keys[i][0]))
	return [keys[i][1].lerp(keys[i + 1][1], k), keys[i][2].lerp(keys[i + 1][2], k), h]

func _draw_tex(tex: Texture2D, pos: Vector2, sc: float, flip_x: bool = false, mod: Color = Color.WHITE, rot: float = 0.0) -> void:
	if tex == null:
		return
	var sz := tex.get_size() * sc
	draw_set_transform(pos, rot, Vector2(-1.0 if flip_x else 1.0, 1.0))
	draw_texture_rect(tex, Rect2(-sz * 0.5, sz), false, mod)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw() -> void:
	var sky := _sky_colors()
	var sky_top: Color = sky[0]
	var sky_bot: Color = sky[1]
	var hour: float = sky[2]
	var night := SaveManager.is_night()
	var biome := SaveManager.current_biome()
	var bot := bottom_y()
	var shake := Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)) * screen_shake if screen_shake > 0.0 else Vector2.ZERO
	var off := Vector2(shake.x, -cam_y + shake.y)

	# Gökyüzü
	if cam_y < SURF + 10.0:
		var steps := 10
		for i in range(steps):
			var y0 := float(i) / float(steps) * SURF
			var y1 := float(i + 1) / float(steps) * SURF
			var c := sky_top.lerp(sky_bot, float(i) / float(steps))
			draw_rect(Rect2(off.x - 10.0, off.y + y0, W + 20.0, y1 - y0 + 1.0), c)

		var day_k := (hour - 6.0) / 14.0
		if not night and day_k > 0.0 and day_k < 1.0:
			var sx := lerpf(60.0, W - 60.0, day_k)
			var sy := SURF - 30.0 - sin(day_k * PI) * 130.0
			draw_circle(off + Vector2(sx, sy), 42.0, Color(1.0, 0.94, 0.7, 0.35))
			draw_circle(off + Vector2(sx, sy), 26.0, Color("#fff3b0"))
		elif night:
			for i in range(60):
				var sx := fmod(float(i) * 137.5, W)
				var sy := fmod(float(i) * 71.3, SURF - 40.0)
				var a := 0.4 + 0.4 * sin(t * 2.0 + float(i))
				draw_rect(Rect2(off + Vector2(sx, sy), Vector2(2, 2)), Color(1, 1, 1, a))
			draw_circle(off + Vector2(W - 130.0, 60.0), 22.0, Color("#f4f1d8"))
			draw_circle(off + Vector2(W - 120.0, 54.0), 20.0, sky_top)

			for ss in shooting_stars:
				var p1 := off + Vector2(float(ss["x"]), float(ss["y"]))
				var p2 := p1 - Vector2(float(ss["vx"]), float(ss["vy"])) * 0.08
				draw_line(p1, p2, Color(1.0, 1.0, 0.9, clampf(float(ss["life"]) * 1.4, 0.0, 1.0)), 2.0)

			if str(biome["id"]) == "fjord":
				for i in range(3):
					var pts := PackedVector2Array()
					for x_i in range(0, int(W) + 25, 24):
						pts.append(off + Vector2(float(x_i), 62.0 + sin(float(x_i) * 0.008 + t * 0.7 + float(i) * 2.0) * 22.0 + float(i) * 14.0))
					draw_polyline(pts, Color(0.28, 1.0, 0.74, 0.24) if i % 2 == 0 else Color(0.48, 0.65, 1.0, 0.22), 14.0)

		# Bulutlar
		var w_cur := SaveManager.get_weather()
		var c_col := Color(0.78, 0.82, 1.0, 0.08) if night else (Color(0.55, 0.62, 0.72, 0.78) if bool(w_cur["rain"]) else Color(1, 1, 1, 0.75))
		for i in range(4):
			var cx := fmod(float(i) * 260.0 + t * (8.0 + float(i) * 3.0), W + 200.0) - 100.0
			var cy := 30.0 + float(i) * 22.0
			var s := 1.0 + float(i % 2) * 0.4
			draw_circle(off + Vector2(cx, cy), 16.0 * s, c_col)
			draw_circle(off + Vector2(cx + 18.0 * s, cy - 8.0 * s), 20.0 * s, c_col)
			draw_circle(off + Vector2(cx + 40.0 * s, cy), 15.0 * s, c_col)

		if not night and not bool(w_cur["storm"]):
			for b in birds:
				var bx := float(b["x"])
				var by := float(b["y"])
				var wg := sin(float(b["ph"])) * 4.0
				draw_line(off + Vector2(bx - 6.0, by + wg), off + Vector2(bx, by - 2.0), Color(0.12, 0.2, 0.28, 0.55), 1.6)
				draw_line(off + Vector2(bx, by - 2.0), off + Vector2(bx + 6.0, by + wg), Color(0.12, 0.2, 0.28, 0.55), 1.6)

		var hill_cols: Array = biome["hills_night"] if night else biome["hills_day"]
		_draw_hills(off, SURF - 6.0, 56.0 if str(biome["id"]) == "fjord" else 34.0, 0.012 if str(biome["id"]) == "fjord" else 0.006, 1.0, hill_cols[0])
		_draw_hills(off, SURF - 2.0, 42.0 if str(biome["id"]) == "volcano" else 20.0, 0.011, 2.0, hill_cols[1])

		var bid := str(biome["id"])
		if bid == "volcano":
			draw_circle(off + Vector2(W * 0.72, SURF - 44.0), 58.0, Color(1.0, 0.42, 0.12, 0.24))
		elif bid == "coral":
			_draw_palm(off + Vector2(W - 85.0, SURF - 4.0), night)
			_draw_palm(off + Vector2(W - 155.0, SURF - 2.0), night)
		elif bid == "sakura":
			_draw_sakura_shore(off, night)
		elif bid == "emerald":
			_draw_emerald_shore(off, night)
		elif bid == "lake":
			_draw_lake_reeds(off, night)

	# Su gövdesi (katmanlı gradyan)
	var pal: Array = biome["water_night"] if night else biome["water_day"]
	var water_h := bot - SURF + 220.0
	var bands := 24
	for i in range(bands):
		var k0 := float(i) / float(bands)
		var k1 := float(i + 1) / float(bands)
		var wy0 := SURF + k0 * water_h
		var wy1 := SURF + k1 * water_h
		if wy1 < cam_y - 20.0 or wy0 > cam_y + H + 20.0:
			continue
		var col: Color
		if k0 < 0.33:
			col = (pal[0] as Color).lerp(pal[1], k0 / 0.33)
		elif k0 < 0.66:
			col = (pal[1] as Color).lerp(pal[2], (k0 - 0.33) / 0.33)
		else:
			col = (pal[2] as Color).lerp(pal[3], (k0 - 0.66) / 0.34)
		draw_rect(Rect2(off.x, off.y + wy0, W, wy1 - wy0 + 2.0), col)

	if frenzy_left > 0.0:
		draw_rect(Rect2(off.x, off.y + SURF, W, bot - SURF + 100.0), Color(1.0, 0.85, 0.28, 0.06 + 0.04 * sin(t * 5.0)))

	# Güneş / Ay su yansıması
	if cam_y < SURF + 80.0:
		var day_k := (hour - 6.0) / 14.0
		var rx := (W - 130.0) if night else (lerpf(60.0, W - 60.0, day_k) if (day_k > 0.0 and day_k < 1.0) else -999.0)
		if rx > 0.0:
			var r_col := Color(0.9, 0.94, 1.0, 0.14) if night else Color(1.0, 0.96, 0.75, 0.22)
			for i in range(6):
				var rw := 54.0 - float(i) * 7.0 + sin(t * 3.0 + float(i)) * 6.0
				draw_rect(Rect2(off + Vector2(rx - rw * 0.5, SURF + 10.0 + float(i) * 11.0), Vector2(rw, 3.0)), r_col)

	# Işık hüzmeleri
	if not night and cam_y < SURF + 450.0:
		for i in range(6):
			var rx := fmod(float(i) * 190.0 + sin(t * 0.3 + float(i)) * 40.0, W)
			var poly := PackedVector2Array([
				off + Vector2(rx, SURF), off + Vector2(rx + 50.0, SURF),
				off + Vector2(rx + 140.0, SURF + 420.0), off + Vector2(rx + 40.0, SURF + 420.0),
			])
			draw_colored_polygon(poly, Color(0.7, 0.9, 1.0, 0.08))

	# Biyom sualtı silüet yapıları
	_draw_landmarks(off, biome, bot)

	# Deniz anaları
	for jl in jellies:
		var jy := float(jl["y"])
		if jy < cam_y - 60.0 or jy > cam_y + H + 60.0:
			continue
		var jp := off + Vector2(float(jl["x"]), jy)
		var jc: Color = jl["color"]
		var jr := float(jl["r"]) * (1.0 + sin(float(jl["ph"])) * 0.12)
		draw_circle(jp, jr * 2.0, Color(jc.r, jc.g, jc.b, 0.18))
		draw_circle(jp, jr, Color(jc.r, jc.g, jc.b, 0.75))
		for k in range(-1, 2):
			var sw := sin(t * 4.0 + float(jl["ph"]) + float(k)) * 5.0
			draw_line(jp + Vector2(float(k) * 5.0, 0.0), jp + Vector2(float(k) * 4.0 + sw, 22.0), Color(jc.r, jc.g, jc.b, 0.55), 1.5)

	# Derinlik işaretleri
	var max_d := SaveManager.max_depth()
	for m in range(25, SaveManager.max_world_depth() + 1, 25):
		var y := SURF + float(m) * PPM
		if y < cam_y - 20.0 or y > cam_y + H + 20.0:
			continue
		var locked := m > max_d
		var dc := Color(1.0, 0.47, 0.47, 0.55) if locked else Color(1, 1, 1, 0.35)
		draw_rect(Rect2(off + Vector2(W - 46.0, y), Vector2(36.0, 2.0)), dc)
		draw_string(_font, off + Vector2(W - 50.0, y - 4.0), "%d m" % m, HORIZONTAL_ALIGNMENT_RIGHT, 42.0, 13, dc)

	var lim_y := SURF + float(max_d) * PPM
	if max_d < SaveManager.max_world_depth() and lim_y > cam_y - 10.0 and lim_y < cam_y + H + 10.0:
		draw_dashed_line(off + Vector2(0.0, lim_y + 18.0), off + Vector2(W - 60.0, lim_y + 18.0), Color(1.0, 0.55, 0.47, 0.55), 2.0, 10.0)

	# Arka plan dekor
	for d in decor:
		var dy := float(d["y"])
		if dy < cam_y - 200.0 or dy - 200.0 > cam_y + H:
			continue
		var tex := GameData.get_env_texture(str(d["spr"]))
		if tex == null:
			continue
		if str(d["kind"]) == "bg":
			var sz := tex.get_size() * float(d["s"])
			draw_texture_rect(tex, Rect2(off + Vector2(float(d["x"]), dy - sz.y), sz), false, Color(1, 1, 1, 0.35))
		elif str(d["kind"]) == "drift":
			var dp := off + Vector2(float(d["x"]) + sin(t * 0.4 + float(d["ph"])) * 12.0, dy + sin(t * 0.6 + float(d["ph"])) * 8.0)
			_draw_tex(tex, dp, float(d["s"]), false, Color(1, 1, 1, 0.12))

	# Kabarcıklar
	for b in bubbles:
		_draw_tex(GameData.get_env_texture(str(b["spr"])), off + Vector2(float(b["x"]), float(b["y"])), float(b["s"]), false, Color(1, 1, 1, 0.7))

	# Batık Hazineler
	for tr in treasures:
		var ty := float(tr["y"])
		if ty < cam_y - 60.0 or ty > cam_y + H + 60.0:
			continue
		var tp := off + Vector2(float(tr["x"]), ty)
		var gr := 24.0 + sin(t * 4.0 + float(tr["ph"])) * 5.0
		draw_circle(tp, gr, Color(1.0, 0.9, 0.45, 0.35))
		draw_string(_font, tp + Vector2(-14.0, 8.0), str(tr["type"]["icon"]), HORIZONTAL_ALIGNMENT_CENTER, 28.0, 24, Color.WHITE)

	# Tehlikeler (Kemik Balıklar)
	for h in hazards:
		var hy := float(h["y"])
		if hy < cam_y - 80.0 or hy > cam_y + H + 80.0:
			continue
		_draw_tex(GameData.get_fish_texture(str(h["spr"])), off + Vector2(float(h["x"]), hy), float(h["scale"]), float(h["dir"]) < 0.0, Color(1, 1, 1, 0.85))

	# Balıklar
	for f in fishes:
		var fy := float(f["y"])
		if fy < cam_y - 90.0 or fy > cam_y + H + 90.0:
			continue
		var fp := off + Vector2(float(f["x"]), fy)
		var sp: Dictionary = f["sp"]
		var sc := float(f["scale"])
		if bool(f.get("is_boss", false)) or bool(sp.get("boss", false)):
			draw_circle(fp, 72.0 * sc + sin(t * 5.0) * 8.0, Color(1.0, 0.32, 0.16, 0.32))
			draw_circle(fp, 44.0 * sc, Color(1.0, 0.82, 0.25, 0.28))
		elif int(sp["r"]) >= 4:
			draw_circle(fp, 62.0 * sc, Color(1.0, 0.84, 0.35, 0.22))
		elif night and int(sp["r"]) >= 2:
			draw_circle(fp, 38.0 * sc + 10.0, Color(0.63, 0.86, 1.0, 0.14))

		if bool(f["hooked"]) and not fight.is_empty() and (float(fight["warn_t"]) > 0.0 or float(fight["surge"]) > 0.0):
			draw_circle(fp, 44.0 * sc + 12.0, Color(1.0, 0.35, 0.16, 0.4))

		var tint := Color(str(sp["tint"])) if sp.has("tint") else Color.WHITE
		var tex := GameData.get_fish_texture(str(sp["spr"]))
		_draw_tex(tex, fp, sc, float(f["dir"]) < 0.0, tint)

		if float(f["alerted"]) > 0.0 and not bool(f["hooked"]):
			draw_string(_font, fp + Vector2(-8.0, -24.0 * sc - 8.0), "!", HORIZONTAL_ALIGNMENT_CENTER, 16.0, 16, Color("#ffe066"))

	# Dip zemini
	if bot - 10.0 < cam_y + H:
		var tops := ["terrain_sand_top_a", "terrain_sand_top_b", "terrain_sand_top_c", "terrain_sand_top_d"]
		var idx := 0
		var tx := 0.0
		while tx < W:
			var im1 := GameData.get_env_texture(tops[idx % 4])
			if im1 != null:
				draw_texture_rect(im1, Rect2(off + Vector2(tx, bot), Vector2(64.0, 64.0 * float(im1.get_height()) / float(im1.get_width()))), false)
			var im2 := GameData.get_env_texture("terrain_sand_a" if idx % 2 == 1 else "terrain_sand_b")
			if im2 != null:
				draw_texture_rect(im2, Rect2(off + Vector2(tx, bot + 58.0), Vector2(64.0, 64.0)), false)
			var im3 := GameData.get_env_texture("terrain_dirt_a" if idx % 2 == 1 else "terrain_dirt_b")
			if im3 != null:
				draw_texture_rect(im3, Rect2(off + Vector2(tx, bot + 120.0), Vector2(64.0, 64.0)), false)
			tx += 64.0
			idx += 1
		if str(biome["id"]) == "volcano":
			for vx in [160.0, 480.0, 790.0]:
				draw_circle(off + Vector2(vx, bot + 4.0), 75.0, Color(1.0, 0.38, 0.08, 0.35 + 0.12 * sin(t * 3.0 + vx)))
		for d in decor:
			if str(d["kind"]) == "fg":
				var im := GameData.get_env_texture(str(d["spr"]))
				if im != null:
					var sz := im.get_size() * float(d["s"])
					draw_texture_rect(im, Rect2(off + Vector2(float(d["x"]) - sz.x * 0.5, float(d["y"]) - sz.y), sz), false)

	# Yüzey dalgası
	var wave_pts := PackedVector2Array()
	for x_i in range(0, int(W) + 13, 12):
		wave_pts.append(off + Vector2(float(x_i), SURF + sin(float(x_i) * 0.03 + t * 2.0) * 2.5))
	draw_polyline(wave_pts, Color(0.47, 0.67, 0.9, 0.45) if night else Color(1, 1, 1, 0.65), 4.0)

	# Tatlı göl yüzeyi detayları (Nilüferler, minik ördek, yüzen sakura çiçekleri!)
	_draw_cute_surface_props(off, biome)

	# Su yüzeyi Balık Sürüleri (Hotspots ✨)
	for hs in hotspots:
		var pulse := 1.0 + sin(float(hs["ph"])) * 0.16
		var hp := off + Vector2(float(hs["x"]), SURF + 4.0)
		draw_circle(hp, 36.0 * pulse, Color(1.0, 0.92, 0.38, 0.3))
		draw_string(_font, hp + Vector2(-36.0, -14.0 + sin(float(hs["ph"])) * 3.0), "✨ Sürü!", HORIZONTAL_ALIGNMENT_CENTER, 72.0, 13, Color("#fff4a3"))

	# Zıplayan yüzey balıkları
	for j in jumpers:
		var ang := atan2(float(j["vy"]), float(j["vx"]))
		_draw_tex(GameData.get_fish_texture(str(j["spr"])), off + Vector2(float(j["x"]), float(j["y"])), 34.0 / GameData.fish_used_width(str(j["spr"])), float(j["vx"]) < 0.0, Color(1, 1, 1, 0.95), ang)

	for r in ripples:
		var rt := float(r["t"])
		draw_arc(off + Vector2(float(r["x"]), SURF + 2.0), 10.0 + rt * 50.0, 0.0, TAU, 24, Color(1, 1, 1, 0.55 * (1.0 - rt / 1.4)), 2.0)

	for p in particles:
		draw_circle(off + Vector2(float(p["x"]), float(p["y"])), float(p["r"]), Color(0.86, 0.96, 1.0, 1.0 - float(p["t"])))

	for a in ambient_parts:
		var ak := str(a["kind"])
		var ac := Color(0.94, 0.98, 1.0, 0.75) if ak == "snow" else (
			Color(1.0, 0.72, 0.85, 0.88) if ak == "sakura" else (
			Color(1.0, 0.48, 0.12, minf(1.0, float(a["life"]))) if ak == "ember" else
			Color(1.0, 0.96, 0.5, 0.45 + 0.45 * sin(t * 6.0 + float(a["x"])))))
		draw_circle(off + Vector2(float(a["x"]), float(a["y"])), float(a["r"]), ac)

	# İskele, Tekne, Balıkçı, Misina
	_draw_pier(off, night, biome)
	if int(SaveManager.data["lv"].get("boat", 0)) > 0:
		_draw_boat(off, night)
	_draw_line(off)

	# Ekran uzayı efektleri: derinlik karartması + fener
	var depth_k := clampf((cam_y - SURF) / maxf(1.0, bot - SURF), 0.0, 1.0)
	if depth_k > 0.0:
		var lantern_r := float(SaveManager.up("lantern")) + (75.0 if bool(SaveManager.active_bait()["glow"]) else 0.0)
		var dark_a := clampf(0.18 + depth_k * 0.52 - lantern_r * 0.0012, 0.05, 0.72)
		draw_rect(Rect2(0, 0, W, H), Color(0.0, 0.02, 0.08, dark_a))
		if lantern_r > 0.0 and float(hook["y"]) > SURF:
			draw_circle(Vector2(float(hook["x"]), float(hook["y"]) - cam_y), 95.0 + lantern_r * 0.5, Color(1.0, 0.96, 0.72, 0.09))

	# Yağmur (sadece su yüzeyinin üstünde!)
	if not rain_drops.is_empty() and cam_y < SURF + 20.0:
		var surf_screen := SURF - cam_y
		for r in rain_drops:
			var ry := float(r["y"]) - cam_y
			if ry < surf_screen:
				var y2 := minf(surf_screen, ry + float(r["len"]))
				draw_line(Vector2(float(r["x"]), ry), Vector2(float(r["x"]) - 4.0, y2), Color(0.7, 0.86, 1.0, 0.45), 1.3)

	if lightning_alpha > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(0.86, 0.92, 1.0, lightning_alpha * 0.45))

	# Sonar Radar
	var sonar_range := float(SaveManager.up("sonar"))
	if sonar_range > 0.0 and float(hook["y"]) > SURF and state in ["sinking", "rising", "fight"]:
		var hs_pos := Vector2(float(hook["x"]), float(hook["y"]) - cam_y)
		var pulse_r := fmod(t * 85.0, maxf(10.0, sonar_range * PPM * 0.8))
		draw_arc(hs_pos, pulse_r, 0.0, TAU, 48, Color(0.2, 0.94, 0.7, 0.3), 2.0)
		for f in fishes:
			var d := Vector2(float(f["x"]) - float(hook["x"]), float(f["y"]) - float(hook["y"])).length()
			if d <= sonar_range * PPM:
				var fp := Vector2(float(f["x"]), float(f["y"]) - cam_y)
				var r_idx := int(f["sp"]["r"])
				var bc := Color(1.0, 0.84, 0.0, 0.9) if r_idx >= 3 else (Color(0.4, 0.86, 1.0, 0.85) if r_idx >= 2 else Color(0.32, 1.0, 0.48, 0.72))
				draw_circle(fp, 4.0, bc)
		for tr in treasures:
			var d := Vector2(float(tr["x"]) - float(hook["x"]), float(tr["y"]) - float(hook["y"])).length()
			if d <= sonar_range * PPM:
				draw_rect(Rect2(Vector2(float(tr["x"]) - 3.0, float(tr["y"]) - cam_y - 3.0), Vector2(6, 6)), Color("#ffe066"))

	if state == "fight" and not fight.is_empty() and float(fight["shake"]) > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(1.0, 0.24, 0.24, float(fight["shake"]) * 0.09))

	for c in confetti:
		draw_rect(Rect2(Vector2(float(c["x"]), float(c["y"])), Vector2(float(c["w"]), float(c["h"]))), c["color"])

	for ft in float_texts:
		var a := clampf(float(ft["life"]), 0.0, 1.0)
		var fy := float(ft["y"]) if bool(ft["screen"]) else (float(ft["y"]) - cam_y)
		var col: Color = ft["color"]
		draw_string(_font, Vector2(float(ft["x"]) - 150.0, fy), str(ft["text"]), HORIZONTAL_ALIGNMENT_CENTER, 300.0, int(ft["size"]), Color(col.r, col.g, col.b, a))

func _draw_hills(off: Vector2, base_y: float, amp: float, freq: float, seed_v: float, col: Color) -> void:
	var pts := PackedVector2Array([off + Vector2(0.0, SURF + 2.0)])
	for x_i in range(0, int(W) + 1, 16):
		var xf := float(x_i)
		var hy := minf(SURF - 2.0, base_y - amp * (0.5 + 0.5 * sin(xf * freq + seed_v * 3.0)) - amp * 0.35 * sin(xf * freq * 2.7 + seed_v))
		pts.append(off + Vector2(xf, hy))
	pts.append(off + Vector2(W, SURF + 2.0))
	draw_colored_polygon(pts, col)

func _draw_palm(base: Vector2, night: bool) -> void:
	draw_line(base, base + Vector2(-8.0, -76.0), Color("#1b2838") if night else Color("#6e4e2e"), 7.0)
	var leaf_c := Color("#163338") if night else Color("#3a8c4e")
	var top := base + Vector2(-8.0, -76.0)
	for ang in [-2.3, -1.6, -0.9, -0.2, 0.4]:
		var dir := Vector2(cos(ang), sin(ang)) * 34.0
		draw_line(top, top + dir, leaf_c, 6.0)

func _draw_lake_reeds(off: Vector2, night: bool) -> void:
	var col := Color("#1f4232") if night else Color("#40916c")
	var tip_c := Color("#4a301e") if night else Color("#7f4f24")
	for rx in [420.0, 434.0, 446.0, 815.0, 828.0, 842.0]:
		var sw := sin(t * 1.8 + rx * 0.1) * 4.0
		draw_line(off + Vector2(rx, SURF + 2.0), off + Vector2(rx + sw, SURF - 26.0), col, 3.0)
		draw_circle(off + Vector2(rx + sw, SURF - 26.0), 3.5, tip_c)

func _draw_sakura_shore(off: Vector2, night: bool) -> void:
	# Kırmızı kemerli ahşap Japon köprüsü
	var br_c := Color("#6e1d28") if night else Color("#c1121f")
	draw_arc(off + Vector2(610.0, SURF + 32.0), 68.0, PI + 0.35, TAU - 0.35, 20, br_c, 8.0)
	draw_arc(off + Vector2(610.0, SURF + 20.0), 68.0, PI + 0.35, TAU - 0.35, 20, br_c, 3.0)
	# Pembe Kiraz Çiçeği Ağacı
	var tx := W - 110.0
	draw_line(off + Vector2(tx, SURF), off + Vector2(tx - 10.0, SURF - 66.0), Color("#3b2229") if night else Color("#5c3a21"), 9.0)
	var bl_c := Color("#7a3e58") if night else Color("#ff8fab")
	var bl_c2 := Color("#994f6e") if night else Color("#ffb3c6")
	for p in [Vector2(-24, -72), Vector2(4, -84), Vector2(26, -70), Vector2(-6, -64), Vector2(18, -58)]:
		draw_circle(off + Vector2(tx, SURF) + p, 22.0, bl_c)
	for p in [Vector2(-14, -78), Vector2(14, -78), Vector2(0, -68)]:
		draw_circle(off + Vector2(tx, SURF) + p, 14.0, bl_c2)

func _draw_emerald_shore(off: Vector2, night: bool) -> void:
	# Çam ağaçları
	var pine_c := Color("#123026") if night else Color("#1b4332")
	for px in [460.0, 505.0, 548.0, 810.0, 865.0, 910.0]:
		var h := 46.0 + fmod(px * 13.0, 26.0)
		draw_colored_polygon(PackedVector2Array([off + Vector2(px, SURF - h), off + Vector2(px - 18.0, SURF), off + Vector2(px + 18.0, SURF)]), pine_c)
	# Sıcak orman kulübesi + tüten baca dumanı
	var cx := 680.0
	draw_rect(Rect2(off + Vector2(cx - 28.0, SURF - 34.0), Vector2(56.0, 34.0)), Color("#4a2c18") if night else Color("#7f4f24"))
	draw_colored_polygon(PackedVector2Array([off + Vector2(cx - 34.0, SURF - 34.0), off + Vector2(cx, SURF - 58.0), off + Vector2(cx + 34.0, SURF - 34.0)]), Color("#2b1c12") if night else Color("#582f0e"))
	# Sıcak parlayan pencere
	draw_rect(Rect2(off + Vector2(cx - 10.0, SURF - 24.0), Vector2(14.0, 14.0)), Color("#ffd166"))
	if night:
		draw_circle(off + Vector2(cx - 3.0, SURF - 17.0), 22.0, Color(1.0, 0.85, 0.4, 0.22))
	# Baca & duman halkaları
	draw_rect(Rect2(off + Vector2(cx + 14.0, SURF - 56.0), Vector2(8.0, 18.0)), Color("#444"))
	for i in range(3):
		var st := fmod(t * 0.7 + float(i) * 0.33, 1.0)
		draw_circle(off + Vector2(cx + 18.0 + sin(t * 2.0 + float(i)) * 5.0, SURF - 60.0 - st * 34.0), 4.0 + st * 5.0, Color(0.92, 0.94, 0.96, 0.45 * (1.0 - st)))

func _draw_cute_surface_props(off: Vector2, biome: Dictionary) -> void:
	var bid := str(biome["id"])
	if bid in ["lake", "sakura", "emerald"]:
		# Nilüfer yaprakları & pembe lotus çiçekleri
		for lx in [480.0, 620.0, 775.0]:
			var bob := sin(t * 2.2 + lx * 0.05) * 1.8
			var lp := off + Vector2(lx, SURF + 4.0 + bob)
			draw_circle(lp, 11.0, Color("#40916c"))
			draw_circle(lp + Vector2(0, -3.0), 4.5, Color("#ff8fab") if bid != "emerald" else Color("#ffe066"))
	if bid == "lake":
		# Tatlı yüzen sarı ördek!
		var dx := 560.0 + sin(t * 0.35) * 110.0
		var facing := 1.0 if cos(t * 0.35) >= 0.0 else -1.0
		var dp := off + Vector2(dx, SURF - 3.0 + sin(t * 3.0) * 1.5)
		draw_circle(dp, 8.0, Color("#ffd43b"))
		draw_circle(dp + Vector2(facing * 6.0, -7.0), 5.5, Color("#ffd43b"))
		draw_circle(dp + Vector2(facing * 11.0, -7.0), 2.5, Color("#ff6b35"))
		draw_circle(dp + Vector2(facing * 7.5, -8.5), 1.3, Color("#222"))

func _draw_landmarks(off: Vector2, biome: Dictionary, bot: float) -> void:
	var bid := str(biome["id"])
	if bid == "lake":
		var ay := SURF + 88.0 * PPM
		if ay > cam_y - 160.0 and ay < cam_y + H + 160.0:
			var col := Color(0.03, 0.11, 0.21, 0.24)
			draw_line(off + Vector2(740, ay - 55), off + Vector2(740, ay + 35), col, 9.0)
			draw_line(off + Vector2(714, ay - 34), off + Vector2(766, ay - 34), col, 7.0)
			draw_arc(off + Vector2(740, ay + 12), 34.0, 0.0, PI, 16, col, 8.0)
	elif bid == "sakura":
		# Batık Torii kapısı silüeti
		var ty := SURF + 78.0 * PPM
		if ty > cam_y - 160.0 and ty < cam_y + H + 160.0:
			var col := Color(0.45, 0.08, 0.16, 0.28)
			draw_rect(Rect2(off + Vector2(410, ty - 70), Vector2(14, 110)), col)
			draw_rect(Rect2(off + Vector2(536, ty - 70), Vector2(14, 110)), col)
			draw_rect(Rect2(off + Vector2(390, ty - 76), Vector2(180, 14)), col)
			draw_rect(Rect2(off + Vector2(404, ty - 48), Vector2(152, 10)), col)
	elif bid == "emerald":
		# Batık yosunlu kütük silüeti
		var ey := SURF + 95.0 * PPM
		if ey > cam_y - 160.0 and ey < cam_y + H + 160.0:
			draw_line(off + Vector2(220, ey + 20), off + Vector2(460, ey - 24), Color(0.03, 0.18, 0.14, 0.3), 24.0)
	elif bid == "coral":
		var cy := SURF + 72.0 * PPM
		if cy > cam_y - 180.0 and cy < cam_y + H + 180.0:
			draw_arc(off + Vector2(480, cy + 90), 140.0, PI, TAU, 24, Color(0.02, 0.17, 0.26, 0.25), 24.0)
	elif bid == "fjord":
		var sy := bot - 40.0
		if sy > cam_y - 160.0 and sy < cam_y + H + 160.0:
			var col := Color(0.01, 0.04, 0.08, 0.3)
			draw_colored_polygon(PackedVector2Array([off + Vector2(520, sy - 20), off + Vector2(780, sy - 10), off + Vector2(740, sy + 42), off + Vector2(560, sy + 42)]), col)
			draw_rect(Rect2(off + Vector2(645, sy - 125), Vector2(10, 110)), col)
	elif bid == "volcano":
		var my := bot - 20.0
		if my > cam_y - 160.0 and my < cam_y + H + 160.0:
			for cx in [240.0, 660.0]:
				draw_colored_polygon(PackedVector2Array([off + Vector2(cx, my + 20), off + Vector2(cx - 22, my - 65), off + Vector2(cx + 8, my - 95), off + Vector2(cx + 28, my + 20)]), Color(1.0, 0.36, 0.15, 0.32))

func _draw_pier(off: Vector2, night: bool, biome: Dictionary) -> void:
	var deck := SURF - 34.0
	var cols: Array = biome["pier"]
	for x in [30.0, 120.0, 210.0, 290.0]:
		draw_rect(Rect2(off + Vector2(x, deck), Vector2(14, 80)), cols[2])
		draw_rect(Rect2(off + Vector2(x, SURF), Vector2(14, 40)), Color(0, 0, 0, 0.15))
	for i in range(10):
		draw_rect(Rect2(off + Vector2(float(i) * 32.0, deck - 12.0), Vector2(31, 14)), cols[0] if i % 2 == 1 else cols[1])
	draw_rect(Rect2(off + Vector2(0.0, deck + 2.0), Vector2(320, 5)), cols[3])

	# Kova
	draw_colored_polygon(PackedVector2Array([off + Vector2(150, deck - 12), off + Vector2(176, deck - 12), off + Vector2(172, deck - 40), off + Vector2(154, deck - 40)]), Color("#8aa0b4"))
	draw_rect(Rect2(off + Vector2(152, deck - 42), Vector2(22, 4)), Color("#6b8296"))
	if not (SaveManager.data["basket"] as Array).is_empty():
		draw_colored_polygon(PackedVector2Array([off + Vector2(160, deck - 42), off + Vector2(154, deck - 52), off + Vector2(168, deck - 50)]), Color("#ff9f43"))

	# Fener
	draw_rect(Rect2(off + Vector2(40, deck - 70), Vector2(6, 58)), Color("#3d2a17"))
	draw_rect(Rect2(off + Vector2(34, deck - 84), Vector2(18, 16)), Color("#ffd56a") if night else Color("#d9c79a"))
	if night:
		draw_circle(off + Vector2(43, deck - 76), 46.0, Color(1.0, 0.82, 0.39, 0.22))

	if int(SaveManager.data["lv"].get("boat", 0)) == 0:
		_draw_fisherman(off, 268.0, deck - 12.0, ROD_TIP)

func _draw_fisherman(off: Vector2, bx: float, by: float, tip_base: Vector2) -> void:
	var pull := sin(t * 10.0) * 2.0 if state == "fight" else (-cast_power * 0.06 if state == "charging" else 0.0)
	draw_rect(Rect2(off + Vector2(bx - 6.0, by - 6.0), Vector2(30, 10)), Color("#2f4f7a"))
	draw_rect(Rect2(off + Vector2(bx + 20.0, by - 2.0), Vector2(10, 14)), Color("#3a2a1a"))
	draw_rect(Rect2(off + Vector2(bx - 12.0, by - 44.0), Vector2(26, 40)), Color("#e0703a"))
	draw_circle(off + Vector2(bx + 1.0, by - 54.0 + pull * 0.3), 11.0, Color("#f2c79b"))
	var hat_c := Color.WHITE if int(SaveManager.data["lv"].get("boat", 0)) >= 3 else Color("#e8c84a")
	draw_rect(Rect2(off + Vector2(bx - 14.0, by - 66.0 + pull * 0.3), Vector2(30, 6)), hat_c)
	draw_rect(Rect2(off + Vector2(bx - 8.0, by - 76.0 + pull * 0.3), Vector2(18, 12)), hat_c)
	draw_rect(Rect2(off + Vector2(bx + 5.0, by - 56.0 + pull * 0.3), Vector2(3, 3)), Color("#222222"))

	var hand := Vector2(bx + 16.0, by - 30.0 + pull)
	draw_line(off + Vector2(bx + 4.0, by - 36.0), off + hand, Color("#f2c79b"), 6.0)
	var has_load := (not (hook["fish"] as Dictionary).is_empty()) or (not (hook["treasure"] as Dictionary).is_empty())
	var bend := (18.0 + sin(t * 12.0) * 4.0) if state == "fight" else (12.0 if has_load else (-cast_power * 0.14 if state == "charging" else 0.0))
	var rod_cols := [Color("#6e4726"), Color("#3d3d3d"), Color("#2b6cb0"), Color("#d49b00"), Color("#00b5d8"), Color("#9f7aea"), Color("#ff5e7e")]
	var r_col: Color = rod_cols[clampi(int(SaveManager.data["lv"].get("rod", 0)), 0, rod_cols.size() - 1)]
	var tip_w := Vector2(tip_base.x, tip_base.y + bend)
	draw_line(off + hand + Vector2(-14.0, 10.0), off + tip_w, r_col, 4.0)
	draw_circle(off + hand + Vector2(-4.0, 4.0), 5.0, Color("#f5c542") if int(SaveManager.data["lv"].get("reel", 0)) >= 3 else Color("#b03030"))
	hook["tip"] = tip_w

func _draw_boat(off: Vector2, night: bool) -> void:
	var lv := clampi(int(SaveManager.data["lv"].get("boat", 1)), 1, 3)
	var bob := sin(t * 2.6) * 2.5
	var x := boat_x
	var y := SURF + bob
	_draw_fisherman(off, x + 2.0, y - 16.0, Vector2(x + 86.0, y - 110.0))

	if lv == 1:
		draw_colored_polygon(PackedVector2Array([off + Vector2(x - 48, y - 14), off + Vector2(x + 56, y - 14), off + Vector2(x + 40, y + 8), off + Vector2(x - 36, y + 8)]), Color("#8c5527"))
		draw_rect(Rect2(off + Vector2(x - 46, y - 17), Vector2(100, 5)), Color("#b5743c"))
	elif lv == 2:
		draw_colored_polygon(PackedVector2Array([off + Vector2(x - 56, y - 18), off + Vector2(x + 68, y - 18), off + Vector2(x + 48, y + 9), off + Vector2(x - 46, y + 9)]), Color("#e8f1f8"))
		draw_rect(Rect2(off + Vector2(x - 52, y - 11), Vector2(112, 5)), Color("#d93838"))
		draw_rect(Rect2(off + Vector2(x - 62, y - 16), Vector2(10, 18)), Color("#333344"))
	else:
		draw_colored_polygon(PackedVector2Array([off + Vector2(x - 68, y - 20), off + Vector2(x + 76, y - 20), off + Vector2(x + 54, y + 10), off + Vector2(x - 56, y + 10)]), Color.WHITE)
		draw_rect(Rect2(off + Vector2(x - 62, y - 10), Vector2(130, 5)), Color("#185adb"))
		draw_rect(Rect2(off + Vector2(x - 62, y - 14), Vector2(130, 3)), Color("#f5c542"))
		draw_rect(Rect2(off + Vector2(x - 58, y - 42), Vector2(42, 22)), Color("#dff6ff"))
		if night:
			draw_circle(off + Vector2(x + 66, y - 18), 22.0, Color(1.0, 0.92, 0.55, 0.35))

func _draw_line(off: Vector2) -> void:
	var tip: Vector2 = hook["tip"]
	var hx := float(hook["x"])
	var hy := float(hook["y"])
	var line_c := Color(1.0, 0.92, 0.58, 0.85) if int(SaveManager.data["lv"].get("line", 0)) >= 3 else Color(1, 1, 1, 0.75)
	draw_line(off + tip, off + Vector2(hx, hy - 10.0), line_c, 1.5)

	if state != "idle" and state != "charging" and hy > SURF:
		var fk := clampf((SURF - tip.y) / maxf(1.0, hy - tip.y), 0.0, 1.0)
		var fx := lerpf(tip.x, hx, fk)
		var bob := (sin(t * 20.0) * 3.0 + 4.0) if state == "fight" else sin(t * 3.0) * 1.5
		draw_circle(off + Vector2(fx, SURF - 2.0 + bob), 6.0, Color("#e23b3b"))
		draw_circle(off + Vector2(fx, SURF - 4.0 + bob), 4.0, Color.WHITE)

	var bait := SaveManager.active_bait()
	if bool(hook["bait"]) and bool(bait["glow"]) and hy > SURF:
		var bc: Color = bait["color"]
		draw_circle(off + Vector2(hx, hy), 24.0, Color(bc.r, bc.g, bc.b, 0.32))

	var hook_c := Color("#ffd84d") if int(SaveManager.data["lv"].get("hook", 0)) > 0 else Color("#cfd6dc")
	draw_line(off + Vector2(hx, hy - 10.0), off + Vector2(hx, hy + 2.0), hook_c, 2.5)
	draw_arc(off + Vector2(hx - 5.0, hy + 2.0), 5.0, 0.0, PI, 12, hook_c, 2.5)

	if bool(hook["bait"]):
		draw_circle(off + Vector2(hx + 2.0, hy + 2.0), 4.0, bait["color"])

	if not (hook["fish"] as Dictionary).is_empty() and state != "fight":
		var f: Dictionary = hook["fish"]
		var sp: Dictionary = f["sp"]
		var tint := Color(str(sp["tint"])) if sp.has("tint") else Color.WHITE
		_draw_tex(GameData.get_fish_texture(str(sp["spr"])), off + Vector2(hx, hy + 14.0), float(f["scale"]), float(f["dir"]) < 0.0, tint, sin(t * 9.0) * 0.25)

	if not (hook["treasure"] as Dictionary).is_empty() and state == "rising":
		draw_string(_font, off + Vector2(hx - 14.0, hy + 22.0), str(hook["treasure"]["type"]["icon"]), HORIZONTAL_ALIGNMENT_CENTER, 28.0, 24, Color.WHITE)
