extends SceneTree

## Olta Gölü (Godot 4.7) Kapsamlı Otomatik Test Paketi
## Çalıştırma:
##   godot --headless --path . --script res://tests/test_runner.gd

var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	await _run_all()
	print("==========================================")
	print("OLTA GÖLÜ TEST SONUCU: %d geçti, %d başarısız" % [passed, failed])
	print("==========================================")
	quit(1 if failed > 0 else 0)

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

	# 1. Balık veritabanı & 150+ tür & tüm görsellerin yüklenmesi
	check(gd.species.size() >= 150, "species_count_150_plus", "got %d" % gd.species.size())
	var missing_tex := 0
	var missing_info := 0
	for sp in gd.species:
		if str(sp.get("fact", "")).is_empty() or str(sp.get("habitat", "")).is_empty() or str(sp.get("diet", "")).is_empty() or str(sp.get("latin", "")).is_empty():
			missing_info += 1
		var tex: Texture2D = gd.get_fish_texture(str(sp["spr"]))
		if tex == null:
			missing_tex += 1
	check(missing_info == 0, "all_species_have_encyclopedia_info", "missing=%d" % missing_info)
	check(missing_tex == 0, "all_species_textures_load", "missing=%d" % missing_tex)

	# Tehlike ve ortam görselleri
	for h_spr in gd.HAZARD_SPRITES:
		check(gd.get_fish_texture(h_spr) != null, "hazard_tex_" + h_spr)
	for e_spr in ["bubble_a", "seaweed_green_a", "rock_a", "terrain_sand_top_a", "terrain_dirt_a"]:
		check(gd.get_env_texture(e_spr) != null, "env_tex_" + e_spr)

	# 4 Bölge Bossu
	check(gd.boss_species.size() == 4, "four_biome_bosses", "got %d" % gd.boss_species.size())
	for b in gd.BIOMES:
		var boss: Dictionary = gd.get_boss_for_biome(str(b["id"]))
		check(not boss.is_empty() and str(boss.get("biome", "")) == str(b["id"]), "boss_for_" + str(b["id"]))

	# 2. SaveManager & Ekonomi & Pazar & Görevler & Akvaryum
	sm.reset_save()
	check(int(sm.data["money"]) == 0, "reset_money_zero")
	check((sm.data["missions"] as Array).size() == 3, "three_initial_missions")
	check((sm.data["market_hot"] as Array).size() == 3, "three_market_hot_items")

	sm.data["money"] = 12000
	check(sm.buy_upgrade("rod"), "buy_rod_upgrade")
	check(sm.buy_upgrade("boat"), "buy_boat_upgrade")
	check(sm.buy_upgrade("aquarium"), "buy_aquarium_upgrade")
	check(sm.buy_bait("golden"), "buy_golden_bait")
	check(sm.switch_biome("coral"), "unlock_coral_biome")
	check(sm.switch_biome("fjord"), "unlock_fjord_biome")
	check(sm.switch_biome("volcano"), "unlock_volcano_biome")
	check((sm.data["biomes"] as Array).size() == 4, "all_4_biomes_unlocked")
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

	# 3. Main sahnesi kurulumu & canlı simülasyon testi
	var packed := load("res://scenes/main.tscn") as PackedScene
	check(packed != null, "load_main_tscn")
	var main_node := packed.instantiate()
	root.add_child(main_node)
	await process_frame

	main_node.start_game()
	var world = main_node.world
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
	for p_id in ["shop", "aquarium", "tournament", "basket", "missions", "book"]:
		main_node.open_panel(p_id)
		await process_frame
		check(main_node._current_panel == p_id, "panel_render_" + p_id)
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
