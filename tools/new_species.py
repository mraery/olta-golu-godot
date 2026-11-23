# -*- coding: utf-8 -*-
"""Olta Gölü — yeni balık türleri (gerçek türler, Türkçe ansiklopedi bilgisi + sprite parametreleri).

Alanlar:
  len  : türün bilinen en büyük boyu (cm)      life: ortalama/azami ömür (yıl, metin)
  tr   : Türkiye sularındaki durumu (metin)     iucn: LC NT VU EN CR DD
  home : en sık görüldüğü oyun bölgeleri        beh : çekişme karakteri (sakin|kacak|dalgic|ziplayan|inatci)
  art  : fishgen.render parametreleri
"""

# ---- sprite ön ayarları ------------------------------------------------------
P = {
    "perch":    dict(L=32, H=7.0, tail="fork", dorsal=(0.25, 0.7), dorsal_type="spiky", dorsal_h=4, eye=2),
    "bream":    dict(L=30, H=9.0, tail="fork", dorsal=(0.3, 0.72), dorsal_type="spiky", dorsal_h=3, peak=0.42, blunt=0.7, eye=2),
    "mackerel": dict(L=38, H=6.0, tail="fork", dorsal=(0.25, 0.4), dorsal_h=4, ped=0.16, peak=0.4, eye=2),
    "tuna":     dict(L=44, H=9.5, tail="lunate", dorsal=(0.3, 0.42), dorsal_h=6, ped=0.12, peak=0.4, blunt=0.5, eye=2),
    "herring":  dict(L=28, H=4.5, tail="fork", dorsal=(0.38, 0.52), dorsal_h=3, anal_h=1.5, eye=2, pect=2),
    "mullet":   dict(L=34, H=6.0, tail="fork", dorsal=(0.3, 0.45), dorsal_h=3, blunt=0.9, eye=2),
    "grouper":  dict(L=38, H=9.0, tail="round", dorsal=(0.22, 0.75), dorsal_type="spiky", dorsal_h=3, mouth="big", blunt=0.6, eye=2, peak=0.35),
    "eel":      dict(L=60, H=3.2, tail="point", dorsal=(0.3, 0.98), dorsal_h=1.5, dorsal_type="round", anal=(0.5, 0.98), anal_h=1.2, wave=3, peak=0.2, ped=0.6, pect=2, eye=1, gill_line=False),
    "shark":    dict(L=48, H=6.5, tail="shark", dorsal=(0.33, 0.47), dorsal_h=8, dorsal_type="tri", gill_slits=4, pect=6, peak=0.38, anal_h=2, eye=1, gill_line=False),
    "pike":     dict(L=46, H=5.0, tail="fork", dorsal=(0.7, 0.82), dorsal_h=4, anal=(0.7, 0.82), anal_h=3, blunt=0.9, peak=0.5, mouth="big", eye=2),
    "bill":     dict(L=46, H=7.0, tail="lunate", snout=16, ped=0.15, dorsal=(0.12, 0.3), dorsal_h=9, eye=2),
    "deep":     dict(L=34, H=5.0, tail="fork", teeth=1, mouth="big", eye=2, eye_col="#bfe9ff", dorsal=(0.15, 0.25), dorsal_h=3, outline="#05070c"),
    "angler":   dict(L=30, H=10, mouth="big", teeth=1, blunt=0.3, peak=0.25, tail="round", eye=1, dorsal_h=0, pect=4),
    "disc":     dict(L=24, H=11, tail="square", dorsal=(0.2, 0.8), dorsal_h=5, anal=(0.35, 0.85), anal_h=5, peak=0.45, blunt=0.6, ped=0.35, eye=2),
    "catfish":  dict(L=48, H=6.0, barbels=2, tail="round", dorsal=(0.3, 0.36), dorsal_h=3, anal=(0.45, 0.97), anal_h=3, mouth="big", peak=0.2, ped=0.55, blunt=0.4, eye=1),
    "sturgeon": dict(L=50, H=5.5, tail="shark", snout=5, snout_dy=1, snout_thick=1, barbels=1, dorsal=(0.72, 0.8), dorsal_h=3, peak=0.35, pattern="dots", n=14, eye=1),
    "carp":     dict(L=36, H=8.5, tail="fork", dorsal=(0.3, 0.68), dorsal_h=3, peak=0.4, blunt=0.75, eye=2),
    "trout":    dict(L=36, H=6.5, tail="square", dorsal=(0.36, 0.5), dorsal_h=4, blunt=0.7, eye=2),
    "puffer":   dict(L=24, H=9.5, tail="round", peak=0.45, blunt=0.5, ped=0.3, dorsal=(0.7, 0.8), dorsal_h=3, eye=2),
    "scorpion": dict(L=30, H=8.0, tail="round", dorsal=(0.15, 0.75), dorsal_type="spiky", dorsal_h=5, mouth="big", blunt=0.5, pect=5, pattern="mottled", eye=2),
    "gar":      dict(L=50, H=4.5, tail="round", snout=8, snout_thick=1, dorsal=(0.78, 0.86), dorsal_h=3, anal=(0.78, 0.86), anal_h=3, pattern="spots", eye=2),
    "goby":     dict(L=26, H=5.0, tail="round", dorsal=(0.3, 0.75), dorsal_h=3, blunt=0.4, eye=2, eye_y=0.45),
    "flat":     dict(shape="flat", L=30, H=12),
    "ray":      dict(shape="ray", L=30),
}


def A(base, **kw):
    d = dict(P[base])
    d.update(kw)
    return d


S = []


def F(id, name, latin, art, d, kg, r, st, val, spd, home, length, life, tr, iucn, habitat, diet, fact, story, beh=None, night=None):
    e = {
        "id": id, "name": name, "latin": latin, "spr": "fish_gen_" + id, "d": list(d), "kg": list(kg),
        "str": st, "val": val, "r": r, "sc": 0.6, "spd": list(spd), "home": home,
        "len": length, "life": life, "tr": tr, "iucn": iucn,
        "habitat": habitat, "diet": diet, "fact": fact, "story": story, "art": art,
    }
    if beh:
        e["beh"] = beh
    if night:
        e["night"] = night
    S.append(e)


MED = ["coral", "lake"]
SEA = ["coral"]
FRESH = ["lake", "emerald", "sakura"]
NORTH = ["fjord"]
DEEP = ["volcano", "fjord"]
TROP = ["coral"]
EXOTIC = ["emerald", "volcano"]

# ============================== TÜRKİYE DENİZLERİ ==============================
F("lufer", "Lüfer", "Pomatomus saltatrix",
  A("mackerel", L=38, H=7, body="#4f7fa6", belly="#dfe9ef", fin="#5c7c94", dorsal=(0.32, 0.7), dorsal_type="round", mouth="big", teeth=1),
  (4, 60), (0.6, 6.5), 2, 3.4, 40, (60, 96), MED, 130, "9 yıla kadar", "Boğaz ve Marmara'nın simgesi; sonbaharda göç eder", "VU",
  "Kıyıya yakın açık sular, akıntılı boğazlar", "Hamsi, istavrit ve küçük balık sürüleri",
  "Keskin dişleriyle bilinen, sürü halinde avlanan doymak bilmez bir yırtıcıdır. Boyuna göre çinakop, sarıkanat, lüfer ve kofana diye adlandırılır.",
  "İstanbul'da yaşlı balıkçılar 'Lüfer gelince Boğaz bayram yapar' derdi; ilk kofanayı tutan, kahvede bir hafta çay ısmarlarmış.", beh="kacak")
F("palamut", "Palamut", "Sarda sarda",
  A("mackerel", L=40, H=7, body="#3e5f88", belly="#e2e8ee", pattern="stripes", n=5, pcol="#24384f", tail="lunate", finlets="#d8c55a", ped=0.15),
  (3, 70), (0.8, 7.0), 2, 3.3, 38, (70, 105), MED, 90, "5 yıl", "Karadeniz'den Ege'ye göç eder, sonbahar avı ünlüdür", "LC",
  "Açık kıyı suları, göç yolları", "Hamsi, sardalya, kalamar",
  "Sırtındaki eğik koyu çizgilerle tanınır. Karadeniz'de yumurtlar, sonbaharda büyük sürüler halinde Boğaz'dan Marmara'ya iner.",
  "Ekim ayında Boğaz'da martılar bir yere toplandıysa, balıkçılar kayığa koşar: 'Palamut sürüsü altında!'", beh="kacak")
F("hamsi", "Hamsi", "Engraulis encrasicolus",
  A("herring", L=26, H=3.8, body="#5f8fa8", belly="#eef3f6", pattern="lateral", pcol="#c9d6de", snout=1, snout_col="#5f8fa8"),
  (1, 40), (0.01, 0.06), 0, 1.0, 16, (60, 95), MED, 20, "3 yıl", "Karadeniz'in en önemli balığı; kışın bolca tutulur", "LC",
  "Kıyıya yakın yüzey suları", "Plankton",
  "Karadeniz mutfağının vazgeçilmezidir. Milyonlarca bireylik sürüler halinde yaşar; yunusların ve palamutun ana besinidir.",
  "Rize'de bir teyze, hamsiyle kırk çeşit yemek yaptığını söyler; kırk birincisini de 'hamsili tatlı' diye anlatırmış.", beh="sakin")
F("istavrit", "İstavrit", "Trachurus mediterraneus",
  A("mackerel", L=32, H=6, body="#6f93a8", belly="#e7edf1", pattern="lateral", pcol="#3d5566", pattern2="", eye=2),
  (2, 60), (0.08, 0.5), 0, 1.4, 19, (55, 90), MED, 60, "9 yıl", "Tüm denizlerimizde bol; çapariyle avlanır", "LC",
  "Kıyı ve açık sular, sürüler halinde", "Küçük balıklar ve kabuklular",
  "Yan çizgisi boyunca dizilmiş sert kemik pulları vardır. İskeleden çapariyle en çok tutulan balıklardan biridir.",
  "Çocukluğunda ilk balığını iskeleden çapariyle tutan herkes, o günü istavritle hatırlar.", beh="kacak")
F("kalkan", "Kalkan", "Scophthalmus maximus",
  A("flat", L=30, H=12, body="#7a6a4a", fin="#8a7a5a", pattern="spots", n=18, pcol="#3a3020", pattern2="dots", p2col="#b0a080"),
  (15, 80), (1.5, 14.0), 3, 4.0, 50, (25, 45), ["coral", "fjord"], 100, "25 yıl", "Karadeniz'in değerli balığı; av yasakları vardır", "LC",
  "Kumlu ve çakıllı dipler", "Dip balıkları, kalamar, kabuklular",
  "Yassı gövdesinin iki gözü de sol taraftadır. Derisinde küçük kemik düğmeler bulunur; kumla renk değiştirerek kamufle olur.",
  "Sinop'ta kalkan ağını çeken balıkçılar, yakaladıkları ilk büyük kalkanı limandaki kediye değil, imama hediye edermiş.", beh="dalgic")
F("barbunya", "Barbunya", "Mullus barbatus",
  A("mullet", L=30, H=6, body="#e8746a", belly="#ffe3dc", fin="#f2a07a", barbels=2, blunt=0.9),
  (5, 70), (0.05, 0.3), 1, 1.6, 30, (35, 60), MED, 30, "11 yıl", "Ege ve Akdeniz'de çok sevilen lezzet balığı", "LC",
  "Çamurlu ve kumlu dipler", "Kumda gömülü küçük canlılar",
  "Çenesinin altındaki iki bıyıkla kumu yoklar. Heyecanlandığında rengi koyu kırmızıya döner.",
  "Bodrum'da bir aşçı, barbunyayı ancak bıyıkları dimdikse taze sayarmış.", beh="sakin")
F("tekir", "Tekir", "Mullus surmuletus",
  A("mullet", L=30, H=6, body="#d96a52", belly="#ffe0d0", fin="#f0b07a", barbels=2, pattern="stripes", n=2, pcol="#f2d24a", blunt=0.9),
  (3, 60), (0.08, 0.5), 1, 1.7, 31, (35, 60), MED, 40, "10 yıl", "Kayalık kıyılarda; sarı çizgilerle barbunyadan ayrılır", "LC",
  "Kayalık ve çayırlık dipler", "Solucanlar, kabuklular",
  "Barbunyanın kuzenidir; yanlarında sarı şeritler ve ilk sırt yüzgecinde koyu çizgiler bulunur.",
  "Dalgıçlar tekirin bıyıklarıyla kumu karıştırdığını görünce, peşinden gelen küçük balıklara 'tekirin dilencileri' derlermiş.", beh="sakin")
F("sardalya", "Sardalya", "Sardina pilchardus",
  A("herring", L=28, H=4.5, body="#4c7ea6", belly="#eef3f6", pattern="dots", n=5, pcol="#26476a"),
  (1, 50), (0.03, 0.12), 0, 1.0, 16, (60, 95), ["coral"], 27, "15 yıl", "Ege'de, özellikle Gelibolu ve Ayvalık'ta ünlü", "LC",
  "Kıyı ve açık yüzey suları", "Plankton",
  "Yan tarafındaki koyu benek sırasıyla tanınır. Gece ışığa gelir; balıkçılar lamba ile avlar.",
  "Ayvalık'ta sardalya mevsimi açıldığında, rüzgar bile tuzlu ve kızarmış balık kokarmış.", beh="sakin", night=1.6)
F("uskumru", "Uskumru", "Scomber scombrus",
  A("mackerel", body="#3c7a7a", belly="#eef3f3", pattern="back", pcol="#173c40", freq=1.3, finlets="#2c5050"),
  (2, 60), (0.2, 1.4), 1, 2.2, 26, (65, 100), ["coral", "fjord"], 60, "17 yıl", "Eskiden Karadeniz'de bol; bugün azaldı", "LC",
  "Açık deniz yüzey suları", "Küçük balıklar, kabuklular",
  "Sırtındaki zebra benzeri dalgalı koyu çizgilerle tanınır. Yüzme kesesi yoktur, durmadan yüzmek zorundadır.",
  "Eski İstanbul'da 'uskumru dolması' ancak usta aşçıların işiydi; balığın derisi yırtılmadan iç pilavla doldurulurmuş.", beh="kacak")
F("kolyoz", "Kolyoz", "Scomber colias",
  A("mackerel", body="#4a7f9c", belly="#f0f4f6", pattern="back", pcol="#1f3c55", freq=0.7, pattern2="dots", p2col="#2f5570", finlets="#3c6a80"),
  (2, 60), (0.15, 1.0), 0, 2.0, 22, (65, 100), MED, 50, "13 yıl", "Ege ve Akdeniz'de bol", "LC",
  "Açık deniz kıyı suları", "Küçük balıklar, plankton",
  "Uskumruya çok benzer; karnındaki küçük koyu beneklerle ayrılır. Çapari ile kolayca avlanır.",
  "Çanakkale'de 'kolyozu uskumru diye satan, ertesi gün kayığını boş bulur' diye bir söz varmış.", beh="kacak")
F("lagos", "Lagos", "Epinephelus costae",
  A("grouper", body="#9a7a55", belly="#d9c6a6", pattern="stripes", n=4, pcol="#6a4e33"),
  (20, 100), (2.0, 15.0), 3, 4.2, 48, (30, 55), ["coral", "volcano"], 140, "20+ yıl", "Ege ve Akdeniz kayalıklarında", "DD",
  "Derin kayalık resifler", "Balık, ahtapot, kabuklular",
  "Yanlarındaki koyu boyuna şeritlerle orfozdan ayrılır. Hayatına dişi olarak başlar, büyüdükçe erkeğe dönüşür.",
  "Kaşlı bir zıpkıncı, lagosun mağarasına üç kez dalıp üçünde de balığın ona göz kırptığına yemin edermiş.", beh="dalgic")
F("sinarit", "Sinarit", "Dentex dentex",
  A("bream", L=34, H=8.5, body="#b5876a", belly="#efe0d0", fin="#d9a080", pattern="dots", n=10, pcol="#4f6fa6", teeth=1),
  (15, 110), (1.5, 12.0), 3, 4.0, 47, (40, 70), MED, 100, "36 yıl", "Ege ve Akdeniz'de değerli av balığı", "VU",
  "Kayalık ve çayırlık derin dipler", "Balık, kalamar, ahtapot",
  "Güçlü köpek dişleriyle avını yakalayan iri bir mercan türüdür. Yaşlandıkça alnı belirginleşir.",
  "Gökova'da bir balıkçı, sinaritle yarım saat boğuştuktan sonra misinayı kesip 'Bu kadar inatçıya saygı lazım' demiş.", beh="inatci")
F("fangri", "Fangri", "Pagrus pagrus",
  A("bream", body="#e07a6e", belly="#ffe5dc", fin="#f09a8a", pattern="dots", n=12, pcol="#7cb2e6"),
  (10, 90), (0.5, 6.0), 2, 3.2, 40, (40, 70), MED, 91, "20 yıl", "Tüm kıyılarımızda; kayalıklarda", "LC",
  "Kayalık ve kumlu dipler", "Kabuklular, yumuşakçalar, küçük balıklar",
  "Pembe-kırmızı gövdesinde küçük mavi benekler vardır. Mercan balıklarının en irisidir.",
  "Kaş'ta 'fangri tutan gün denize bir ekmek atılır' diye bir gelenek varmış.", beh="dalgic")
F("eskina", "Eşkina", "Sciaena umbra",
  A("perch", L=32, H=8, body="#5a4a3a", belly="#a8906a", fin="#2a2420", blunt=0.5),
  (3, 40), (0.3, 3.0), 2, 2.4, 36, (30, 50), MED, 70, "21 yıl", "Kayalık kıyılarda; av baskısı yüzünden azalıyor", "VU",
  "Kayalık mağaralar ve oyuklar", "Kabuklular, küçük balıklar",
  "Gündüz mağaralarda saklanır, gece avlanır. Yüzme kesesiyle 'gak gak' sesler çıkarabilir.",
  "Dalgıçlar eşkinanın mağarada çıkardığı sesi duyunca 'Kayalar konuşuyor' derlermiş.", beh="dalgic", night=1.8)
F("minakop", "Minakop", "Umbrina cirrosa",
  A("perch", L=34, H=7.5, body="#a89a72", belly="#ece4cc", pattern="stripes", n=6, pcol="#7a8aa6", barbels=1),
  (3, 50), (0.5, 4.5), 2, 2.6, 37, (35, 60), MED, 100, "20 yıl", "Kumsallara yakın sularda", "VU",
  "Kumlu sığ kıyılar, nehir ağızları", "Solucanlar, kabuklular",
  "Çenesinin altında tek bir kısa bıyık vardır. Yanlarında eğik dalgalı çizgiler bulunur.",
  "Kumsaldan surf olta atan balıkçıların sabrının ödülü minakoptur; 'Dalga kırılınca minakop vurur' derler.", beh="sakin")
F("iskorpit", "İskorpit", "Scorpaena porcus",
  A("scorpion", body="#8a5a3a", pcol="#4a2a1a", pcol2="#b88a5a"),
  (2, 60), (0.1, 0.8), 1, 2.0, 30, (20, 40), MED, 37, "10 yıl", "Tüm kayalık kıyılarımızda", "LC",
  "Kayalık ve yosunlu dipler", "Küçük balıklar, karides",
  "Sırt yüzgecindeki zehirli dikenleri acı veren bir sokma yapar. Çorbası çok meşhurdur.",
  "Kumkapı'da balıkçılar iskorpiti eldivenle tutar; 'Çorbası tatlı, iğnesi acı' derler.", beh="dalgic")
F("lipsoz", "Lipsoz", "Scorpaena scrofa",
  A("scorpion", L=34, H=9, body="#c0583a", pcol="#7a2a1a", pcol2="#e8a070"),
  (20, 110), (0.5, 3.0), 2, 2.8, 40, (20, 40), MED, 50, "15 yıl", "Derin kayalıklarda", "LC",
  "Derin kayalık ve çakıllı dipler", "Balık, kabuklular",
  "İskorpitin iri ve kırmızı akrabasıdır. Kamuflajı o kadar iyidir ki dalgıçlar üstüne basana kadar fark etmez.",
  "Yaşlı bir dalgıç, lipsozun 'kayanın kızarmış hali' olduğunu söylermiş.", beh="dalgic")
F("kirlangic", "Kırlangıç", "Chelidonichthys lucerna",
  A("perch", L=34, H=6, body="#d0704a", belly="#f5d8c8", pect=8, fin="#3a8ac0", blunt=0.3, dorsal_type="tri"),
  (10, 120), (0.3, 3.5), 2, 2.6, 38, (30, 55), MED, 75, "15 yıl", "Ege ve Marmara'da yaygın", "LC",
  "Kumlu ve çamurlu dipler", "Kabuklular, küçük balıklar",
  "Mavi kanat gibi göğüs yüzgeçleri vardır; ayak gibi kullandığı ışınlarla dipte 'yürür' ve horlama sesi çıkarır.",
  "Çocuklar ilk kırlangıcı görünce 'Kanatlı balık!' diye bağırır; ses çıkarınca da şaşkınlıkla oltayı bırakırmış.", beh="sakin")
F("dil", "Dil Balığı", "Solea solea",
  A("flat", L=34, H=8, body="#8a7a62", fin="#7a6a52", pattern="mottled", pcol="#5a4a3a", pcol2="#a09070", dens=0.2),
  (5, 80), (0.2, 2.5), 1, 2.2, 34, (20, 40), ["coral", "lake"], 70, "30 yıl", "Marmara ve Ege'de; lezzetli bir yassı balık", "DD",
  "Kumlu ve çamurlu dipler", "Solucanlar, küçük yumuşakçalar",
  "Uzun oval yassı bir balıktır; gündüz kuma gömülür, gece avlanır. Gözleri sağ taraftadır.",
  "Eski bir aşçı, dil balığının 'tavaya ancak iki kez dokunmasını' isterdi; üçüncüde lezzetin kaçtığını söylerdi.", beh="dalgic", night=1.7)
F("zargana", "Zargana", "Belone belone",
  A("bill", L=48, H=3.2, body="#3a7a6a", belly="#e8f0ee", snout=12, snout_col="#3a7a6a", tail="fork", dorsal=(0.75, 0.86), dorsal_h=3, anal=(0.72, 0.86), anal_h=3, ped=0.5),
  (1, 30), (0.1, 1.2), 1, 1.8, 28, (70, 105), MED, 94, "18 yıl", "Tüm kıyılarımızda; yüzeyde gezer", "LC",
  "Yüzey suları", "Küçük balıklar",
  "Gaga gibi uzun ince çeneleri vardır. Kılçıkları pişince yeşilimsi renge döner; bu yüzden bazıları yemekten çekinir.",
  "Oltaya takılan zargana suyun üstünde dans eder; çocuklar ona 'denizin kalemi' derlermiş.", beh="ziplayan")
F("kilic", "Kılıç Balığı", "Xiphias gladius",
  A("bill", L=48, H=7, body="#3d4d66", belly="#c9ced6", snout=18, snout_col="#2f3747", dorsal_h=9),
  (30, 150), (25.0, 70.0), 3, 5.2, 50, (70, 110), ["coral", "volcano"], 455, "9 yıl", "Ege ve Akdeniz'de; avı kotaya tabidir", "LC",
  "Açık okyanus, gündüz derin, gece yüzey", "Kalamar ve balıklar",
  "Yassı kılıcıyla avını yaralar. Gözlerini ve beynini ısıtan özel bir dokusu sayesinde soğuk derinliklerde keskin görür.",
  "Eski Akdeniz balıkçıları kılıç balığı avlarken şarkı söylemezmiş; balığın Rumca bildiğine inanırlarmış.", beh="ziplayan")
F("orkinos", "Mavi Yüzgeçli Orkinos", "Thunnus thynnus",
  A("tuna", body="#1f3550", belly="#e6ebf0", finlets="#ffd23f", pattern="lateral", pcol="#8fa6bf"),
  (10, 140), (30.0, 80.0), 3, 5.4, 52, (70, 110), ["coral", "fjord"], 458, "40 yıl", "Akdeniz'de; geçmişte Boğaz'da da avlanırdı", "LC",
  "Açık okyanus, göç yolları", "Uskumru, ringa, kalamar",
  "Saatte 70 km'ye kadar yüzebilir ve vücut sıcaklığını suyun üstünde tutabilen ender balıklardandır.",
  "1950'lerde İstanbul Boğazı'nda dev orkinoslar tutulurmuş; yaşlılar 'bir orkinos bir köyü doyururdu' der.", beh="dalgic")
F("akya2", "Akya (Lichia)", "Lichia amia",
  A("mackerel", L=40, H=8, body="#9aa8b0", belly="#f0f2f4", pattern="lateral", pcol="#3a4a55", fin="#5a6a75", tail="fork", peak=0.42),
  (3, 60), (2.0, 20.0), 3, 4.4, 46, (70, 105), MED, 200, "10 yıl", "Ege ve Akdeniz; sportif avcıların gözdesi", "LC",
  "Kıyıya yakın açık sular", "Kefal, istavrit, sardalya",
  "Yan çizgisi S şeklinde kıvrılır. Yemi yakaladığı anda büyük bir hızla kaçar.",
  "Akya vurduğunda makara öyle çığlık atar ki, balıkçılar sesi duyar duymaz 'Akya!' diye bağırır.", beh="kacak")
F("sariagiz", "Sarıağız", "Argyrosomus regius",
  A("perch", L=42, H=7.5, body="#9a8a6a", belly="#efe6cc", fin="#c8a05a", mouth="big", blunt=0.6),
  (5, 80), (3.0, 30.0), 3, 4.6, 46, (35, 60), MED, 200, "40 yıl", "Ege ve Akdeniz nehir ağızlarında", "LC",
  "Kumlu kıyılar ve nehir ağızları", "Balık, kalamar, karides",
  "Ağzının içi altın sarısıdır. Yüzme kesesiyle 'davul' sesi çıkararak sürüsüyle haberleşir.",
  "Dalyan bekçileri gece suyun altından gelen davul seslerini duyunca 'Sarıağız sürüsü geldi' derlermiş.", beh="inatci", night=1.5)
F("mirmir", "Mırmır", "Lithognathus mormyrus",
  A("bream", body="#c8c0a8", belly="#f2efe6", pattern="bars", n=7, bw=1, pcol="#5a5448"),
  (1, 40), (0.15, 1.0), 1, 1.8, 28, (40, 70), MED, 55, "12 yıl", "Kumsal kıyılarımızda yaygın", "LC",
  "Kumlu sığ kıyılar", "Kumdaki solucanlar ve kabuklular",
  "Gümüşi gövdesinde ince dikey çizgiler vardır. Kumu hortum gibi ağzıyla süzerek beslenir.",
  "Kumsalda çocukların ayak bileğine sürtünen merak dolu küçük balık genellikle bir mırmırdır.", beh="sakin")
F("isparoz", "İsparoz", "Diplodus annularis",
  A("bream", L=26, H=8, body="#d8d0a0", belly="#f4f0dc", fin="#e8d060", pattern="eyespot", pcol="#202020", pcol2="#202020", spot_u=0.82),
  (1, 40), (0.05, 0.25), 0, 1.3, 18, (40, 70), MED, 24, "8 yıl", "Tüm kıyılarımızda çok yaygın", "LC",
  "Deniz çayırları ve kayalık kıyılar", "Solucanlar, kabuklular",
  "Kuyruk sapındaki siyah halkayla tanınır. Yemi çok hızlı çalan bir 'yem hırsızı'dır.",
  "İskeledeki her balıkçının bir isparoz hikâyesi vardır: 'Yemimi yedi, iğneye dokunmadı!'", beh="kacak")
F("kupes", "Kupes", "Boops boops",
  A("herring", L=28, H=5, body="#a6a87a", belly="#f0f0e0", pattern="stripes", n=3, pcol="#d8c060", eye=3),
  (1, 60), (0.05, 0.3), 0, 1.2, 17, (50, 80), MED, 36, "9 yıl", "Tüm denizlerimizde bol", "LC",
  "Kıyı suları, sürüler halinde", "Plankton, algler",
  "Gövdesine göre iri gözleri vardır; Latince adı da 'öküz gözlü' anlamına gelir.",
  "Kupes sürüsü iskelenin altına girdiğinde su sarı ışıltılarla dolarmış.", beh="sakin")
F("izmarit", "İzmarit", "Spicara smaris",
  A("herring", L=26, H=4.5, body="#8a96a8", belly="#eef0f4", pattern="eyespot", pcol="#202530", pcol2="#202530", spot_u=0.45),
  (5, 80), (0.03, 0.15), 0, 1.1, 16, (45, 75), MED, 20, "8 yıl", "Ege ve Akdeniz'de", "LC",
  "Deniz çayırları", "Plankton",
  "Yanında koyu bir leke vardır. Üreme döneminde erkekler mavi-turuncu renklere bürünür.",
  "Yunan adalarında izmarit kurutup kışa saklarlar; Türk kıyılarında da eskiden böyle yapılırmış.", beh="sakin")
F("gumus", "Gümüş Balığı", "Atherina boyeri",
  A("herring", L=22, H=3.2, body="#a8c8c0", belly="#f6faf8", pattern="lateral", pcol="#e8f8ff", eye=2),
  (0, 20), (0.005, 0.02), 0, 0.9, 15, (55, 85), ["lake", "sakura", "coral"], 9, "3 yıl", "Hem denizde hem lagün ve göllerde", "LC",
  "Lagünler, göller ve kıyı suları", "Zooplankton",
  "Yanında gümüş bir şerit taşıyan, tuzlu ve tatlı suya uyum sağlayabilen minik bir balıktır.",
  "Eğirdir Gölü'nde gümüş balığı tavası, köyün düğün sofralarının baş tacıymış.", beh="sakin")
F("mezgit2", "Mezgit", "Merlangius merlangus",
  A("mackerel", L=34, H=5.5, body="#a8a088", belly="#f4f2ec", tail="square", dorsal=(0.25, 0.75), dorsal_type="round", dorsal_h=3, anal=(0.35, 0.85), pattern="lateral", pcol="#6a6455"),
  (10, 120), (0.1, 1.5), 1, 1.6, 26, (35, 60), ["coral", "fjord"], 70, "20 yıl", "Karadeniz'in kış balığı", "LC",
  "Soğuk kıyı suları, çamurlu dipler", "Karides, küçük balıklar",
  "Morina ailesindendir; üç sırt yüzgeci ve iki anal yüzgeci vardır. Eti yumuşak ve beyazdır.",
  "Karadeniz'de 'Mezgit tavası yemeyen kışı yaşamamış' derler.", beh="sakin")
F("berlam", "Berlam", "Merluccius merluccius",
  A("pike", L=44, H=5, body="#8a96a6", belly="#eef0f4", tail="square", dorsal=(0.3, 0.9), dorsal_type="round", dorsal_h=3, anal=(0.45, 0.9), anal_h=2, teeth=1, peak=0.35),
  (40, 150), (0.5, 8.0), 2, 2.8, 36, (35, 60), ["coral", "fjord"], 140, "20 yıl", "Marmara, Ege ve Akdeniz'in derin sularında", "LC",
  "Derin çamurlu dipler", "Balık ve kalamar",
  "Gündüz dipte durur, gece yüzeye yaklaşarak avlanır. Ağzının içi koyu renklidir.",
  "Marmara balıkçıları 'Berlam gece kalkar, sabah iner' der, ağlarını ona göre atarlar.", beh="dalgic", night=1.8)
F("fener", "Fener Balığı", "Lophius piscatorius",
  A("angler", body="#6b5a42", belly="#8a7a5a", lure="#ffe26b", pattern="mottled", pcol="#4a3a2a", pcol2="#8a7a5a", eye_y=0.5),
  (30, 150), (2.0, 30.0), 3, 4.0, 46, (15, 30), ["coral", "fjord", "volcano"], 200, "24 yıl", "Tüm denizlerimizin derin diplerinde", "LC",
  "Derin kumlu ve çamurlu dipler", "Pusuya düşürdüğü balıklar",
  "Başındaki olta benzeri uzantıyı sallayarak avını çeker; dev ağzı neredeyse kendi boyuna yakın balıkları yutabilir.",
  "Balıkçılar fener balığını ilk görünce korkar ama tadına bakınca 'Çirkin ama çok tatlı' derler.", beh="inatci")
F("trakonya", "Trakonya", "Trachinus draco",
  A("goby", L=34, H=5, body="#a89a72", belly="#ece4cc", pattern="stripes", n=4, pcol="#5a7ab0", dorsal=(0.15, 0.25), dorsal_h=4, dorsal_type="spiky", eye_y=0.5, tail="square"),
  (1, 60), (0.1, 1.0), 1, 1.9, 30, (30, 50), MED, 53, "15 yıl", "Kumsallarda; zehirli dikenlerine dikkat!", "LC",
  "Kumlu sığ kıyılar (kuma gömülür)", "Küçük balıklar, karides",
  "Kuma gömülü bekler; sırt ve solungaç dikenlerindeki zehir çok acı verir. Plajda basan kişinin ayağına sıcak su iyi gelir.",
  "Kumsal cankurtaranları trakonya sokmasını 'denizin arı iğnesi' diye anlatırmış.", beh="dalgic")
F("lahoz", "Lahoz", "Epinephelus aeneus",
  A("grouper", body="#8a8a7a", belly="#d8d8c8", pattern="stripes", n=3, pcol="#e8e8d8"),
  (20, 110), (2.0, 25.0), 3, 4.4, 47, (30, 55), ["coral"], 120, "20+ yıl", "Akdeniz kıyılarımızda", "NT",
  "Kumlu ve kayalık derin dipler", "Balık, kalamar, kabuklular",
  "Başının yanlarındaki açık renkli çapraz çizgilerle diğer orfozlardan ayrılır.",
  "Mersin'de bir dalgıç, lahozun kendisini mağarasının kapısında bekleyip izlediğini anlatırmış.", beh="dalgic")
F("kayabaligi", "Kaya Balığı", "Gobius niger",
  A("goby", body="#5a4a3a", belly="#a8987a", pattern="mottled", pcol="#3a2a1a", pcol2="#7a6a4a", dens=0.3),
  (0, 25), (0.01, 0.06), 0, 1.0, 15, (25, 45), ["lake", "coral"], 18, "5 yıl", "Tüm kıyılarımızda en yaygın küçük balık", "LC",
  "Taşlık sığ kıyılar", "Küçük kabuklular, solucanlar",
  "Karın yüzgeçleri birleşerek vantuz oluşturur; böylece dalgalarda kayalara tutunur.",
  "Çocukların iskeleden yakaladığı ilk balık çoğu zaman bir kaya balığıdır; ona herkes 'kaya' der geçer.", beh="sakin")
F("dulger", "Dülger Balığı", "Zeus faber",
  A("disc", L=26, H=11, body="#a8a088", belly="#d8d0b8", pattern="eyespot", pcol="#202020", pcol2="#f0e8c8", spot_u=0.45, dorsal_type="spiky", dorsal_h=8, fin="#6a6a5a"),
  (30, 150), (0.5, 3.0), 2, 2.4, 42, (20, 35), MED, 90, "12 yıl", "Ege ve Akdeniz; nadir ama değerli", "",
  "Kıyıya yakın derin sular", "Küçük balıklar",
  "İnce gövdesinin ortasında sarı halkalı siyah bir leke vardır. Önden çok ince göründüğü için avına sezdirmeden yaklaşır.",
  "Efsaneye göre o kara leke, balığı tutan bir azizin parmak iziymiş; bu yüzden ona 'Aziz Petrus balığı' da derler.", beh="sakin")
F("gelincik", "Gelincik", "Phycis phycis",
  A("mackerel", L=34, H=6, body="#7a4a3a", belly="#b89080", tail="round", dorsal=(0.3, 0.92), dorsal_type="round", dorsal_h=3, anal=(0.45, 0.92), barbels=1, pect=3),
  (20, 150), (0.3, 3.0), 2, 2.4, 36, (25, 45), MED, 65, "10 yıl", "Kayalık derin sularda", "LC",
  "Kayalık mağaralar", "Kabuklular, küçük balıklar",
  "Morina ailesindendir; gündüz mağarada saklanır, karın yüzgeçlerindeki ince ışınlarla çevresini hisseder.",
  "Gece balıkçıları 'Gelincik ay ışığında mağaradan çıkar' derler.", beh="dalgic", night=2.0)
F("mersin", "Mersin Morinası", "Huso huso",
  A("sturgeon", L=56, body="#6a7a7a", belly="#d8e0dc", pcol="#e0e8e4"),
  (20, 140), (25.0, 80.0), 4, 5.6, 58, (25, 45), ["fjord", "lake"], 800, "100+ yıl", "Karadeniz ve Kızılırmak; nesli kritik, avı yasak!", "CR",
  "Karadeniz ve büyük nehirler", "Balıklar, yumuşakçalar",
  "Dünyanın en büyük tatlısu balıklarından biridir; dinozor çağından beri neredeyse değişmeden yaşar. Havyarı yüzünden neredeyse tükenmiştir.",
  "Kızılırmak kıyısındaki köylerde, mersinin 'nehrin dedesi' olduğuna ve görenin uzun yaşayacağına inanılırmış.", beh="inatci")
F("deniz_ati", "Deniz Atı", "Hippocampus guttulatus",
  dict(shape="seahorse", body="#c8903a"),
  (1, 25), (0.01, 0.03), 3, 1.0, 50, (8, 18), ["coral", "lake"], 18, "5 yıl", "Ege, Marmara ve Akdeniz çayırlarında; korunur", "",
  "Deniz çayırları (Posidonia)", "Minik kabuklular",
  "Yavruları erkek taşır! Kuyruğuyla bitkilere tutunur, gözlerini birbirinden bağımsız oynatabilir.",
  "Balıkçılar ağdan çıkan deniz atını hemen suya geri bırakır; 'Uğur getirir, kızdırmayın' derler.", beh="sakin")
F("deniz_igne", "Deniz İğnesi", "Syngnathus acus",
  A("eel", L=56, H=2.0, body="#8a9a5a", belly="#c8d0a0", snout=5, snout_col="#8a9a5a", pattern="bars", n=12, bw=1, pcol="#5a6a3a", tail="round", wave=0, tail_size=1.5),
  (1, 30), (0.01, 0.05), 2, 1.0, 38, (10, 22), ["coral", "lake"], 50, "4 yıl", "Kıyı çayırlarında", "LC",
  "Deniz çayırları", "Minik kabuklular",
  "Deniz atının düz akrabasıdır. Çayır yaprakları arasında dik durarak kendini gizler.",
  "Ağa takılan deniz iğnesine çocuklar 'kalemtıraş balığı' derlermiş.", beh="sakin")
F("torpil", "Torpil Balığı", "Torpedo marmorata",
  A("ray", disc="round", body="#8a6a4a", pattern="mottled", pcol="#5a3a2a", pcol2="#b08a60", dens=0.25),
  (5, 100), (1.0, 12.0), 2, 3.0, 40, (20, 38), MED, 100, "15 yıl", "Kumlu kıyılarımızda", "",
  "Kumlu ve çamurlu dipler", "Dipte yaşayan balıklar",
  "Vücudundaki elektrik organlarıyla 200 volta kadar akım üretip avını sersemletir.",
  "Antik Roma hekimleri baş ağrısı için hastanın alnına canlı torpil balığı koyarmış!", beh="dalgic")
F("keman", "Keman Balığı", "Rhinobatos rhinobatos",
  A("ray", disc="guitar", body="#b09a72", pattern="dots", n=8, pcol="#7a6a4a"),
  (5, 80), (2.0, 15.0), 3, 3.6, 46, (25, 45), ["coral"], 100, "24 yıl", "Doğu Akdeniz kıyılarında; nesli tehlikede", "CR",
  "Kumlu sığ dipler", "Kabuklular, küçük balıklar",
  "Gövdesi gitara benzeyen bir vatoz türüdür; önü vatoz, arkası köpekbalığı gibidir.",
  "İskenderun'da balıkçılar keman balığını görünce 'Denizin müzisyeni' diye gülümser ve geri salarlarmış.", beh="dalgic")
F("camgoz", "Camgöz", "Galeorhinus galeus",
  A("shark", L=46, body="#7a8a96", belly="#eef1f4", eye=2, eye_col="#e0f0ff"),
  (20, 150), (5.0, 30.0), 3, 4.6, 46, (45, 75), ["coral", "fjord"], 195, "55 yıl", "Tüm denizlerimizde; azalıyor", "CR",
  "Kıta sahanlığı ve kıyı suları", "Balık ve kalamar",
  "Gözleri cam gibi parlak olduğu için bu adı almıştır. 50 yılı aşkın yaşayabilir.",
  "Eski balıkçılar camgözün gözlerine bakan kişinin geleceği görebileceğine inanırmış.", beh="kacak")
F("mahmuzlu", "Mahmuzlu Camgöz", "Squalus acanthias",
  A("shark", L=44, H=5.5, body="#6a7684", belly="#e8ecf0", pattern="dots", n=10, pcol="#e8ecf0", dorsal_type="spiky"),
  (30, 150), (2.0, 10.0), 3, 4.0, 44, (40, 70), ["fjord", "coral"], 160, "75+ yıl", "Karadeniz'de en yaygın köpekbalığı", "VU",
  "Soğuk kıyı ve açık sular", "Balık, kalamar, kabuklular",
  "Her iki sırt yüzgecinin önünde zehirli birer diken bulunur. Gebeliği iki yıla kadar sürer!",
  "Karadenizli balıkçılar ona 'köpek balığı' der; hamsi ağlarını delip geçtiğinde söylenmedik söz kalmazmış.", beh="kacak")
F("mako", "Mako Köpekbalığı", "Isurus oxyrinchus",
  A("shark", L=50, H=7, body="#3a5a8a", belly="#f0f4f8", tail="lunate", eye=2),
  (20, 150), (25.0, 75.0), 4, 5.8, 58, (80, 120), ["coral", "volcano"], 400, "30 yıl", "Akdeniz'de nadir; korunur", "EN",
  "Açık okyanus", "Orkinos, kılıç balığı, kalamar",
  "Saatte 70 km'yi aşan hızıyla dünyanın en hızlı köpekbalığıdır; oltaya takılınca sudan metrelerce sıçrayabilir.",
  "Sportif balıkçılar bir makoyla savaştıktan sonra bir hafta kollarını kaldıramadıklarını anlatır.", beh="ziplayan")
F("mavi_kopek", "Mavi Köpekbalığı", "Prionace glauca",
  A("shark", L=54, H=5.5, body="#2f6ac0", belly="#f0f6ff", pect=9, eye=2),
  (10, 150), (20.0, 60.0), 3, 5.0, 52, (50, 85), ["coral", "fjord"], 380, "20 yıl", "Ege ve Akdeniz açıklarında", "NT",
  "Açık okyanus", "Kalamar ve sürü balıkları",
  "Parlak mavi sırtı ve uzun göğüs yüzgeçleriyle okyanusları dolaşır; bir yılda binlerce kilometre göç eder.",
  "Açık denizde mavi köpekbalığı görenler 'okyanus mavisi canlandı sandım' der.", beh="kacak")
F("cekic", "Çekiçbaşlı Köpekbalığı", "Sphyrna lewini",
  A("shark", L=50, body="#6a7a6a", belly="#e8ece8", snout=0, eye=1),
  (30, 150), (25.0, 70.0), 4, 5.6, 58, (45, 80), ["coral", "volcano"], 430, "35 yıl", "Akdeniz'de çok nadir", "CR",
  "Açık deniz ve resif kenarları", "Vatozlar, kalamar, balık",
  "Çekiç biçimli başı, dipteki avlarının elektrik alanlarını algılayan bir dedektör gibi çalışır.",
  "Dalgıçlar yüzlerce çekiçbaşlının birlikte yüzdüğü 'okullar' görünce nefeslerini tutar.", beh="dalgic")

# =============================== TATLI SULAR (TR) ===============================
F("yayin", "Yayın Balığı", "Silurus glanis",
  A("catfish", body="#3f4536", belly="#b9b493", pattern="mottled", pcol="#2c3127", pcol2="#55604a", dens=0.18),
  (5, 90), (5.0, 60.0), 3, 5.0, 46, (25, 45), ["lake", "emerald"], 280, "50 yıl", "Sakarya, Kızılırmak ve barajlarda; Avrupa'nın dev balığı", "LC",
  "Büyük nehirler, göller ve barajlar", "Balık, kurbağa, hatta su kuşları",
  "Avrupa'nın en büyük tatlısu balığıdır; 2,5 metreyi geçen bireyler kaydedilmiştir. Bıyıklarıyla karanlıkta avını bulur.",
  "Baraj gölündeki balıkçılar, yayının bir ördeği yuttuğunu gördüklerinde bir daha göle ayaklarını sokmamışlar.", beh="inatci", night=2.0)
F("sudak2", "Sudak", "Sander lucioperca",
  A("perch", L=42, H=6, body="#8a9a7a", belly="#eef0e4", pattern="bars", n=6, pcol="#4a5a3a", teeth=1, eye=2, eye_col="#e8f0c0"),
  (3, 60), (1.0, 12.0), 2, 3.6, 40, (40, 70), ["lake", "emerald"], 130, "20 yıl", "Eğirdir, Beyşehir ve barajlarda yaygın", "LC",
  "Bulanık göller ve yavaş nehirler", "Küçük balıklar",
  "Gözlerindeki özel yansıtıcı tabaka sayesinde bulanık ve karanlık suda iyi görür; gün batımında avlanır.",
  "Eğirdir'de sudak avcıları 'Güneş göle değince sudak uyanır' der.", beh="kacak", night=1.6)
F("inci_kefali", "İnci Kefali", "Alburnus tarichi",
  A("herring", L=28, H=4.8, body="#9ab0b8", belly="#f4f8fa", pattern="lateral", pcol="#e8f8ff", fin="#d8a080"),
  (0, 30), (0.05, 0.25), 2, 1.4, 36, (55, 85), ["lake", "sakura"], 25, "8 yıl", "Yalnızca Van Gölü havzasında yaşar (endemik)!", "",
  "Van Gölü'nün sodalı suyu ve tatlısu derelerine göç", "Plankton",
  "Dünyada sadece Van Gölü'nde yaşar. Her bahar sodalı gölden tatlı derelere akın ederek yumurtlar; bu göç izlemeye değer bir doğa olayıdır.",
  "Van'da bahar gelince çocuklar dere kenarına koşar: 'İnci kefalleri şelaleye tırmanıyor!'", beh="ziplayan")
F("kadife", "Kadife Balığı", "Tinca tinca",
  A("carp", L=34, H=7.5, body="#4a6a2a", belly="#c8c070", fin="#3a4a20", tail="round", eye=2, eye_col="#e8603a", barbels=1),
  (1, 25), (0.3, 3.5), 1, 2.4, 30, (20, 40), ["lake", "emerald", "sakura"], 70, "20 yıl", "Göl ve barajlarımızda", "LC",
  "Bitkili, çamurlu durgun sular", "Dip canlıları, larvalar",
  "Derisi kadife gibi yumuşak ve kaygandır. Turuncu-kırmızı gözleri vardır; oksijeni az sularda bile yaşayabilir.",
  "Eski Avrupa'da kadifenin sümüksü derisinin diğer balıkları iyileştirdiğine inanılır, ona 'doktor balık' denirmiş.", beh="sakin")
F("siraz", "Siraz", "Capoeta capoeta",
  A("carp", L=34, H=6.5, body="#8a8a6a", belly="#ece8d4", pattern="dots", n=10, pcol="#4a4a3a", barbels=1, blunt=0.8),
  (1, 25), (0.2, 2.0), 1, 2.2, 27, (40, 70), ["lake", "emerald"], 50, "12 yıl", "Doğu Anadolu ve Kafkas akarsularında", "LC",
  "Hızlı akan taşlı nehirler", "Taşlardaki yosunlar",
  "Alt çenesindeki sert kenarla taşların üzerindeki yosunu kazıyarak beslenir.",
  "Kars'ta siraz tutup ateşte pişirmek, çocukların yaz tatilinin en güzel anıdır.", beh="kacak")
F("abant", "Abant Alabalığı", "Salmo abanticus",
  A("trout", body="#7a8a5a", belly="#ece8d0", pattern="spots", n=16, pcol="#d83a2a", pattern2="dots", p2col="#2a2a1a"),
  (0, 40), (0.3, 3.0), 2, 2.8, 40, (50, 80), ["lake", "emerald"], 60, "8 yıl", "Yalnızca Abant Gölü'nde yaşar (endemik)", "",
  "Soğuk ve temiz dağ gölü", "Böcek larvaları, küçük balıklar",
  "Abant Gölü'ne özgü bir alabalıktır; yanlarındaki kırmızı benekler beyaz halkalarla çevrilidir.",
  "Abant'ta yaşlı bir bekçi, gölün en büyük alabalığının 'kıyıdaki çınarın gölgesinde uyuduğunu' söylermiş.", beh="ziplayan")
F("karabalik", "Karabalık", "Clarias gariepinus",
  A("catfish", L=46, body="#3a3a36", belly="#9a9a88", barbels=3, dorsal=(0.3, 0.97), dorsal_h=3, tail="round"),
  (1, 30), (1.0, 15.0), 2, 3.6, 36, (25, 45), ["lake", "emerald", "volcano"], 170, "15 yıl", "Asi Nehri ve Amik Ovası'nda; Hatay'ın simgesi", "LC",
  "Bataklıklar, sıcak nehirler", "Her şeyi yer: balık, böcek, bitki",
  "Solungaçlarının yanında hava soluyabildiği özel bir organ vardır; kuruyan su birikintilerinde bile günlerce yaşayabilir.",
  "Hatay'da 'Karabalık ölmez, sadece çamura dalar' derler.", beh="inatci", night=1.6)

# ================================= KUZEY DENİZLERİ ===============================
F("atlantik_somon", "Atlantik Somonu", "Salmo salar",
  A("trout", L=42, body="#7890a8", belly="#f2f4f6", pattern="dots", n=14, pcol="#2a3a4a", tail="fork"),
  (0, 100), (2.0, 20.0), 3, 4.4, 46, (60, 95), ["fjord", "emerald"], 150, "13 yıl", "Türkiye'de doğal olarak yaşamaz", "",
  "Kuzey Atlantik ve nehirler", "Balık, karides",
  "Denizde büyür, doğduğu nehre kokusunu takip ederek geri dönüp şelalelere tırmanarak yumurtlar.",
  "Norveçli balıkçılar 'Somon nehrini asla unutmaz' der; bir nehre her yıl aynı somonların döndüğüne inanırlar.", beh="ziplayan")
F("arktik_alabalik", "Kutup Alabalığı", "Salvelinus alpinus",
  A("trout", body="#3a5a6a", belly="#ff8a5a", pattern="dots", n=16, pcol="#f0c0a0", fin="#e06a4a"),
  (5, 120), (0.5, 8.0), 2, 3.4, 42, (45, 75), NORTH, 107, "40 yıl", "Türkiye'de yaşamaz", "LC",
  "Buzul gölleri ve kutup denizleri", "Böcek larvaları, küçük balıklar",
  "Dünyanın en kuzeyinde yaşayan tatlısu balığıdır; üreme döneminde karnı alev turuncusuna döner.",
  "İzlanda'da buzu delip kutup alabalığı tutan bir çocuk, köyde kahraman ilan edilirmiş.", beh="kacak")
F("gronland", "Grönland Köpekbalığı", "Somniosus microcephalus",
  A("shark", L=56, H=7, body="#4a5058", belly="#7a8088", tail="shark", dorsal_h=3, pattern="mottled", pcol="#3a4048", pcol2="#5a6068", dens=0.15, eye=1, eye_col="#a0d8e0"),
  (100, 150), (60.0, 95.0), 4, 6.0, 62, (12, 22), DEEP, 640, "250–500 yıl!", "Yalnızca Kuzey Buz Denizi'nde", "VU",
  "Kuzey Buz Denizi'nin karanlık derinlikleri", "Balık, fok, leş",
  "Bilinen en uzun yaşayan omurgalıdır: bazı bireylerin 400 yaşından büyük olduğu tahmin edilir. Saatte 1 km kadar yavaş yüzer.",
  "Grönlandlı avcılar onun 'dünyanın başlangıcını görmüş balık' olduğuna inanırmış.", beh="inatci")
F("halibut", "Atlantik Halibutu", "Hippoglossus hippoglossus",
  A("flat", L=38, H=13, body="#5a5a4a", fin="#4a4a3a", pattern="mottled", pcol="#3a3a2a", pcol2="#7a7a62", dens=0.15),
  (40, 150), (15.0, 70.0), 3, 5.2, 52, (25, 45), NORTH, 470, "50 yıl", "Türkiye'de yaşamaz", "",
  "Soğuk derin dipler", "Morina, ringa, yengeç",
  "Dünyanın en büyük yassı balığıdır; 300 kilogramı geçen bireyler tutulmuştur.",
  "Norveç'te bir halibut o kadar büyükmüş ki balıkçılar onu tekneye çekmek için vinç çağırmış.", beh="dalgic")
F("mezgit_morina", "Mezgit Morinası (Haddock)", "Melanogrammus aeglefinus",
  A("mackerel", L=34, H=6, body="#5a6470", belly="#eef0f2", tail="square", dorsal=(0.22, 0.78), dorsal_type="round", pattern="lateral", pcol="#1a1a1a", pattern2="eyespot", p2col="#1a1a1a", spot_u=0.3),
  (20, 150), (0.5, 5.0), 1, 2.4, 30, (35, 60), NORTH, 112, "20 yıl", "Türkiye'de yaşamaz", "",
  "Kuzey Atlantik dipleri", "Dip omurgasızları",
  "Göğüs yüzgecinin üstündeki koyu leke 'şeytanın parmak izi' olarak bilinir. İngiliz 'fish and chips'inin klasik balığıdır.",
  "İskoç balıkçılar o lekeye 'Aziz Petrus'un başparmağı' der.", beh="sakin")
F("kurt_baligi", "Kurt Balığı", "Anarhichas lupus",
  A("eel", L=52, H=5, body="#6a7a8a", belly="#a8b0b8", pattern="bars", n=10, bw=2, pcol="#3a4a5a", teeth=1, mouth="big", wave=1, tail="round", eye=2),
  (40, 150), (2.0, 18.0), 3, 4.2, 48, (20, 35), NORTH, 150, "20 yıl", "Türkiye'de yaşamaz", "",
  "Kuzey Atlantik'in kayalık dipleri", "Midye, deniz kestanesi, yengeç",
  "Güçlü köpek dişleri ve öğütücü azı dişleriyle deniz kestanelerini kırarak yer. Kanında doğal antifriz bulunur.",
  "İzlandalı balıkçılar kurt balığının ısırığının botu delebileceği konusunda yeni gelenleri uyarırmış.", beh="inatci")
F("lompa", "Lompa Balığı", "Cyclopterus lumpus",
  A("puffer", L=26, H=10, body="#5a7a4a", belly="#c8d090", pattern="dots", n=14, pcol="#2a3a20", big=1, dorsal_h=4),
  (5, 120), (0.5, 5.0), 1, 2.0, 32, (15, 28), NORTH, 60, "13 yıl", "Türkiye'de yaşamaz", "NT",
  "Soğuk kayalık kıyılar", "Denizanası, küçük kabuklular",
  "Karnındaki vantuzla kayalara yapışır. Erkekler, yumurtaları sert dalgalarda bile haftalarca korur.",
  "Somon çiftliklerinde lompalar somonların bitlerini temizlemek için 'temizlikçi' olarak çalıştırılır.", beh="sakin")
F("capelin", "Kapelin", "Mallotus villosus",
  A("herring", L=26, H=3.8, body="#5a8a8a", belly="#f0f6f6", pattern="lateral", pcol="#a8d0d0"),
  (0, 80), (0.02, 0.06), 0, 1.0, 15, (60, 95), NORTH, 25, "6 yıl", "Türkiye'de yaşamaz", "LC",
  "Kuzey kutup denizleri", "Plankton",
  "Kuzey okyanuslarının besin zincirinin temelidir; balinalar, morinalar ve deniz kuşları onunla beslenir.",
  "Kanada'da 'kapelin dalgası' geldiğinde, milyonlarca balık yumurtlamak için kumsala vurur ve kıyı gümüş renge bürünür.", beh="sakin")
F("ringa2", "Atlantik Ringası", "Clupea harengus",
  A("herring", L=30, H=5, body="#3a6a8a", belly="#f2f6f8", pattern="lateral", pcol="#c8e0f0"),
  (0, 100), (0.1, 0.6), 0, 1.2, 18, (60, 95), NORTH, 45, "20 yıl", "Türkiye'de yaşamaz", "LC",
  "Kuzey Atlantik, büyük sürüler", "Plankton",
  "Milyarlarca bireylik sürüler oluşturur. Ringalar yüzme keselerinden hava bırakarak 'osuruk' benzeri seslerle haberleşir!",
  "Hollanda'da yılın ilk taze ringası açık artırmada bir servete satılırmış.", beh="sakin")
F("buz_baligi", "Buz Balığı", "Champsocephalus gunnari",
  A("pike", L=40, H=4.5, body="#b8d0d8", belly="#f0f8fa", fin="#a0b8c0", eye=3, dorsal=(0.2, 0.32), dorsal_h=5),
  (60, 150), (0.2, 1.5), 3, 2.4, 52, (30, 50), DEEP, 66, "15 yıl", "Yalnızca Antarktika sularında", "",
  "Antarktika'nın buz gibi suları", "Kril",
  "Kanında kırmızı kan hücresi yoktur; kanı neredeyse şeffaftır! Oksijeni doğrudan buz gibi sudan alır.",
  "Kutup araştırmacıları ilk buz balığını kestiklerinde şeffaf kanı görüp hayalet sanmışlar.", beh="sakin")
F("kurekburun", "Kürek Burunlu Mersin", "Polyodon spathula",
  A("sturgeon", L=52, body="#7a8a96", belly="#d8e0e6", snout=14, snout_thick=1, pattern="", barbels=0),
  (10, 90), (5.0, 40.0), 3, 4.6, 52, (30, 50), ["emerald", "lake"], 220, "30 yıl", "Türkiye'de yaşamaz (Mississippi)", "VU",
  "Büyük yavaş nehirler", "Plankton (ağzını açıp süzer)",
  "Kürek biçimli uzun burnu, planktonun elektrik alanlarını algılayan bir anten gibidir.",
  "Mississippi'deki balıkçılar ona 'kaşık gagalı' der; dinozorlarla aynı dönemde yaşadığını anlatırlar.", beh="dalgic")

# ================================= DERİN DENİZ ================================
F("engerek", "Engerek Balığı", "Chauliodus sloani",
  A("deep", body="#1c2230", belly="#2a3346", photophores="#7fe7ff"),
  (110, 150), (0.05, 0.3), 3, 2.6, 52, (30, 50), DEEP, 35, "15 yıl", "Akdeniz'in derinliklerinde de bulunur", "LC",
  "1000 m'ye kadar derin sular", "Küçük balıklar, karides",
  "Dişleri o kadar uzundur ki ağzını kapatamaz; dişler kafasının dışına taşar. Karnındaki ışıklarla avını çeker.",
  "Derin deniz robotunun kamerasına ilk kez bir engerek balığı yakalandığında, bilim insanları onu 'derinlerin ejderhası' diye adlandırmış.", beh="kacak", night=1.5)
F("baltabaligi", "Balta Balığı", "Argyropelecus hemigymnus",
  A("disc", L=18, H=8, body="#b0c0d0", belly="#e8f0f8", photophores="#7fffd0", eye=3, tail="fork", dorsal_h=2, anal_h=2, outline="#05070c"),
  (110, 150), (0.005, 0.02), 2, 1.0, 44, (35, 55), DEEP, 4, "2 yıl", "Akdeniz derinliklerinde", "LC",
  "Alacakaranlık bölgesi (200–600 m)", "Zooplankton",
  "Balta biçimli ayna gibi gövdesiyle görünmez olur; karnındaki ışıklar gölgesini silerek aşağıdan bakan avcılardan gizlenir.",
  "Gece ağına balta balığı takılan balıkçı, sudan gümüş bir yaprak çıktığını sanmış.", beh="sakin", night=1.5)
F("fener_derin", "Derin Deniz Fener Balığı", "Melanocetus johnsonii",
  A("angler", L=26, H=11, body="#1a1a20", belly="#2a2a30", lure="#7fffd0", outline="#000000", eye=1, eye_y=0.55),
  (120, 150), (0.05, 0.5), 3, 2.0, 54, (8, 16), DEEP, 18, "bilinmiyor", "Akdeniz'de kaydı yok", "LC",
  "Işık girmeyen abis (1000–4000 m)", "Işığa yaklaşan her canlı",
  "Başındaki ışıklı yemin ışığını içindeki bakteriler üretir. Erkekleri minicik olup dişiye yapışarak yaşar.",
  "Derin deniz belgeselini izleyen bir çocuk, 'Bu balık feneri kendi taşıyor!' diye bağırmış.", beh="inatci")
F("kocadis", "Koca Diş Balığı", "Anoplogaster cornuta",
  A("deep", L=26, H=8, body="#3a2a2a", belly="#4a3a3a", tail="fork", blunt=0.3, peak=0.3, photophores=None),
  (115, 150), (0.05, 0.2), 3, 2.2, 52, (20, 35), DEEP, 18, "bilinmiyor", "Akdeniz'de kaydı yok", "LC",
  "Abis (500–2000 m)", "Küçük balıklar, karides",
  "Vücuduna oranla dişleri okyanustaki en büyük olan balıktır; ağzını kapatabilmek için beyninin iki yanında yuvalar vardır.",
  "Bilim insanları onu ilk gördüklerinde 'öcü balığı' adını koymuş.", beh="dalgic")
F("ejderbalik", "Derin Deniz Ejder Balığı", "Stomias boa",
  A("eel", L=54, H=3.0, body="#101418", belly="#1a2028", teeth=1, mouth="big", photophores="#ff6ad5", barbels=1, wave=2, eye=2, outline="#000000"),
  (110, 150), (0.05, 0.2), 3, 2.4, 54, (30, 50), DEEP, 32, "bilinmiyor", "Akdeniz derinliklerinde bulunur", "LC",
  "Derin açık okyanus", "Küçük balıklar",
  "Siyah derisi ışığı neredeyse tamamen emer; çenesindeki bıyığın ucunda ışık saçan bir yem bulunur.",
  "Gece yarısı ağdan çıkan ışıklı bu yılanı görünce balıkçılar haç çıkarmış.", beh="kacak", night=1.6)
F("kurek_akulu", "Fırfırlı Köpekbalığı", "Chlamydoselachus anguineus",
  A("eel", L=56, H=4.2, body="#5a4a40", belly="#7a6a5a", teeth=1, mouth="big", gill_slits=6, tail="shark", wave=1.5, eye=2),
  (120, 150), (5.0, 15.0), 4, 4.2, 60, (20, 35), DEEP, 200, "bilinmiyor", "Akdeniz'de çok nadir kayıtlar", "LC",
  "Derin kıta yamaçları", "Kalamar, balık",
  "80 milyon yıldır neredeyse değişmeden yaşayan 'yaşayan fosil'dir. 300 dişi yılan gibi geriye doğru kıvrıktır.",
  "Japon balıkçılar onu deniz yılanı efsanelerinin kaynağı sayar.", beh="inatci")
F("goblin", "Goblin Köpekbalığı", "Mitsukurina owstoni",
  A("shark", L=52, H=5.5, body="#c8909a", belly="#e8c0c8", snout=6, snout_col="#c8909a", snout_dy=-2, snout_thick=1, teeth=1, dorsal_h=3, tail="whip", eye=1),
  (120, 150), (20.0, 60.0), 4, 5.2, 62, (20, 35), DEEP, 380, "bilinmiyor", "Yalnızca birkaç ülkede kaydı var", "LC",
  "Derin kıta yamaçları (250–1300 m)", "Kalamar, balık, kabuklular",
  "Pembe derili, uzun burunlu bu köpekbalığı avını yakalarken çenesini sapan gibi ileri fırlatır.",
  "Okyanus biyologları bir goblin köpekbalığı görmenin 'piyango kazanmaktan zor' olduğunu söyler.", beh="dalgic")
F("blob", "Damla Balığı", "Psychrolutes marcidus",
  A("puffer", L=26, H=9, body="#e8b8b8", belly="#f4d0d0", tail="round", blunt=0.3, dorsal_h=0, eye=1, pect=3),
  (120, 150), (0.5, 2.0), 3, 1.2, 50, (5, 12), DEEP, 30, "bilinmiyor", "Avustralya ve Yeni Zelanda derinlikleri", "",
  "Derin deniz dipleri (600–1200 m)", "Dipte sürüklenen yiyecekler",
  "Yoğunluğu sudan biraz azdır; enerji harcamadan dipte süzülür. Yüzeye çıkarıldığında basınç farkından 'eriyen' bir hale gelir.",
  "2013'te 'dünyanın en çirkin hayvanı' seçildi; o günden beri en sevilen derin deniz maskotudur.", beh="sakin")
F("varilgoz", "Fıçı Gözlü Balık", "Macropinna microstoma",
  A("deep", L=26, H=6, body="#3a3a44", belly="#5a5a64", teeth=0, mouth="normal", eye=3, eye_col="#7fffb0", eye_y=0.55, photophores=None, tail="square"),
  (115, 150), (0.05, 0.2), 4, 1.4, 60, (15, 25), DEEP, 15, "bilinmiyor", "Pasifik'te", "",
  "Derin Pasifik (600–800 m)", "Denizanası tentakülleri, plankton",
  "Başı şeffaf bir kubbedir! İçindeki yeşil tüp gözlerini yukarı ya da ileri döndürebilir.",
  "İlk videosu yayınlandığında insanlar onu uzaylı sanmıştı.", beh="sakin")
F("fener_kucuk", "Fener Balıkçığı (Lanternfish)", "Myctophum punctatum",
  A("herring", L=24, H=4, body="#3a4a5a", belly="#7a8a9a", eye=3, photophores="#9af0ff"),
  (100, 150), (0.005, 0.02), 1, 1.0, 26, (50, 80), DEEP, 11, "3 yıl", "Akdeniz derinliklerinde bol", "LC",
  "Alacakaranlık bölgesi; gece yüzeye çıkar", "Zooplankton",
  "Okyanustaki balıkların biyokütlesinin büyük kısmını oluşturur. Her gece yüzeye, her sabah derinlere göç eder.",
  "Denizaltı sonarcıları onların sürülerini 'sahte deniz dibi' sanarmış.", beh="kacak", night=2.2)
F("selakant", "Selakant", "Latimeria chalumnae",
  A("grouper", L=42, H=8, body="#3a4a6a", belly="#5a6a8a", pattern="spots", n=14, pcol="#c8d0e0", big=1, tail="round", dorsal_type="round", pect=6, mouth="normal"),
  (110, 150), (25.0, 80.0), 4, 5.4, 62, (15, 28), ["volcano"], 200, "100 yıl", "Hint Okyanusu'nda", "CR",
  "Volkanik mağaralar (150–700 m)", "Balık, kalamar",
  "66 milyon yıl önce soyunun tükendiği sanılıyordu; 1938'de canlı yakalandı. Yüzgeçleri bacak gibi kemiklidir.",
  "Güney Afrikalı müze küratörü Marjorie Courtenay-Latimer, balıkçı teknesinde ilk selakantı görünce 'Bu imkânsız!' diye haykırmış.", beh="inatci")

# ================================== TROPİKAL ===================================
F("yelken", "Yelken Balığı", "Istiophorus platypterus",
  A("bill", body="#264d8c", belly="#e0e6ef", pattern="bars", n=9, bw=1, pcol="#7fb0ff", snout=12, dorsal=(0.08, 0.62), dorsal_h=15, dorsal_type="sail", fin="#28467a"),
  (5, 120), (20.0, 60.0), 4, 5.6, 58, (90, 130), TROP, 340, "13 yıl", "Akdeniz'e nadiren Süveyş'ten girer", "LC",
  "Tropikal açık okyanus", "Sardalya, uskumru, kalamar",
  "Okyanusun en hızlı balıklarındandır. Dev yelken yüzgecini açarak sürüleri sıkıştırır, kılıcıyla vurarak avlar.",
  "Kostarika'da bir kaptan, yelken balığı yelkenini açınca 'okyanus mavi bayrak açtı' dermiş.", beh="ziplayan")
F("marlin", "Mavi Marlin", "Makaira nigricans",
  A("bill", L=50, H=8, body="#1c3a6a", belly="#e8eef6", pattern="bars", n=10, bw=1, pcol="#6aa0e0", snout=16, dorsal_h=11),
  (20, 150), (40.0, 90.0), 4, 6.0, 62, (90, 130), ["coral", "volcano"], 500, "27 yıl", "Türkiye'de yaşamaz", "VU",
  "Tropikal ve ılık açık okyanus", "Orkinos, uskumru, kalamar",
  "Dişileri 800 kilogramı geçebilir. Avlanırken vücudu parlak mavi çizgilerle 'yanıp söner'.",
  "Hemingway'in 'Yaşlı Adam ve Deniz' romanındaki Santiago'nun üç gün boğuştuğu dev balık bir marlindir.", beh="ziplayan")
F("lambuka", "Lambuka (Mahi-mahi)", "Coryphaena hippurus",
  A("mackerel", L=42, H=8, body="#3aa860", belly="#f2e04a", pattern="dots", n=12, pcol="#1a5aa0", blunt=0.2, peak=0.15, dorsal=(0.05, 0.85), dorsal_h=4, dorsal_type="round", fin="#2a7ad0", pattern2="gradient", p2col="#f2d04a"),
  (0, 60), (2.0, 20.0), 3, 4.4, 46, (80, 115), ["coral"], 210, "5 yıl", "Akdeniz'de sonbaharda görülür", "LC",
  "Yüzer nesnelerin altında, açık deniz", "Uçan balık, kalamar",
  "Yeşil-altın-mavi rengiyle denizin en renkli balıklarındandır; sudan çıkınca renkleri hızla solar.",
  "Maltalı balıkçılar lambuka için denize hurma yaprağı salar; balıklar gölgesine toplanır.", beh="ziplayan")
F("sarikanat_orkinos", "Sarı Yüzgeçli Orkinos", "Thunnus albacares",
  A("tuna", body="#1c3a6a", belly="#e8eef4", finlets="#ffe03a", pattern="stripes", n=1, pcol="#f2d03a", dorsal_h=10, anal_h=8, fin="#f2d03a"),
  (5, 140), (15.0, 65.0), 3, 5.2, 52, (80, 120), ["coral", "volcano"], 239, "8 yıl", "Türkiye'de yaşamaz", "LC",
  "Tropikal açık okyanus", "Balık, kalamar, kabuklular",
  "Uzun, orak biçimli sarı yüzgeçleriyle tanınır. Yunuslarla birlikte avlandığı sık görülür.",
  "Hawaii'de ona 'ahi' denir; 'ateş' anlamına gelen bu ad, oltayı çekerken makaranın ısınmasından gelir.", beh="kacak")
F("balina_kopek", "Balina Köpekbalığı", "Rhincodon typus",
  A("shark", L=58, H=8, body="#3a5070", belly="#e0e6ee", pattern="dots", n=40, pcol="#f0f4f8", pattern2="lateral", p2col="#8aa0b8", blunt=0.2, peak=0.3, mouth="big", eye=1, gill_slits=5),
  (5, 120), (70.0, 95.0), 4, 5.8, 60, (18, 30), TROP, 1800, "80–130 yıl", "Türkiye'de yaşamaz", "EN",
  "Tropikal okyanuslar", "Plankton ve küçük balıklar (süzerek)",
  "Dünyanın en büyük balığıdır; boyu 18 metreye ulaşabilir. Dev olmasına rağmen yalnızca plankton yer ve insanlara zararsızdır.",
  "Filipinler'de balıkçılar ona 'butanding' der ve onu görmeyi uğurlu sayar.", beh="inatci")
F("mandarin", "Mandarin Balığı", "Synchiropus splendidus",
  A("goby", L=24, H=5.5, body="#2a6ad0", belly="#3a8ae0", pattern="patches", n=7, pcol="#ff8a2a", pcol2="#2ad0c0", fin="#ff6a2a", dorsal_h=4),
  (1, 20), (0.005, 0.02), 3, 1.0, 54, (8, 18), TROP, 7, "15 yıl", "Pasifik resiflerinde", "LC",
  "Mercan resiflerinin kumlu molozları", "Minik kabuklular",
  "Mavi rengini pigmentten değil hücrelerinden alan nadir hayvanlardandır. Gün batımında çiftler halinde dans eder.",
  "Dalgıçlar gün batımında mandarin dansını izlemek için saatlerce resifte bekler.", beh="sakin")
F("discus", "Diskus", "Symphysodon aequifasciatus",
  A("disc", L=22, H=12, body="#c85a2a", belly="#e0a070", pattern="stripes", n=8, pcol="#3aa0d0", pcol2="#3aa0d0", fin="#d06a3a"),
  (1, 25), (0.1, 0.5), 2, 1.4, 42, (15, 30), ["emerald", "sakura"], 20, "15 yıl", "Amazon havzasında", "LC",
  "Amazon'un sakin kolları", "Larvalar, küçük kabuklular",
  "Yavrular ilk haftalarında ebeveynlerinin derisinden salgılanan 'sütle' beslenir!",
  "Akvaryumcular diskusa 'akvaryumların kralı' der.", beh="sakin")
F("melek", "Melek Balığı (Skalar)", "Pterophyllum scalare",
  A("disc", L=20, H=10, body="#d8d0b0", belly="#f0ece0", pattern="bars", n=3, bw=2, pcol="#2a2a2a", dorsal_h=14, dorsal_type="trail", anal_h=14, anal_type="trail"),
  (1, 25), (0.02, 0.1), 1, 1.2, 30, (15, 30), ["emerald", "sakura"], 15, "10 yıl", "Amazon havzasında", "LC",
  "Bitkili yavaş akan nehirler", "Küçük böcekler ve larvalar",
  "Uzun yüzgeçleriyle bitkiler arasında gizlenir. Eşler yumurtalarını yaprak üzerine yapıştırıp birlikte korur.",
  "Bir akvaryumcu, melek balığının sabah kendisini cama gelip 'selamladığına' yemin edermiş.", beh="sakin")
F("beta", "Beta (Siyam Savaşçısı)", "Betta splendens",
  A("perch", L=24, H=5, body="#c02a4a", belly="#e04a6a", fin="#8a2ad0", dorsal_h=6, dorsal_type="round", anal_h=7, tail="round", tail_size=1.8, dorsal=(0.4, 0.8), anal=(0.3, 0.9)),
  (0, 15), (0.003, 0.01), 2, 1.0, 40, (15, 30), ["sakura", "emerald"], 7, "3 yıl", "Tayland çeltik tarlalarında", "VU",
  "Sığ çeltik tarlaları ve bataklıklar", "Böcek larvaları",
  "Labirent organıyla havadan oksijen alır. Erkekler köpükten yuva yapar ve birbirleriyle kavga ederler.",
  "Tayland'da eskiden beta dövüşleri köy meydanlarında izlenirmiş; bugün renkleri için sevilir.", beh="kacak")
F("neon", "Neon Tetra", "Paracheirodon innesi",
  A("herring", L=20, H=3.6, body="#2a3a5a", belly="#c03a3a", pattern="stripes", n=1, pcol="#4af0ff", eye=2),
  (0, 15), (0.001, 0.003), 1, 0.9, 26, (40, 70), ["emerald", "sakura"], 4, "5 yıl", "Amazon kaynak sularında", "LC",
  "Karanlık, çay renkli orman dereleri", "Mikro plankton",
  "Parlak mavi şeridi ışığı yansıtarak karanlık sularda sürüyü bir arada tutar.",
  "Bir akvaryumdaki yüz neon tetra, odayı ışıl ışıl bir şehre çevirir.", beh="kacak")
F("tas_baligi", "Taş Balığı", "Synanceia verrucosa",
  A("scorpion", L=28, H=9, body="#7a6a5a", pcol="#5a4a3a", pcol2="#a8806a", dens=0.4, dorsal_h=3, blunt=0.3, eye=1, eye_y=0.6),
  (1, 30), (0.3, 2.0), 3, 2.0, 52, (5, 12), TROP, 40, "10 yıl", "Kızıldeniz'den Doğu Akdeniz'e yayılma riski var", "LC",
  "Resiflerdeki kayalar arasında", "Pusuya düşürdüğü balıklar",
  "Dünyanın en zehirli balığıdır; taşla ayırt edilemeyecek kadar iyi kamufle olur. Sırt dikenlerinin zehri öldürücü olabilir.",
  "Avustralya plajlarında 'taşa basmadan önce iki kez bak' tabelaları onun yüzündendir.", beh="dalgic")
F("kurbagabaligi", "Kurbağa Balığı", "Antennarius maculatus",
  A("angler", L=24, H=10, body="#f0c040", belly="#f8e080", lure="#ff6a6a", pattern="spots", n=10, pcol="#c06a2a", eye=1),
  (1, 30), (0.05, 0.3), 3, 1.2, 50, (5, 12), TROP, 15, "bilinmiyor", "Hint-Pasifik resiflerinde", "LC",
  "Mercan ve sünger arası", "Küçük balıklar",
  "Göğüs yüzgeçleriyle dipte yürür; ağzını açarak avını 6 milisaniyede yutar, bu bilinen en hızlı av hareketlerindendir.",
  "Dalgıçlar onu sünger sanıp yanından geçer; ancak 'süngerin' göz kırptığını fark edince durur.", beh="inatci")
F("goliath", "Dev Orfoz (Goliath)", "Epinephelus itajara",
  A("grouper", L=46, H=11, body="#6a6a4a", belly="#a8a07a", pattern="spots", n=20, pcol="#3a3a2a"),
  (10, 80), (40.0, 90.0), 4, 5.6, 58, (15, 30), TROP, 250, "37+ yıl", "Türkiye'de yaşamaz (Atlantik)", "VU",
  "Batıklar ve mangrovlar", "Istakoz, vatoz, kaplumbağa",
  "360 kiloya ulaşabilen bu dev orfoz, tehdit edildiğinde yüzme kesesiyle gök gürültüsüne benzer bir ses çıkarır.",
  "Florida dalgıçları batıklarda dev orfozun kendilerini 'büyükanne gibi' süzdüğünü anlatır.", beh="inatci")
F("snook", "Snook Balığı", "Centropomus undecimalis",
  A("pike", L=42, H=5.5, body="#a8b0a0", belly="#f0f2ec", pattern="lateral", pcol="#1a1a1a", dorsal=(0.3, 0.42), dorsal_h=5),
  (0, 40), (1.0, 15.0), 2, 3.6, 40, (50, 80), ["coral", "emerald"], 140, "20 yıl", "Türkiye'de yaşamaz", "LC",
  "Mangrovlar ve nehir ağızları", "Balık, karides",
  "Yan çizgisi siyah bir şerit gibi belirgindir. Su ısısı düşerse hemen tatlı su kaynaklarına sığınır.",
  "Florida'da gece köprülerin ışıkları altında snook avlamak bir gelenektir.", beh="kacak", night=1.5)

# ================================ EGZOTİK NEHİRLER ==============================
F("arapaima", "Arapaima", "Arapaima gigas",
  A("pike", L=56, H=6.5, body="#5a6a5a", belly="#c84a3a", pattern="gradient", pcol="#c03a2a", dorsal=(0.72, 0.88), anal=(0.72, 0.88), anal_h=4, dorsal_h=4, tail="round", teeth=0),
  (0, 40), (40.0, 90.0), 4, 5.6, 58, (25, 45), EXOTIC, 300, "20 yıl", "Amazon'da", "DD",
  "Amazon taşkın ormanları", "Balık, bazen kuşlar",
  "Dünyanın en büyük tatlısu balıklarındandır; havadan soluk alması için birkaç dakikada bir yüzeye çıkmak zorundadır. Pulları piranha dişine karşı zırh gibidir.",
  "Amazon köylerinde arapaimanın soluk alırken çıkardığı 'hıh' sesini duyan avcı, zıpkınını hazırlar.", beh="ziplayan")
F("arowana", "Gümüş Arowana", "Osteoglossum bicirrhosum",
  A("pike", L=50, H=5.5, body="#c0c8c8", belly="#f2f4f4", pattern="dots", n=30, pcol="#e8f0f0", barbels=1, dorsal=(0.55, 0.95), anal=(0.5, 0.95), dorsal_h=3, anal_h=4, tail="point"),
  (0, 25), (1.0, 6.0), 3, 3.4, 48, (40, 70), EXOTIC, 120, "15 yıl", "Amazon'da", "",
  "Taşkın ormanları, yüzey", "Böcekler, kuşlar, küçük balıklar",
  "Sudan bir metre yükseğe zıplayarak dallardaki böcekleri ve hatta kuşları yakalar; bu yüzden 'su maymunu' diye de bilinir.",
  "Asya'da akrabası olan arowananın evlere şans ve zenginlik getirdiğine inanılır.", beh="ziplayan")
F("oskar", "Oskar", "Astronotus ocellatus",
  A("bream", L=30, H=9, body="#3a3a2a", belly="#5a4a2a", pattern="patches", n=5, pcol="#ff7a2a", pcol2="#ff9a3a", pattern2="eyespot", p2col="#ff7a2a", spot_u=0.92, tail="round"),
  (0, 25), (0.5, 1.6), 2, 2.4, 38, (25, 45), EXOTIC, 45, "20 yıl", "Amazon'da", "",
  "Yavaş akan nehirler", "Balık, kerevit, böcek",
  "Kuyruğundaki göz benzeri leke yırtıcıları şaşırtır. Akvaryumda sahibini tanıyıp el sallamasına tepki verdiği bilinir.",
  "Bir akvaryumcu, oskarının hayal kırıklığına uğrayınca taşlarını tek tek yerinden oynattığını anlatırmış.", beh="inatci")
F("kaplan_baligi", "Kaplan Balığı", "Hydrocynus vittatus",
  A("mackerel", L=40, H=7, body="#b8c0c0", belly="#f2f4f4", pattern="stripes", n=4, pcol="#2a2a2a", fin="#e04a2a", teeth=1, mouth="big"),
  (0, 40), (2.0, 15.0), 3, 4.6, 50, (70, 105), EXOTIC, 105, "10 yıl", "Afrika nehirlerinde", "LC",
  "Afrika'nın büyük nehirleri ve gölleri", "Balık; uçan kırlangıçları bile yakalar",
  "Kırmızı yüzgeçleri ve dışarı taşan keskin dişleriyle Afrika'nın en korkulan tatlısu avcısıdır; havadaki kırlangıçları zıplayarak yakaladığı görüntülenmiştir.",
  "Zambezi'deki avcılar 'Kaplan balığını tuttuysan dişini kolye yap' derler.", beh="ziplayan")
F("payara", "Vampir Balığı (Payara)", "Hydrolycus scomberoides",
  A("mackerel", L=42, H=6.5, body="#b8c4c8", belly="#eef2f4", teeth=1, mouth="big", fin="#7a8a90", tail="fork", pattern="eyespot", pcol="#202020", pcol2="#202020", spot_u=0.2),
  (0, 40), (1.0, 12.0), 3, 4.4, 50, (60, 95), EXOTIC, 117, "bilinmiyor", "Amazon ve Orinoko'da", "",
  "Hızlı akan nehir bölümleri", "Diğer balıklar (piranha bile)",
  "Alt çenesindeki 15 cm'ye varan iki köpek dişi, üst çenesindeki deliklere yerleşir. Piranhaları bile avlar.",
  "Venezuela'da şelale altında payara avlamak, en cesur balıkçıların işidir.", beh="ziplayan")
F("pavus", "Tavus Levreği", "Cichla ocellaris",
  A("perch", L=40, H=7.5, body="#c8b040", belly="#f0e8c0", pattern="bars", n=3, bw=3, pcol="#2a2a1a", pattern2="eyespot", p2col="#e04a2a", spot_u=0.92, fin="#e05a2a"),
  (0, 30), (1.0, 8.0), 3, 4.2, 46, (55, 90), EXOTIC, 75, "10 yıl", "Amazon'da", "",
  "Sıcak tropikal nehirler", "Balık",
  "Kuyruğundaki göz lekesi tavus kuşunu andırır. Yeme saldırışı sportif balıkçılar arasında efsanedir.",
  "Brezilyalı rehberler 'Tavus vurunca kalbin değil, makaran durur' der.", beh="kacak")
F("yilanbas", "Yılanbaş Balığı", "Channa argus",
  A("pike", L=46, H=5, body="#6a6a4a", belly="#c8c0a0", pattern="patches", n=8, pcol="#2a2a1a", pcol2="#3a3a2a", dorsal=(0.3, 0.95), dorsal_h=3, anal=(0.5, 0.95), anal_h=3, tail="round", blunt=0.5),
  (0, 25), (1.0, 8.0), 3, 4.0, 44, (35, 60), EXOTIC, 85, "8 yıl", "Doğu Asya'da; istilacı tür", "LC",
  "Bataklık ve bitkili sular", "Balık, kurbağa, kerevit",
  "Başı yılana benzer; hava solur ve karada kısa mesafe sürünebilir. Birçok ülkede istilacı olarak yasaklıdır.",
  "Amerika'da bir yılanbaş bir gölden diğerine sürünerek geçince haberlere çıkmış.", beh="inatci")
F("akciger", "Akciğerli Balık", "Protopterus annectens",
  A("eel", L=50, H=4.2, body="#6a5a4a", belly="#a89a7a", pattern="spots", n=16, pcol="#3a2a1a", pect=0, tail="point", wave=1.5, eye=1),
  (0, 15), (1.0, 5.0), 3, 3.4, 48, (15, 28), EXOTIC, 100, "20+ yıl", "Batı Afrika'da", "LC",
  "Kuruyan bataklıklar", "Salyangoz, balık, bitkiler",
  "Akciğerleriyle hava solur. Bataklık kuruyunca çamurda kendine bir koza örer ve yağmuru beklerken yıllarca uyuyabilir.",
  "Afrikalı çiftçiler, tarlayı sürerken kurumuş çamurdan canlı balık çıktığını görünce şaşkınlıkla kaçarmış.", beh="inatci")
F("bisir", "Bişir (Ejder Balığı)", "Polypterus senegalus",
  A("eel", L=46, H=3.8, body="#7a7a5a", belly="#c8c8a0", dorsal=(0.3, 0.95), dorsal_h=3, dorsal_type="spiky", pect=4, tail="round", wave=1, eye=2),
  (0, 15), (0.1, 0.5), 2, 2.0, 40, (20, 35), EXOTIC, 50, "15 yıl", "Afrika'da", "LC",
  "Bitkili sığ nehirler", "Larvalar, küçük balıklar",
  "Sırtında küçük yelken yüzgeçleri dizisi vardır; ejderha gibi görünür. 360 milyon yıllık bir soydan gelir.",
  "Akvaryumcular ona 'mini dinozor' der.", beh="dalgic")
F("timsah_gar", "Timsah Turnası", "Atractosteus spatula",
  A("gar", L=56, H=5.5, body="#5a6a4a", belly="#c8c8a0", snout=10, pcol="#3a4a2a", n=20),
  (0, 40), (30.0, 85.0), 4, 5.4, 58, (25, 45), EXOTIC, 300, "50+ yıl", "Kuzey Amerika'da", "LC",
  "Büyük yavaş nehirler ve bataklıklar", "Balık, su kuşları",
  "Timsah benzeri geniş burnu ve iki sıra dişiyle 100 milyon yıldır yaşar. Yumurtaları zehirlidir.",
  "Louisiana'da dev bir timsah turnasının tekneye 'merhaba' der gibi burnunu dayadığı anlatılır.", beh="inatci")
F("elektrik", "Elektrikli Yılan Balığı", "Electrophorus electricus",
  A("eel", L=58, H=4.0, body="#3a3a30", belly="#c87a3a", anal=(0.2, 0.98), anal_h=2, dorsal_h=0, pect=2, tail="point", wave=2, eye=1),
  (0, 25), (5.0, 20.0), 4, 4.8, 60, (15, 30), EXOTIC, 250, "15 yıl", "Amazon'da", "LC",
  "Çamurlu, oksijensiz Amazon suları", "Balık, kurbağa",
  "Aslında bir yılan balığı değil, bıçak balığı akrabasıdır. 800 volta varan elektrik şoku üretebilir!",
  "Alexander von Humboldt, 1800'de Venezuela'da elektrikli yılan balıklarının atları bile sersemlettiğini yazmıştı.", beh="dalgic")
F("pirana_siyah", "Kara Piranha", "Serrasalmus rhombeus",
  A("bream", L=28, H=10, body="#4a5058", belly="#8a9098", eye=2, eye_col="#e02a2a", teeth=1, mouth="big", tail="square", fin="#2a2a30"),
  (0, 25), (0.5, 3.0), 2, 3.0, 40, (40, 70), EXOTIC, 45, "10 yıl", "Amazon'da", "",
  "Amazon nehirleri", "Balık, meyve, leş",
  "Kırmızı gözlü bu piranha, akrabalarına göre daha yalnız ve güçlü ısırıklıdır; vücuduna oranla ısırma gücü en yüksek balıklardandır.",
  "Amazonlu çocuklar, piranhanın yalnızca kan kokusu alınca saldırdığını bilir ve nehirde rahatça yüzer.", beh="kacak")

# ============================== ÇİÇEK / ORMAN GÖLLERİ ============================
F("koi_sanke", "Sanke Koi", "Cyprinus rubrofuscus 'Sanke'",
  A("carp", body="#f4f2ee", belly="#fbfaf8", pattern="patches", n=6, pcol="#e03a2a", pcol2="#1a1a1a", barbels=1),
  (0, 20), (1.0, 8.0), 2, 2.6, 44, (20, 40), ["sakura"], 90, "50+ yıl", "Süs havuzlarında", "",
  "Bahçe havuzları", "Bitki, böcek, yem",
  "Beyaz zemin üzerinde kırmızı ve siyah lekeleri olan klasik bir koi çeşididir. Japonya'da sanat eseri gibi değerlendirilir.",
  "Japonya'da 226 yıl yaşadığı söylenen 'Hanako' adlı bir koi efsanesi vardır.", beh="sakin")
F("koi_ogon", "Ogon Koi", "Cyprinus rubrofuscus 'Ogon'",
  A("carp", body="#f2c43a", belly="#fae08a", pattern="gradient", pcol="#ffe680", barbels=1),
  (0, 20), (1.0, 8.0), 3, 2.6, 52, (20, 40), ["sakura"], 90, "50+ yıl", "Süs havuzlarında", "",
  "Bahçe havuzları", "Bitki, böcek, yem",
  "Tek renk metalik altın parıltısıyla 'zenginlik balığı' olarak bilinir.",
  "Bir çay bahçesinin sahibi, ogon koisinin her sabah havuzun kenarına gelip güneşi selamladığını anlatır.", beh="sakin")
F("japon_medaka", "Medaka", "Oryzias latipes",
  A("herring", L=20, H=3.6, body="#e8b060", belly="#f8e8c0", eye=3, dorsal=(0.7, 0.82)),
  (0, 10), (0.001, 0.003), 0, 0.9, 15, (35, 60), ["sakura"], 4, "2 yıl", "Doğu Asya'da", "LC",
  "Pirinç tarlaları", "Böcek larvaları",
  "Uzaya gönderilip yörüngede yumurtlayan ilk omurgalılardandır (1994)!",
  "Japon çocukları medaka'yı kavanozda büyütür; 'Pirinç tarlasının küçük balığı' diye şarkısı vardır.", beh="sakin")
F("altin_orf", "Altın Orf", "Leuciscus idus",
  A("carp", L=34, H=6.5, body="#f0903a", belly="#fae0b0", fin="#f07a2a"),
  (0, 25), (0.3, 3.0), 1, 2.2, 32, (40, 70), ["sakura", "emerald", "lake"], 80, "20 yıl", "Kuzey Anadolu nehirlerinde yabani formu var", "LC",
  "Büyük nehirler, göller ve havuzlar", "Böcekler, salyangoz",
  "Turuncu formu süs havuzlarında sevilir; sürü halinde yüzeye yakın yüzer.",
  "Avrupa'da saray havuzlarına altın orf koyulur, misafirler ekmek atarak onları çağırırmış.", beh="sakin")
F("dere_alabalik", "Dere Alabalığı", "Salmo trutta fario",
  A("trout", body="#8a7a4a", belly="#f0e0b0", pattern="spots", n=18, pcol="#c02a2a", pattern2="dots", p2col="#2a1a10"),
  (0, 25), (0.1, 2.5), 2, 2.8, 38, (50, 80), ["emerald", "lake"], 80, "10 yıl", "Doğu Karadeniz ve Toroslar'ın soğuk derelerinde", "LC",
  "Soğuk, berrak, oksijenli dereler", "Böcekler, larvalar",
  "Kırmızı beneklerle süslenmiş, temiz suyun göstergesi sayılan bir balıktır. Sinekle avı çok zevklidir.",
  "Rize'de bir dede, derenin en büyük alabalığını 'Paşa' diye çağırır, yakalasa bile geri salarmış.", beh="ziplayan")
F("gokkusagi_ciklit", "Mavi Çiklit (Malawi)", "Maylandia zebra",
  A("bream", L=26, H=7.5, body="#3a7ae0", belly="#8ab8f0", pattern="bars", n=6, bw=2, pcol="#1a2a6a", tail="round"),
  (0, 25), (0.01, 0.05), 1, 1.4, 28, (30, 55), ["emerald", "sakura"], 12, "10 yıl", "Afrika'da Malawi Gölü'nde", "LC",
  "Kayalık göl kıyıları", "Kayalardaki algler",
  "Dişiler yumurtaları ve yavruları ağızlarında taşır; tehlikede yavrular annenin ağzına saklanır.",
  "Malawi'de gölde şnorkelle yüzenler, kayaların renkli çiklitlerle 'canlı mozaiğe' döndüğünü anlatır.", beh="kacak")

# ============================== VOLKANİK / EFSANEVİ ==============================
F("opah", "Opah", "Lampris guttatus",
  A("disc", L=30, H=13, body="#c04a5a", belly="#d07080", pattern="dots", n=26, pcol="#f0f0f0", fin="#e02a2a", tail="lunate"),
  (60, 150), (20.0, 60.0), 4, 5.0, 58, (35, 60), ["volcano", "coral"], 200, "bilinmiyor", "Akdeniz'de nadir kayıt", "LC",
  "Açık okyanus derinlikleri", "Kalamar, kril, balık",
  "Tüm vücudunu ısıtabilen bilinen tek sıcakkanlı balıktır! Yüzgeçlerini kuş kanadı gibi çırparak yüzer.",
  "Hawaii'li balıkçılar opahı 'uğur balığı' sayar ve onu satmak yerine iyi niyet hediyesi olarak verirmiş.", beh="dalgic")
F("kirmizi_snapper", "Kırmızı Snapper", "Lutjanus campechanus",
  A("bream", L=34, H=9, body="#e04a3a", belly="#f8b0a0", eye=2, eye_col="#ff3a2a"),
  (20, 120), (1.0, 12.0), 2, 3.4, 42, (35, 60), ["volcano", "coral"], 100, "57 yıl", "Türkiye'de yaşamaz", "VU",
  "Resif ve batıklar", "Balık, karides, kalamar",
  "Kırmızı gözleri ve gövdesiyle tanınır. 50 yılı aşkın yaşayabilir.",
  "Meksika Körfezi'nde dedeler torunlarına 'Kızıl lahozu tutan hafta boyunca şanslı olur' der.", beh="dalgic")
F("okyanus_levregi", "Okyanus Kızıl Levreği", "Sebastes norvegicus",
  A("scorpion", L=34, H=8, body="#e05a2a", pcol="#c03a1a", pcol2="#f08a5a", dens=0.15, eye=3),
  (80, 150), (0.5, 6.0), 2, 3.0, 42, (20, 40), DEEP, 100, "75 yıl", "Türkiye'de yaşamaz", "",
  "Kuzey Atlantik derinlikleri", "Kril, balık",
  "Yavrularını canlı doğurur. Soğuk derinliklerde yavaş büyür; bu yüzden aşırı avlanmaya karşı çok hassastır.",
  "Norveçli balıkçılar 'Kaya balığı, dedenin dedesi kadar yaşlı olabilir' der.", beh="dalgic")
F("dev_gobi", "Dev Kaya Gobisi", "Gobius cobitis",
  A("goby", body="#6a3a2a", belly="#c88a5a", pattern="dots", n=14, pcol="#ffb03a", dens=0.2),
  (5, 60), (0.05, 0.3), 1, 1.4, 30, (20, 40), ["volcano", "coral"], 27, "10 yıl", "Ege ve Akdeniz kıyılarında", "LC",
  "Gelgit havuzları ve kayalık kıyılar", "Algler, küçük kabuklular",
  "Kayalık gelgit havuzlarının en iri gobisidir; ısınan sığ havuzlara dayanıklıdır.",
  "Santorini kıyılarında çocuklar volkanik taşların arasında bu gobileri saklambaç oynar gibi kovalar.", beh="sakin")
F("kral_uskumru", "Kral Uskumru", "Scomberomorus cavalla",
  A("mackerel", L=46, H=6, body="#5a7a9a", belly="#eef2f6", pattern="lateral", pcol="#2a3a4a", teeth=1, finlets="#a0b0c0"),
  (5, 120), (5.0, 35.0), 3, 4.6, 48, (85, 120), ["volcano", "coral"], 184, "14 yıl", "Türkiye'de yaşamaz", "LC",
  "Kıyıya yakın tropikal sular", "Balık, kalamar",
  "Yemi yakalarken sudan metrelerce havaya sıçrayan bu balığa 'smoker' denir; makarayı dumanlandıracak kadar hızlı kaçar.",
  "Florida'daki turnuvalarda en büyük kral uskumruyu tutan kaptan 'yılın kralı' ilan edilir.", beh="ziplayan")
F("doktor", "Doktor Balığı", "Garra rufa",
  A("goby", L=26, H=4.5, body="#7a7a6a", belly="#d8d4c0", pattern="lateral", pcol="#4a4a3a", eye_y=0.3, barbels=1),
  (0, 30), (0.005, 0.03), 1, 1.0, 26, (35, 60), ["volcano", "lake"], 14, "5 yıl", "Sivas Kangal Balıklı Kaplıcası'nda ünlüdür", "LC",
  "Sıcak kaplıca suları ve Dicle-Fırat havzası dereleri", "Algler ve ölü deri hücreleri",
  "Kangal'daki 35 °C'lik kaplıca suyunda yaşar; suya giren insanların ölü derisini kemirerek 'balık terapisi' yapar.",
  "Kangal'da bir çoban, kuzusunu yıkarken balıkların ayağını gıdıkladığını fark etmiş; kaplıcanın ünü böyle başlamış derler.", beh="sakin")
F("kizil_aslan", "Beyaz Yüzgeçli Aslan Balığı", "Pterois radiata",
  A("scorpion", L=28, H=8, body="#a8302a", pattern="bars", n=7, bw=1, pcol="#f8f0e8", pect=9, dorsal_h=10, fin="#e8d0c0", dens=0.0),
  (5, 80), (0.2, 1.0), 3, 2.4, 52, (15, 30), ["volcano", "coral"], 24, "15 yıl", "Kızıldeniz'de; akrabası Akdeniz'e yerleşti", "LC",
  "Resif mağaraları", "Karides, küçük balıklar",
  "Uzun beyaz yelpaze yüzgeçleriyle avını köşeye sıkıştırır. Dikenlerindeki zehir çok acı verir.",
  "Akdeniz'e Süveyş'ten giren aslan balıkları için Kaş'ta 'aslan balığı yeme festivali' düzenlenir.", beh="dalgic")

if __name__ == "__main__":
    print(len(S), "tür")
