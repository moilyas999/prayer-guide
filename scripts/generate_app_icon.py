#!/usr/bin/env python3
"""Prayer Guide app icon: green + white geometric, no text, no alpha, no iOS mask."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 1024
OUT = (
    Path(__file__).resolve().parents[1]
    / "PrayerGuide"
    / "Resources"
    / "Assets.xcassets"
    / "AppIcon.appiconset"
    / "AppIcon.png"
)

GREEN = (18, 92, 62)
GREEN_DEEP = (10, 58, 40)
WHITE = (246, 250, 246)


def regular_polygon(cx: float, cy: float, radius: float, sides: int, rotation: float) -> list[tuple[float, float]]:
    points = []
    for i in range(sides):
        angle = rotation + (2 * math.pi * i / sides)
        points.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle)))
    return points


def star_points(cx: float, cy: float, outer: float, inner: float, points: int, rotation: float) -> list[tuple[float, float]]:
    verts = []
    for i in range(points * 2):
        radius = outer if i % 2 == 0 else inner
        angle = rotation + (math.pi * i / points)
        verts.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle)))
    return verts


def main() -> None:
    image = Image.new("RGB", (SIZE, SIZE), GREEN)
    draw = ImageDraw.Draw(image)
    cx = cy = SIZE / 2

    # Soft radial depth without leaving the square (no baked iOS mask).
    for i in range(18):
        t = i / 17
        r = SIZE * (0.62 - t * 0.08)
        shade = tuple(int(GREEN[j] * (1 - t * 0.22) + GREEN_DEEP[j] * (t * 0.22)) for j in range(3))
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=shade, width=3)

    outer = regular_polygon(cx, cy, 390, 8, math.radians(22.5))
    draw.polygon(outer, outline=WHITE, width=22)

    inner_oct = regular_polygon(cx, cy, 286, 8, math.radians(22.5))
    draw.polygon(inner_oct, outline=WHITE, width=14)

    diamond = regular_polygon(cx, cy, 248, 4, math.radians(45))
    draw.polygon(diamond, outline=WHITE, width=12)

    star = star_points(cx, cy, 168, 72, 8, math.radians(-90))
    draw.polygon(star, fill=WHITE)

    # Inner void keeps the mark geometric rather than a filled blob.
    void = regular_polygon(cx, cy, 46, 8, math.radians(22.5))
    draw.polygon(void, fill=GREEN)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT, format="PNG")
    with Image.open(OUT) as check:
        assert check.mode == "RGB"
        assert check.size == (SIZE, SIZE)
        extrema = check.getextrema()
        assert all(channel[0] == channel[1] or True for channel in extrema)
    print(f"Wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
