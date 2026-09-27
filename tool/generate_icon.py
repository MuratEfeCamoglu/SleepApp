"""Uygulama ikonunu üretir: espresso zemin, honey uyku halkası, krem hilal.

Çalıştırma (proje kökünden):  python tool/generate_icon.py
Gerekli: Pillow.

Renkler CLAUDE.md §5 tokenlarından: espresso #2B211C, honey #E7B04A,
background (krem) #F4EDE2, dark border #40352D (halka track'i).
Çıktı: Android (legacy + adaptive + monochrome), iOS ve web ikonları.
"""

import json
import math
import os

from PIL import Image, ImageChops, ImageDraw

ESPRESSO = (0x2B, 0x21, 0x1C)
HONEY = (0xE7, 0xB0, 0x4A)
CREAM = (0xF4, 0xED, 0xE2)
TRACK = (0x40, 0x35, 0x2D)

SS = 4  # Kenar yumuşatma için süper örnekleme.
SWEEP = 0.78  # Halkanın doluluğu; SleepRingChart gibi −90°'den başlar.


def draw_mark(size, scale, background, mono=False):
    """[scale]: halka dış yarıçapının kenar uzunluğuna oranı."""
    s = size * SS
    img = Image.new("RGBA", (s, s), background + (255,) if background else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = s / 2
    outer = s * scale
    stroke = outer * 0.21
    r = outer - stroke / 2
    box = (c - r - stroke / 2, c - r - stroke / 2, c + r + stroke / 2, c + r + stroke / 2)
    ring = (255, 255, 255) if mono else HONEY

    if not mono:
        d.ellipse(box, outline=TRACK, width=round(stroke))
    start, end = -90, -90 + 360 * SWEEP
    d.arc(box, start, end, fill=ring, width=round(stroke))
    # Yuvarlak uçlar.

    for a in (start, end):
        x = c + r * math.cos(math.radians(a))
        y = c + r * math.sin(math.radians(a))
        h = stroke / 2
        d.ellipse((x - h, y - h, x + h, y + h), fill=ring)

    # Hilal: dolu daire eksi kaydırılmış daire (maske ile).
    moon_r = outer * 0.50
    cut_r = moon_r * 0.86
    ox, oy = moon_r * 0.52, -moon_r * 0.38
    mask = Image.new("L", (s, s), 0)
    md = ImageDraw.Draw(mask)
    md.ellipse((c - moon_r, c - moon_r, c + moon_r, c + moon_r), fill=255)
    cut = Image.new("L", (s, s), 0)
    ImageDraw.Draw(cut).ellipse(
        (c + ox - cut_r, c + oy - cut_r, c + ox + cut_r, c + oy + cut_r), fill=255
    )
    mask = ImageChops.subtract(mask, cut)
    moon = Image.new("RGBA", (s, s), ((255, 255, 255) if mono else CREAM) + (255,))
    img.paste(moon, (0, 0), mask)

    return img.resize((size, size), Image.LANCZOS)


def save(img, path, alpha=True):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    (img if alpha else img.convert("RGB")).save(path)


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")

# Tam kare ikonda halka oranı; adaptive/maskable'da güvenli alana sığacak kadar küçük.
FULL = 0.34
SAFE = 0.29

# Android legacy (API < 26).
for density, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
    save(draw_mark(px, FULL, ESPRESSO), os.path.join(RES, f"mipmap-{density}", "ic_launcher.png"))

# Android adaptive: 108dp tuval, zemin renk kaynağından.
for density, px in {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}.items():
    folder = os.path.join(RES, f"mipmap-{density}")
    save(draw_mark(px, SAFE, None), os.path.join(folder, "ic_launcher_foreground.png"))
    save(draw_mark(px, SAFE, None, mono=True), os.path.join(folder, "ic_launcher_monochrome.png"))

os.makedirs(os.path.join(RES, "mipmap-anydpi-v26"), exist_ok=True)
with open(os.path.join(RES, "mipmap-anydpi-v26", "ic_launcher.xml"), "w", encoding="utf-8") as f:
    f.write(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
        "</adaptive-icon>\n"
    )
with open(os.path.join(RES, "values", "ic_launcher_background.xml"), "w", encoding="utf-8") as f:
    f.write(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="ic_launcher_background">#2B211C</color>\n'
        "</resources>\n"
    )

# iOS: Contents.json'daki her dosya; App Store alfa kabul etmez.
ios = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
with open(os.path.join(ios, "Contents.json"), encoding="utf-8") as f:
    contents = json.load(f)
for entry in contents["images"]:
    name = entry.get("filename")
    if not name:
        continue
    base = float(entry["size"].split("x")[0])
    px = round(base * int(entry["scale"].rstrip("x")))
    save(draw_mark(px, FULL, ESPRESSO), os.path.join(ios, name), alpha=False)

# Web.
web = os.path.join(ROOT, "web")
for px in (192, 512):
    save(draw_mark(px, FULL, ESPRESSO), os.path.join(web, "icons", f"Icon-{px}.png"))
    save(draw_mark(px, SAFE, ESPRESSO), os.path.join(web, "icons", f"Icon-maskable-{px}.png"))
save(draw_mark(32, FULL, ESPRESSO), os.path.join(web, "favicon.png"))

print("İkonlar üretildi.")
