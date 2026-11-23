# 🎣 Olta Gölü (Godot 4.7)

**376 benzersiz balık türü (her birinin kendi 2D pixel-art görseli ve kısa hikayesiyle!)**, **6 tatlı 2D göl ve bölge**, **çizgili tenteli 2D Balık Pazarı & NPC müşteri siparişleri**, **canlı kişisel akvaryum**, **3 kademeli tekne sistemi**, **6 bölge bossu** ve **90 saniyelik turnuvalar** içeren 2D balık tutma oyunu.

## ✨ Özellikler

- **🐟 376 Balık Türü, Kısa Hikayeler & Tam Ansiklopedi**: Her balık türü için Latince ad, yaşam alanı, beslenme, zorluk yıldızı, biyolojik bilgi ve kısa bir **balıkçı hikayesi**.
- **🇹🇷 +115 Yeni Gerçek Tür**: Lüfer, palamut, hamsi, kalkan, barbunya, inci kefali, Abant alabalığı, mersin morinası, doktor balığı… ayrıca kılıç, orkinos, köpekbalıkları, derin deniz canavarları (engerek, fener, goblin köpekbalığı, selakant) ve egzotik nehir balıkları (arapaima, elektrikli yılan balığı). Her biri `tools/fishgen.py` ile üretilmiş kendine özgü pixel-art sprite'a sahip ve en sık görüldüğü bölgelerde daha çok çıkar.
- **🪪 Balık Kimlik Kartı**: Yakalama ekranında ve Günlük'te gerçek boy (ve tuttuğun balığın tahmini boyu), ömür, Türkiye'de nerede görüldüğü, IUCN koruma durumu, çekişme karakteri, derinlik/zaman ve boy sınıfı (Yavru → Efsanevi Boy).
- **🎣 Yeni Yakalama Mekaniği**: Balık vurunca **❗ hemen bas** (Kusursuz Kanca = +%18 ilerleme, +%15 XP); türün karakterine göre (Sakin, Kaçak, Zıplayan, Dalgıç, İnatçı) **hareket eden yeşil bölge**; balık sağa/sola kaçınca **ters yöne bas** (A/D veya fareyle sürükle); yorulunca kolaylaşan **balık gücü** barı; zıplayan balıklarda havadayken makarayı bırak!
- **👀 Görünür Balıklar**: Tüm sprite'lar türün gerçek boyuna göre ölçeklenir; 16 px'lik minik pixel balıklar artık nokta gibi değil.
- **🏪 Tatlı 2D Balık Pazarı (`B`)**: Kırmızı-beyaz çizgili tenteli ahşap tezgah, buz kasalarında sergilenen balıkların, animasyonlu 4 NPC müşteri (**Şef Hüseyin**, **Kedi Minnoş**, **Koleksiyoncu Leyla**, **Kaptan Osman**) ve özel sipariş bonusları (`+%65`–`+%90`), günlük talep (`+%50`) ve **🤝 Pazarlık Et** mekaniği!
- **🗺️ 6 Tatlı 2D Göl & Bölge**:
  - 🏞️ **Huzur Gölü** (0–150m): Nilüfer yaprakları, lotus çiçekleri, gölde yüzen minik sarı ördek, sazlıklar ve batık çapa.
  - 🌸 **Kiraz Çiçeği Göleti** (0–155m): Uçuşan pembe sakura yaprakları, kırmızı kemerli Japon köprüsü, batık Torii kapısı, +%20 altın & +%25 nadir.
  - 🏝️ **Mercan Koyu** (0–165m): Turkuaz sular, palmiyeler, mercan kemeri, +%28 altın & +%38 nadir.
  - 🌲 **Zümrüt Orman Gölü** (0–180m): Çam ormanı, bacasından duman tüten sıcak orman kulübesi, ateş böcekleri, +%38 altın & +%40 dev ağırlık.
  - 🏔️ **Karanlık Fiyort** (0–195m): Kar yağışı, gece **Kuzey Işıkları (Aurora)**, batık Viking gemisi, +%50 altın & +%42 dev ağırlık.
  - 🌋 **Volkanik Çukur** (0–225m): Lav yarıkları, yükselen kıvılcımlar, magma kristalleri, +%80 altın & x2.2 nadir/efsanevi.
- **🐠 Canlı Kişisel Akvaryum (`Q`)**: Yakaladığın balıkları akvaryumuna koy, suya tıklayarak veya butonla yemle (`2x` gelir), ziyaretçilerden pasif altın topla!
- **🚤 3 Kademeli Tekne & ✨ Balık Sürüleri**: İskeleden başlayıp **Ahşap Sandal → Motorlu Tekne → Kaptan Yatı** al, `←` / `→` ile gölde gez ve su yüzeyindeki parlayan **`✨ Sürü!`** noktalarını yakala.
- **🐉 4 Bölge Bossu**: Her bölgenin kendine özgü efsanevi dev boss balığı (`Gölün Efendisi`, `Mercan Kralı`, `Fiyort Leviathanı`, `Magma Ejderi`).
- **🏆 90 Saniyelik Turnuvalar (`T`)**: Bronz, Gümüş ve Altın liglerinde zamana karşı yarışıp kupa, altın ve özel yem paketleri kazan.
- **🧺 Sepet & Günlük Balık Pazarı (`B`)**: Her oyun günü belirli türler **+%50 talep** görür.
- **📜 Görevler (`G`), 10 Rütbe & 26 Başarım (`K`)**: Dinamik görevler, kalıcı rütbe bonusu, kupa rafı ve ödüllü başarımlar.
- **🎁 Günlük Giriş Ödülü (`O`)**: 7 günlük seri takvimi; her gün altın + özel yem. Gün atlarsan seri sıfırlanır, ödüller rütbeyle artar.
- **🌙 Çevrimdışı Akvaryum Geliri**: Oyun kapalıyken akvaryum ziyaretçileri %50 hızla (en fazla 8 saat) altın bırakır.
- **📊 İstatistik Sekmesi**: Oyun süresi, isabet oranı, toplam kazanç, nadirlik bazında av dağılımı ve daha fazlası (`K` → İstatistik).
- **▶️ Devam Et / Yeni Oyun**: Ana menüde kayıt özeti; otomatik kayıt (20 sn) ve pencere kapanırken kayıt.
- **🔊 Prosedürel WebAudio-Tarzı Ses Sentezi**: Harici ses dosyasına ihtiyaç duymadan 16-bit PCM sentezli 18 farklı ses efekti.

## 🎮 Kontroller

| Tuş / İşlem | Görev |
| --- | --- |
| `Boşluk` / `Enter` / Sol Tık | Basılı tut & yeşil bölgede bırak (Mükemmel Atış), sar, çek |
| `←` `→` veya `A` `D` / Sürükle | Suda iğneyi yönlendir • Yüzeyde tekneyi sür |
| `1` – `5` | Hızlı yem seçimi |
| `M` | Mağaza (Yükseltmeler, Özel Yemler, Bölgeler) |
| `Q` | Canlı Akvaryum |
| `T` | 90 Saniyelik Turnuva |
| `B` | Balık Sepeti & Günlük Pazar |
| `G` | Görevler & Rütbe |
| `K` | Balıkçı Günlüğü, Kupa Rafı & Başarımlar |
| `O` | Günlük Giriş Ödülü |
| `S` | Ses Aç / Kapa |
| `Esc` | Açık paneli kapat |

## 🚀 Çalıştırma & Otomatik Test (Godot 4.7)

```bash
# Godot 4.7 ile çalıştır
godot --path .

# Headless otomatik test paketini çalıştır (102/102 test — oyuncu kaydı yedeklenip geri yüklenir)
godot --headless --path . --import
godot --headless --path . --script res://tests/test_runner.gd
```

## 🎨 Görsel Kaynaklar
- [Kenney Fish Pack](https://kenney.nl/) (CC0)
- CC0 Pixel Fishes Pack

## 🧰 Yeni Tür Ekleme
```bash
# tools/new_species.py içine F(...) satırı ekle, sonra:
python3 tools/build_species.py          # sprite üretir + data/fish_db.json'u günceller
godot --headless --path . --import      # yeni PNG'leri içe aktar
```
