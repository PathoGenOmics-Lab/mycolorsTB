#!/usr/bin/env python3
"""Build images/mycolors_dark.png, the dark-theme variant of images/mycolors.png.

WHAT IT PRODUCES
    images/mycolors_dark.png, a pixel-for-pixel copy of the hand-drawn mycolorsTB
    logo in which only the neutral dark ink has been lightened. Every coloured
    pixel and the whole alpha channel are carried over unchanged.

WHY IT EXISTS
    images/mycolors.png has a transparent background. The word "mycolors", the
    letters "TB", the drawn bacilli and the central branches of the tree are
    black ink, so they disappear when GitHub renders the README on a dark
    canvas. The README pairs the two files with a <picture> element whose dark
    source points at this file:

        <picture>
          <source media="(prefers-color-scheme: dark)"
                  srcset="https://raw.githubusercontent.com/PathoGenOmics-Lab/mycolorsTB/main/images/mycolors_dark.png">
          <img alt="..." src="https://raw.githubusercontent.com/PathoGenOmics-Lab/mycolorsTB/main/images/mycolors.png">
        </picture>

    Those URLs are absolute, and deliberately so: README.md ships inside the CRAN
    source tarball while images/ does not, because of ^images$ in .Rbuildignore.
    A relative path would resolve to nothing for anyone reading the installed
    package. Do not "tidy" them into relative paths.

    The light file keeps its current name and is not modified.

HOW IT DECIDES WHAT IS INK
    A pixel is ink when, in HSV, saturation < 0.12 and value < 0.50. That rule
    was checked against all 14 lineage colours of the package palette and none
    of them is caught by it. The closest calls are L5 #995200 (v = 0.600, above
    the value cut) and L10 #8fbda1 (s = 0.243, above the saturation cut).

HOW IT RECOLOURS
    An ink pixel keeps its hue and saturation and has its HSV value inverted,
    v -> 1 - v, so black becomes white and any lighter grey stays proportionally
    shaded instead of collapsing to a flat tone. Alpha is copied byte for byte,
    which matters because the drawing is antialiased through the alpha channel
    and roughly three quarters of the canvas is fully transparent, so any change
    to alpha would show up as a halo.

WHY THE CEILING IS PURE WHITE AND NOT GITHUB'S #e6edf3
    Measured with WCAG 2.1 relative luminance, white beats GitHub's dark
    foreground on every dark canvas GitHub ships:

        canvas                      #ffffff    #e6edf3
        dark default   #0d1117      18.92:1    16.02:1
        dark dimmed    #22272e      15.02:1    12.72:1
        dark high con. #010409      20.54:1    17.38:1

    White is also the closer mirror of the light variant, where black ink on
    #ffffff reaches 21.00:1: white recovers 90.1 percent of that on the default
    dark canvas against 76.3 percent for #e6edf3. Two further reasons: #e6edf3
    is not neutral (s = 0.0535, a blue cast), so using it as a ceiling would
    inject a hue into strokes the ink rule defines as hueless; and it is the
    foreground of GitHub's dark *default* theme only, while this PNG is a fixed
    asset that also renders on dimmed, on high contrast and outside GitHub.

USAGE
    python3 .github/scripts/make_dark_logo.py

    Runs from anywhere; paths are resolved relative to the repository root. The
    script rebuilds the file and then verifies its own output, printing the
    pixel counts and contrast ratios it measured. Requires numpy and Pillow.
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image, PngImagePlugin

REPO = Path(__file__).resolve().parents[2]
SRC = REPO / "images" / "mycolors.png"
DST = REPO / "images" / "mycolors_dark.png"

# Verified ink rule. See the module docstring for the palette check behind it.
INK_MAX_SATURATION = 0.12
INK_MAX_VALUE = 0.50

# Canvases the result is measured against.
CANVAS_LIGHT = "#ffffff"
CANVASES_DARK = [
    ("dark default", "#0d1117"),
    ("dark dimmed", "#22272e"),
    ("dark high contrast", "#010409"),
]


# ---------------------------------------------------------------- colour maths

def rgb_to_hsv(rgb):
    """Vectorised RGB to HSV. Input and output are floats in [0, 1].

    Matches colorsys.rgb_to_hsv, including its convention that hue is 0 and
    saturation is 0 for greys.
    """
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx = rgb.max(axis=-1)
    mn = rgb.min(axis=-1)
    delta = mx - mn

    v = mx
    s = np.where(mx > 0, delta / np.where(mx > 0, mx, 1.0), 0.0)

    safe = np.where(delta > 0, delta, 1.0)
    rc = (mx - r) / safe
    gc = (mx - g) / safe
    bc = (mx - b) / safe
    h = np.where(mx == r, bc - gc, np.where(mx == g, 2.0 + rc - bc, 4.0 + gc - rc))
    h = np.where(delta > 0, (h / 6.0) % 1.0, 0.0)
    return h, s, v


def hsv_to_rgb(h, s, v):
    """Vectorised HSV to RGB. Input and output are floats in [0, 1]."""
    i = np.floor(h * 6.0).astype(np.int64)
    f = h * 6.0 - i
    i = np.mod(i, 6)

    p = v * (1.0 - s)
    q = v * (1.0 - s * f)
    t = v * (1.0 - s * (1.0 - f))

    cases = np.stack(
        [
            np.stack([v, t, p], axis=-1),
            np.stack([q, v, p], axis=-1),
            np.stack([p, v, t], axis=-1),
            np.stack([p, q, v], axis=-1),
            np.stack([t, p, v], axis=-1),
            np.stack([v, p, q], axis=-1),
        ],
        axis=0,
    )
    idx = np.broadcast_to(i[np.newaxis, ..., np.newaxis], (1,) + i.shape + (3,))
    out = np.take_along_axis(cases, idx, axis=0)[0]

    grey = np.broadcast_to(v[..., np.newaxis], out.shape)
    return np.where((s <= 0.0)[..., np.newaxis], grey, out)


def _channel_luminance(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4


def relative_luminance(rgb):
    r, g, b = rgb
    return (
        0.2126 * _channel_luminance(r)
        + 0.7152 * _channel_luminance(g)
        + 0.0722 * _channel_luminance(b)
    )


def parse_hex(value):
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def contrast_ratio(fg, bg):
    """WCAG 2.1 contrast ratio between two opaque colours given as RGB triples."""
    lighter = max(relative_luminance(fg), relative_luminance(bg))
    darker = min(relative_luminance(fg), relative_luminance(bg))
    return (lighter + 0.05) / (darker + 0.05)


# ------------------------------------------------------------------- transform

def ink_mask(rgb_u8):
    """Boolean mask of the neutral dark ink, from 8 bit RGB of shape (h, w, 3)."""
    _, s, v = rgb_to_hsv(rgb_u8.astype(np.float64) / 255.0)
    return (s < INK_MAX_SATURATION) & (v < INK_MAX_VALUE)


def build(src_path, dst_path):
    source = Image.open(src_path)
    dpi = source.info.get("dpi")
    source = source.convert("RGBA")
    pixels = np.asarray(source)

    rgb = pixels[..., :3]
    alpha = pixels[..., 3]
    mask = ink_mask(rgb)

    # Invert the HSV value of the ink, keeping hue and saturation.
    h, s, v = rgb_to_hsv(rgb[mask].astype(np.float64) / 255.0)
    lifted = hsv_to_rgb(h, s, 1.0 - v)
    lifted = np.clip(np.rint(lifted * 255.0), 0, 255).astype(np.uint8)

    out = pixels.copy()
    out[..., :3][mask] = lifted
    # Alpha is never touched: out was copied from pixels and only RGB was written.

    result = Image.fromarray(out)  # already uint8 RGBA, mode is inferred
    meta = PngImagePlugin.PngInfo()
    meta.add_text("Software", "mycolorsTB .github/scripts/make_dark_logo.py")

    save_kwargs = {"optimize": True, "pnginfo": meta}
    if dpi is not None:
        save_kwargs["dpi"] = dpi
    result.save(dst_path, format="PNG", **save_kwargs)
    return mask


# ---------------------------------------------------------------- verification

def verify(src_path, dst_path, mask):
    before = np.asarray(Image.open(src_path).convert("RGBA"))
    after = np.asarray(Image.open(dst_path).convert("RGBA"))

    ok = True
    total = before.shape[0] * before.shape[1]
    visible = before[..., 3] > 0
    ink_count = int(mask.sum())

    print("source %s  %dx%d" % (src_path.name, before.shape[1], before.shape[0]))
    print("output %s  %dx%d" % (dst_path.name, after.shape[1], after.shape[0]))
    print()
    print("pixels total          %9d" % total)
    print("fully transparent     %9d  %5.2f%%" % ((~visible).sum(), 100 * (~visible).sum() / total))
    print("visible               %9d" % visible.sum())
    print("ink (rule s<%.2f v<%.2f) %6d  %5.2f%% of visible"
          % (INK_MAX_SATURATION, INK_MAX_VALUE, ink_count, 100 * ink_count / visible.sum()))
    print("coloured, visible     %9d  %5.2f%% of visible"
          % ((visible & ~mask).sum(), 100 * (visible & ~mask).sum() / visible.sum()))
    print()

    # 1. exactly the ink pixels changed
    changed = np.any(before[..., :3] != after[..., :3], axis=-1)
    changed_count = int(changed.sum())
    print("1. RGB changed pixels  %9d   ink pixels %9d   %s"
          % (changed_count, ink_count, "MATCH" if changed_count == ink_count else "MISMATCH"))
    stray = int((changed & ~mask).sum())
    missed = int((~changed & mask).sum())
    print("   changed outside ink mask %d, ink left unchanged %d" % (stray, missed))
    ok &= changed_count == ink_count and stray == 0 and missed == 0

    # 2. every coloured pixel byte identical
    coloured = ~mask
    identical = np.array_equal(before[..., :3][coloured], after[..., :3][coloured])
    print("2. coloured pixels byte identical            %s" % ("YES" if identical else "NO"))
    ok &= identical

    # 3. alpha identical
    alpha_same = np.array_equal(before[..., 3], after[..., 3])
    print("3. alpha channel byte identical              %s" % ("YES" if alpha_same else "NO"))
    ok &= alpha_same

    # 4. contrast
    opaque_ink = mask & (before[..., 3] == 255)
    brightest = after[..., :3][opaque_ink]
    brightest = brightest[np.argmax(brightest.astype(np.int64).sum(axis=-1))]
    brightest = tuple(int(c) for c in brightest)
    print()
    print("4. brightest fully opaque ink in the dark variant  #%02x%02x%02x" % brightest)
    for name, canvas in CANVASES_DARK:
        print("      vs %-20s %-9s  %6.2f:1"
              % (name, canvas, contrast_ratio(brightest, parse_hex(canvas))))
    darkest = before[..., :3][opaque_ink]
    darkest = darkest[np.argmin(darkest.astype(np.int64).sum(axis=-1))]
    darkest = tuple(int(c) for c in darkest)
    print("   darkest fully opaque ink in the light variant   #%02x%02x%02x" % darkest)
    print("      vs %-20s %-9s  %6.2f:1"
          % ("light", CANVAS_LIGHT, contrast_ratio(darkest, parse_hex(CANVAS_LIGHT))))

    # 5. file size
    src_bytes = src_path.stat().st_size
    dst_bytes = dst_path.stat().st_size
    print()
    print("5. file size  light %d bytes, dark %d bytes, %+.1f%%"
          % (src_bytes, dst_bytes, 100 * (dst_bytes - src_bytes) / src_bytes))

    print()
    print("VERIFY: %s" % ("PASS" if ok else "FAIL"))
    return ok


def main():
    if not SRC.is_file():
        sys.exit("missing source image: %s" % SRC)
    mask = build(SRC, DST)
    if not verify(SRC, DST, mask):
        sys.exit("verification failed")


if __name__ == "__main__":
    main()
