"""Olta Gölü — prosedürel pixel-art balık sprite üreticisi.

Mevcut pixel paketlerle aynı stil: sola bakan balık, koyu dış çizgi, üstten
gölgeli gövde, açık karın, desen, yüzgeç ve göz. Her tür kendi parametreleriyle
tekil bir 2D sprite alır.

Kullanım:  from fishgen import render;  img = render(spec)  (PIL.Image RGBA)
"""
from __future__ import annotations

import math
import random
from PIL import Image


def hexc(s: str) -> tuple[int, int, int]:
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def shade(c, f):
    """f<0 koyulaştır, f>0 aç."""
    return mix(c, (0, 0, 0), -f) if f < 0 else mix(c, (255, 255, 255), f)


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px: dict[tuple[int, int], tuple[int, int, int]] = {}
        self.layer: dict[tuple[int, int], int] = {}

    def put(self, x, y, c, layer=1):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            if self.layer.get((x, y), -1) <= layer:
                self.px[(x, y)] = c
                self.layer[(x, y)] = layer

    def get(self, x, y):
        return self.px.get((x, y))

    def poly(self, pts, c, layer=1):
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        for y in range(int(math.floor(min(ys))), int(math.ceil(max(ys))) + 1):
            for x in range(int(math.floor(min(xs))), int(math.ceil(max(xs))) + 1):
                if _inside(x + 0.5, y + 0.5, pts):
                    self.put(x, y, c, layer)

    def outline(self, col):
        filled = set(self.px.keys())
        edge = set()
        for (x, y) in filled:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (x + dx, y + dy)
                if n not in filled and 0 <= n[0] < self.w and 0 <= n[1] < self.h:
                    edge.add(n)
        for (x, y) in edge:
            self.px[(x, y)] = col
            self.layer[(x, y)] = 0

    def image(self):
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        for (x, y), c in self.px.items():
            img.putpixel((x, y), (*c, 255))
        bbox = img.getbbox()
        return img.crop(bbox) if bbox else img


def _inside(x, y, pts):
    n = len(pts)
    ins = False
    j = n - 1
    for i in range(n):
        xi, yi = pts[i]
        xj, yj = pts[j]
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi + 1e-9) + xi:
            ins = not ins
        j = i
    return ins


# ---------------------------------------------------------------- gövde profili
def profile(u, s):
    """u: 0 burun → 1 kuyruk sapı. Üst ve alt yarı yükseklik çarpanı döner."""
    p = s.get("peak", 0.35)
    blunt = s.get("blunt", 0.55)
    ped = s.get("ped", 0.28)
    if u < p:
        k = (u / p) ** blunt
    else:
        v = (u - p) / (1 - p)
        k = 1 - (1 - ped) * (v ** s.get("taper", 1.5))
    hump = s.get("hump", 0.0)
    up = k * (1 + hump * math.sin(math.pi * min(1, u / max(0.01, p * 1.6))))
    lo = k * s.get("belly_k", 1.0)
    return up, lo


def render(spec: dict, seed: int = 0) -> Image.Image:
    rnd = random.Random(seed or hash(spec.get("id", "x")) & 0xFFFF)
    shape = spec.get("shape", "fish")
    if shape == "seahorse":
        return _seahorse(spec)
    if shape == "ray":
        return _ray(spec, rnd)
    if shape == "flat":
        return _flatfish(spec, rnd)

    L = spec.get("L", 34)
    H = spec.get("H", 7.0)
    body = hexc(spec.get("body", "#8899aa"))
    belly = hexc(spec.get("belly", "#e8eef2"))
    fin = hexc(spec.get("fin", spec.get("body", "#8899aa")))
    out = hexc(spec.get("outline", "#141822"))
    tail = spec.get("tail", "fork")
    snout = spec.get("snout", 0)
    pad = 10 + (snout if snout > 0 else 0)
    cw = L + 22 + pad
    ch = int(H * 2 * (1 + spec.get("hump", 0)) + 24 + spec.get("dorsal_h", 0) * 2 + spec.get("anal_h", 0) * 2)
    c = Canvas(cw, max(ch, 16))
    cy = c.h / 2 + spec.get("dy", 0)
    x0 = pad

    wave = spec.get("wave", 0.0)

    def mid(u):
        return cy + wave * math.sin(u * math.pi * 2.2)

    # --- kuyruk
    tx = x0 + L
    th = min(H, 8.5) * spec.get("tail_size", 1.2) * (0.72 if tail == "round" else 1.0)
    tcol = fin
    if tail == "fork":
        c.poly([(tx - 2, mid(1) - 1.5), (tx + th * 1.1, mid(1) - th * 1.25), (tx + th * 0.55, mid(1)),
                (tx + th * 1.1, mid(1) + th * 1.25), (tx - 2, mid(1) + 1.5)], tcol, 1)
    elif tail == "lunate":
        c.poly([(tx - 2, mid(1) - 1.2), (tx + th * 0.9, mid(1) - th * 1.6), (tx + th * 0.5, mid(1) - th * 0.4),
                (tx + th * 0.3, mid(1)), (tx + th * 0.5, mid(1) + th * 0.4), (tx + th * 0.9, mid(1) + th * 1.6),
                (tx - 2, mid(1) + 1.2)], tcol, 1)
    elif tail == "round":
        for a in range(-60, 61, 6):
            r = th * 1.05
            c.poly([(tx - 2, mid(1)), (tx + r * math.cos(math.radians(a)), mid(1) + r * math.sin(math.radians(a))),
                    (tx + r * math.cos(math.radians(a + 6)), mid(1) + r * math.sin(math.radians(a + 6)))], tcol, 1)
    elif tail == "square":
        c.poly([(tx - 2, mid(1) - 1.5), (tx + th * 0.9, mid(1) - th), (tx + th * 0.9, mid(1) + th), (tx - 2, mid(1) + 1.5)], tcol, 1)
    elif tail == "shark":
        c.poly([(tx - 3, mid(1) - 1), (tx + th * 1.5, mid(1) - th * 1.7), (tx + th * 0.7, mid(1) + 0.5),
                (tx + th * 0.8, mid(1) + th * 0.8), (tx - 3, mid(1) + 1.5)], tcol, 1)
    elif tail == "point":
        c.poly([(tx - 3, mid(1) - 2), (tx + th * 1.4, mid(1)), (tx - 3, mid(1) + 2)], tcol, 1)
    elif tail == "whip":
        for i in range(int(th * 3)):
            c.put(tx + i, mid(1) + math.sin(i * 0.4) * 0.8, tcol, 1)

    # --- sırt / anal yüzgeçleri
    dh = spec.get("dorsal_h", H * 0.6)
    d0, d1 = spec.get("dorsal", (0.3, 0.65))
    dtype = spec.get("dorsal_type", "tri")
    if dh > 0:
        pts = []
        for i in range(0, 11):
            u = d0 + (d1 - d0) * i / 10
            up, _ = profile(u, spec)
            yb = mid(u) - up * H + 1
            if dtype == "tri":
                hh = dh * (1 - abs(i - 3) / 7) if i <= 10 else 0
            elif dtype == "sail":
                hh = dh * math.sin(math.pi * i / 10) ** 0.5
            elif dtype == "spiky":
                hh = dh * (0.6 + 0.4 * (i % 2))
            elif dtype == "trail":
                hh = dh * (0.3 + 0.7 * i / 10)
            else:
                hh = dh * math.sin(math.pi * i / 10)
            pts.append((x0 + u * L, yb - hh))
        base = [(x0 + d1 * L, mid(d1) - profile(d1, spec)[0] * H + 2), (x0 + d0 * L, mid(d0) - profile(d0, spec)[0] * H + 2)]
        c.poly(pts + base, fin, 1)
        if dtype == "spiky":
            for i in range(0, 11, 2):
                u = d0 + (d1 - d0) * i / 10
                for k in range(int(dh) + 1):
                    c.put(x0 + u * L, mid(u) - profile(u, spec)[0] * H - k, shade(fin, -0.35), 2)
    ah = spec.get("anal_h", H * 0.4)
    a0, a1 = spec.get("anal", (0.55, 0.78))
    if ah > 0:
        pts = []
        for i in range(0, 11):
            u = a0 + (a1 - a0) * i / 10
            _, lo = profile(u, spec)
            hh = ah * (math.sin(math.pi * i / 10) if spec.get("anal_type") != "trail" else (0.3 + 0.7 * i / 10))
            pts.append((x0 + u * L, mid(u) + lo * H - 1 + hh))
        base = [(x0 + a1 * L, mid(a1) + profile(a1, spec)[1] * H - 2), (x0 + a0 * L, mid(a0) + profile(a0, spec)[1] * H - 2)]
        c.poly(pts + base, fin, 1)
    # ikinci sırt yüzgeci (orkinos, palamut gibi) + finlet
    if spec.get("finlets"):
        for i in range(5):
            u = 0.72 + i * 0.05
            up, lo = profile(u, spec)
            c.put(x0 + u * L, mid(u) - up * H - 1, hexc(spec["finlets"]), 2)
            c.put(x0 + u * L, mid(u) + lo * H + 1, hexc(spec["finlets"]), 2)

    # --- gövde
    for xi in range(L + 1):
        u = xi / L
        up, lo = profile(u, spec)
        top = mid(u) - up * H
        bot = mid(u) + lo * H
        for y in range(int(math.floor(top)), int(math.ceil(bot)) + 1):
            if y < top - 0.4 or y > bot + 0.4:
                continue
            t = (y - top) / max(1, bot - top)
            if t < 0.22:
                col = shade(body, -0.22)
            elif t < spec.get("belly_line", 0.62):
                col = body
            else:
                col = mix(body, belly, min(1, (t - spec.get("belly_line", 0.62)) * 3.2))
            c.put(x0 + xi, y, col, 2)

    # --- burun uzantısı (kılıç, zargana, marlin, mersin)
    if snout:
        sc = hexc(spec.get("snout_col", "#2a2f3a"))
        for i in range(snout + 1):
            y = mid(0) + spec.get("snout_dy", 0)
            c.put(x0 - i, y, sc, 3)
            if spec.get("snout_thick") and i < snout * 0.7:
                c.put(x0 - i, y + 1, sc, 3)

    # --- desen
    _pattern(c, spec, x0, L, H, mid, rnd)

    # --- göğüs yüzgeci
    px_ = x0 + L * spec.get("pect_x", 0.24)
    py_ = mid(0.24) + H * 0.25
    ps = spec.get("pect", 3.0)
    if ps > 0:
        c.poly([(px_, py_ - 1), (px_ + ps * 1.6, py_ + ps * 0.6), (px_ + ps * 0.4, py_ + ps * 1.0)], shade(fin, -0.12), 3)

    # --- solungaç + göz + ağız
    gx = x0 + L * spec.get("gill", 0.2)
    up, lo = profile(spec.get("gill", 0.2), spec)
    if spec.get("gill_slits"):
        for k in range(spec["gill_slits"]):
            for y in range(int(mid(0.2) - up * H * 0.35), int(mid(0.2) + lo * H * 0.35) + 1):
                c.put(gx + k * 2, y, shade(body, -0.4), 3)
    elif spec.get("gill_line", True):
        for y in range(int(mid(0.2) - up * H * 0.55), int(mid(0.2) + lo * H * 0.55) + 1):
            c.put(gx + 0.6 * math.sin((y - mid(0.2)) * 0.25), y, shade(body, -0.35), 3)
    ex = x0 + L * spec.get("eye_x", 0.1)
    ey = mid(0.1) - H * spec.get("eye_y", 0.25)
    es = spec.get("eye", 1)
    eye_c = hexc(spec.get("eye_col", "#ffffff"))
    if es >= 2:
        for dx in range(-1, 2):
            for dy in range(-1, 2):
                if abs(dx) + abs(dy) < 2 or es >= 3:
                    c.put(ex + dx, ey + dy, eye_c, 4)
        c.put(ex, ey, (10, 10, 14), 5)
        c.put(ex - 1, ey, (10, 10, 14), 5)
    else:
        c.put(ex, ey, eye_c, 4)
        c.put(ex - 1, ey, (10, 10, 14), 5)
    if spec.get("mouth", "normal") == "big":
        for i in range(int(L * 0.12)):
            c.put(x0 + i, mid(0.05) + H * 0.25 + i * 0.15, (40, 10, 14), 4)
    if spec.get("teeth"):
        for i in range(0, int(L * 0.14), 2):
            c.put(x0 + i + 1, mid(0.05) + H * 0.2, (245, 245, 235), 5)
            c.put(x0 + i + 1, mid(0.05) + H * 0.2 + 1, (245, 245, 235), 5)
    if spec.get("barbels"):
        bc = shade(body, -0.3)
        for k in range(spec["barbels"]):
            bx = x0 + 1 + k * 2
            by = mid(0.05) + profile(0.05, spec)[1] * H * 0.6
            for i in range(3 + k):
                c.put(bx + i * 0.35, by + 1 + i, bc, 3)
    if spec.get("lure"):
        lc = hexc(spec["lure"])
        for i in range(7):
            c.put(x0 + 3 - i * 0.6, mid(0) - H * 0.9 - i * 0.8, shade(body, -0.3), 4)
        lx, ly = x0 + 3 - 7 * 0.6, mid(0) - H * 0.9 - 7 * 0.8
        for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1), (-1, 0), (0, -1)):
            c.put(lx + dx, ly + dy, lc, 5)

    c.outline(out)
    # parlak noktalar outline'ın üstüne (derin deniz fotoforları)
    if spec.get("photophores"):
        pc = hexc(spec["photophores"])
        for xi in range(2, L - 2, 3):
            u = xi / L
            _, lo = profile(u, spec)
            c.put(x0 + xi, mid(u) + lo * H - 1, pc, 6)
    return c.image()


def _pattern(c, s, x0, L, H, mid, rnd):
    pat = s.get("pattern", "")
    pc = hexc(s.get("pcol", "#222222"))
    pc2 = hexc(s.get("pcol2", s.get("pcol", "#222222")))

    def inside(x, y):
        return c.layer.get((int(x), int(y)), -1) == 2

    if pat == "bars":
        n = s.get("n", 5)
        for k in range(n):
            u = 0.2 + 0.7 * (k + 0.5) / n
            for xi in range(s.get("bw", 2)):
                for y in range(c.h):
                    if inside(x0 + u * L + xi, y):
                        c.put(x0 + u * L + xi, y, pc if k % 2 == 0 or not s.get("alt") else pc2, 2)
    elif pat == "stripes":
        n = s.get("n", 3)
        for k in range(n):
            off = -H * 0.6 + k * (H * 1.3 / max(1, n - 1 if n > 1 else 1))
            for xi in range(int(L * 0.15), L):
                u = xi / L
                y = mid(u) + off * (1 - 0.3 * u)
                if inside(x0 + xi, y):
                    c.put(x0 + xi, y, pc if k % 2 == 0 else pc2, 2)
    elif pat in ("spots", "dots"):
        n = s.get("n", 14)
        for _ in range(n * 3):
            x = x0 + rnd.uniform(0.15, 0.95) * L
            y = rnd.uniform(0, c.h)
            if inside(x, y):
                c.put(x, y, pc, 2)
                if pat == "spots" and s.get("big"):
                    c.put(x + 1, y, pc, 2)
                n -= 1
                if n <= 0:
                    break
    elif pat == "mottled":
        for x in range(c.w):
            for y in range(c.h):
                if inside(x, y) and rnd.random() < s.get("dens", 0.28):
                    c.put(x, y, pc if rnd.random() < 0.6 else pc2, 2)
    elif pat == "back":
        # sırtta dalgalı koyu desen (uskumru, palamut)
        for xi in range(int(L * 0.18), L):
            u = xi / L
            up, _ = profile(u, s)
            top = mid(u) - up * H
            k = int((math.sin(xi * s.get("freq", 0.9)) + 1) * H * 0.35) + 1
            for y in range(int(top), int(top + k)):
                if inside(x0 + xi, y):
                    c.put(x0 + xi, y, pc, 2)
    elif pat == "lateral":
        for xi in range(int(L * 0.18), L):
            u = xi / L
            y = mid(u) - H * 0.05
            if inside(x0 + xi, y):
                c.put(x0 + xi, y, pc, 2)
    elif pat == "eyespot":
        x = x0 + L * s.get("spot_u", 0.8)
        y = mid(0.8) - H * 0.2
        for dx in range(-2, 3):
            for dy in range(-2, 3):
                if dx * dx + dy * dy <= 4 and inside(x + dx, y + dy):
                    c.put(x + dx, y + dy, pc2 if dx * dx + dy * dy <= 1 else pc, 2)
    elif pat == "gradient":
        for (x, y), _ in list(c.px.items()):
            if c.layer[(x, y)] == 2:
                t = (x - x0) / L
                c.px[(x, y)] = mix(c.px[(x, y)], pc, max(0, t - 0.25) * 0.8)
    elif pat == "patches":
        for _ in range(s.get("n", 4)):
            cx = x0 + rnd.uniform(0.2, 0.85) * L
            cy = mid(0.5) + rnd.uniform(-H * 0.6, H * 0.4)
            r = rnd.uniform(1.5, 3.2)
            col = pc if rnd.random() < 0.5 else pc2
            for dx in range(-4, 5):
                for dy in range(-4, 5):
                    if dx * dx + dy * dy <= r * r and inside(cx + dx, cy + dy):
                        c.put(cx + dx, cy + dy, col, 2)
    if s.get("pattern2"):
        s2 = dict(s)
        s2["pattern"] = s["pattern2"]
        s2["pcol"] = s.get("p2col", "#222222")
        s2["pcol2"] = s.get("p2col", "#222222")
        s2.pop("pattern2")
        _pattern(c, s2, x0, L, H, mid, rnd)


# ---------------------------------------------------------------- özel şekiller
def _flatfish(s, rnd):
    L = s.get("L", 30)
    H = s.get("H", 11)
    body = hexc(s.get("body", "#8a7a5a"))
    fin = hexc(s.get("fin", s.get("body")))
    c = Canvas(L + 20, int(H * 2 + 14))
    cy = c.h / 2
    x0 = 4
    # saçak yüzgeç
    for xi in range(int(L * 0.08), int(L * 0.92)):
        u = xi / L
        r = math.sin(math.pi * min(1, u / 0.92)) ** 0.7 * H + 2
        for y in (cy - r, cy + r):
            c.put(x0 + xi, y, fin, 1)
            c.put(x0 + xi, y + (1 if y > cy else -1), shade(fin, -0.15), 1)
    for xi in range(L):
        u = xi / L
        r = math.sin(math.pi * min(1, u / 0.92)) ** 0.7 * H
        for y in range(int(cy - r), int(cy + r) + 1):
            c.put(x0 + xi, y, shade(body, -0.12) if y < cy - r * 0.6 else body, 2)
    c.poly([(x0 + L * 0.9, cy - 2), (x0 + L + 7, cy - 5), (x0 + L + 7, cy + 5), (x0 + L * 0.9, cy + 2)], fin, 1)
    s2 = dict(s)
    s2["pattern"] = s.get("pattern", "spots")

    def mid(u):
        return cy
    _pattern(c, s2, x0, L, H, mid, rnd)
    for ex, ey in ((x0 + 4, cy - H * 0.45), (x0 + 6, cy - H * 0.15)):
        c.put(ex, ey, (255, 255, 255), 4)
        c.put(ex + 1, ey, (10, 10, 14), 5)
    c.outline(hexc(s.get("outline", "#141822")))
    return c.image()


def _ray(s, rnd):
    W = s.get("L", 30)
    body = hexc(s.get("body", "#6a6a7a"))
    c = Canvas(W + 34, W + 6)
    cx, cy = W * 0.55, c.h / 2
    hw = W * 0.5
    disc = s.get("disc", "diamond")
    for y in range(c.h):
        for x in range(c.w):
            dx, dy = (x - cx) / hw, (y - cy) / hw
            if disc == "round":
                ok = dx * dx + dy * dy * 1.05 <= 1
            elif disc == "guitar":
                ok = (dx + 0.1) ** 2 * 0.55 + dy * dy * 3.2 <= 0.6 or (abs(dy) < 0.18 and -0.2 < dx < 1.35)
            else:
                ok = abs(dx) * 0.9 + abs(dy) <= 0.95 and dx < 0.75
            if ok:
                c.put(x, y, shade(body, -0.1) if dy < -0.3 else body, 2)
    # kuyruk
    for i in range(int(W * 0.9)):
        c.put(cx + hw * 0.7 + i, cy + math.sin(i * 0.15) * 0.5, shade(body, -0.25), 1)
    if disc == "guitar":
        for i in range(5):
            c.poly([(cx + hw * 0.6, cy - 1), (cx + hw * 0.85, cy - 5), (cx + hw * 0.95, cy - 1)], shade(body, -0.1), 1)
    _pattern(c, s, cx - hw, int(hw * 2), hw, lambda u: cy, rnd)
    c.put(cx - hw * 0.35, cy - 2, (250, 250, 250), 4)
    c.put(cx - hw * 0.35, cy + 2, (250, 250, 250), 4)
    c.outline(hexc(s.get("outline", "#141822")))
    return c.image()


def _seahorse(s):
    body = hexc(s.get("body", "#d9a441"))
    c = Canvas(24, 34)
    pts = [(9, 4), (12, 3), (14, 5), (19, 6), (19, 8), (14, 8), (14, 10), (12, 13), (13, 17), (13, 21),
           (11, 25), (8, 27), (6, 29), (7, 31), (10, 31), (9, 29), (11, 28), (14, 25), (16, 20), (16, 15),
           (15, 11), (16, 8), (15, 6), (13, 4), (10, 2)]
    c.poly(pts, body, 2)
    for y in range(9, 26, 2):
        c.put(12 if y < 22 else 11, y, shade(body, -0.3), 3)
    c.poly([(15, 12), (19, 14), (16, 17)], shade(body, 0.25), 1)
    for x, y in ((11, 2), (13, 2), (12, 1)):
        c.put(x, y, shade(body, -0.2), 2)
    c.put(13, 5, (255, 255, 255), 4)
    c.put(13, 5, (10, 10, 14), 5)
    c.outline(hexc(s.get("outline", "#141822")))
    img = c.image()
    return img.transpose(Image.FLIP_LEFT_RIGHT)
