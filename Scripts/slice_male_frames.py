#!/usr/bin/env python3
"""Slice the male sprite sheets in Frames/ into Sources/TinyNudges/Resources/male/<name>_<n>.png.

Each sheet is a row of transparent-background poses. Frames of one sequence share a canvas
(so the character doesn't jump around) scaled to a fixed height, like the female frames.
Requires Pillow and numpy:  python3 Scripts/slice_male_frames.py
"""
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
SRC, OUT = ROOT / "Frames", ROOT / "Sources/TinyNudges/Resources/male"
BODY_H, EYE_H = 256, 300      # output heights, matching the female sprites
BUST_SCALE = 1.65             # head-and-shoulders frames drawn this much larger than the full-body scale


def load(name):
    im = np.array(Image.open(SRC / name).convert("RGBA"))
    im[im[..., 3] < 24] = 0   # drop faint glow/halo pixels
    # drop stray specks (leftovers at the sheet edges) that would stretch the frame's bounding box
    labels, n = ndimage.label(im[..., 3] > 0, structure=np.ones((3, 3)))
    sizes = ndimage.sum(np.ones_like(labels), labels, range(1, n + 1))
    for i, size in enumerate(sizes, start=1):
        if size < 150: im[labels == i] = 0
    return im


def split(im):
    """One image per run of non-empty columns."""
    cols = (im[..., 3] > 0).any(axis=0)
    runs, start = [], None
    for x, on in enumerate(cols):
        if on and start is None: start = x
        if not on and start is not None: runs.append((start, x)); start = None
    if start is not None: runs.append((start, len(cols)))
    return [im[:, a:b] for a, b in runs]


def bbox(im):
    ys, xs = np.nonzero(im[..., 3])
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def canvas(frames, height, scale=None):
    """Crop frames to their shared bounding height, scale to `height`, bottom-align on one canvas."""
    boxes = [bbox(f) for f in frames]
    top, bottom = min(b[1] for b in boxes), max(b[3] for b in boxes)
    scale = scale or height / (bottom - top)
    width = int(max(f.shape[1] for f in frames) * scale)
    out = []
    for f, b in zip(frames, boxes):
        img = Image.fromarray(f[top:bottom, b[0]:b[2]])
        img = img.resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))), Image.LANCZOS)
        c = Image.new("RGBA", (width, round((bottom - top) * scale)))
        c.paste(img, ((width - img.width) // 2, c.height - img.height))
        out.append(c)
    return out, scale


def save(frames, name):
    for i, f in enumerate(frames):
        f.save(OUT / f"{name}_{i}.png", optimize=True)
    print(f"{name}: {len(frames)} frames, {frames[0].size}")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    save(canvas(split(load("Male Walk In.png")), BODY_H)[0], "walkin")
    save(canvas(split(load("Male Walk Out.png")), BODY_H)[0], "walkout")
    save(canvas(split(load("Male Give Water.png")), BODY_H)[0], "give")
    save(canvas(split(load("Male Happy.png")), BODY_H)[0][:1], "happy")   # the jumping pose
    save(canvas(split(load("Male Sad.png")), BODY_H)[0], "sad")

    # Eye break: 5 glasses poses (0-4), then 3 head-and-shoulders "look around" poses (5-7).
    glasses, scale = canvas(split(load("Male glasses.png")), EYE_H)
    looks, _ = canvas(split(load("Male Look around.png")), EYE_H, scale * BUST_SCALE)
    w, h = glasses[0].size
    placed = []
    for f in looks:
        c = Image.new("RGBA", (w, h))
        c.paste(f, ((w - f.width) // 2, h - f.height))
        placed.append(c)
    save(glasses + placed, "eye")


if __name__ == "__main__":
    main()
