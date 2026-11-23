# -*- coding: utf-8 -*-
"""Eski türlere kimlik bilgisi ekler, adları düzeltir, çift kayıtları birleştirir (tekrar çalıştırılabilir)."""
import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from legacy_species import L, ALIASES, LEGACY_ART
import zlib
from fishgen import render

ROOT = os.path.join(os.path.dirname(__file__), "..")
DB = os.path.join(ROOT, "data", "fish_db.json")
db = json.load(open(DB, encoding="utf-8"))
db = [x for x in db if x["id"] not in ALIASES]
names = set()
n = 0
for x in db:
    if x["id"] in L:
        name, ln, life, tr, home, iucn = L[x["id"]]
        if name:
            x["name"] = name
        x["len"], x["life"], x["tr"], x["home"] = ln, life, tr, home
        if iucn:
            x["iucn"] = iucn
        else:
            x.pop("iucn", None)
        n += 1
    if x["id"] in LEGACY_ART:
        spr = "fish_gen_" + x["id"]
        render(LEGACY_ART[x["id"]], seed=zlib.crc32(x["id"].encode()) & 0xFFFF).save(os.path.join(ROOT, "assets", "fish", spr + ".png"))
        x["spr"] = spr
        x.pop("tint", None)
    if x["latin"] == "Lepomis macrochirus" and x["id"].endswith("_x_cyanellus"):
        x["latin"] = "Lepomis macrochirus × L. cyanellus"
    assert x["name"] not in names, x["name"]
    names.add(x["name"])
json.dump(db, open(DB, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
json.dump(ALIASES, open(os.path.join(ROOT, "data", "fish_aliases.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=2)
missing = [x["id"] for x in db if "len" not in x and not x.get("boss")]
print("güncellenen:", n, "toplam tür:", len(db), "bilgisi eksik:", missing)
