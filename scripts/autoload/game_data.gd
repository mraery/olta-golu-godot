extends Node

## Tüm oyun verileri: 184 balık türü, 4 bölge, 10 yükseltme, 5 yem, 4 hava durumu,
## 3 turnuva, 20 başarım, hazineler ve görev şablonları.

const W: float = 960.0
const H: float = 540.0
const SURF: float = 190.0
const PPM: float = 12.0

const RARITIES: Array[Dictionary] = [
	{"name": "Yaygın",    "w": 60.0, "color": Color("#8c8c8c"), "bg": Color("#e3e3e3")},
	{"name": "Sık",       "w": 30.0, "color": Color("#2a7a2a"), "bg": Color("#d6f5d6")},
	{"name": "Nadir",     "w": 13.0, "color": Color("#1d5fb0"), "bg": Color("#d6e8ff")},
	{"name": "Çok Nadir", "w": 5.0,  "color": Color("#6b2fb8"), "bg": Color("#ead9ff")},
	{"name": "Efsanevi",  "w": 1.4,  "color": Color("#995c00"), "bg": Color("#ffe58a")},
]

const HAZARD_SPRITES: Array[String] = [
	"fish_blue_skeleton", "fish_green_skeleton", "fish_red_skeleton", "fish_orange_skeleton"
]

const BIOMES: Array[Dictionary] = [
	{
		"id": "lake", "name": "Huzur Gölü", "icon": "🏞️", "cost": 0, "max_depth": 150,
		"val_mul": 1.0, "rare_mul": 1.0, "weight_mul": 1.0,
		"desc": "Sakin sular, yemyeşil tepeler ve klasik ahşap iskele. Başlamak için ideal.",
		"bonus_text": "Dengeli balık dağılımı",
		"water_day":   [Color("#38a6e0"), Color("#1f7cc0"), Color("#124f8c"), Color("#0a2c55")],
		"water_night": [Color("#1b4f7a"), Color("#123a62"), Color("#0b2547"), Color("#050f22")],
		"hills_day":   [Color("#6aa874"), Color("#4f9463")],
		"hills_night": [Color("#172440"), Color("#10203a")],
		"pier":        [Color("#a8743f"), Color("#b9824a"), Color("#5a3a1e"), Color("#7d522b")],
		"ambient": "leaves",
	},
	{
		"id": "coral", "name": "Mercan Koyu", "icon": "🏝️", "cost": 800, "max_depth": 165,
		"val_mul": 1.25, "rare_mul": 1.35, "weight_mul": 1.05,
		"desc": "Turkuaz tropikal sular, palmiye ağaçları ve renkli mercan resifleri.",
		"bonus_text": "+%25 altın • +%35 nadir balık",
		"water_day":   [Color("#29d4c6"), Color("#149eb8"), Color("#0c658a"), Color("#073452")],
		"water_night": [Color("#14687a"), Color("#0d4961"), Color("#072c42"), Color("#041426")],
		"hills_day":   [Color("#d9b977"), Color("#6fb365")],
		"hills_night": [Color("#282d4a"), Color("#162a3d")],
		"pier":        [Color("#c9985a"), Color("#d9aa6c"), Color("#7a532a"), Color("#9c6e3b")],
		"ambient": "tropical",
	},
	{
		"id": "fjord", "name": "Karanlık Fiyort", "icon": "🏔️", "cost": 2400, "max_depth": 190,
		"val_mul": 1.45, "rare_mul": 1.55, "weight_mul": 1.35,
		"desc": "Buz gibi kuzey suları, çam ormanları ve geceleri dans eden kuzey ışıkları.",
		"bonus_text": "+%45 altın • +%35 dev ağırlık • Kuzey Işıkları",
		"water_day":   [Color("#3e7a9e"), Color("#265578"), Color("#163552"), Color("#091829")],
		"water_night": [Color("#1b3852"), Color("#10243b"), Color("#091526"), Color("#040914")],
		"hills_day":   [Color("#5f758a"), Color("#38524d")],
		"hills_night": [Color("#152030"), Color("#0d1a24")],
		"pier":        [Color("#7a6e63"), Color("#8c7f73"), Color("#423932"), Color("#594f46")],
		"ambient": "snow",
	},
	{
		"id": "volcano", "name": "Volkanik Çukur", "icon": "🌋", "cost": 6000, "max_depth": 220,
		"val_mul": 1.75, "rare_mul": 2.1, "weight_mul": 1.5,
		"desc": "Kızgın lav yarıklarıyla aydınlanan efsanevi abis. En büyük canavarlar burada yaşar.",
		"bonus_text": "+%75 altın • x2.1 nadir/efsanevi • 220m derinlik",
		"water_day":   [Color("#4b6b8a"), Color("#364466"), Color("#2b2042"), Color("#260d1c")],
		"water_night": [Color("#2d2c4a"), Color("#211a36"), Color("#1a0e26"), Color("#17050c")],
		"hills_day":   [Color("#5c4347"), Color("#3d292d")],
		"hills_night": [Color("#26171c"), Color("#170c10")],
		"pier":        [Color("#4d4346"), Color("#5e5256"), Color("#2b2326"), Color("#3b3034")],
		"ambient": "embers",
	},
]

const UPGRADES: Array[Dictionary] = [
	{"id": "rod",      "ic": "🎣", "name": "Olta Boyu",    "vals": [30, 55, 85, 115, 150, 185, 220], "cost": [0, 110, 340, 820, 1800, 3600, 6800]},
	{"id": "line",     "ic": "🧵", "name": "Misina",       "vals": [0, 12, 24, 36, 50, 65],          "cost": [0, 140, 420, 1050, 2400, 5000]},
	{"id": "reel",     "ic": "⚙️", "name": "Makara",       "vals": [0, 20, 40, 65, 95, 130],         "cost": [0, 130, 400, 950, 2200, 4800]},
	{"id": "bait",     "ic": "🪱", "name": "Yem Kalitesi", "vals": [1.0, 1.4, 1.9, 2.6, 3.5, 4.6],   "cost": [0, 190, 560, 1400, 3200, 6500]},
	{"id": "lantern",  "ic": "🏮", "name": "Dip Feneri",   "vals": [0, 100, 165, 240, 330],          "cost": [0, 260, 720, 1700, 3600]},
	{"id": "sonar",    "ic": "📡", "name": "Sonar Radar",  "vals": [0, 28, 50, 78, 110],             "cost": [0, 320, 900, 2100, 4200]},
	{"id": "basket",   "ic": "🧺", "name": "Balık Sepeti", "vals": [6, 12, 20, 32, 50],              "cost": [0, 180, 520, 1300, 3000]},
	{"id": "hook",     "ic": "🪝", "name": "Altın Kanca",  "vals": [0, 15, 30, 50, 75],              "cost": [0, 300, 850, 2100, 4800]},
	{"id": "boat",     "ic": "🚤", "name": "Tekne",        "vals": [0, 1, 2, 3],                     "cost": [0, 250, 1100, 3400]},
	{"id": "aquarium", "ic": "🐠", "name": "Akvaryum",     "vals": [4, 8, 14, 22],                   "cost": [0, 220, 700, 2000]},
]

const BAITS: Array[Dictionary] = [
	{"id": "worm",   "name": "Solucan",         "icon": "🪱", "color": Color("#ff7aa8"), "cost": 0,   "pack": 0, "infinite": true,  "attract_r": 1.0,  "rare_mul": 1.0,  "val_mul": 1.0,  "weight_mul": 1.0,  "treasure_mul": 1.0, "anti_hazard": false, "glow": false, "desc": "Standart sınırsız balık yemi."},
	{"id": "shrimp", "name": "Parlak Karides",  "icon": "🦐", "color": Color("#ff9b54"), "cost": 65,  "pack": 5, "infinite": false, "attract_r": 1.85, "rare_mul": 1.35, "val_mul": 1.15, "weight_mul": 1.25, "treasure_mul": 1.0, "anti_hazard": false, "glow": false, "desc": "Balıkları uzaktan çeker, +%25 ağırlık & +%15 altın."},
	{"id": "glow",   "name": "Fosforlu Yem",    "icon": "✨", "color": Color("#4dffb8"), "cost": 120, "pack": 5, "infinite": false, "attract_r": 1.5,  "rare_mul": 1.75, "val_mul": 1.25, "weight_mul": 1.15, "treasure_mul": 1.4, "anti_hazard": true,  "glow": true,  "desc": "Derinlerde parlar, Kemik Balıkları uzaklaştırır!"},
	{"id": "golden", "name": "Altın Yem",       "icon": "👑", "color": Color("#ffd633"), "cost": 220, "pack": 5, "infinite": false, "attract_r": 1.65, "rare_mul": 2.8,  "val_mul": 1.5,  "weight_mul": 1.35, "treasure_mul": 1.5, "anti_hazard": false, "glow": true,  "desc": "Nadir & Efsanevi balık şansı x2.8, +%50 satış değeri!"},
	{"id": "magnet", "name": "Hazine Mıknatısı","icon": "🧲", "color": Color("#ff4f6d"), "cost": 160, "pack": 4, "infinite": false, "attract_r": 1.15, "rare_mul": 1.2,  "val_mul": 1.1,  "weight_mul": 1.0,  "treasure_mul": 4.5, "anti_hazard": true,  "glow": true,  "desc": "Batık hazine ve inci şansı x4.5! Kemik Balık işlemez."},
]

const WEATHERS: Array[Dictionary] = [
	{"id": "clear",  "name": "Açık",     "icon": "☀️", "bite_mul": 1.0,  "rare_mul": 1.0,  "val_mul": 1.0,  "rain": false, "storm": false},
	{"id": "cloudy", "name": "Bulutlu",  "icon": "☁️", "bite_mul": 1.2,  "rare_mul": 1.18, "val_mul": 1.1,  "rain": false, "storm": false},
	{"id": "rain",   "name": "Yağmurlu", "icon": "🌧️", "bite_mul": 1.45, "rare_mul": 1.45, "val_mul": 1.25, "rain": true,  "storm": false},
	{"id": "storm",  "name": "Fırtına",  "icon": "⛈️", "bite_mul": 1.75, "rare_mul": 2.0,  "val_mul": 1.45, "rain": true,  "storm": true},
]

const DEPTH_ZONES: Array[Dictionary] = [
	{"max": 35,  "name": "Sığ Sular",     "color": Color("#69dbff")},
	{"max": 75,  "name": "Mercan Bandı",  "color": Color("#43c59e")},
	{"max": 120, "name": "Alacakaranlık", "color": Color("#7c83fd")},
	{"max": 165, "name": "Derin Vadi",    "color": Color("#b77cff")},
	{"max": 999, "name": "Abis Çukuru",   "color": Color("#ff6b6b")},
]

const RANKS: Array[Dictionary] = [
	{"lv": 1,  "xp": 0,    "title": "Acemi Balıkçı"},
	{"lv": 2,  "xp": 120,  "title": "Göl Çırağı"},
	{"lv": 3,  "xp": 320,  "title": "Kıyı Avcısı"},
	{"lv": 4,  "xp": 650,  "title": "Usta Olta"},
	{"lv": 5,  "xp": 1150, "title": "Derinlik Kaşifi"},
	{"lv": 6,  "xp": 1850, "title": "Resif Kaptanı"},
	{"lv": 7,  "xp": 2800, "title": "Fırtına Avcısı"},
	{"lv": 8,  "xp": 4100, "title": "Abis Fatihi"},
	{"lv": 9,  "xp": 5800, "title": "Efsane Balıkçı"},
	{"lv": 10, "xp": 8000, "title": "Denizler Hakimi"},
]

const TREASURE_TYPES: Array[Dictionary] = [
	{"id": "chest",  "name": "Batık Hazine Sandığı", "icon": "🧰", "min_d": 25, "gold": [90, 280],  "xp": 45, "desc": "Eski bir korsan sandığı! İçi altın sikkelerle dolu."},
	{"id": "pearl",  "name": "Dev İnci İstiridyesi", "icon": "🦪", "min_d": 15, "gold": [60, 190],  "xp": 35, "desc": "Işıl ışıl parlayan nadir bir göl incisi!"},
	{"id": "bottle", "name": "Mesaj Şişesi",         "icon": "🍾", "min_d": 8,  "gold": [35, 110],  "xp": 25, "notes": [
		"\"Fırtınalı gecelerde 125m derine in, Kadim Yılan Kral uyanır…\"",
		"\"Fosforlu yem Kemik Balıkları kaçırır, boşuna yem kaptırma!\"",
		"\"Balık Pazarı'ndaki günlük fırsatları takip et, sepetini +%50 fazlaya sat!\"",
		"\"Mükemmel atış yaparsan iğnen daha hızlı batar ve nadir balık şansın artar.\"",
		"\"Volkanik Çukur'un dibinde Magma Ejderi yüzüyor…\"",
	]},
]

const TOURNAMENTS: Array[Dictionary] = [
	{"id": "bronze", "name": "🥉 Bronz Göl Turnuvası",      "duration": 90.0, "goal_kind": "kg",   "goal": 12.0,   "reward_gold": 450,  "reward_xp": 140, "reward_bait": "shrimp", "desc": "90 saniyede toplam 12 kg balık yakala!"},
	{"id": "silver", "name": "🥈 Gümüş Kaptan Kupası",      "duration": 90.0, "goal_kind": "kg",   "goal": 32.0,   "reward_gold": 1100, "reward_xp": 280, "reward_bait": "glow",   "desc": "90 saniyede toplam 32 kg balık yakala!"},
	{"id": "gold",   "name": "🥇 Altın Efsane Şampiyonası", "duration": 90.0, "goal_kind": "gold", "goal": 1800.0, "reward_gold": 2800, "reward_xp": 520, "reward_bait": "golden", "desc": "90 saniyede 1.800 altınlık balık yakala!"},
]

const ACHIEVEMENTS: Array[Dictionary] = [
	{"id": "first_catch", "ic": "🐟", "name": "İlk Av",             "desc": "İlk balığını yakala",                    "reward": 40},
	{"id": "species_10",  "ic": "📖", "name": "Meraklı Doğa",       "desc": "10 farklı balık türü keşfet",            "reward": 150},
	{"id": "species_30",  "ic": "📚", "name": "Biyolog",            "desc": "30 farklı balık türü keşfet",            "reward": 450},
	{"id": "species_75",  "ic": "🧬", "name": "Ansiklopedi",        "desc": "75 farklı balık türü keşfet",            "reward": 1400},
	{"id": "species_150", "ic": "🌐", "name": "Efsane Koleksiyoncu","desc": "150 farklı balık türü keşfet",           "reward": 3500},
	{"id": "combo_5",     "ic": "🔥", "name": "Seri Avcı",          "desc": "5'li yakalama kombosuna ulaş",           "reward": 180},
	{"id": "combo_10",    "ic": "⚡", "name": "Durdurulamaz",       "desc": "10'lu yakalama kombosuna ulaş",          "reward": 500},
	{"id": "perfect_5",   "ic": "🎯", "name": "Keskin Nişancı",     "desc": "5 kez Mükemmel Atış yap",                "reward": 160},
	{"id": "heavy_15",    "ic": "⚖️", "name": "Ağır Siklet",        "desc": "15 kg veya daha ağır balık yakala",      "reward": 300},
	{"id": "heavy_40",    "ic": "🐋", "name": "Canavar Avcısı",     "desc": "40 kg veya daha ağır balık yakala",      "reward": 950},
	{"id": "treasure_3",  "ic": "💎", "name": "Hazine Avcısı",      "desc": "3 batık hazine çıkar",                   "reward": 250},
	{"id": "night_5",     "ic": "🌙", "name": "Gece Kuşu",          "desc": "Gece 5 balık yakala",                    "reward": 200},
	{"id": "storm_5",     "ic": "⛈️", "name": "Fırtına Kaptanı",    "desc": "Yağmur veya fırtınada 5 balık yakala",   "reward": 260},
	{"id": "deep_100",    "ic": "🌊", "name": "Derin Dalgıç",       "desc": "100m veya daha derinden balık yakala",   "reward": 400},
	{"id": "legendary_1", "ic": "👑", "name": "Efsanevi An",        "desc": "Efsanevi bir balık yakala",              "reward": 1000},
	{"id": "rich_5000",   "ic": "💰", "name": "Zengin Balıkçı",     "desc": "Toplam 5.000 altın kazan",               "reward": 500},
	{"id": "biome_all",   "ic": "🗺️", "name": "Dünya Gezgini",      "desc": "Tüm 4 balıkçılık bölgesini aç",          "reward": 1500},
	{"id": "boat_owner",  "ic": "🚤", "name": "Tekne Kaptanı",      "desc": "İlk tekneni satın al ve göle açıl",      "reward": 200},
	{"id": "aqua_3",      "ic": "🐠", "name": "Akvaryum Ustası",    "desc": "Akvaryumuna en az 3 balık yerleştir",    "reward": 220},
	{"id": "boss_1",      "ic": "🐉", "name": "Efsane Avcısı",      "desc": "Bir Bölge Boss balığını yakala",         "reward": 1200},
	{"id": "tourney_1",   "ic": "🏆", "name": "Turnuva Şampiyonu",  "desc": "Bir Balıkçılık Turnuvası kazan",         "reward": 450},
]

const MISSION_POOL: Array[Dictionary] = [
	{"type": "catch_any",   "targets": [3, 5, 8, 12],          "gold": [80, 150, 280, 460],  "xp": [40, 75, 130, 200]},
	{"type": "catch_kg",    "targets": [6, 15, 35, 70],        "gold": [100, 210, 420, 750], "xp": [50, 95, 180, 290]},
	{"type": "catch_rare",  "targets": [1, 2, 4, 6],           "gold": [140, 280, 550, 950], "xp": [70, 130, 240, 380]},
	{"type": "catch_deep",  "targets": [25, 50, 80, 120],      "gold": [110, 220, 420, 800], "xp": [55, 105, 190, 320], "need": 2},
	{"type": "perfect",     "targets": [2, 3, 5, 7],           "gold": [90, 180, 320, 520],  "xp": [45, 85, 145, 220]},
	{"type": "treasure",    "targets": [1, 2, 3, 4],           "gold": [130, 260, 460, 760], "xp": [65, 120, 200, 310]},
	{"type": "earn_gold",   "targets": [180, 450, 1100, 2500], "gold": [100, 220, 450, 880], "xp": [50, 100, 195, 330]},
	{"type": "catch_night", "targets": [2, 3, 5, 8],           "gold": [130, 250, 450, 750], "xp": [65, 115, 200, 310]},
]

var species: Array[Dictionary] = []
var species_by_id: Dictionary = {}
var boss_species: Array[Dictionary] = []
var tex_cache: Dictionary = {}

func _ready() -> void:
	_load_species_db()

func _load_species_db() -> void:
	species.clear()
	species_by_id.clear()
	boss_species.clear()
	var file := FileAccess.open("res://data/fish_db.json", FileAccess.READ)
	if file == null:
		push_error("GameData: res://data/fish_db.json okunamadı!")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("GameData: fish_db.json geçerli bir dizi değil!")
		return
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY:
			species.append(item)
			species_by_id[item["id"]] = item
			if item.get("boss", false):
				boss_species.append(item)

func get_species(id: String) -> Dictionary:
	return species_by_id.get(id, species[0] if species.size() > 0 else {})

func get_boss_for_biome(biome_id: String) -> Dictionary:
	for b in boss_species:
		if b.get("biome", "") == biome_id:
			return b
	return boss_species[0] if boss_species.size() > 0 else {}

func get_biome(id: String) -> Dictionary:
	for b in BIOMES:
		if b["id"] == id:
			return b
	return BIOMES[0]

func get_upgrade(id: String) -> Dictionary:
	for u in UPGRADES:
		if u["id"] == id:
			return u
	return {}

func get_bait(id: String) -> Dictionary:
	for b in BAITS:
		if b["id"] == id:
			return b
	return BAITS[0]

func get_depth_zone(depth_m: float) -> Dictionary:
	for z in DEPTH_ZONES:
		if depth_m <= float(z["max"]):
			return z
	return DEPTH_ZONES[DEPTH_ZONES.size() - 1]

func upgrade_desc(id: String, val) -> String:
	match id:
		"rod":      return "İnebileceğin derinlik: %d m" % int(val)
		"line":     return "Gerginlik toleransı +%%%d" % int(val)
		"reel":     return "Sarma hızı +%%%d" % int(val)
		"bait":     return "Nadir balık şansı x%.1f" % float(val)
		"lantern":  return "Karanlık derinlikler kapalı" if int(val) == 0 else "Aydınlatma yarıçapı: %d px" % int(val)
		"sonar":    return "Yakındaki balıklar gizli" if int(val) == 0 else "Sonar tarama menzili: %d m" % int(val)
		"basket":   return "Sepet kapasitesi: %d balık" % int(val)
		"hook":     return "Standart satış fiyatı" if int(val) == 0 else "Tüm balık fiyatları +%%%d" % int(val)
		"boat":
			var names := ["İskele (sabit)", "Ahşap Sandal (← → gez!)", "Motorlu Tekne (hızlı + %15 şans)", "Kaptan Yatı (süper hız + %35 şans)"]
			return names[clampi(int(val), 0, names.size() - 1)]
		"aquarium": return "Akvaryum kapasitesi: %d balık" % int(val)
	return ""

func mission_label(m_type: String, target: int) -> String:
	match m_type:
		"catch_any":   return "%d balık yakala" % target
		"catch_kg":    return "Toplam %d kg balık yakala" % target
		"catch_rare":  return "%d adet Nadir veya üstü balık yakala" % target
		"catch_deep":  return "%dm veya daha derinden 2 balık yakala" % target
		"perfect":     return "%d kez Mükemmel Atış yap" % target
		"treasure":    return "%d batık hazine çıkar" % target
		"earn_gold":   return "%d altın değerinde balık sat" % target
		"catch_night": return "Gece vakti %d balık yakala" % target
	return ""

func get_fish_texture(spr_name: String) -> Texture2D:
	if tex_cache.has(spr_name):
		return tex_cache[spr_name]
	var path := "res://assets/fish/%s.png" % spr_name
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	elif FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			tex = ImageTexture.create_from_image(img)
	tex_cache[spr_name] = tex
	return tex

func get_env_texture(spr_name: String) -> Texture2D:
	var key := "env_" + spr_name
	if tex_cache.has(key):
		return tex_cache[key]
	var path := "res://assets/env/%s.png" % spr_name
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	elif FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			tex = ImageTexture.create_from_image(img)
	tex_cache[key] = tex
	return tex

func fish_difficulty_stars(sp: Dictionary) -> int:
	return clampi(int(round(float(sp.get("str", 1.5)))), 1, 5)

func fish_difficulty_label(stars: int) -> String:
	var labels := ["Çok Kolay", "Kolay", "Orta", "Zor", "Çok Zor"]
	return labels[clampi(stars - 1, 0, labels.size() - 1)]
