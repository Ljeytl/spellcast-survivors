"""Generates the night-camp pixel art to match assets/typecast: small palettes,
3-tone shading lit from the top-left, near-black outlines (flames unoutlined).
Run: python3 tools/generate_camp_art.py  -> assets/typecast/Camp/*.png
"""
import math, random
from pathlib import Path
from PIL import Image

OUT = Path(__file__).resolve().parents[1] / "assets/typecast/Camp"
OUTLINE = (20, 20, 13, 255)
P = {
    "wood_d": (59, 42, 28), "wood_m": (107, 74, 44), "wood_l": (154, 108, 62), "wood_ring": (196, 152, 98),
    "stone_d": (62, 61, 54), "stone_m": (109, 107, 93), "stone_l": (161, 159, 140),
    "ember": (168, 50, 30), "orange": (240, 122, 36), "yellow": (247, 200, 67), "hot": (255, 242, 184),
    "cloth_d": (58, 63, 92), "cloth_m": (91, 97, 137), "cloth_l": (139, 144, 184), "patch": (168, 96, 58), "patch_d": (120, 62, 36),
    "inside": (24, 22, 30), "rope": (190, 170, 120),
    "roll_d": (122, 46, 42), "roll_m": (168, 71, 58), "roll_l": (201, 106, 79), "pillow": (214, 205, 182), "pillow_d": (160, 150, 128),
}

def canvas(w, h):
    return [[None] * w for _ in range(h)]

def put(g, x, y, c):
    if 0 <= y < len(g) and 0 <= x < len(g[0]):
        g[y][x] = c

def outline(g):
    h, w = len(g), len(g[0])
    out = [row[:] for row in g]
    for y in range(h):
        for x in range(w):
            if g[y][x] is None and any(0 <= y + dy < h and 0 <= x + dx < w and g[y + dy][x + dx] not in (None, OUTLINE)
                                        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                out[y][x] = OUTLINE
    return out

def save(g, name, scale_preview=False):
    h, w = len(g), len(g[0])
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y in range(h):
        for x in range(w):
            c = g[y][x]
            if c is not None:
                im.putpixel((x, y), c if len(c) == 4 else c + (255,))
    OUT.mkdir(parents=True, exist_ok=True)
    im.save(OUT / name)
    return im

def ellipse(g, cx, cy, rx, ry, colour_at):
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if d <= 1.0:
                put(g, x, y, colour_at(x - cx, y - cy, d))

def shade3(dark, mid, light):
    # Lit from the top-left.
    def f(dx, dy, d):
        s = -dx * 0.6 - dy
        return light if s > 1.2 and d < 0.7 else dark if s < -1.0 or d > 0.85 and dy > 0 else mid
    return f

def log(g, x0, y0, x1, y1, thick=3):
    n = int(max(abs(x1 - x0), abs(y1 - y0)))
    for i in range(n + 1):
        t = i / n
        x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        for k in range(thick):
            c = P["wood_l"] if k == 0 else P["wood_d"] if k == thick - 1 else P["wood_m"]
            put(g, round(x), round(y) + k, c)
    for (ex, ey) in ((x0, y0), (x1, y1)):
        for k in range(thick):
            put(g, round(ex), round(ey) + k, P["wood_ring"] if k == 1 else P["wood_m"])

def campfire_base():
    g = canvas(34, 18)
    log(g, 6, 11, 27, 5)
    log(g, 6, 5, 27, 11)
    ellipse(g, 17, 9, 3, 2, lambda dx, dy, d: P["hot"] if d < 0.3 else P["orange"] if d < 0.7 else P["ember"])
    rng = random.Random(3)
    for i in range(10):
        a = i * math.tau / 10 + 0.2
        sx, sy = 17 + math.cos(a) * 14, 9 + math.sin(a) * 6.2
        r = 2.3 + rng.random() * 0.8
        ellipse(g, sx, sy, r + 0.4, r * 0.8, shade3(P["stone_d"], P["stone_m"], P["stone_l"]))
    return outline(g)

def flame(frame):
    g = canvas(18, 24)
    rng = random.Random(10 + frame)
    sway = math.sin(frame * math.tau / 4) * 1.2
    layers = [(P["ember"], 7.5, 21), (P["orange"], 5.8, 17), (P["yellow"], 4.0, 13), (P["hot"], 2.2, 8)]
    for colour, half_w, height in layers:
        for y in range(24):
            h = 23 - y
            if h > height:
                continue
            t = h / height
            width = half_w * (1 - t ** 1.6) * (0.85 + 0.3 * math.sin(t * 6 + frame))
            cx = 9 + sway * t * 1.6
            for x in range(18):
                if abs(x + 0.5 - cx) <= width:
                    put(g, x, y, colour)
    for _ in range(3):
        put(g, 9 + rng.randint(-5, 5), rng.randint(0, 6), P["yellow"] if rng.random() < 0.5 else P["orange"])
    return g

def tent():
    g = canvas(52, 40)
    apex, base_y, left, right = (26, 3), 37, 3, 49
    for y in range(apex[1], base_y + 1):
        t = (y - apex[1]) / (base_y - apex[1])
        lx, rx = apex[0] - (apex[0] - left) * t, apex[0] + (right - apex[0]) * t
        for x in range(int(lx), int(rx) + 1):
            # The left panel faces the light; the right panel is in shade.
            c = P["cloth_m"] if x < apex[0] else P["cloth_d"]
            if x < apex[0] and (x - lx) < 2:
                c = P["cloth_l"]
            if abs(x - apex[0]) < 1:
                c = P["cloth_l"]
            put(g, x, y, c)
    # Door flap: dark opening with one flap pinned back.
    for y in range(16, base_y + 1):
        t = (y - 16) / (base_y - 16)
        half = 2 + 7 * t
        for x in range(int(26 - half), int(26 + half * 0.4) + 1):
            put(g, x, y, P["inside"])
        for x in range(int(26 + half * 0.4), int(26 + half * 0.4) + 3):
            put(g, x, y, P["cloth_l"])
    # A badly sewn patch, because the wizard is broke.
    for y in range(22, 28):
        for x in range(9, 15):
            put(g, x, y, P["patch"] if (x + y) % 5 else P["patch_d"])
    for x in range(9, 15, 2):
        put(g, x, 21, P["rope"])
    # Pole tips and guy ropes.
    for k in range(3):
        put(g, apex[0], apex[1] - 1 - k, P["wood_m"])
    for i in range(10):
        put(g, left - 1 - i // 3, base_y - 8 + i, P["rope"])
        put(g, right + 1 + i // 3, base_y - 8 + i, P["rope"])
    return outline(g)

def bedroll():
    g = canvas(34, 16)
    for y in range(3, 14):
        for x in range(6, 32):
            if (x - 6) < 2 and (y < 5 or y > 11):
                continue
            c = P["roll_l"] if y < 6 else P["roll_d"] if y > 10 else P["roll_m"]
            put(g, x, y, c)
    for y in range(4, 13):
        put(g, 22, y, P["wood_d"])
        put(g, 23, y, P["wood_m"])
    ellipse(g, 6, 8, 5, 4, lambda dx, dy, d: P["pillow"] if dy < 1 else P["pillow_d"])
    return outline(g)

def log_seat():
    g = canvas(26, 16)
    for y in range(6, 14):
        for x in range(2, 24):
            put(g, x, y, P["wood_l"] if y < 8 else P["wood_d"] if y > 11 else P["wood_m"])
    ellipse(g, 22, 9.5, 3, 4, lambda dx, dy, d: P["wood_ring"] if d < 0.35 else P["wood_l"] if d < 0.7 else P["wood_m"])
    put(g, 22, 9, P["wood_m"])
    for x in (7, 13, 18):
        put(g, x, 9, P["wood_d"])
        put(g, x + 1, 10, P["wood_d"])
    return outline(g)

if __name__ == "__main__":
    save(campfire_base(), "Campfire Base.png")
    for f in range(4):
        save(flame(f), "Campfire Flame %d.png" % (f + 1))
    save(tent(), "Tent.png")
    save(bedroll(), "Bedroll.png")
    save(log_seat(), "Log Seat.png")
    print("wrote", sorted(p.name for p in OUT.glob("*.png")))
