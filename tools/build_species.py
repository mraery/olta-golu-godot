# -*- coding: utf-8 -*-
"""Yeni türlerin sprite'larını üretir ve data/fish_db.json'a ekler/günceller (tekrar çalıştırılabilir)."""
import json, os, sys, zlib
sys.path.insert(0, os.path.dirname(__file__))
from fishgen import render
from new_species import S

ROOT = os.path.join(os.path.dirname(__file__), "..")
DB = os.path.join(ROOT, "data", "fish_db.json")
OUT = os.path.join(ROOT, "assets", "fish")

db = json.load(open(DB, encoding="utf-8"))
# Eski kayıtta morina yanlışlıkla 'Mezgit' adını taşıyordu
for x in db:
    if x.get("latin") == "Gadus morhua" and x["name"].startswith("Mezgit"):
        x["name"] = "Morina (Morhua)"
by_id = {x["id"]: i for i, x in enumerate(db)}
for sp in S:
    art = dict(sp["art"])
    img = render(art, seed=zlib.crc32(sp["id"].encode()) & 0xFFFF)
    img.save(os.path.join(OUT, sp["spr"] + ".png"))
    entry = {k: v for k, v in sp.items() if k != "art"}
    if not entry["iucn"]:
        entry.pop("iucn")
    if entry["id"] in by_id:
        db[by_id[entry["id"]]] = entry
    else:
        by_id[entry["id"]] = len(db)
        db.append(entry)
json.dump(db, open(DB, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("toplam tür:", len(db), "yeni/güncel:", len(S))
