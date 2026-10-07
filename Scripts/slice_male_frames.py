#!/usr/bin/env python3
"""Slice the male sprite sheets in Frames/ into Sources/TinyNudges/Resources/male/<name>_<n>.png.

Each sheet is a row of transparent-background poses; Frames/Specific.png holds the eye-break poses and "Male Cool pose .png" the standing pose. Frames of one sequence share a canvas
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
BUST_SCALE = 1.2              # head-and-shoulders frames drawn this much larger than the full-body scale

# Where each eye-break pose sits on Frames/Specific.png: (x0, x1, y0, y1) in pixels.
EYE_BOXES = [(0, 275, 388, 724), (190, 385, 388, 640), (380, 560, 388, 640), (556, 726, 388, 640),
             (726, 906, 388, 640), (900, 1096, 388, 640), (1096, 1280, 388, 640), (1280, 1470, 405, 640)]
LAPTOP_BOX = (1540, 1950, 100, 400)    # lying down with the laptop: the pose she holds while asking
STRETCH_BOX = (1895, 2171, 0, 421)     # the big yawn


def load(name):
    im = np.array(Image.open(SRC / name).convert("RGBA"))
    im[im[..., 3] < 24] = 0   # drop faint glow/halo pixels
    # drop stray specks (leftovers at the sheet edges) that would stretch the frame's bounding box
    labels, n = ndimage.label(im[..., 3] > 0, structure=np.ones((3, 3)))
    sizes = ndimage.sum(np.ones_like(labels), labels, range(1, n + 1))
    for i, size in enumerate(sizes, start=1):
        if size < 150: im[labels == i] = 0
    return im


def cutout(name):
    """An image with an opaque light background (the cool pose): make the background transparent."""
    rgb = np.array(Image.open(SRC / name).convert("RGB")).astype(int)
    pale = ((rgb.max(2) - rgb.min(2)) < 28) & (rgb.mean(2) > 95)   # grey-white, unlike skin, khaki or boots
    labels, n = ndimage.label(pale)
    edge = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]]))) - {0}
    below_waist = {i for i, c in enumerate(ndimage.center_of_mass(pale, labels, range(1, n + 1)), start=1)
                   if c[0] > rgb.shape[0] * 0.65}   # pale gaps between the legs (the shirt is higher up)
    bg = np.isin(labels, list(edge | below_waist))
    alpha = ndimage.binary_erosion(~bg, iterations=1)   # trim the light fringe
    return np.dstack([rgb.astype(np.uint8), alpha.astype(np.uint8) * 255])


def split(im):
    """One image per run of non-empty columns."""
    cols = (im[..., 3] > 0).any(axis=0)
    runs, start = [], None
    for x, on in enumerate(cols):
        if on and start is None: start = x
        if not on and start is not None: runs.append((start, x)); start = None
    if start is not None: runs.append((start, len(cols)))
    return [im[:, a:b] for a, b in runs]


def pose(im, box):
    """The one pose inside `box`: its biggest blob, plus any small bits (sparkles, '?') right next to it."""
    x0, x1, y0, y1 = box
    crop = im[y0:y1, x0:x1].copy()
    near = ndimage.binary_dilation(crop[..., 3] > 0, iterations=3)
    labels, n = ndimage.label(near, structure=np.ones((3, 3)))
    areas = ndimage.sum(crop[..., 3] > 0, labels, range(1, n + 1))
    main = int(np.argmax(areas)) + 1
    close = ndimage.binary_dilation(labels == main, iterations=40)
    for i, area in enumerate(areas, start=1):
        blob = labels == i
        on_edge = blob[0].any() or blob[-1].any() or blob[:, 0].any() or blob[:, -1].any()   # a neighbour's edge
        keep = i == main or (area < 2500 and not on_edge and (close & blob).any())
        if not keep: crop[labels == i] = 0
    return crop


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


def mirrored(frames):
    return [f.transpose(Image.FLIP_LEFT_RIGHT) for f in frames]


def save(frames, name):
    for i, f in enumerate(frames):
        f.save(OUT / f"{name}_{i}.png", optimize=True)
    print(f"{name}: {len(frames)} frames, {frames[0].size}")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    # He enters from the right edge walking left and leaves to the right; the sheets face the other way.
    save(mirrored(canvas(split(load("Male Walk In.png")), BODY_H)[0]), "walkin")
    save(mirrored(canvas(split(load("Male Walk Out.png")), BODY_H)[0]), "walkout")
    save(canvas(split(load("Male Give Water.png")), BODY_H)[0], "give")
    save(canvas(split(load("Male Happy.png")), BODY_H)[0][:1], "happy")   # the jumping pose
    save(canvas(split(load("Male Sad.png")), BODY_H)[0], "sad")

    sheet = load("Specific.png")
    save(canvas([pose(cutout("Male Cool pose .png"), (0, 296, 0, 556))], BODY_H)[0], "idle")   # hands in pockets: the pose he strikes while talking

    # Eye break: 8 poses (0 = full body, 1-7 head-and-shoulders), then the laptop and yawn poses.
    eyes = [pose(sheet, b) for b in EYE_BOXES]
    full, scale = canvas(eyes[:1], EYE_H)
    busts, _ = canvas(eyes[1:], EYE_H, scale * BUST_SCALE)
    w, h = max(f.width for f in full + busts), full[0].height
    placed = []
    for f in full + busts:   # one shared canvas so the character doesn't jump between poses
        c = Image.new("RGBA", (w, h))
        c.paste(f, ((w - f.width) // 2, h - f.height))
        placed.append(c)
    save(placed, "eye")
    save(canvas([pose(sheet, LAPTOP_BOX)], EYE_H)[0] + canvas([pose(sheet, STRETCH_BOX)], EYE_H)[0], "relax")


if __name__ == "__main__":
    main()
