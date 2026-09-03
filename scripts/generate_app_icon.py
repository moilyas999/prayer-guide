#!/usr/bin/env python3
"""My Five app icon: five quiet timetable marks on linen. No text, no alpha, no iOS mask."""

from __future__ import annotations

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

LINEN = (246, 242, 235)
BAR = (58, 68, 92)


def main() -> None:
    image = Image.new("RGB", (SIZE, SIZE), LINEN)
    draw = ImageDraw.Draw(image)

    # Five even marks, like a printed timetable. Original geometry — not a mosque,
    # crescent, octagon, or star.
    left = 236
    right = 788
    top = 214
    gap = 86
    thickness = 52
    for i in range(5):
        y0 = top + i * gap
        y1 = y0 + thickness
        draw.rounded_rectangle((left, y0, right, y1), radius=16, fill=BAR)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT, format="PNG")
    with Image.open(OUT) as check:
        assert check.mode == "RGB"
        assert check.size == (SIZE, SIZE)
    print(f"Wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
