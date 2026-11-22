# 🎣 Olta Gölü (Godot 4.7)

**261 benzersiz balık türü (her birinin kısa hikayesiyle!)**, **6 tatlı 2D göl ve bölge**, **çizgili tenteli 2D Balık Pazarı & NPC müşteri siparişleri**, **canlı kişisel akvaryum**, **3 kademeli tekne sistemi**, **6 bölge bossu** ve **90 saniyelik turnuvalar** içeren 2D balık tutma oyunu.

## ✨ Özellikler

- **🐟 261 Balık Türü, Kısa Hikayeler & Tam Ansiklopedi**: Her balık türü için Latince ad, yaşam alanı, beslenme, zorluk yıldızı, biyolojik bilgi ve kısa bir **balıkçı hikayesi** (hem yakalama ekranında hem de `Balıkçı Günlüğü` detay kartında).
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
- **📜 Görevler (`G`), 10 Rütbe & 21 Başarım (`K`)**: Dinamik görevler, kalıcı rütbe bonusu, kupa rafı ve ödüllü başarımlar.
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
| `S` | Ses Aç / Kapa |
| `Esc` | Açık paneli kapat |

## 🚀 Çalıştırma & Otomatik Test (Godot 4.7)

```bash
# Godot 4.7 ile çalıştır
godot --path .

# Headless otomatik test paketini çalıştır (58/58 test)
godot --headless --path . --import
godot --headless --path . --script res://tests/test_runner.gd
```

## 🎨 Görsel Kaynaklar
- [Kenney Fish Pack](https://kenney.nl/) (CC0)
- CC0 Pixel Fishes Pack
