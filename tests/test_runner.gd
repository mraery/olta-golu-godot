extends SceneTree

## Olta Gölü (Godot 4.7) Kapsamlı Otomatik Test Paketi
## Çalıştırma:
##   godot --headless --path . --script res://tests/test_runner.gd

var passed: int = 0
var failed: int = 0

var _save_backup: String = ""
var _had_save: bool = false
const _SAVE := "user://olta_golu_save.json"

func _initialize() -> void:
	# Oyuncunun gerçek kaydını yedekle; testler bitince geri yüklenir.
	_had_save = FileAccess.file_exists(_SAVE)
	if _had_save:
		_save_backup = FileAccess.get_file_as_string(_SAVE)
	await _run_all()
	_restore_save()
	print("==========================================")
	print("OLTA GÖLÜ TEST SONUCU: %d geçti, %d başarısız" % [passed, failed])
	print("==========================================")
	quit(1 if failed > 0 else 0)

func _restore_save() -> void:
	if _had_save:
		var f := FileAccess.open(_SAVE, FileAccess.WRITE)
		if f != null:
			f.store_string(_save_backup)
			f.close()
		var sm := root.get_node_or_null("SaveManager")
		if sm != null:
			sm.load_save()
	elif FileAccess.file_exists(_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_SAVE))

func check(cond: bool, label: String, detail: String = "") -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL [%s] %s" % [label, detail])

func _run_all() -> void:
	await process_frame
	var gd := root.get_node_or_null("GameData")
	var sm := root.get_node_or_null("SaveManager")
	var am := root.get_node_or_null("AudioManager")
	check(gd != null, "autoload_gamedata")
	check(sm != null, "autoload_savemanager")
	check(am != null, "autoload_audiomanager")
	if gd == null or sm == null:
		return

	# 1. Balık veritabanı & 261 tür & tüm hikayeler & tüm görsellerin yüklenmesi
	check(gd.species.size() >= 250, "species_count_250_plus", "got %d" % gd.species.size())
	var missing_tex := 0
	var missing_info := 0
	var missing_story := 0
	for sp in gd.species:
		if str(sp.get("fact", "")).is_empty() or str(sp.get("habitat", "")).is_empty() or str(sp.get("diet", "")).is_empty() or str(sp.get("latin", "")).is_empty():
			missing_info += 1
		if str(sp.get("story", "")).is_empty():
			missing_story += 1
		var tex: Texture2D = gd.get_fish_texture(str(sp["spr"]))
		if tex == null:
			missing_tex += 1
	check(missing_info == 0, "all_species_have_encyclopedia_info", "missing=%d" % missing_info)
	check(missing_story == 0, "all_species_have_short_story", "missing=%d" % missing_story)
	check(missing_tex == 0, "all_species_textures_load", "missing=%d" % missing_tex)

	# Tehlike ve ortam görselleri
	for h_spr in gd.HAZARD_SPRITES:
		check(gd.get_fish_texture(h_spr) != null, "hazard_tex_" + h_spr)
	for e_spr in ["bubble_a", "seaweed_green_a", "rock_a", "terrain_sand_top_a", "terrain_dirt_a"]:
		check(gd.get_env_texture(e_spr) != null, "env_tex_" + e_spr)

	# 6 Göl/Bölge & 6 Bölge Bossu
	check(gd.BIOMES.size() == 6, "six_cute_2d_lakes", "got %d" % gd.BIOMES.size())
	check(gd.boss_species.size() == 6, "six_biome_bosses", "got %d" % gd.boss_species.size())
	for b in gd.BIOMES:
		var boss: Dictionary = gd.get_boss_for_biome(str(b["id"]))
		check(not boss.is_empty() and str(boss.get("biome", "")) == str(b["id"]), "boss_for_" + str(b["id"]))

	# 2. SaveManager & Ekonomi & 2D Balık Pazarı & Görevler & Akvaryum
	sm.reset_save()
	check(int(sm.data["money"]) == 0, "reset_money_zero")
	check((sm.data["missions"] as Array).size() == 3, "three_initial_missions")
	check((sm.data["market_hot"] as Array).size() == 3, "three_market_hot_items")
	check(not sm.get_market_customer().is_empty(), "market_customer_present")
	var sample_item := {"sp_id": "king", "kg": 15.0, "depth_m": 130, "base_val": 100}
	check(sm.calc_market_price(sample_item, 1.25) > 100, "market_price_with_haggle_bonus")

	sm.data["money"] = 20000
	check(sm.buy_upgrade("rod"), "buy_rod_upgrade")
	check(sm.buy_upgrade("boat"), "buy_boat_upgrade")
	check(sm.buy_upgrade("aquarium"), "buy_aquarium_upgrade")
	check(sm.buy_bait("golden"), "buy_golden_bait")
	check(sm.switch_biome("sakura"), "unlock_sakura_lake")
	check(sm.switch_biome("coral"), "unlock_coral_biome")
	check(sm.switch_biome("emerald"), "unlock_emerald_lake")
	check(sm.switch_biome("fjord"), "unlock_fjord_biome")
	check(sm.switch_biome("volcano"), "unlock_volcano_biome")
	check((sm.data["biomes"] as Array).size() == 6, "all_6_lakes_unlocked")
	check(sm.data["achievements"].has("biome_all"), "ach_biome_all_unlocked")
	check(sm.data["achievements"].has("boat_owner"), "ach_boat_owner_unlocked")

	# XP & Rütbe seviye atlama
	sm.add_xp(400)
	check(int(sm.get_rank_info()["cur"]["lv"]) >= 3, "rank_level_up")

	# Akvaryum pasif gelir + 2x besleme + toplama
	sm.data["aquarium"].append({"uid": "t1", "sp_id": "king", "kg": 25.0, "base_val": 400})
	var r1: int = sm.aqua_rate_per_min()
	check(r1 > 0, "aqua_income_rate_positive")
	sm.aqua_fed_until_msec = Time.get_ticks_msec() + 60000
	var r2: int = sm.aqua_rate_per_min()
	check(r2 == r1 * 2, "aqua_fed_2x_boost")
	sm.tick_aquarium_income(120.0)
	var collected: int = sm.collect_aqua_bank()
	check(collected > 0, "aqua_collect_bank_positive")

	# Kasa tavanı aşıldığında oyun içi tik kasayı geri kırpmamalı
	sm.data["aqua_bank"] = 99999.0
	sm.tick_aquarium_income(1.0)
	check(float(sm.data["aqua_bank"]) >= 99999.0, "aqua_tick_does_not_shrink_bank")
	sm.data["aqua_bank"] = 0.0

	# Çevrimdışı akvaryum geliri
	var now := int(Time.get_unix_time_from_system())
	sm.data["last_seen"] = now - 3600
	var off: Dictionary = sm.apply_offline_income(now)
	check(not off.is_empty() and int(off["gold"]) > 0, "offline_income_after_1h")
	var base_rate := 0
	for it in sm.data["aquarium"]:
		base_rate += sm.aqua_fish_income(it)
	check(int(off.get("gold", 0)) == int(floor(base_rate * 60.0 * 0.5)), "offline_income_amount", str(off))
	sm.data["last_seen"] = now - 86400 * 3
	var off_cap: Dictionary = sm.apply_offline_income(now)
	check(int(off_cap.get("gold", 0)) == int(floor(base_rate * 480.0 * 0.5)), "offline_income_capped_8h")
	sm.data["last_seen"] = now - 30
	check(sm.apply_offline_income(now).is_empty(), "offline_income_ignores_short_gap")
	sm.data["aqua_bank"] = 0.0

	# Günlük giriş ödülü serisi
	sm.data["daily"] = {"last_date": "", "streak": 0}
	var m0 := int(sm.data["money"])
	var c1: Dictionary = sm.claim_daily("2026-03-01")
	check(not c1.is_empty() and int(c1["day_idx"]) == 0, "daily_claim_day1")
	check(int(sm.data["money"]) == m0 + int(c1["gold"]), "daily_gold_added")
	check(sm.claim_daily("2026-03-01").is_empty(), "daily_no_double_claim")
	var c2: Dictionary = sm.claim_daily("2026-03-02")
	check(int(c2.get("streak", 0)) == 2 and str(c2.get("bait", "")) == "shrimp", "daily_streak_2_with_bait")
	var c3: Dictionary = sm.claim_daily("2026-03-05")
	check(int(c3.get("streak", 0)) == 1, "daily_streak_resets_after_gap")
	sm.data["daily"] = {"last_date": "2026-02-28", "streak": 6}
	var c7: Dictionary = sm.claim_daily("2026-03-01")
	check(int(c7.get("day_idx", -1)) == 6, "daily_day7_across_month")
	check(sm.data["achievements"].has("streak_7"), "ach_streak_7_unlocked")
	var c8: Dictionary = sm.claim_daily("2026-03-02")
	check(int(c8.get("day_idx", -1)) == 0 and int(c8.get("streak", 0)) == 8, "daily_cycle_wraps")

	# 100 av başarımı
	sm.data["book"]["test_sp"] = {"n": 100, "max": 1.0, "deep": 5}
	sm.check_achievements()
	check(sm.data["achievements"].has("catch_100"), "ach_catch_100_unlocked")
	sm.data["book"].erase("test_sp")

	# Yeni türler: kimlik bilgisi, karakter, ekran boyu
	check(gd.species.size() >= 370, "species_count_370_plus", "got %d" % gd.species.size())
	var gen_n := 0
	var gen_missing := 0
	var bad_beh := 0
	var bad_px := 0
	var ids := {}
	var dup := 0
	for sp in gd.species:
		if ids.has(sp["id"]): dup += 1
		ids[sp["id"]] = true
		if str(sp["spr"]).begins_with("fish_gen_"):
			gen_n += 1
			if not (sp.has("len") and sp.has("life") and sp.has("tr") and sp.has("home")):
				gen_missing += 1
		if not gd.BEHAVIORS.has(gd.fish_behavior(sp)): bad_beh += 1
		var px: float = gd.fish_used_width(str(sp["spr"])) * gd.fish_draw_scale(sp, 0.5)
		if px < 24.0 or px > 170.0: bad_px += 1
	check(gen_n >= 110, "generated_species_110_plus", "got %d" % gen_n)
	check(gen_missing == 0, "generated_species_have_identity", "missing=%d" % gen_missing)
	check(bad_beh == 0, "all_species_have_behavior")
	check(bad_px == 0, "all_species_visible_on_screen_size", "bad=%d" % bad_px)
	check(dup == 0, "species_ids_unique", "dup=%d" % dup)
	var lufer: Dictionary = gd.get_species("lufer")
	check(str(lufer.get("latin", "")) == "Pomatomus saltatrix", "lufer_present")
	check(str(gd.size_class(0.1)[0]).contains("Yavru") and str(gd.size_class(1.2)[0]).contains("Efsanevi"), "size_classes")
	check(gd.est_length_cm(lufer, float(lufer["kg"][1])) > gd.est_length_cm(lufer, float(lufer["kg"][0])), "est_length_grows_with_kg")

	# 3. Main sahnesi kurulumu & canlı simülasyon testi
	var packed := load("res://scenes/main.tscn") as PackedScene
	check(packed != null, "load_main_tscn")
	var main_node := packed.instantiate()
	root.add_child(main_node)
	await process_frame

	check(main_node._menu_box.get_child_count() >= 2, "menu_continue_shown_with_progress")
	main_node.start_game()
	var world = main_node.world
	check(main_node._current_panel == "daily", "daily_panel_auto_opens_on_start")
	main_node.close_panels()
	check(world.state == "idle", "state_idle_after_start")

	# Mükemmel atış
	world.start_charge()
	world.cast_power = 78.0
	world.release_charge()
	check(world.state == "sinking", "state_sinking_after_cast")
	check(world.perfect_cast == true, "perfect_cast_detected")

	# 5 kare simülasyon
	for _i in range(5):
		await process_frame

	# Savaş & Balık yakalama & Satma / Sepet / Akvaryum
	var sample_fish: Dictionary = world.fishes[0]
	world.start_fight(sample_fish)
	check(world.state == "fight", "state_fight")
	world.end_fight(true)
	check(world.state == "rising", "state_rising_after_win")
	world.land_catch()
	check(world.state == "catch", "state_catch_modal")
	main_node._close_catch("basket")
	check((sm.data["basket"] as Array).size() == 1, "fish_added_to_basket")

	# Yeni çekişme: kanca atma, hareketli bölge, yan çekiş, dayanıklılık
	var f2: Dictionary = world.fishes[1]
	world.start_fight(f2)
	check(world.fight["phase"] == "hook", "fight_starts_with_hookset")
	world.on_fight_press()
	check(world.fight["phase"] == "fight" and world.fight["hook_q"] == "perfect", "perfect_hookset")
	check(float(world.fight["progress"]) > 0.15, "perfect_hook_progress_bonus")
	var lo0 := float(world.fight["lo"])
	var moved := false
	world.input_hold = false
	for _k in range(40):
		world._update_fight(0.05, 2000.0)
		if world.state != "fight": break
		if absf(float(world.fight["lo"]) - lo0) > 0.5: moved = true
	check(moved, "fight_zone_moves")
	if world.state == "fight":
		world.fight["pull"] = -1
		world.fight["pull_left"] = 5.0
		world.fight["surge"] = 0.0
		world.fight["warn_t"] = 0.0
		world.fight["surge_t"] = 99.0
		world.fight["tension"] = 50.0
		world.input_right = true
		world._update_fight(0.1, 2000.0)
		var t_counter := float(world.fight["tension"])
		world.input_right = false
		world.fight["tension"] = 50.0
		world._update_fight(0.1, 2000.0)
		var t_wrong := float(world.fight["tension"])
		check(t_counter < t_wrong, "counter_pull_lowers_tension", "%f vs %f" % [t_counter, t_wrong])
		var st0 := float(world.fight["stamina"])
		world.fight["pull"] = 0
		world.fight["tension"] = (float(world.fight["lo"]) + float(world.fight["hi"])) * 0.5
		world.input_hold = true
		world._update_fight(0.1, 2000.0)
		world.input_hold = false
		check(float(world.fight["stamina"]) < st0, "stamina_drains_in_zone")
		world.end_fight(true)
	world.land_catch()
	check(world.state == "catch", "catch_after_new_fight")
	main_node._close_catch("sell")
	var f3: Dictionary = world.fishes[2]
	world.start_fight(f3)
	world._update_fight(1.0, 2000.0)
	check(world.fight["hook_q"] == "miss", "late_hookset_is_weak")
	world.end_fight(false, "escape")
	for _k in range(200):
		await process_frame
		if world.state == "idle": break
	world.set_game_state("idle")

	# Hazine yakalama
	world.hook["treasure"] = world.treasures[0]
	world.land_treasure()
	check(world.state == "treasure", "state_treasure_modal")
	main_node._close_treasure()
	check(world.state == "idle", "state_idle_after_treasure")

	# Turnuva başlat & kazan
	check(world.start_tournament("bronze"), "start_bronze_tourney")
	world.finish_tournament(true)
	check(int(sm.data["stats"]["tourney_wins"]) == 1, "tourney_win_recorded")

	# Boss doğurma
	world.spawn_boss()
	check(not world.boss_ref.is_empty(), "boss_spawned")

	# Tüm 6 paneli sırayla açıp hatasız render edildiğini doğrula
	for p_id in ["shop", "aquarium", "tournament", "basket", "missions", "book", "daily"]:
		main_node.open_panel(p_id)
		await process_frame
		check(main_node._current_panel == p_id, "panel_render_" + p_id)
	main_node._book_filter = "stats"
	main_node.open_panel("book")
	await process_frame
	check(main_node._panel_body.get_child_count() >= 2, "book_stats_tab_render")
	main_node._book_filter = "all"
	check(float(sm.data["stats"]["play_secs"]) > 0.0, "play_time_tracked")
	# Ansiklopedi detay kartını aç
	var caught_id := str((sm.data["book"] as Dictionary).keys()[0])
	main_node._open_fish_detail(caught_id)
	check(main_node._detail_overlay.visible, "fish_detail_modal_visible")
	main_node.close_panels()
	check(world.state == "idle", "close_panels_returns_idle")

	# Test verisini temizle (kullanıcı temiz başlasın)
	main_node.queue_free()
	sm.reset_save()
	await process_frame
