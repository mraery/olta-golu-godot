# 🎣 Olta Gölü (Godot 4.7)

**184 benzersiz balık türü**, **4 farklı balıkçılık bölgesi**, **canlı kişisel akvaryum**, **3 kademeli tekne sistemi**, **4 bölge bossu**, **90 saniyelik turnuvalar**, **günlük balık pazarı** ve **tam Türkçe balık ansiklopedisi** içeren 2D balık tutma oyunu.

## ✨ Özellikler

- **🐟 184 Balık Türü & Tam Ansiklopedi**: Her balık türü için Latince bilimsel ad, yaşam alanı, beslenme alışkanlığı, zorluk derecesi ve ilginç biyolojik bilgiler (hem yakalama ekranında hem de `Balıkçı Günlüğü` detay kartında).
- **🗺️ 4 Benzersiz Bölge (Biyom)**:
  - 🏞️ **Huzur Gölü** (0–150m): Klasik göl, gündüz kuşları, gece ateş böcekleri, batık çapa.
  - 🏝️ **Mercan Koyu** (0–165m): Turkuaz sular, palmiye, mercan kemeri, +%25 altın & +%35 nadir balık.
  - 🏔️ **Karanlık Fiyort** (0–190m): Kar yağışı, gece **Kuzey Işıkları (Aurora)**, batık Viking gemisi, +%45 altın & +%35 dev ağırlık.
  - 🌋 **Volkanik Çukur** (0–220m): Lav yarıkları, yükselen kıvılcımlar, magma kristalleri, +%75 altın & x2.1 nadir/efsanevi şansı.
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
