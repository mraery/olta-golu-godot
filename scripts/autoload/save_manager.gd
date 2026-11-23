extends Node

## Kalıcı kayıt, ekonomi, görevler, başarımlar, günlük balık pazarı, akvaryum geliri ve rütbe sistemi.

const SAVE_PATH := "user://olta_golu_save.json"

signal data_changed()
signal toast_requested(msg: String)
signal level_up_achieved(new_lv: int, title: String)
signal achievement_unlocked(ach: Dictionary)

var data: Dictionary = {}
var aqua_fed_until_msec: int = 0
## Oyun açılışında hesaplanan çevrimdışı gelir: {"secs": int, "gold": int}
var offline_report: Dictionary = {}

func _ready() -> void:
	load_save()
	offline_report = apply_offline_income(int(Time.get_unix_time_from_system()))
	ensure_missions()
	ensure_market()

func default_save() -> Dictionary:
	return {
		"money": 0,
		"xp": 0,
		"lv": {
			"rod": 0, "line": 0, "reel": 0, "bait": 0, "lantern": 0,
			"sonar": 0, "basket": 0, "hook": 0, "boat": 0, "aquarium": 0
		},
		"biome": "lake",
		"biomes": ["lake"],
		"baits": {"shrimp": 2, "glow": 0, "golden": 0, "magnet": 0},
		"active_bait": "worm",
		"basket": [],
		"aquarium": [],
		"aqua_bank": 0.0,
		"book": {},
		"missions": [],
		"achievements": {},
		"stats": {
			"max_combo": 0, "perfect_casts": 0, "heaviest": 0.0, "treasures": 0,
			"night_catches": 0, "rain_catches": 0, "deepest": 0, "legendaries": 0,
			"bosses": 0, "tourney_wins": 0, "haggles": 0, "play_secs": 0.0, "best_streak": 0, "perfect_hooks": 0
		},
		"tourney_best": {},
		"market_day": -1,
		"market_hot": [],
		"minutes": 8 * 60,
		"casts": 0,
		"total": 0,
		"sound": true,
		"last_seen": 0,
		"daily": {"last_date": "", "streak": 0},
		"tips": {},
		"collections": {},
	}

func load_save() -> void:
	var def := default_save()
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f != null:
			var parsed = JSON.parse_string(f.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				for k in parsed.keys():
					if k in ["lv", "baits", "stats", "daily", "tips", "collections"] and typeof(parsed[k]) == TYPE_DICTIONARY:
						for sub_k in parsed[k].keys():
							def[k][sub_k] = parsed[k][sub_k]
					else:
						def[k] = parsed[k]
	data = def
	migrate_species_ids()

## Birleştirilen çift türlerin eski id'lerini asıl id'ye taşır (günlük kayıtları birleştirilir).
func migrate_species_ids() -> void:
	if GameData.aliases.is_empty():
		return
	var book: Dictionary = data["book"]
	for old_id in book.keys():
		var new_id := GameData.canonical_id(str(old_id))
		if new_id == str(old_id):
			continue
		var a: Dictionary = book[old_id]
		var b: Dictionary = book.get(new_id, {})
		book[new_id] = {
			"n": int(a.get("n", 0)) + int(b.get("n", 0)),
			"max": maxf(float(a.get("max", 0.0)), float(b.get("max", 0.0))),
			"deep": maxi(int(a.get("deep", 0)), int(b.get("deep", 0))),
		}
		book.erase(old_id)
	for key in ["aquarium", "basket"]:
		for item in data[key]:
			item["sp_id"] = GameData.canonical_id(str(item.get("sp_id", "")))
	for h in data["market_hot"]:
		if h.has("id"):
			h["id"] = GameData.canonical_id(str(h["id"]))

func save_game() -> void:
	data["last_seen"] = int(Time.get_unix_time_from_system())
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))

func reset_save() -> void:
	data = default_save()
	ensure_missions()
	ensure_market()
	save_game()
	data_changed.emit()

func up(id: String):
	var u := GameData.get_upgrade(id)
	if u.is_empty():
		return 0
	var vals: Array = u["vals"]
	var lv := clampi(int(data["lv"].get(id, 0)), 0, vals.size() - 1)
	return vals[lv]

func current_biome() -> Dictionary:
	return GameData.get_biome(str(data["biome"]))

func max_world_depth() -> int:
	return int(current_biome()["max_depth"])

func max_depth() -> int:
	return mini(int(up("rod")), max_world_depth())

func is_night() -> bool:
	var h := fmod(float(data["minutes"]) / 60.0, 24.0)
	return h >= 20.0 or h < 6.0

func get_weather() -> Dictionary:
	var idx := int(int(data["minutes"]) / 180) % GameData.WEATHERS.size()
	return GameData.WEATHERS[idx]

func active_bait() -> Dictionary:
	return GameData.get_bait(str(data["active_bait"]))

func get_rank_info() -> Dictionary:
	var cur: Dictionary = GameData.RANKS[0]
	var nxt: Dictionary = GameData.RANKS[1]
	var xp := int(data["xp"])
	for i in range(GameData.RANKS.size()):
		if xp >= int(GameData.RANKS[i]["xp"]):
			cur = GameData.RANKS[i]
			nxt = GameData.RANKS[i + 1] if i + 1 < GameData.RANKS.size() else {}
	var pct := 1.0
	if not nxt.is_empty():
		pct = clampf(float(xp - int(cur["xp"])) / float(int(nxt["xp"]) - int(cur["xp"])), 0.0, 1.0)
	return {
		"cur": cur,
		"next": nxt,
		"pct": pct,
		"bonus_mul": 1.0 + float(int(cur["lv"]) - 1) * 0.04,
	}

func add_xp(amount: int) -> void:
	var before_lv := int(get_rank_info()["cur"]["lv"])
	data["xp"] = int(data["xp"]) + amount
	var after_cur: Dictionary = get_rank_info()["cur"]
	var after_lv := int(after_cur["lv"])
	if after_lv > before_lv:
		level_up_achieved.emit(after_lv, str(after_cur["title"]))
		toast_requested.emit("⬆️ Seviye %d: %s! (+%%%d fiyat bonusu)" % [after_lv, str(after_cur["title"]), (after_lv - 1) * 4])

# ---------------- Günlük Balık Pazarı ----------------
func ensure_market() -> void:
	var day := int(int(data["minutes"]) / (24 * 60))
	if int(data["market_day"]) != day or (data["market_hot"] as Array).is_empty():
		data["market_day"] = day
		var hot_r := 1 + (day % 3)
		var pool: Array[Dictionary] = []
		var md := max_depth() + 15
		for s in GameData.species:
			if not s.get("boss", false) and int(s["d"][0]) <= md:
				pool.append(s)
		if pool.is_empty():
			pool = GameData.species.duplicate()
		var p1: Dictionary = pool[(day * 17 + 3) % pool.size()]
		var p2: Dictionary = pool[(day * 31 + 7) % pool.size()]
		data["market_hot"] = [
			{"kind": "rarity", "r": hot_r, "label": "%s Balıklar" % GameData.RARITIES[hot_r]["name"]},
			{"kind": "species", "id": p1["id"], "label": p1["name"]},
			{"kind": "species", "id": p2["id"], "label": p2["name"]},
		]
		save_game()

func is_hot_demand(sp: Dictionary) -> bool:
	ensure_market()
	for h in data["market_hot"]:
		if h["kind"] == "rarity" and int(h["r"]) == int(sp["r"]):
			return true
		if h["kind"] == "species" and str(h["id"]) == str(sp["id"]):
			return true
	return false

func get_market_customer() -> Dictionary:
	var day := int(int(data["minutes"]) / (12 * 60))
	return GameData.MARKET_CUSTOMERS[day % GameData.MARKET_CUSTOMERS.size()]

func matches_customer_order(item: Dictionary, customer: Dictionary) -> bool:
	var sp := GameData.get_species(str(item.get("sp_id", "")))
	var kind := str(customer.get("want_kind", ""))
	match kind:
		"rare":    return int(sp.get("r", 0)) >= 2
		"shallow": return int(item.get("depth_m", 0)) <= 35
		"heavy":   return float(item.get("kg", 0.0)) >= 3.0
		"deep":    return int(item.get("depth_m", 0)) >= 40
	return false

func calc_market_price(item: Dictionary, haggle_mul: float = 1.0) -> int:
	var sp := GameData.get_species(str(item.get("sp_id", "")))
	var cust := get_market_customer()
	var mult := haggle_mul
	if is_hot_demand(sp):
		mult *= 1.5
	if matches_customer_order(item, cust):
		mult *= float(cust.get("bonus", 1.5))
	return maxi(2, int(round(float(item.get("base_val", 10)) * mult)))

func calc_fish_value(sp: Dictionary, kg: float, depth_m: int, combo: int, frenzy: bool, include_hot: bool = true) -> int:
	var w := get_weather()
	var biome := current_biome()
	var bait := active_bait()
	var rank := get_rank_info()
	var hook_bonus := 1.0 + float(up("hook")) / 100.0
	var combo_mul := 1.0 + minf(0.5, maxf(0.0, float(combo - 1)) * 0.1)
	var frenzy_mul := 2.0 if frenzy else 1.0
	var hot_mul := 1.5 if (include_hot and is_hot_demand(sp)) else 1.0
	var raw := kg * float(sp["val"]) * (1.0 + float(depth_m) / 115.0) * float(w["val_mul"]) * float(biome["val_mul"]) * float(bait["val_mul"]) * float(rank["bonus_mul"]) * hook_bonus * combo_mul * frenzy_mul * hot_mul
	return maxi(2, int(round(raw)))

# ---------------- Akvaryum Pasif Gelir ----------------
func aqua_fish_income(item: Dictionary) -> int:
	var sp := GameData.get_species(str(item["sp_id"]))
	return maxi(4, int(round(6.0 + float(sp.get("r", 0)) * 14.0 + sqrt(float(item.get("kg", 1.0))) * 5.0)))

func aqua_rate_per_min() -> int:
	var aq: Array = data["aquarium"]
	if aq.is_empty():
		return 0
	var base := 0
	for item in aq:
		base += aqua_fish_income(item)
	var fed_mul := 2 if Time.get_ticks_msec() < aqua_fed_until_msec else 1
	return base * fed_mul

func tick_aquarium_income(dt: float) -> void:
	var rate := aqua_rate_per_min()
	if rate <= 0:
		return
	var max_bank := maxf(250.0, float(rate * 12))
	var bank := float(data["aqua_bank"])
	# Çevrimdışı gelirle tavanı aşmış bir kasa oyunda geri kırpılmasın.
	if bank >= max_bank:
		return
	data["aqua_bank"] = minf(max_bank, bank + (float(rate) / 60.0) * dt)

func tick_play_time(dt: float) -> void:
	var st: Dictionary = data["stats"]
	st["play_secs"] = float(st.get("play_secs", 0.0)) + dt

## Oyun kapalıyken akvaryum ziyaretçilerinden gelen gelir (en fazla 8 saat, %50 hız).
func apply_offline_income(now_unix: int) -> Dictionary:
	var last := int(data.get("last_seen", 0))
	if last <= 0 or now_unix <= last:
		return {}
	var secs := now_unix - last
	if secs < GameData.OFFLINE_MIN_SECS:
		return {}
	var aq: Array = data["aquarium"]
	if aq.is_empty():
		return {}
	var base := 0
	for item in aq:
		base += aqua_fish_income(item)
	var mins := minf(float(secs) / 60.0, GameData.OFFLINE_MAX_MIN)
	var gold := int(floor(float(base) * mins * GameData.OFFLINE_RATE))
	if gold <= 0:
		return {}
	data["aqua_bank"] = float(data["aqua_bank"]) + float(gold)
	data["last_seen"] = now_unix
	return {"secs": secs, "gold": gold}

func total_catches() -> int:
	var n := 0
	for rec in (data["book"] as Dictionary).values():
		n += int(rec.get("n", 0))
	return n

func has_progress() -> bool:
	return int(data["casts"]) > 0 or not (data["book"] as Dictionary).is_empty() or int(data["money"]) > 0

# ---------------- Günlük Giriş Ödülü ----------------
static func _day_number(date_str: String) -> int:
	if date_str.is_empty():
		return -999999
	return int(Time.get_unix_time_from_datetime_string(date_str + "T12:00:00") / 86400)

func today_str() -> String:
	return Time.get_date_string_from_system()

## {"available": bool, "day_idx": 0-6 (alınacak/son alınan gün), "streak": int}
func daily_status(today: String = "") -> Dictionary:
	if today.is_empty():
		today = today_str()
	var dl: Dictionary = data["daily"]
	var last := str(dl.get("last_date", ""))
	var streak := int(dl.get("streak", 0))
	if last == today:
		return {"available": false, "day_idx": (maxi(1, streak) - 1) % 7, "streak": streak}
	var gap := _day_number(today) - _day_number(last)
	var next_streak := streak + 1 if gap == 1 else 1
	return {"available": true, "day_idx": (next_streak - 1) % 7, "streak": next_streak}

func daily_gold(day_idx: int) -> int:
	var rw: Dictionary = GameData.DAILY_REWARDS[clampi(day_idx, 0, 6)]
	var lv := int(get_rank_info()["cur"]["lv"])
	return int(round(float(rw["gold"]) * (1.0 + float(lv - 1) * 0.15)))

func claim_daily(today: String = "") -> Dictionary:
	if today.is_empty():
		today = today_str()
	var st := daily_status(today)
	if not bool(st["available"]):
		return {}
	var idx := int(st["day_idx"])
	var rw: Dictionary = GameData.DAILY_REWARDS[idx]
	var gold := daily_gold(idx)
	data["money"] = int(data["money"]) + gold
	data["total"] = int(data["total"]) + gold
	if rw.has("bait"):
		var bid := str(rw["bait"])
		data["baits"][bid] = int(data["baits"].get(bid, 0)) + int(rw["n"])
	data["daily"] = {"last_date": today, "streak": int(st["streak"])}
	var stats: Dictionary = data["stats"]
	stats["best_streak"] = maxi(int(stats.get("best_streak", 0)), int(st["streak"]))
	add_xp(15 + idx * 5)
	check_achievements()
	save_game()
	data_changed.emit()
	return {"gold": gold, "bait": str(rw.get("bait", "")), "n": int(rw.get("n", 0)), "day_idx": idx, "streak": int(st["streak"])}

func collect_aqua_bank() -> int:
	var amt := int(floor(float(data["aqua_bank"])))
	if amt <= 0:
		return 0
	data["aqua_bank"] = float(data["aqua_bank"]) - float(amt)
	data["money"] = int(data["money"]) + amt
	data["total"] = int(data["total"]) + amt
	progress_missions("earn_gold", float(amt))
	check_achievements()
	save_game()
	data_changed.emit()
	return amt

# ---------------- Görevler ----------------
func ensure_missions() -> void:
	var ms: Array = data["missions"]
	while ms.size() < 3:
		var existing: Array[String] = []
		for m in ms:
			existing.append(str(m["type"]))
		ms.append(_make_mission(existing))

func _make_mission(existing_types: Array[String]) -> Dictionary:
	var lv := int(get_rank_info()["cur"]["lv"])
	var tier := clampi(int(floor(float(lv - 1) / 2.5)), 0, 3)
	var cands: Array[Dictionary] = []
	for tpl in GameData.MISSION_POOL:
		if not existing_types.has(str(tpl["type"])):
			cands.append(tpl)
	var chosen: Dictionary = cands[randi() % cands.size()] if not cands.is_empty() else GameData.MISSION_POOL[randi() % GameData.MISSION_POOL.size()]
	var target := int(chosen["targets"][tier])
	var need := int(chosen.get("need", target))
	return {
		"id": "m_%d_%d" % [Time.get_ticks_msec(), randi() % 99999],
		"type": str(chosen["type"]),
		"target": target,
		"need": need,
		"prog": 0.0,
		"gold": int(chosen["gold"][tier]),
		"xp": int(chosen["xp"][tier]),
		"label": GameData.mission_label(str(chosen["type"]), target),
	}

func progress_missions(m_type: String, amount: float = 1.0, depth_m: int = 0) -> void:
	ensure_missions()
	var newly_ready := false
	for m in data["missions"]:
		if float(m["prog"]) >= float(m["need"]):
			continue
		var inc := 0.0
		if str(m["type"]) == m_type:
			if m_type == "catch_deep":
				if depth_m >= int(m["target"]):
					inc = 1.0
			else:
				inc = amount
		if inc > 0.0:
			m["prog"] = minf(float(m["need"]), snappedf(float(m["prog"]) + inc, 0.01))
			if float(m["prog"]) >= float(m["need"]):
				newly_ready = true
	if newly_ready:
		toast_requested.emit("📜 Bir görev tamamlandı! Ödülünü al (G)")

func claim_mission(id: String) -> Dictionary:
	var ms: Array = data["missions"]
	for i in range(ms.size()):
		if str(ms[i]["id"]) == id and float(ms[i]["prog"]) >= float(ms[i]["need"]):
			var m: Dictionary = ms[i]
			data["money"] = int(data["money"]) + int(m["gold"])
			data["total"] = int(data["total"]) + int(m["gold"])
			add_xp(int(m["xp"]))
			ms.remove_at(i)
			ensure_missions()
			check_achievements()
			save_game()
			data_changed.emit()
			return m
	return {}

# ---------------- Başarımlar ----------------
func _check_ach_condition(ach_id: String) -> bool:
	var book_n := (data["book"] as Dictionary).size()
	var st: Dictionary = data["stats"]
	match ach_id:
		"first_catch": return book_n >= 1
		"species_10":  return book_n >= 10
		"species_30":  return book_n >= 30
		"species_75":  return book_n >= 75
		"species_150": return book_n >= 150
		"combo_5":     return int(st.get("max_combo", 0)) >= 5
		"combo_10":    return int(st.get("max_combo", 0)) >= 10
		"perfect_5":   return int(st.get("perfect_casts", 0)) >= 5
		"heavy_15":    return float(st.get("heaviest", 0.0)) >= 15.0
		"heavy_40":    return float(st.get("heaviest", 0.0)) >= 40.0
		"treasure_3":  return int(st.get("treasures", 0)) >= 3
		"night_5":     return int(st.get("night_catches", 0)) >= 5
		"storm_5":     return int(st.get("rain_catches", 0)) >= 5
		"deep_100":    return int(st.get("deepest", 0)) >= 100
		"legendary_1": return int(st.get("legendaries", 0)) >= 1
		"rich_5000":   return int(data["total"]) >= 5000
		"biome_all":     return (data["biomes"] as Array).size() >= 6
		"boat_owner":    return int(data["lv"].get("boat", 0)) >= 1
		"aqua_3":        return (data["aquarium"] as Array).size() >= 3
		"boss_1":        return int(st.get("bosses", 0)) >= 1
		"tourney_1":     return int(st.get("tourney_wins", 0)) >= 1
		"market_haggle": return int(st.get("haggles", 0)) >= 1
		"catch_100":     return total_catches() >= 100
		"hook_10":       return int(st.get("perfect_hooks", 0)) >= 10
		"species_300":   return book_n >= 300
		"streak_7":      return int(st.get("best_streak", 0)) >= 7
	return false

# ---------------- Bölge Koleksiyonu ----------------
const COLLECTION_STEPS: Array[int] = [25, 50, 75, 100]

## [yakalanan, toplam] — o bölgeyi yuva edinen türler
func biome_collection(biome_id: String) -> Array:
	var total := 0
	var got := 0
	var book: Dictionary = data["book"]
	for sp in GameData.species:
		if sp.has("home") and (sp["home"] as Array).has(biome_id):
			total += 1
			if book.has(str(sp["id"])):
				got += 1
	return [got, total]

func collection_reward(biome_id: String, step: int) -> int:
	var b := GameData.get_biome(biome_id)
	return int(round((250.0 + float(b["cost"]) * 0.2) * float(step) / 25.0))

## Yeni ulaşılan kilometre taşlarını öder; ödenenleri döndürür
func check_collections() -> Array:
	var paid: Array = []
	var ms: Dictionary = data.get("collections", {})
	for b in GameData.BIOMES:
		var bid := str(b["id"])
		var gt := biome_collection(bid)
		if int(gt[1]) <= 0:
			continue
		var pct := float(gt[0]) * 100.0 / float(gt[1])
		for step in COLLECTION_STEPS:
			if pct >= float(step) and int(ms.get(bid, 0)) < step:
				ms[bid] = step
				var rew := collection_reward(bid, step)
				data["money"] = int(data["money"]) + rew
				data["total"] = int(data["total"]) + rew
				add_xp(30 + step)
				paid.append({"biome": bid, "step": step, "gold": rew})
				toast_requested.emit("🗺️ %s %s koleksiyonu %%%d! (+%d altın)" % [str(b["icon"]), str(b["name"]), step, rew])
	data["collections"] = ms
	return paid

func check_achievements() -> Array[Dictionary]:
	check_collections()
	var unlocked: Array[Dictionary] = []
	var achs: Dictionary = data["achievements"]
	for a in GameData.ACHIEVEMENTS:
		var aid := str(a["id"])
		if achs.has(aid):
			continue
		if _check_ach_condition(aid):
			achs[aid] = Time.get_unix_time_from_system()
			var rew := int(a["reward"])
			data["money"] = int(data["money"]) + rew
			data["total"] = int(data["total"]) + rew
			add_xp(40)
			unlocked.append(a)
			achievement_unlocked.emit(a)
			toast_requested.emit("🎖️ Başarım: %s (+%d altın!)" % [str(a["name"]), rew])
	if not unlocked.is_empty():
		save_game()
		data_changed.emit()
	return unlocked

# ---------------- Satın Alma & Yem ----------------
func buy_upgrade(id: String) -> bool:
	var u := GameData.get_upgrade(id)
	if u.is_empty():
		return false
	var lv := int(data["lv"].get(id, 0))
	var vals: Array = u["vals"]
	if lv >= vals.size() - 1:
		return false
	var cost := int(u["cost"][lv + 1])
	if int(data["money"]) < cost:
		return false
	data["money"] = int(data["money"]) - cost
	data["lv"][id] = lv + 1
	check_achievements()
	save_game()
	data_changed.emit()
	return true

func buy_bait(id: String) -> bool:
	var b := GameData.get_bait(id)
	if b.get("infinite", false):
		return false
	var cost := int(b["cost"])
	if int(data["money"]) < cost:
		return false
	data["money"] = int(data["money"]) - cost
	data["baits"][id] = int(data["baits"].get(id, 0)) + int(b["pack"])
	data["active_bait"] = id
	save_game()
	data_changed.emit()
	return true

func select_bait(id: String) -> bool:
	var b := GameData.get_bait(id)
	if not b.get("infinite", false) and int(data["baits"].get(id, 0)) <= 0:
		return false
	data["active_bait"] = id
	save_game()
	data_changed.emit()
	return true

func consume_bait() -> void:
	var b := active_bait()
	if b.get("infinite", false):
		return
	var bid := str(b["id"])
	var left := maxi(0, int(data["baits"].get(bid, 0)) - 1)
	data["baits"][bid] = left
	if left <= 0:
		data["active_bait"] = "worm"
		toast_requested.emit("%s %s bitti — Solucan'a geçildi" % [str(b["icon"]), str(b["name"])])
	save_game()
	data_changed.emit()

func switch_biome(id: String) -> bool:
	var b := GameData.get_biome(id)
	var owned: Array = data["biomes"]
	if not owned.has(id):
		var cost := int(b["cost"])
		if int(data["money"]) < cost:
			return false
		data["money"] = int(data["money"]) - cost
		owned.append(id)
	data["biome"] = id
	check_achievements()
	save_game()
	data_changed.emit()
	return true
