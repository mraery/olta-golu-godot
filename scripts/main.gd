extends Node

## Ana oyun kontrolcüsü: WorldCanvas + tüm HUD, diyaloglar, mağaza, sepet, akvaryum,
## turnuva, görevler, günlük ve balık ansiklopedisi arayüzü.

@onready var world: WorldCanvas = $WorldCanvas
@onready var ui: CanvasLayer = $UI

var _hud_bar: HBoxContainer
var _lbl_money: Label
var _lbl_depth: Label
var _lbl_clock: Label
var _lbl_weather: Label
var _btn_biome: Button
var _lbl_level: Label
var _xp_bar: ProgressBar
var _lbl_combo: Label
var _btn_basket: Button
var _btn_missions: Button
var _btn_aqua: Button
var _btn_sound: Button
var _btn_daily: Button
var _menu_box: VBoxContainer
var _reset_armed: bool = false
var _autosave_t: float = 0.0

var _lbl_zone: Label
var _lbl_frenzy: Label
var _lbl_boss: Label
var _tourney_box: PanelContainer
var _lbl_tourney_title: Label
var _lbl_tourney_prog: Label
var _lbl_tourney_clock: Label
var _tourney_bar: ProgressBar

var _bait_bar: HBoxContainer
var _lbl_hint: Label
var _toast_box: VBoxContainer

var _cast_panel: PanelContainer
var _cast_needle: ColorRect
var _fight_panel: PanelContainer
var _lbl_fight_title: Label
var _lbl_fight_warn: Label
var _fight_zone: ColorRect
var _fight_needle: ColorRect
var _fight_prog: ProgressBar

var _menu_overlay: ColorRect
var _catch_overlay: ColorRect
var _treasure_overlay: ColorRect
var _panel_overlay: ColorRect
var _detail_overlay: ColorRect

var _panel_title: Label
var _panel_body: VBoxContainer
var _panel_extra: Label

var _current_panel: String = ""
var _shop_tab: String = "upgrades"
var _book_filter: String = "all"
var _last_catch: Dictionary = {}
var _last_treasure: Dictionary = {}
var _aqua_view: AquariumView = null
var _market_view: MarketView = null
var _haggle_mul: float = 1.0
var _haggle_used: bool = false

func _ready() -> void:
	_build_ui()
	_connect_signals()
	_refresh_bait_bar()
	_refresh_hud()
	_rebuild_menu()
	_menu_overlay.visible = true

func _process(delta: float) -> void:
	if world.state == "menu":
		return
	_autosave_t += delta
	if _autosave_t >= 20.0:
		_autosave_t = 0.0
		SaveManager.save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if SaveManager.data.size() > 0:
			SaveManager.save_game()

func _connect_signals() -> void:
	world.hint_changed.connect(func(txt: String):
		_lbl_hint.text = txt
		_lbl_hint.visible = (not txt.is_empty()) and world.state != "menu"
	)
	world.cast_meter_changed.connect(func(vis: bool, pwr: float):
		_cast_panel.visible = vis
		_cast_needle.position.x = clampf(pwr / 100.0, 0.0, 1.0) * 244.0
	)
	world.fight_started.connect(func(title: String, lo: float, hi: float):
		_fight_panel.visible = true
		_lbl_fight_title.text = title
		_lbl_fight_warn.visible = false
		_fight_zone.position.x = lo / 100.0 * 380.0
		_fight_zone.size.x = (hi - lo) / 100.0 * 380.0
		_bait_bar.visible = false
	)
	world.fight_updated.connect(func(tension: float, prog: float, warn: bool):
		_fight_needle.position.x = clampf(tension, 0.0, 100.0) / 100.0 * 374.0
		_fight_prog.value = prog * 100.0
		_lbl_fight_warn.visible = warn
	)
	world.fight_ended.connect(func():
		_fight_panel.visible = false
		_bait_bar.visible = world.state != "menu"
	)
	world.fish_landed.connect(_show_catch_modal)
	world.treasure_landed.connect(_show_treasure_modal)
	world.boss_changed.connect(func(active: bool, lbl: String):
		_lbl_boss.visible = active
		_lbl_boss.text = "⚠️ BÖLGE BOSSU GÖRÜLDÜ! %s" % lbl
	)
	world.frenzy_changed.connect(func(secs: float):
		_lbl_frenzy.visible = secs > 0.0
		if secs > 0.0:
			_lbl_frenzy.text = "✨ ALTIN BALIK AKINI! 2x Altın • %ds" % int(ceil(secs))
	)
	world.tourney_changed.connect(func(active: bool, title: String, prog_txt: String, pct: float, secs: int):
		_tourney_box.visible = active
		if active:
			_lbl_tourney_title.text = title
			_lbl_tourney_prog.text = prog_txt
			_lbl_tourney_clock.text = "⏱️ %ds" % secs
			_tourney_bar.value = pct * 100.0
	)
	world.hud_dirty.connect(_refresh_hud)
	SaveManager.toast_requested.connect(_show_toast)
	SaveManager.data_changed.connect(func():
		_refresh_hud()
		_refresh_bait_bar()
	)
	SaveManager.level_up_achieved.connect(func(lv: int, _title: String):
		AudioManager.play("level_up")
		world.spawn_confetti(GameData.W * 0.5, GameData.H * 0.36, 36)
		world.add_float_text(GameData.W * 0.5, GameData.H * 0.36, "⬆️ SEVİYE %d!" % lv, Color("#4dffb8"), 24, true)
	)

# ---------------- Stil Yardımcıları ----------------
func _style_box(bg: Color, border: Color = Color(1, 1, 1, 0.2), radius: int = 12, bw: int = 2, pad: int = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad * 0.6
	sb.content_margin_bottom = pad * 0.6
	return sb

func _make_pill(text: String, text_col: Color = Color.WHITE) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", text_col)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_stylebox_override("normal", _style_box(Color(0.02, 0.1, 0.2, 0.72), Color(1, 1, 1, 0.2), 18, 2, 10))
	return lbl

func _make_btn(text: String, primary: bool = true, min_w: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	if min_w > 0.0:
		b.custom_minimum_size.x = min_w
	b.add_theme_font_size_override("font_size", 15)
	if primary:
		b.add_theme_color_override("font_color", Color("#2a1d05"))
		b.add_theme_stylebox_override("normal", _style_box(Color("#ffd24c"), Color("#c78c00"), 12, 2, 10))
		b.add_theme_stylebox_override("hover", _style_box(Color("#ffe27a"), Color("#c78c00"), 12, 2, 10))
		b.add_theme_stylebox_override("pressed", _style_box(Color("#f0b824"), Color("#9e6e00"), 12, 2, 10))
	else:
		b.add_theme_color_override("font_color", Color("#14436b"))
		b.add_theme_stylebox_override("normal", _style_box(Color("#d9eeff"), Color("#7faad1"), 12, 2, 10))
		b.add_theme_stylebox_override("hover", _style_box(Color("#eef7ff"), Color("#568ec2"), 12, 2, 10))
	return b

func _make_icon_btn(icon_txt: String, tip: String) -> Button:
	var b := Button.new()
	b.text = icon_txt
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(36, 36)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _style_box(Color(0.02, 0.1, 0.2, 0.72), Color(1, 1, 1, 0.25), 10, 2, 4))
	b.add_theme_stylebox_override("hover", _style_box(Color(0.08, 0.24, 0.42, 0.85), Color("#ffe066"), 10, 2, 4))
	return b

# ---------------- UI Kurulumu ----------------
func _build_ui() -> void:
	# Üst HUD
	_hud_bar = HBoxContainer.new()
	_hud_bar.position = Vector2(10, 8)
	_hud_bar.size = Vector2(GameData.W - 20, 42)
	_hud_bar.add_theme_constant_override("separation", 6)
	_hud_bar.visible = false
	ui.add_child(_hud_bar)

	_lbl_money = _make_pill("🪙 0", Color("#ffe066"))
	_lbl_depth = _make_pill("⬇ 0m / 30m")
	_lbl_clock = _make_pill("☀ 08:00")
	_lbl_weather = _make_pill("☀️ Açık", Color("#ffe680"))
	_btn_biome = _make_icon_btn("🏞️ Huzur Gölü", "Bölge Değiştir")
	_btn_biome.custom_minimum_size = Vector2(118, 34)
	_btn_biome.add_theme_font_size_override("font_size", 13)
	_btn_biome.pressed.connect(func(): _shop_tab = "biomes"; open_panel("shop"))

	var lv_box := HBoxContainer.new()
	lv_box.add_theme_constant_override("separation", 4)
	_lbl_level = _make_pill("Sv.1", Color("#7ce8ff"))
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(44, 10)
	_xp_bar.show_percentage = false
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lv_box.add_child(_lbl_level)
	lv_box.add_child(_xp_bar)

	_lbl_combo = _make_pill("🔥 x2", Color("#fff3b0"))
	_lbl_combo.add_theme_stylebox_override("normal", _style_box(Color("#e85d04"), Color("#fff3b0"), 18, 2, 8))
	_lbl_combo.visible = false

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var btn_shop := _make_icon_btn("🛒", "Mağaza (M)")
	btn_shop.pressed.connect(func(): toggle_panel("shop"))
	_btn_aqua = _make_icon_btn("🐠", "Canlı Akvaryum (Q)")
	_btn_aqua.pressed.connect(func(): toggle_panel("aquarium"))
	var btn_tourney := _make_icon_btn("🏆", "90 sn Turnuva (T)")
	btn_tourney.pressed.connect(func(): toggle_panel("tournament"))
	_btn_basket = _make_icon_btn("🧺", "Sepet & Pazar (B)")
	_btn_basket.pressed.connect(func(): toggle_panel("basket"))
	_btn_missions = _make_icon_btn("📜", "Görevler (G)")
	_btn_missions.pressed.connect(func(): toggle_panel("missions"))
	var btn_book := _make_icon_btn("📖", "Balıkçı Günlüğü (K)")
	btn_book.pressed.connect(func(): toggle_panel("book"))
	_btn_daily = _make_icon_btn("🎁", "Günlük Ödül (O)")
	_btn_daily.pressed.connect(func(): toggle_panel("daily"))
	_btn_sound = _make_icon_btn("🔊", "Ses (S)")
	_btn_sound.pressed.connect(_on_toggle_sound)

	for c in [_lbl_money, _lbl_depth, _lbl_clock, _lbl_weather, _btn_biome, lv_box, _lbl_combo, spacer, btn_shop, _btn_aqua, btn_tourney, _btn_basket, _btn_missions, btn_book, _btn_daily, _btn_sound]:
		_hud_bar.add_child(c)

	# Derinlik Bölgesi Etiketi
	_lbl_zone = _make_pill("Sığ Sular", Color("#69dbff"))
	_lbl_zone.position = Vector2(GameData.W - 170, 56)
	_lbl_zone.visible = false
	ui.add_child(_lbl_zone)

	# Balık Akını & Boss Afişleri
	_lbl_frenzy = _make_pill("✨ ALTIN BALIK AKINI!", Color("#3d2200"))
	_lbl_frenzy.add_theme_stylebox_override("normal", _style_box(Color("#ffd43b"), Color("#fff7c2"), 18, 2, 12))
	_lbl_frenzy.position = Vector2(280, 56)
	_lbl_frenzy.visible = false
	ui.add_child(_lbl_frenzy)

	_lbl_boss = _make_pill("⚠️ BÖLGE BOSSU!", Color("#fff6cc"))
	_lbl_boss.add_theme_stylebox_override("normal", _style_box(Color("#c92a2a"), Color("#ffd43b"), 18, 2, 12))
	_lbl_boss.position = Vector2(230, 88)
	_lbl_boss.visible = false
	ui.add_child(_lbl_boss)

	# Canlı Turnuva Barı
	_tourney_box = PanelContainer.new()
	_tourney_box.add_theme_stylebox_override("panel", _style_box(Color(0.02, 0.1, 0.2, 0.86), Color("#ffd43b"), 14, 2, 8))
	_tourney_box.position = Vector2(300, 56)
	_tourney_box.custom_minimum_size = Vector2(360, 48)
	_tourney_box.visible = false
	var tvb := VBoxContainer.new()
	var thb := HBoxContainer.new()
	_lbl_tourney_title = Label.new()
	_lbl_tourney_prog = Label.new()
	_lbl_tourney_prog.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_tourney_prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_tourney_clock = Label.new()
	_lbl_tourney_clock.add_theme_color_override("font_color", Color("#ffe066"))
	thb.add_child(_lbl_tourney_title)
	thb.add_child(_lbl_tourney_prog)
	thb.add_child(_lbl_tourney_clock)
	_tourney_bar = ProgressBar.new()
	_tourney_bar.custom_minimum_size = Vector2(0, 10)
	_tourney_bar.show_percentage = false
	tvb.add_child(thb)
	tvb.add_child(_tourney_bar)
	_tourney_box.add_child(tvb)
	ui.add_child(_tourney_box)

	# Sol Alt Yem Barı
	_bait_bar = HBoxContainer.new()
	_bait_bar.position = Vector2(10, GameData.H - 52)
	_bait_bar.add_theme_constant_override("separation", 5)
	_bait_bar.visible = false
	ui.add_child(_bait_bar)

	# Sağ Alt İpucu
	_lbl_hint = _make_pill("", Color.WHITE)
	_lbl_hint.position = Vector2(GameData.W - 430, GameData.H - 44)
	_lbl_hint.custom_minimum_size = Vector2(416, 0)
	_lbl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_hint.visible = false
	ui.add_child(_lbl_hint)

	# Bildirimler (Toast)
	_toast_box = VBoxContainer.new()
	_toast_box.position = Vector2(240, 114)
	_toast_box.custom_minimum_size = Vector2(480, 0)
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_toast_box)

	# Atış Gücü Çubuğu
	_cast_panel = PanelContainer.new()
	_cast_panel.add_theme_stylebox_override("panel", _style_box(Color(0.02, 0.1, 0.2, 0.86), Color(1, 1, 1, 0.3), 14, 2, 10))
	_cast_panel.position = Vector2(345, GameData.H - 115)
	_cast_panel.visible = false
	var cvb := VBoxContainer.new()
	var clbl := Label.new()
	clbl.text = "🎯 Atış Gücü — Yeşil bölgede bırak!"
	clbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clbl.add_theme_color_override("font_color", Color("#ffe680"))
	var ctrack := ColorRect.new()
	ctrack.custom_minimum_size = Vector2(250, 18)
	ctrack.color = Color("#355070")
	var csweet := ColorRect.new()
	csweet.position = Vector2(250.0 * 0.68, 0)
	csweet.size = Vector2(250.0 * 0.20, 18)
	csweet.color = Color("#32d976")
	_cast_needle = ColorRect.new()
	_cast_needle.size = Vector2(6, 18)
	_cast_needle.color = Color.WHITE
	ctrack.add_child(csweet)
	ctrack.add_child(_cast_needle)
	cvb.add_child(clbl)
	cvb.add_child(ctrack)
	_cast_panel.add_child(cvb)
	ui.add_child(_cast_panel)

	# Çekme Mini-Oyunu Paneli
	_fight_panel = PanelContainer.new()
	_fight_panel.add_theme_stylebox_override("panel", _style_box(Color(0.02, 0.1, 0.2, 0.86), Color(1, 1, 1, 0.25), 16, 2, 12))
	_fight_panel.position = Vector2(270, GameData.H - 122)
	_fight_panel.visible = false
	var fvb := VBoxContainer.new()
	var fhb := HBoxContainer.new()
	fhb.alignment = BoxContainer.ALIGNMENT_CENTER
	_lbl_fight_title = Label.new()
	_lbl_fight_title.text = "🐟 Balık vurdu!"
	_lbl_fight_warn = Label.new()
	_lbl_fight_warn.text = " ⚡ HAMLE! BIRAK! "
	_lbl_fight_warn.add_theme_stylebox_override("normal", _style_box(Color("#e03131"), Color.WHITE, 10, 1, 4))
	_lbl_fight_warn.visible = false
	fhb.add_child(_lbl_fight_title)
	fhb.add_child(_lbl_fight_warn)
	var ftrack := ColorRect.new()
	ftrack.custom_minimum_size = Vector2(380, 22)
	ftrack.color = Color("#3a4a5c")
	_fight_zone = ColorRect.new()
	_fight_zone.size = Vector2(180, 22)
	_fight_zone.color = Color("#36d97a")
	var danger := ColorRect.new()
	danger.position = Vector2(350, 0)
	danger.size = Vector2(30, 22)
	danger.color = Color("#e03131")
	_fight_needle = ColorRect.new()
	_fight_needle.size = Vector2(6, 22)
	_fight_needle.color = Color.WHITE
	ftrack.add_child(_fight_zone)
	ftrack.add_child(danger)
	ftrack.add_child(_fight_needle)
	_fight_prog = ProgressBar.new()
	_fight_prog.custom_minimum_size = Vector2(380, 12)
	_fight_prog.show_percentage = false
	var fhint := Label.new()
	fhint.text = "Basılı tut: makarayı sar • Bırak: gerginliği düşür"
	fhint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fhint.add_theme_font_size_override("font_size", 12)
	fvb.add_child(fhb)
	fvb.add_child(ftrack)
	fvb.add_child(_fight_prog)
	fvb.add_child(fhint)
	_fight_panel.add_child(fvb)
	ui.add_child(_fight_panel)

	_build_overlays()

func _make_overlay() -> ColorRect:
	var ov := ColorRect.new()
	ov.color = Color(0.01, 0.05, 0.1, 0.62)
	ov.position = Vector2.ZERO
	ov.size = Vector2(GameData.W, GameData.H)
	ov.visible = false
	ui.add_child(ov)
	return ov

func _make_card(parent: Control, w: float, h: float = 0.0) -> PanelContainer:
	var cc := CenterContainer.new()
	cc.position = Vector2.ZERO
	cc.size = Vector2(GameData.W, GameData.H)
	parent.add_child(cc)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(w, h)
	card.add_theme_stylebox_override("panel", _style_box(Color("#fff7e2"), Color("#c7a86a"), 20, 3, 18))
	cc.add_child(card)
	return card

func _build_overlays() -> void:
	# 1. Başlangıç Menüsü
	_menu_overlay = _make_overlay()
	var mcard := _make_card(_menu_overlay, 540, 0)
	var mvb := VBoxContainer.new()
	mvb.add_theme_constant_override("separation", 10)
	var title := Label.new()
	title.text = "🎣 Olta Gölü"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color("#0d5c8f"))
	var sub := Label.new()
	sub.text = "261 balık türü (hepsinin kısa hikayesiyle!), 6 tatlı 2D göl,\n2D Balık Pazarı, canlı akvaryum, tekne sistemi ve 6 bölge bossu!"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color("#5b4320"))
	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", 8)
	var keys := Label.new()
	keys.text = "Boşluk / Sol Tık: basılı tut & bırak (Mükemmel Atış) • ← → / A D: yönlendir & tekne sür\n1–5: yem seç • M: mağaza • Q: akvaryum • T: turnuva • B: sepet • G: görevler • K: günlük • O: günlük ödül"
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keys.add_theme_font_size_override("font_size", 12)
	keys.add_theme_color_override("font_color", Color("#7a623f"))
	for c in [title, sub, _menu_box, keys]:
		mvb.add_child(c)
	mcard.add_child(mvb)

	# 2. Yakalandı, Hazine, Genel Panel, Detay Kartı (dinamik içerikli)
	_catch_overlay = _make_overlay()
	_treasure_overlay = _make_overlay()
	_panel_overlay = _make_overlay()
	_detail_overlay = _make_overlay()

	var pcard := _make_card(_panel_overlay, 780, 460)
	var pvb := VBoxContainer.new()
	pvb.add_theme_constant_override("separation", 8)
	var phb := HBoxContainer.new()
	_panel_title = Label.new()
	_panel_title.add_theme_font_size_override("font_size", 24)
	_panel_title.add_theme_color_override("font_color", Color("#0d5c8f"))
	_panel_extra = Label.new()
	_panel_extra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_extra.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_panel_extra.add_theme_color_override("font_color", Color("#9e6500"))
	var btn_close := _make_btn("✕", false, 36)
	btn_close.pressed.connect(close_panels)
	phb.add_child(_panel_title)
	phb.add_child(_panel_extra)
	phb.add_child(btn_close)
	_panel_body = VBoxContainer.new()
	_panel_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel_body.add_theme_constant_override("separation", 8)
	pvb.add_child(phb)
	pvb.add_child(_panel_body)
	pcard.add_child(pvb)

# ---------------- Oyun Başlatma & HUD ----------------
func _rebuild_menu() -> void:
	for c in _menu_box.get_children():
		c.queue_free()
	_reset_armed = false
	if SaveManager.has_progress():
		var d := SaveManager.data
		var rank := SaveManager.get_rank_info()
		var summary := Label.new()
		summary.text = "🏅 Sv.%d %s   •   🪙 %d   •   📖 %d/%d tür   •   🐟 %d av" % [
			int(rank["cur"]["lv"]), str(rank["cur"]["title"]), int(d["money"]),
			(d["book"] as Dictionary).size(), GameData.species.size(), SaveManager.total_catches()
		]
		summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		summary.add_theme_font_size_override("font_size", 13)
		summary.add_theme_color_override("font_color", Color("#124c78"))
		summary.add_theme_stylebox_override("normal", _style_box(Color("#e8f5ff"), Color("#b5daf5"), 10, 2, 8))
		_menu_box.add_child(summary)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		var btn_cont := _make_btn("▶️ Devam Et", true, 200)
		btn_cont.add_theme_font_size_override("font_size", 22)
		btn_cont.pressed.connect(start_game)
		var btn_new := _make_btn("🆕 Yeni Oyun", false, 150)
		btn_new.pressed.connect(func():
			if not _reset_armed:
				_reset_armed = true
				btn_new.text = "⚠️ Emin misin? Tekrar bas"
				return
			SaveManager.reset_save()
			world.rebuild_world()
			_refresh_bait_bar()
			_refresh_hud()
			start_game()
		)
		row.add_child(btn_cont)
		row.add_child(btn_new)
		_menu_box.add_child(row)
	else:
		var btn_play := _make_btn("🎣 Oyna", true, 200)
		btn_play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn_play.add_theme_font_size_override("font_size", 22)
		btn_play.pressed.connect(start_game)
		_menu_box.add_child(btn_play)

func start_game() -> void:
	_menu_overlay.visible = false
	_hud_bar.visible = true
	_bait_bar.visible = true
	world.set_game_state("idle")
	_refresh_bait_bar()
	_refresh_hud()
	world.hint_changed.emit("İlk atış! Boşluk'a basılı tut ve yeşil bölgede bırak 🎣")
	var off := SaveManager.offline_report
	if not off.is_empty():
		SaveManager.offline_report = {}
		var hrs := float(off["secs"]) / 3600.0
		var away := ("%.1f saat" % hrs) if hrs >= 1.0 else ("%d dakika" % int(float(off["secs"]) / 60.0))
		_show_toast("🐠 Sen yokken (%s) akvaryum ziyaretçileri %d altın bıraktı! (Q)" % [away, int(off["gold"])])
	if bool(SaveManager.daily_status()["available"]):
		open_panel("daily")

func _refresh_hud() -> void:
	var d := SaveManager.data
	_lbl_money.text = "🪙 %d" % int(d["money"])
	var depth_m := maxi(0, int(round((float(world.hook["y"]) - GameData.SURF) / GameData.PPM)))
	_lbl_depth.text = "⬇ %dm / %dm" % [depth_m, SaveManager.max_depth()]
	var mins := int(d["minutes"]) % (24 * 60)
	_lbl_clock.text = "%s %02d:%02d" % ["🌙" if SaveManager.is_night() else "☀", mins / 60, mins % 60]
	var w := SaveManager.get_weather()
	_lbl_weather.text = "%s %s" % [str(w["icon"]), str(w["name"])]
	var b := SaveManager.current_biome()
	_btn_biome.text = "%s %s" % [str(b["icon"]), str(b["name"])]
	var rank := SaveManager.get_rank_info()
	_lbl_level.text = "Sv.%d" % int(rank["cur"]["lv"])
	_xp_bar.value = float(rank["pct"]) * 100.0
	_lbl_combo.visible = world.combo >= 2
	if world.combo >= 2:
		_lbl_combo.text = "🔥 x%d" % world.combo

	var show_zone := world.state != "menu" and depth_m > 0
	_lbl_zone.visible = show_zone
	if show_zone:
		var z := GameData.get_depth_zone(depth_m)
		_lbl_zone.text = "%s • %dm" % [str(z["name"]), depth_m]
		_lbl_zone.add_theme_color_override("font_color", z["color"])

	var b_cnt := (d["basket"] as Array).size()
	_btn_basket.text = "🧺%d" % b_cnt if b_cnt > 0 else "🧺"
	var ready_m := false
	for m in d["missions"]:
		if float(m["prog"]) >= float(m["need"]):
			ready_m = true
			break
	_btn_missions.text = "📜!" if ready_m else "📜"
	_btn_aqua.text = "🐠🪙" if int(floor(float(d["aqua_bank"]))) >= 20 else "🐠"
	_btn_sound.text = "🔊" if AudioManager.sound_on else "🔇"
	_btn_daily.text = "🎁!" if bool(SaveManager.daily_status()["available"]) else "🎁"

func _refresh_bait_bar() -> void:
	for c in _bait_bar.get_children():
		c.queue_free()
	for i in range(GameData.BAITS.size()):
		var b: Dictionary = GameData.BAITS[i]
		var bid := str(b["id"])
		var cnt_txt := "∞" if bool(b["infinite"]) else str(int(SaveManager.data["baits"].get(bid, 0)))
		var active := str(SaveManager.data["active_bait"]) == bid
		var btn := _make_icon_btn("%s%s" % [str(b["icon"]), cnt_txt], "%d: %s — %s" % [i + 1, str(b["name"]), str(b["desc"])])
		btn.custom_minimum_size = Vector2(46, 38)
		btn.add_theme_font_size_override("font_size", 13)
		if active:
			btn.add_theme_stylebox_override("normal", _style_box(Color(1.0, 0.8, 0.2, 0.35), Color("#ffd84d"), 10, 2, 2))
		btn.pressed.connect(func():
			if SaveManager.select_bait(bid):
				AudioManager.play("click")
			else:
				_show_toast("%s %s kalmadı! Mağazadan alabilirsin (M)" % [str(b["icon"]), str(b["name"])])
		)
		_bait_bar.add_child(btn)

func _show_toast(msg: String) -> void:
	var lbl := _make_pill(msg, Color.WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_box.add_child(lbl)
	get_tree().create_timer(2.4).timeout.connect(func():
		if is_instance_valid(lbl):
			lbl.queue_free()
	)

func _on_toggle_sound() -> void:
	AudioManager.toggle_sound()
	_refresh_hud()

# ---------------- Yakalandı & Hazine Modalları ----------------
func _clear_overlay(ov: ColorRect) -> void:
	for c in ov.get_children():
		c.queue_free()

func _show_catch_modal(info: Dictionary) -> void:
	_last_catch = info
	_clear_overlay(_catch_overlay)
	var sp: Dictionary = info["sp"]
	var r_info: Dictionary = GameData.RARITIES[int(sp["r"])]
	var card := _make_card(_catch_overlay, 480, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)

	var r_lbl := Label.new()
	r_lbl.text = "  %s  " % str(r_info["name"]).to_upper()
	r_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	r_lbl.add_theme_color_override("font_color", r_info["color"])
	r_lbl.add_theme_stylebox_override("normal", _style_box(r_info["bg"], r_info["color"], 12, 1, 4))

	var tex_rect := TextureRect.new()
	tex_rect.texture = GameData.get_fish_texture(str(sp["spr"]))
	tex_rect.custom_minimum_size = Vector2(180, 82)
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if sp.has("tint"):
		tex_rect.modulate = Color(str(sp["tint"]))

	var name_lbl := Label.new()
	name_lbl.text = str(sp["name"])
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color("#0d5c8f"))

	var lat_lbl := Label.new()
	lat_lbl.text = "(%s)" % str(sp.get("latin", ""))
	lat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lat_lbl.add_theme_font_size_override("font_size", 12)
	lat_lbl.add_theme_color_override("font_color", Color("#8a7350"))

	var tags: Array[String] = ["+%d XP" % int(info["xp_gain"])]
	if int(info["combo_snap"]) >= 2: tags.append("🔥 Kombo x%d" % int(info["combo_snap"]))
	if bool(info["frenzy_snap"]): tags.append("✨ Akın 2x")
	if bool(info["hot"]): tags.append("📈 Pazar +%50")
	var tag_lbl := Label.new()
	tag_lbl.text = "  •  ".join(tags)
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.add_theme_color_override("font_color", Color("#116b52"))

	var stats_lbl := Label.new()
	stats_lbl.text = "⚖️ %.2f kg   •   ⬇ %d m   •   🪙 +%d altın" % [float(info["kg"]), int(info["depth_m"]), int(info["value"])]
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_size_override("font_size", 16)
	stats_lbl.add_theme_color_override("font_color", Color("#3b2a12"))

	# Balık Ansiklopedisi & Kısa Hikaye Kutusu
	var stars := GameData.fish_difficulty_stars(sp)
	var star_txt := "★".repeat(stars) + "☆".repeat(5 - stars)
	var bio_box := Label.new()
	bio_box.text = "📖 %s\n💬 Hikaye: %s\n🌊 %s • 🍽️ %s • ⚡ %s" % [
		str(sp.get("fact", "")), str(sp.get("story", "")), str(sp.get("habitat", "")), str(sp.get("diet", "")), star_txt
	]
	bio_box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bio_box.add_theme_font_size_override("font_size", 12)
	bio_box.add_theme_color_override("font_color", Color("#4d381a"))
	bio_box.add_theme_stylebox_override("normal", _style_box(Color.WHITE, Color("#ead7a6"), 12, 2, 8))

	for c in [r_lbl, tex_rect, name_lbl, lat_lbl, tag_lbl, stats_lbl, bio_box]:
		vb.add_child(c)

	if bool(info["is_new"]):
		var nb := Label.new()
		nb.text = "✨ Yeni tür! Koleksiyona eklendi"
		nb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nb.add_theme_color_override("font_color", Color("#217a43"))
		vb.add_child(nb)
	if bool(info["is_record"]):
		var rb := Label.new()
		rb.text = "🏆 Yeni ağırlık rekoru!"
		rb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rb.add_theme_color_override("font_color", Color("#996800"))
		vb.add_child(rb)

	var acts := HBoxContainer.new()
	acts.alignment = BoxContainer.ALIGNMENT_CENTER
	acts.add_theme_constant_override("separation", 8)
	var btn_sell := _make_btn("💰 Sat (+%d)" % int(info["value"]), true, 130)
	btn_sell.pressed.connect(func(): _close_catch("sell"))
	var b_cap := int(SaveManager.up("basket"))
	var b_len := (SaveManager.data["basket"] as Array).size()
	var btn_keep := _make_btn("🧺 Sepet (%d/%d)" % [b_len, b_cap], false, 130)
	btn_keep.disabled = b_len >= b_cap
	btn_keep.pressed.connect(func(): _close_catch("basket"))
	var a_cap := int(SaveManager.up("aquarium"))
	var a_len := (SaveManager.data["aquarium"] as Array).size()
	var btn_aq := _make_btn("🐠 Akvaryum (%d/%d)" % [a_len, a_cap], false, 145)
	btn_aq.disabled = a_len >= a_cap
	btn_aq.pressed.connect(func(): _close_catch("aquarium"))
	acts.add_child(btn_sell)
	acts.add_child(btn_keep)
	acts.add_child(btn_aq)
	vb.add_child(acts)

	card.add_child(vb)
	_catch_overlay.visible = true

func _close_catch(mode: String) -> void:
	if _last_catch.is_empty():
		return
	var sp: Dictionary = _last_catch["sp"]
	if mode == "basket":
		SaveManager.data["basket"].append({
			"uid": "b_%d_%d" % [Time.get_ticks_msec(), randi() % 999],
			"sp_id": sp["id"], "kg": snappedf(float(_last_catch["kg"]), 0.01),
			"depth_m": int(_last_catch["depth_m"]), "base_val": int(_last_catch["base_val"]),
		})
		SaveManager.save_game()
		AudioManager.play("click")
		_show_toast("🧺 %s sepete eklendi" % str(sp["name"]))
	elif mode == "aquarium":
		SaveManager.data["aquarium"].append({
			"uid": "aq_%d_%d" % [Time.get_ticks_msec(), randi() % 999],
			"sp_id": sp["id"], "kg": snappedf(float(_last_catch["kg"]), 0.01),
			"base_val": int(_last_catch["base_val"]),
		})
		SaveManager.check_achievements()
		SaveManager.save_game()
		AudioManager.play("splash")
		_show_toast("🐠 %s Canlı Akvaryuma eklendi!" % str(sp["name"]))
	else:
		var val := int(_last_catch["value"])
		SaveManager.data["money"] = int(SaveManager.data["money"]) + val
		SaveManager.data["total"] = int(SaveManager.data["total"]) + val
		SaveManager.progress_missions("earn_gold", float(val))
		SaveManager.check_achievements()
		SaveManager.save_game()
		AudioManager.play("coin")
		_show_toast("+%d altın" % val)
		world.add_float_text(GameData.W * 0.5, GameData.H * 0.48, "+%d 🪙" % val, Color("#ffd84d"), 22, true)
	_catch_overlay.visible = false
	_last_catch = {}
	world.set_game_state("idle")
	world.hint_changed.emit(world._idle_hint())
	_refresh_hud()

func _show_treasure_modal(info: Dictionary) -> void:
	_last_treasure = info
	_clear_overlay(_treasure_overlay)
	var t_type: Dictionary = info["type"]
	var card := _make_card(_treasure_overlay, 420, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	var ic := Label.new()
	ic.text = str(t_type["icon"])
	ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ic.add_theme_font_size_override("font_size", 48)
	var nm := Label.new()
	nm.text = str(t_type["name"])
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 22)
	nm.add_theme_color_override("font_color", Color("#0d5c8f"))
	var desc := Label.new()
	desc.text = str(info["desc"])
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_color_override("font_color", Color("#5b4320"))
	var loot_lines := "💰 +%d Altın   •   ⭐ +%d XP" % [int(info["gold"]), int(info["xp_gain"])]
	var bb: Dictionary = info["bonus_bait"]
	if not bb.is_empty():
		loot_lines += "\n%s +2 %s" % [str(bb["icon"]), str(bb["name"])]
	var loot := Label.new()
	loot.text = loot_lines
	loot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loot.add_theme_color_override("font_color", Color("#9e6500"))
	loot.add_theme_stylebox_override("normal", _style_box(Color.WHITE, Color("#ead7a6"), 12, 2, 10))
	var ok := _make_btn("Harika! Devam et", true, 180)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(_close_treasure)
	for c in [ic, nm, desc, loot, ok]:
		vb.add_child(c)
	card.add_child(vb)
	_treasure_overlay.visible = true

func _close_treasure() -> void:
	_treasure_overlay.visible = false
	_last_treasure = {}
	world.set_game_state("idle")
	world.hint_changed.emit(world._idle_hint())
	_refresh_bait_bar()
	_refresh_hud()

# ---------------- Paneller (Mağaza, Akvaryum, Turnuva, Sepet, Görevler, Günlük) ----------------
func toggle_panel(id: String) -> void:
	if _current_panel == id:
		close_panels()
	else:
		open_panel(id)

func open_panel(id: String) -> void:
	if not (world.state in ["idle", "panel"]):
		_show_toast("Önce oltayı topla")
		return
	world.set_game_state("panel")
	_current_panel = id
	_panel_overlay.visible = true
	world.hint_changed.emit("")
	_render_current_panel()

func close_panels() -> void:
	_panel_overlay.visible = false
	_detail_overlay.visible = false
	_current_panel = ""
	_aqua_view = null
	_market_view = null
	_haggle_mul = 1.0
	_haggle_used = false
	world.set_game_state("idle")
	world.hint_changed.emit(world._idle_hint())

func _clear_panel_body() -> void:
	_aqua_view = null
	_market_view = null
	for c in _panel_body.get_children():
		c.queue_free()

func _render_current_panel() -> void:
	_clear_panel_body()
	match _current_panel:
		"shop":       _render_shop()
		"aquarium":   _render_aquarium()
		"tournament": _render_tournament()
		"basket":     _render_basket()
		"missions":   _render_missions()
		"book":       _render_book()
		"daily":      _render_daily()

func _make_scroll_grid(cols: int) -> Array:
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grid := GridContainer.new()
	grid.columns = cols
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)
	_panel_body.add_child(sc)
	return [sc, grid]

func _render_shop() -> void:
	_panel_title.text = "🛒 Balıkçı Dükkanı"
	_panel_extra.text = "🪙 %d altın" % int(SaveManager.data["money"])
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	for pair in [["upgrades", "⚙️ Yükseltmeler"], ["baits", "🪱 Özel Yemler"], ["biomes", "🗺️ Bölgeler"]]:
		var tb := _make_btn(pair[1], _shop_tab == pair[0])
		tb.pressed.connect(func(): _shop_tab = pair[0]; _render_current_panel())
		tabs.add_child(tb)
	_panel_body.add_child(tabs)

	var grid: GridContainer = _make_scroll_grid(2)[1]
	var money := int(SaveManager.data["money"])

	if _shop_tab == "upgrades":
		for u in GameData.UPGRADES:
			var uid := str(u["id"])
			var lv := int(SaveManager.data["lv"].get(uid, 0))
			var vals: Array = u["vals"]
			var maxed := lv >= vals.size() - 1
			var cost := 0 if maxed else int(u["cost"][lv + 1])
			var item := PanelContainer.new()
			item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item.add_theme_stylebox_override("panel", _style_box(Color.WHITE, Color("#ead7a6"), 14, 2, 10))
			var vb := VBoxContainer.new()
			var hdr := Label.new()
			hdr.text = "%s %s  (Sv.%d/%d)" % [str(u["ic"]), str(u["name"]), lv + 1, vals.size()]
			hdr.add_theme_color_override("font_color", Color("#0d5c8f"))
			var desc := Label.new()
			desc.text = GameData.upgrade_desc(uid, vals[lv])
			desc.add_theme_font_size_override("font_size", 12)
			desc.add_theme_color_override("font_color", Color("#5b4320"))
			vb.add_child(hdr)
			vb.add_child(desc)
			if maxed:
				var ml := Label.new()
				ml.text = "✔ En üst seviye"
				ml.add_theme_color_override("font_color", Color("#217a43"))
				vb.add_child(ml)
			else:
				var nxt := Label.new()
				nxt.text = "Sonraki: " + GameData.upgrade_desc(uid, vals[lv + 1])
				nxt.add_theme_font_size_override("font_size", 11)
				nxt.add_theme_color_override("font_color", Color("#8a7350"))
				var b := _make_btn("%d altın" % cost, true)
				b.disabled = money < cost
				b.pressed.connect(func():
					if SaveManager.buy_upgrade(uid):
						AudioManager.play("buy")
						_show_toast("🚤 Yeni tekne alındı! ← → ile gez!" if uid == "boat" else "%s %s geliştirildi!" % [str(u["ic"]), str(u["name"])])
						_render_current_panel()
				)
				vb.add_child(nxt)
				vb.add_child(b)
			item.add_child(vb)
			grid.add_child(item)
	elif _shop_tab == "baits":
		for b in GameData.BAITS:
			if bool(b["infinite"]): continue
			var bid := str(b["id"])
			var owned := int(SaveManager.data["baits"].get(bid, 0))
			var cost := int(b["cost"])
			var item := PanelContainer.new()
			item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item.add_theme_stylebox_override("panel", _style_box(Color.WHITE, Color("#ead7a6"), 14, 2, 10))
			var vb := VBoxContainer.new()
			var hdr := Label.new()
			hdr.text = "%s %s (Stok: %d)" % [str(b["icon"]), str(b["name"]), owned]
			hdr.add_theme_color_override("font_color", Color("#0d5c8f"))
			var desc := Label.new()
			desc.text = str(b["desc"])
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc.add_theme_font_size_override("font_size", 12)
			desc.add_theme_color_override("font_color", Color("#5b4320"))
			var btn := _make_btn("+%d Adet — %d altın" % [int(b["pack"]), cost], true)
			btn.disabled = money < cost
			btn.pressed.connect(func():
				if SaveManager.buy_bait(bid):
					AudioManager.play("buy")
					_show_toast("%s +%d %s alındı!" % [str(b["icon"]), int(b["pack"]), str(b["name"])])
					_render_current_panel()
			)
			for c in [hdr, desc, btn]: vb.add_child(c)
			item.add_child(vb)
			grid.add_child(item)
	else:
		for b in GameData.BIOMES:
			var bid := str(b["id"])
			var owned := (SaveManager.data["biomes"] as Array).has(bid)
			var active := str(SaveManager.data["biome"]) == bid
			var cost := int(b["cost"])
			var item := PanelContainer.new()
			item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item.add_theme_stylebox_override("panel", _style_box(Color("#f2fff6") if active else Color.WHITE, Color("#1f9d55") if active else Color("#ead7a6"), 14, 2, 10))
			var vb := VBoxContainer.new()
			var hdr := Label.new()
			hdr.text = "%s %s" % [str(b["icon"]), str(b["name"])]
			hdr.add_theme_color_override("font_color", Color("#0d5c8f"))
			var bon := Label.new()
			bon.text = str(b["bonus_text"])
			bon.add_theme_font_size_override("font_size", 12)
			bon.add_theme_color_override("font_color", Color("#217a43"))
			var desc := Label.new()
			desc.text = str(b["desc"])
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc.add_theme_font_size_override("font_size", 12)
			desc.add_theme_color_override("font_color", Color("#5b4320"))
			var btn := _make_btn("✔ Şu an buradasın" if active else ("🚤 Buraya Git" if owned else "Kilidi Aç — %d altın" % cost), not owned)
			btn.disabled = active or ((not owned) and money < cost)
			btn.pressed.connect(func():
				if SaveManager.switch_biome(bid):
					world.rebuild_world()
					AudioManager.play("level_up" if not owned else "splash")
					_show_toast("🚤 %s bölgesine gidildi!" % str(b["name"]))
					_render_current_panel()
			)
			for c in [hdr, bon, desc, btn]: vb.add_child(c)
			item.add_child(vb)
			grid.add_child(item)

func _render_aquarium() -> void:
	var aq: Array = SaveManager.data["aquarium"]
	var cap := int(SaveManager.up("aquarium"))
	var rate := SaveManager.aqua_rate_per_min()
	var bank := int(floor(float(SaveManager.data["aqua_bank"])))
	_panel_title.text = "🐠 Canlı Akvaryumum (%d/%d)" % [aq.size(), cap]
	_panel_extra.text = "🎟️ %d altın/dk" % rate

	_aqua_view = AquariumView.new()
	_aqua_view.fed.connect(func(): _panel_extra.text = "🎟️ %d altın/dk (🍤 2x!)" % SaveManager.aqua_rate_per_min())
	_panel_body.add_child(_aqua_view)

	var ctrls := HBoxContainer.new()
	ctrls.add_theme_constant_override("separation", 8)
	var btn_feed := _make_btn("🍤 Balıkları Yemle (2x Gelir)", false)
	btn_feed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_feed.pressed.connect(func(): if _aqua_view: _aqua_view.drop_food())
	var btn_col := _make_btn("💰 Geliri Topla (+%d altın)" % bank, true)
	btn_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_col.disabled = bank <= 0
	btn_col.pressed.connect(func():
		var amt := SaveManager.collect_aqua_bank()
		if amt > 0:
			AudioManager.play("catch")
			world.spawn_confetti(GameData.W * 0.5, GameData.H * 0.5, 24)
			_show_toast("🐠 Akvaryum bilet geliri: +%d altın!" % amt)
			_render_current_panel()
	)
	ctrls.add_child(btn_feed)
	ctrls.add_child(btn_col)
	_panel_body.add_child(ctrls)

	var grid: GridContainer = _make_scroll_grid(3)[1]
	if aq.is_empty():
		var emp := Label.new()
		emp.text = "Akvaryum boş! Balık tuttuğunda '🐠 Akvaryum' butonuna basarak buraya ekleyebilirsin."
		emp.add_theme_color_override("font_color", Color("#7a623f"))
		grid.add_child(emp)
		return
	for item in aq:
		var sp := GameData.get_species(str(item["sp_id"]))
		var uid := str(item["uid"])
		var inc := SaveManager.aqua_fish_income(item)
		var hb := HBoxContainer.new()
		var b_info := _make_btn("🐟 %s (+%d/dk)" % [str(sp["name"]), inc], false)
		b_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_info.add_theme_font_size_override("font_size", 11)
		b_info.pressed.connect(func(): _open_fish_detail(str(sp["id"])))
		var b_sell := _make_btn("Sat", true)
		b_sell.add_theme_font_size_override("font_size", 11)
		b_sell.pressed.connect(func():
			var idx := aq.find(item)
			if idx >= 0:
				var ref := maxi(10, int(round(float(item.get("base_val", 20)) * 0.8)))
				aq.remove_at(idx)
				SaveManager.data["money"] = int(SaveManager.data["money"]) + ref
				SaveManager.data["total"] = int(SaveManager.data["total"]) + ref
				SaveManager.save_game()
				AudioManager.play("coin")
				_render_current_panel()
		)
		hb.add_child(b_info)
		hb.add_child(b_sell)
		grid.add_child(hb)

func _render_tournament() -> void:
	_panel_title.text = "🏆 90 Saniyelik Balıkçılık Turnuvası"
	_panel_extra.text = "Kazanılan kupa: %d" % int(SaveManager.data["stats"].get("tourney_wins", 0))
	var grid: GridContainer = _make_scroll_grid(3)[1]
	for tr in GameData.TOURNAMENTS:
		var tid := str(tr["id"])
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _style_box(Color.WHITE, Color("#ead7a6"), 14, 2, 12))
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 6)
		var h := Label.new()
		h.text = str(tr["name"])
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.add_theme_color_override("font_color", Color("#0d5c8f"))
		var d := Label.new()
		d.text = str(tr["desc"])
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_theme_font_size_override("font_size", 12)
		d.add_theme_color_override("font_color", Color("#5b4320"))
		var rew := Label.new()
		rew.text = "🎁 +%d altın • +%d XP • +3 özel yem" % [int(tr["reward_gold"]), int(tr["reward_xp"])]
		rew.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rew.add_theme_font_size_override("font_size", 12)
		rew.add_theme_color_override("font_color", Color("#9e6500"))
		var btn := _make_btn("🏁 Başlat", true)
		btn.disabled = not world.active_tourney.is_empty()
		btn.pressed.connect(func():
			if world.start_tournament(tid):
				close_panels()
		)
		for c in [h, d, rew, btn]: vb.add_child(c)
		card.add_child(vb)
		grid.add_child(card)

func _render_basket() -> void:
	SaveManager.ensure_market()
	var basket: Array = SaveManager.data["basket"]
	var cust := SaveManager.get_market_customer()
	_panel_title.text = "🏪 2D Balık Pazarı (%d/%d)" % [basket.size(), int(SaveManager.up("basket"))]

	# Tatlı 2D Pazar Tezgahı Sahnesi
	_market_view = MarketView.new()
	_panel_body.add_child(_market_view)

	var hot_names: Array[String] = []
	for h in SaveManager.data["market_hot"]:
		hot_names.append(str(h["label"]))
	var banner := Label.new()
	banner.text = "📈 Günlük Talep (+%50): " + " • ".join(hot_names) + ("   |   🤝 Pazarlık Bonusu: +%%%d!" % int(round((_haggle_mul - 1.0) * 100.0)) if _haggle_mul > 1.0 else "")
	banner.add_theme_font_size_override("font_size", 12)
	banner.add_theme_color_override("font_color", Color("#6e4500"))
	banner.add_theme_stylebox_override("normal", _style_box(Color("#fff2c6"), Color("#e6bc53"), 10, 2, 6))
	_panel_body.add_child(banner)

	var grid: GridContainer = _make_scroll_grid(3)[1]
	var total_val := 0
	if basket.is_empty():
		var emp := Label.new()
		emp.text = "Tezgahın boş! Balık yakaladığında '🧺 Sepet' diyerek buraya getir; müşteriler özel siparişlere +%90'a varan bonus öder!"
		emp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		emp.add_theme_color_override("font_color", Color("#7a623f"))
		grid.add_child(emp)
	else:
		for item in basket:
			var sp := GameData.get_species(str(item["sp_id"]))
			var hot := SaveManager.is_hot_demand(sp)
			var match_c := SaveManager.matches_customer_order(item, cust)
			var val := SaveManager.calc_market_price(item, _haggle_mul)
			total_val += val
			var card := PanelContainer.new()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var bg_c := Color("#fff5f8") if (hot or match_c) else Color.WHITE
			var bd_c := Color("#f06595") if match_c else (Color("#e6bc53") if hot else Color("#ead7a6"))
			card.add_theme_stylebox_override("panel", _style_box(bg_c, bd_c, 12, 2, 6))
			var vb := VBoxContainer.new()
			var tr := TextureRect.new()
			tr.texture = GameData.get_fish_texture(str(sp["spr"]))
			tr.custom_minimum_size = Vector2(76, 34)
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var nl := Label.new()
			nl.text = str(sp["name"])
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.add_theme_font_size_override("font_size", 11)
			nl.add_theme_color_override("font_color", Color("#3b2a12"))
			var tag_s := ""
			if match_c: tag_s += " %s%s" % [str(cust["icon"]), str(cust["bonus_lbl"])]
			if hot: tag_s += " 🔥+%50"
			var sl := Label.new()
			sl.text = "%.2f kg • %dm%s" % [float(item["kg"]), int(item["depth_m"]), tag_s]
			sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sl.add_theme_font_size_override("font_size", 10)
			sl.add_theme_color_override("font_color", Color("#8a7350"))
			var sb := _make_btn("Sat (+%d)" % val, true)
			sb.add_theme_font_size_override("font_size", 12)
			sb.pressed.connect(func():
				var idx := basket.find(item)
				if idx >= 0:
					basket.remove_at(idx)
					SaveManager.data["money"] = int(SaveManager.data["money"]) + val
					SaveManager.data["total"] = int(SaveManager.data["total"]) + val
					SaveManager.progress_missions("earn_gold", float(val))
					SaveManager.check_achievements()
					SaveManager.save_game()
					AudioManager.play("coin")
					if _market_view: _market_view.trigger_sale_celebration("Harika bir balık! +%d altın!" % val)
					_render_current_panel()
			)
			for c in [tr, nl, sl, sb]: vb.add_child(c)
			card.add_child(vb)
			grid.add_child(card)

	_panel_extra.text = "Toplam: %d altın" % total_val
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 8)
	var btn_haggle := _make_btn("🤝 Pazarlık Et" if not _haggle_used else "✔ Pazarlık Yapıldı", false)
	btn_haggle.disabled = basket.is_empty() or _haggle_used
	btn_haggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_haggle.pressed.connect(func():
		_haggle_used = true
		if randf() < 0.72:
			_haggle_mul = 1.25
			SaveManager.data["stats"]["haggles"] = int(SaveManager.data["stats"].get("haggles", 0)) + 1
			SaveManager.check_achievements()
			SaveManager.save_game()
			AudioManager.play("perfect")
			_show_toast("🤝 Pazarlık tuttu! Tüm fiyatlar +%25 arttı!")
			if _market_view: _market_view.trigger_sale_celebration("Pekala anlaştık! +%25 fazladan veriyorum!")
		else:
			_haggle_mul = 1.05
			AudioManager.play("click")
			_show_toast("😅 Zorlu müşteri! Yine de +%5 kopardın!")
			if _market_view: _market_view.trigger_sale_celebration("Sıkı pazarlıkçısın! Sadece +%5 ekleyebilirim.")
		_render_current_panel()
	)
	var btn_all := _make_btn("💰 Tümünü Sat (+%d altın)" % total_val, true)
	btn_all.disabled = basket.is_empty()
	btn_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_all.pressed.connect(func():
		if basket.is_empty(): return
		basket.clear()
		SaveManager.data["money"] = int(SaveManager.data["money"]) + total_val
		SaveManager.data["total"] = int(SaveManager.data["total"]) + total_val
		SaveManager.progress_missions("earn_gold", float(total_val))
		SaveManager.check_achievements()
		SaveManager.save_game()
		_haggle_mul = 1.0
		_haggle_used = false
		AudioManager.play("catch")
		world.spawn_confetti(GameData.W * 0.5, GameData.H * 0.5, 28)
		_show_toast("💰 Balık Pazarı satışı: +%d altın!" % total_val)
		_render_current_panel()
	)
	foot.add_child(btn_haggle)
	foot.add_child(btn_all)
	_panel_body.add_child(foot)

func _render_missions() -> void:
	SaveManager.ensure_missions()
	var rank := SaveManager.get_rank_info()
	_panel_title.text = "📜 Görevler & Balıkçı Rütbesi"
	_panel_extra.text = "Sv.%d %s" % [int(rank["cur"]["lv"]), str(rank["cur"]["title"])]

	var rcard := PanelContainer.new()
	rcard.add_theme_stylebox_override("panel", _style_box(Color.WHITE, Color("#ead7a6"), 14, 2, 10))
	var rvb := VBoxContainer.new()
	var rl := Label.new()
	rl.text = "🏅 Sv.%d — %s   •   Kalıcı satış bonusu: +%%%d   •   Toplam XP: %d" % [int(rank["cur"]["lv"]), str(rank["cur"]["title"]), (int(rank["cur"]["lv"]) - 1) * 4, int(SaveManager.data["xp"])]
	rl.add_theme_color_override("font_color", Color("#0d5c8f"))
	var rbar := ProgressBar.new()
	rbar.value = float(rank["pct"]) * 100.0
	rvb.add_child(rl)
	rvb.add_child(rbar)
	rcard.add_child(rvb)
	_panel_body.add_child(rcard)

	for m in SaveManager.data["missions"]:
		var ready := float(m["prog"]) >= float(m["need"])
		var mc := PanelContainer.new()
		mc.add_theme_stylebox_override("panel", _style_box(Color("#f2fff6") if ready else Color.WHITE, Color("#2eb872") if ready else Color("#ead7a6"), 14, 2, 10))
		var hb := HBoxContainer.new()
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ml := Label.new()
		ml.text = str(m["label"])
		ml.add_theme_color_override("font_color", Color("#3b2a12"))
		var sl := Label.new()
		sl.text = "İlerleme: %.1f / %d • Ödül: %d altın + %d XP" % [float(m["prog"]), int(m["need"]), int(m["gold"]), int(m["xp"])]
		sl.add_theme_font_size_override("font_size", 12)
		sl.add_theme_color_override("font_color", Color("#7a623f"))
		var mb := ProgressBar.new()
		mb.value = clampf(float(m["prog"]) / float(m["need"]) * 100.0, 0.0, 100.0)
		vb.add_child(ml)
		vb.add_child(sl)
		vb.add_child(mb)
		var btn := _make_btn("🎁 Ödülü Al" if ready else "Devam…", ready, 120)
		btn.disabled = not ready
		var mid := str(m["id"])
		btn.pressed.connect(func():
			var claimed := SaveManager.claim_mission(mid)
			if not claimed.is_empty():
				AudioManager.play("catch")
				world.spawn_confetti(GameData.W * 0.5, GameData.H * 0.5, 28)
				_show_toast("📜 Görev ödülü: +%d altın, +%d XP!" % [int(claimed["gold"]), int(claimed["xp"])])
				_render_current_panel()
		)
		hb.add_child(vb)
		hb.add_child(btn)
		mc.add_child(hb)
		_panel_body.add_child(mc)

func _render_book() -> void:
	var book: Dictionary = SaveManager.data["book"]
	var got := book.size()
	var ach_done := (SaveManager.data["achievements"] as Dictionary).size()
	_panel_title.text = "📖 Balıkçı Günlüğü (%d/%d tür)" % [got, GameData.species.size()]
	_panel_extra.text = "🎖️ %d/%d başarım" % [ach_done, GameData.ACHIEVEMENTS.size()]

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	for pair in [["all", "Tümü"], ["caught", "Yakalanan (%d)" % got], ["shallow", "Sığ"], ["mid", "Orta"], ["deep", "Derin"], ["rare", "Nadir+"], ["trophies", "🏆 Kupa"], ["ach", "🎖️ Başarım"], ["stats", "📊 İstatistik"]]:
		var tb := _make_btn(pair[1], _book_filter == pair[0])
		tb.add_theme_font_size_override("font_size", 12)
		tb.pressed.connect(func(): _book_filter = pair[0]; _render_current_panel())
		tabs.add_child(tb)
	_panel_body.add_child(tabs)

	if _book_filter == "stats":
		_render_stats_tab()
	elif _book_filter == "ach":
		var grid: GridContainer = _make_scroll_grid(2)[1]
		for a in GameData.ACHIEVEMENTS:
			var done := (SaveManager.data["achievements"] as Dictionary).has(str(a["id"]))
			var card := PanelContainer.new()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.add_theme_stylebox_override("panel", _style_box(Color("#f2fff6") if done else Color("#f3ead3"), Color("#2eb872") if done else Color("#ead7a6"), 12, 2, 8))
			var lbl := Label.new()
			lbl.text = "%s %s %s\n%s • +%d altın" % [str(a["ic"]), str(a["name"]), "✔" if done else "", str(a["desc"]), int(a["reward"])]
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", Color("#3b2a12"))
			card.add_child(lbl)
			grid.add_child(card)
	elif _book_filter == "trophies":
		var grid: GridContainer = _make_scroll_grid(3)[1]
		var list: Array[Dictionary] = []
		for sid in book.keys():
			list.append({"sp": GameData.get_species(str(sid)), "rec": book[sid]})
		list.sort_custom(func(a, b): return float(a["rec"]["max"]) > float(b["rec"]["max"]))
		if list.is_empty():
			var emp := Label.new()
			emp.text = "Henüz kupa rafında balık yok. İlk balığını yakala!"
			emp.add_theme_color_override("font_color", Color("#7a623f"))
			grid.add_child(emp)
		else:
			for i in range(mini(6, list.size())):
				var x: Dictionary = list[i]
				var sp: Dictionary = x["sp"]
				var rec: Dictionary = x["rec"]
				var btn := _make_btn("#%d %s\n%.2f kg • %dm • ℹ️ Bilgi" % [i + 1, str(sp["name"]), float(rec["max"]), int(rec["deep"])], false)
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				btn.add_theme_font_size_override("font_size", 12)
				btn.pressed.connect(func(): _open_fish_detail(str(sp["id"])))
				grid.add_child(btn)
	else:
		var grid: GridContainer = _make_scroll_grid(4)[1]
		for sp in GameData.species:
			var sid := str(sp["id"])
			var rec: Dictionary = book.get(sid, {})
			var has_it := not rec.is_empty()
			if _book_filter == "caught" and not has_it: continue
			if _book_filter == "shallow" and int(sp["d"][0]) >= 40: continue
			if _book_filter == "mid" and (int(sp["d"][0]) < 35 or int(sp["d"][0]) >= 90): continue
			if _book_filter == "deep" and int(sp["d"][1]) < 90: continue
			if _book_filter == "rare" and int(sp["r"]) < 2: continue

			var card := PanelContainer.new()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.add_theme_stylebox_override("panel", _style_box(Color.WHITE if has_it else Color("#efe5cc"), Color("#ead7a6"), 12, 2, 6))
			var vb := VBoxContainer.new()
			var tr := TextureRect.new()
			tr.texture = GameData.get_fish_texture(str(sp["spr"]))
			tr.custom_minimum_size = Vector2(84, 40)
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if not has_it:
				tr.modulate = Color(0.1, 0.1, 0.1, 0.35)
			elif sp.has("tint"):
				tr.modulate = Color(str(sp["tint"]))
			var nl := Label.new()
			nl.text = str(sp["name"]) if has_it else "???"
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.add_theme_font_size_override("font_size", 11)
			nl.add_theme_color_override("font_color", Color("#3b2a12") if has_it else Color("#8a7350"))
			var dl := Label.new()
			dl.text = "%d–%dm • %s" % [int(sp["d"][0]), int(sp["d"][1]), str(GameData.RARITIES[int(sp["r"])]["name"])]
			dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dl.add_theme_font_size_override("font_size", 10)
			dl.add_theme_color_override("font_color", Color("#8a7350"))
			vb.add_child(tr)
			vb.add_child(nl)
			vb.add_child(dl)
			if has_it:
				var ib := _make_btn("ℹ️ Bilgi (%.1fkg)" % float(rec["max"]), false)
				ib.add_theme_font_size_override("font_size", 10)
				ib.pressed.connect(func(): _open_fish_detail(sid))
				vb.add_child(ib)
			card.add_child(vb)
			grid.add_child(card)

func _render_daily() -> void:
	var st := SaveManager.daily_status()
	var avail := bool(st["available"])
	var cur_idx := int(st["day_idx"])
	_panel_title.text = "🎁 Günlük Giriş Ödülü"
	_panel_extra.text = "📅 Seri: %d gün • En iyi: %d" % [
		int(SaveManager.data["daily"].get("streak", 0)), int(SaveManager.data["stats"].get("best_streak", 0))
	]
	var info := Label.new()
	info.text = "Her gün oyuna gir, ödülünü topla! Bir gün atlarsan seri 1. güne döner. Ödüller rütben yükseldikçe artar."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color("#5b4320"))
	_panel_body.add_child(info)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(GameData.DAILY_REWARDS.size()):
		var rw: Dictionary = GameData.DAILY_REWARDS[i]
		var done := i < cur_idx or (i == cur_idx and not avail)
		var today := i == cur_idx and avail
		var bg := Color("#f2fff6") if done else (Color("#fff2c6") if today else Color.WHITE)
		var bc := Color("#2eb872") if done else (Color("#e6a400") if today else Color("#ead7a6"))
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(98, 120)
		card.add_theme_stylebox_override("panel", _style_box(bg, bc, 12, 3 if today else 2, 6))
		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		var dl := Label.new()
		dl.text = "%d. Gün" % (i + 1)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.add_theme_color_override("font_color", Color("#0d5c8f"))
		var gl := Label.new()
		gl.text = "🪙 %d" % SaveManager.daily_gold(i)
		gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gl.add_theme_color_override("font_color", Color("#9e6500"))
		var bl := Label.new()
		if rw.has("bait"):
			var b := GameData.get_bait(str(rw["bait"]))
			bl.text = "%s +%d" % [str(b["icon"]), int(rw["n"])]
		else:
			bl.text = " "
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.add_theme_color_override("font_color", Color("#3b2a12"))
		var sl := Label.new()
		sl.text = "✔ Alındı" if done else ("⭐ Bugün" if today else "")
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sl.add_theme_font_size_override("font_size", 11)
		sl.add_theme_color_override("font_color", Color("#217a43") if done else Color("#b86e00"))
		for c in [dl, gl, bl, sl]: vb.add_child(c)
		card.add_child(vb)
		row.add_child(card)
	_panel_body.add_child(row)

	var btn := _make_btn("🎁 Ödülü Topla" if avail else "✔ Bugünün ödülü alındı — yarın tekrar gel!", avail, 320)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.disabled = not avail
	btn.pressed.connect(func():
		var got := SaveManager.claim_daily()
		if got.is_empty():
			return
		AudioManager.play("level_up")
		world.spawn_confetti(GameData.W * 0.5, GameData.H * 0.45, 40)
		var txt := "🎁 %d. gün ödülü: +%d altın" % [int(got["day_idx"]) + 1, int(got["gold"])]
		if not str(got["bait"]).is_empty():
			var b := GameData.get_bait(str(got["bait"]))
			txt += ", %s +%d %s" % [str(b["icon"]), int(got["n"]), str(b["name"])]
		_show_toast(txt + "!")
		_render_current_panel()
	)
	_panel_body.add_child(btn)

static func _fmt_duration(secs: float) -> String:
	var s := int(secs)
	if s >= 3600:
		return "%d sa %d dk" % [s / 3600, (s % 3600) / 60]
	return "%d dk %d sn" % [s / 60, s % 60]

func _render_stats_tab() -> void:
	var d := SaveManager.data
	var st: Dictionary = d["stats"]
	var rarity_counts := [0, 0, 0, 0, 0]
	for sid in (d["book"] as Dictionary).keys():
		var sp := GameData.get_species(str(sid))
		rarity_counts[clampi(int(sp.get("r", 0)), 0, 4)] += int(d["book"][sid].get("n", 0))
	var casts := int(d.get("casts", 0))
	var caught := SaveManager.total_catches()
	var rows: Array = [
		["⏱️ Oyun süresi", _fmt_duration(float(st.get("play_secs", 0.0)))],
		["🎣 Toplam atış", str(casts)],
		["🐟 Yakalanan balık", str(caught)],
		["🎯 İsabet oranı", ("%%%d" % int(round(float(caught) / float(casts) * 100.0))) if casts > 0 else "—"],
		["💰 Toplam kazanç", "%d altın" % int(d["total"])],
		["⚖️ En ağır balık", "%.2f kg" % float(st.get("heaviest", 0.0))],
		["🌊 En derin av", "%d m" % int(st.get("deepest", 0))],
		["🔥 En uzun kombo", "x%d" % int(st.get("max_combo", 0))],
		["🎯 Mükemmel atış", str(int(st.get("perfect_casts", 0)))],
		["💎 Çıkarılan hazine", str(int(st.get("treasures", 0)))],
		["🐉 Yakalanan boss", "%d / %d" % [int(st.get("bosses", 0)), GameData.boss_species.size()]],
		["🏆 Turnuva zaferi", str(int(st.get("tourney_wins", 0)))],
		["🌙 Gece avı", str(int(st.get("night_catches", 0)))],
		["📅 En uzun giriş serisi", "%d gün" % int(st.get("best_streak", 0))],
	]
	for i in range(5):
		rows.append(["%s av" % str(GameData.RARITIES[i]["name"]), str(rarity_counts[i])])
	var grid: GridContainer = _make_scroll_grid(3)[1]
	for r in rows:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _style_box(Color.WHITE, Color("#ead7a6"), 12, 2, 8))
		var hb := HBoxContainer.new()
		var k := Label.new()
		k.text = str(r[0])
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		k.add_theme_font_size_override("font_size", 12)
		k.add_theme_color_override("font_color", Color("#5b4320"))
		var v := Label.new()
		v.text = str(r[1])
		v.add_theme_font_size_override("font_size", 13)
		v.add_theme_color_override("font_color", Color("#0d5c8f"))
		hb.add_child(k)
		hb.add_child(v)
		card.add_child(hb)
		grid.add_child(card)

func _open_fish_detail(sp_id: String) -> void:
	var sp := GameData.get_species(sp_id)
	var rec: Dictionary = SaveManager.data["book"].get(sp_id, {})
	if sp.is_empty() or rec.is_empty():
		return
	_clear_overlay(_detail_overlay)
	var card := _make_card(_detail_overlay, 470, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)

	var hdr := HBoxContainer.new()
	var r_info: Dictionary = GameData.RARITIES[int(sp["r"])]
	var rl := Label.new()
	rl.text = "  %s  " % str(r_info["name"]).to_upper()
	rl.add_theme_color_override("font_color", r_info["color"])
	rl.add_theme_stylebox_override("normal", _style_box(r_info["bg"], r_info["color"], 12, 1, 4))
	var spc := Control.new()
	spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bc := _make_btn("✕", false, 34)
	bc.pressed.connect(func(): _detail_overlay.visible = false)
	hdr.add_child(rl)
	hdr.add_child(spc)
	hdr.add_child(bc)

	var tr := TextureRect.new()
	tr.texture = GameData.get_fish_texture(str(sp["spr"]))
	tr.custom_minimum_size = Vector2(200, 92)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if sp.has("tint"):
		tr.modulate = Color(str(sp["tint"]))

	var nm := Label.new()
	nm.text = str(sp["name"])
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 22)
	nm.add_theme_color_override("font_color", Color("#0d5c8f"))

	var lat := Label.new()
	lat.text = "Latince: %s" % str(sp.get("latin", ""))
	lat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lat.add_theme_font_size_override("font_size", 12)
	lat.add_theme_color_override("font_color", Color("#8a7350"))

	var fact := Label.new()
	fact.text = "📖 " + str(sp.get("fact", ""))
	fact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fact.add_theme_color_override("font_color", Color("#3b2a12"))
	fact.add_theme_stylebox_override("normal", _style_box(Color.WHITE, Color("#ead7a6"), 12, 2, 8))

	var story := Label.new()
	story.text = "💬 Balıkçı Hikayesi: " + str(sp.get("story", ""))
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.add_theme_font_size_override("font_size", 12)
	story.add_theme_color_override("font_color", Color("#6e3b10"))
	story.add_theme_stylebox_override("normal", _style_box(Color("#fff4d6"), Color("#e6bc53"), 12, 2, 8))

	var stars := GameData.fish_difficulty_stars(sp)
	var meta := Label.new()
	meta.text = "🌊 Yaşam Alanı: %s\n🍽️ Beslenme: %s\n📏 Derinlik & Ağırlık: %d–%dm • %.1f–%.1f kg\n⚡ Zorluk: %s (%s) • %s" % [
		str(sp.get("habitat", "")), str(sp.get("diet", "")),
		int(sp["d"][0]), int(sp["d"][1]), float(sp["kg"][0]), float(sp["kg"][1]),
		"★".repeat(stars) + "☆".repeat(5 - stars), GameData.fish_difficulty_label(stars),
		"Özellikle Gece 🌙" if sp.has("night") else "Gündüz & Gece ☀️🌙"
	]
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.add_theme_font_size_override("font_size", 12)
	meta.add_theme_color_override("font_color", Color("#4d381a"))

	var rec_lbl := Label.new()
	rec_lbl.text = "🏆 Rekorun: %.2f kg • En Derin: %dm • Toplam: %d adet" % [float(rec["max"]), int(rec["deep"]), int(rec["n"])]
	rec_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rec_lbl.add_theme_color_override("font_color", Color("#124c78"))
	rec_lbl.add_theme_stylebox_override("normal", _style_box(Color("#e8f5ff"), Color("#b5daf5"), 10, 2, 6))

	for c in [hdr, tr, nm, lat, fact, story, meta, rec_lbl]:
		vb.add_child(c)
	card.add_child(vb)
	_detail_overlay.visible = true
	AudioManager.play("click")

# ---------------- Girdi ----------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.keycode in [KEY_LEFT, KEY_A]:
			world.input_left = k.pressed
		elif k.keycode in [KEY_RIGHT, KEY_D]:
			world.input_right = k.pressed
		elif k.keycode in [KEY_SPACE, KEY_ENTER]:
			if k.pressed and not k.echo:
				if world.state == "menu": start_game()
				elif world.state == "catch": _close_catch("sell")
				elif world.state == "treasure": _close_treasure()
				elif world.state == "idle": world.input_hold = true; world.start_charge()
				elif world.state == "sinking": world.input_hold = true; world.action()
				else: world.input_hold = true
			elif not k.pressed:
				world.input_hold = false
				if world.state == "charging":
					world.release_charge()
		elif k.pressed and not k.echo:
			match k.keycode:
				KEY_M: toggle_panel("shop")
				KEY_Q: toggle_panel("aquarium")
				KEY_T: toggle_panel("tournament")
				KEY_B: toggle_panel("basket")
				KEY_G: toggle_panel("missions")
				KEY_K: toggle_panel("book")
				KEY_O: toggle_panel("daily")
				KEY_S: if world.state != "menu": _on_toggle_sound()
				KEY_ESCAPE:
					if _detail_overlay.visible: _detail_overlay.visible = false
					elif world.state == "panel": close_panels()
				KEY_1: SaveManager.select_bait("worm")
				KEY_2: SaveManager.select_bait("shrimp")
				KEY_3: SaveManager.select_bait("glow")
				KEY_4: SaveManager.select_bait("golden")
				KEY_5: SaveManager.select_bait("magnet")
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			world.input_hold = true
			world.pointer_x = mb.position.x
			world.pointer_down_x = mb.position.x
			world.dragging = false
			if world.state == "idle":
				world.start_charge()
			elif world.state == "sinking":
				world.pending_tap = true
		else:
			if world.state == "charging":
				world.release_charge()
			elif world.pending_tap:
				world.action()
			world.pending_tap = false
			world.input_hold = false
			world.dragging = false
			world.pointer_x = -1.0
	elif event is InputEventMouseMotion and world.input_hold:
		var mm := event as InputEventMouseMotion
		world.pointer_x = mm.position.x
		if absf(world.pointer_x - world.pointer_down_x) > 12.0:
			world.dragging = true
			world.pending_tap = false
