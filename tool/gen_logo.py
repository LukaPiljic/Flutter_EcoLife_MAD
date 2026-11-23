"""Generates the EcoLife app logo (a leaf on a green badge).

Outputs:
  assets/icon/ecolife_logo.png            -> 1024x1024 full-bleed icon
  assets/icon/ecolife_logo_foreground.png -> 1024x1024 transparent leaf (Android adaptive foreground)

Run: python3 tool/gen_logo.py
"""
import math
import os
from PIL import Image, ImageDraw, ImageChops, ImageFilter

SS = 4                # supersample factor for smooth edges
S = 1024
W = S * SS

PRIMARY = (46, 125, 50)      # #2E7D32
PRIMARY_DARK = (0, 80, 5)    # #005005
ACCENT = (102, 187, 106)     # #66BB6A
LEAF_LIGHT = (220, 245, 222)
WHITE = (255, 255, 255)


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def vertical_gradient(size, top, bottom):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        c = lerp(top, bottom, y / (size - 1))
        for x in range(size):
            px[x, y] = c
    return img


def leaf_mask(size):
    """A vertical leaf (lens) shape, pointed top & bottom, rotated to lean.

    Proportions chosen so the rotated lens stays fully inside the canvas
    (height ~0.82, width ~0.45 of size) -> sharp, un-clipped tips.
    """
    R = size * 0.486
    sep = size * 0.522            # horizontal distance between the two circle centers
    cx, cy = size / 2, size / 2
    c1 = Image.new("L", (size, size), 0)
    c2 = Image.new("L", (size, size), 0)
    ImageDraw.Draw(c1).ellipse(
        [cx - sep / 2 - R, cy - R, cx - sep / 2 + R, cy + R], fill=255)
    ImageDraw.Draw(c2).ellipse(
        [cx + sep / 2 - R, cy - R, cx + sep / 2 + R, cy + R], fill=255)
    lens = ImageChops.darker(c1, c2)   # intersection
    lens = lens.rotate(-32, resample=Image.BICUBIC, expand=False)
    return lens


def build_leaf(size):
    """Returns an RGBA leaf image: gradient fill + midrib + veins."""
    mask = leaf_mask(size)

    # leaf body: gradient from accent (base) to light (tip)
    body = Image.new("RGB", (size, size))
    px = body.load()
    for y in range(size):
        c = lerp(ACCENT, LEAF_LIGHT, y / (size - 1))
        for x in range(size):
            px[x, y] = c

    leaf = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    leaf.paste(body, (0, 0), mask)

    # veins drawn onto a layer, then clipped to the leaf mask
    veins = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    vd = ImageDraw.Draw(veins)
    cx, cy = size / 2, size / 2
    ang = math.radians(-32)
    # unit vectors: along the leaf's long axis (base->tip) and perpendicular
    ax, ay = math.sin(ang), -math.cos(ang)     # along axis (points toward tip)
    px, py = math.cos(ang), math.sin(ang)      # perpendicular
    L = size * 0.40
    bx0, by0 = cx - ax * L, cy - ay * L         # base
    tx0, ty0 = cx + ax * L, cy + ay * L         # tip
    vd.line([(bx0, by0), (tx0, ty0)], fill=(255, 255, 255, 160),
            width=int(size * 0.016))
    # symmetric side veins, opening toward the tip
    for t in (0.22, 0.44, 0.66):
        mx = bx0 + (tx0 - bx0) * t
        my = by0 + (ty0 - by0) * t
        span = size * 0.20 * (1 - t * 0.55)
        for s in (+1, -1):
            ex = mx + s * px * span + ax * span * 0.55
            ey = my + s * py * span + ay * span * 0.55
            vd.line([(mx, my), (ex, ey)], fill=(255, 255, 255, 120),
                    width=int(size * 0.009))
    veins.putalpha(ImageChops.darker(veins.getchannel("A"), mask))
    leaf = Image.alpha_composite(leaf, veins)
    return leaf


def main():
    out_dir = "assets/icon"
    os.makedirs(out_dir, exist_ok=True)

    # --- full-bleed icon: green gradient background + leaf ---
    bg = vertical_gradient(W, PRIMARY, PRIMARY_DARK).convert("RGBA")
    leaf = build_leaf(int(W * 0.74))
    # center the leaf
    off = (W - leaf.width) // 2
    icon = bg.copy()
    icon.alpha_composite(leaf, (off, off))
    icon = icon.resize((S, S), Image.LANCZOS)
    icon.convert("RGB").save(os.path.join(out_dir, "ecolife_logo.png"))

    # --- adaptive foreground: transparent bg, leaf within safe zone (~66%) ---
    fg = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    leaf_fg = build_leaf(int(W * 0.58))
    offf = (W - leaf_fg.width) // 2
    fg.alpha_composite(leaf_fg, (offf, offf))
    fg = fg.resize((S, S), Image.LANCZOS)
    fg.save(os.path.join(out_dir, "ecolife_logo_foreground.png"))

    print("wrote", os.path.join(out_dir, "ecolife_logo.png"))
    print("wrote", os.path.join(out_dir, "ecolife_logo_foreground.png"))


if __name__ == "__main__":
    main()
