#!/usr/bin/env python3
"""Build the two artwork files the documentation site needs from images/mycolors.png.

WHAT IT PRODUCES
    docs/assets/emblem.png   the mark shown beside the site name in the masthead
    docs/assets/favicon.ico  the browser tab icon, at 16, 32 and 48 px

    Both are the radial tree cut out of the hand-drawn logo, and nothing else.
    The word "mycolors", the letters "TB" and the four bacilli are dropped.

WHY IT EXISTS
    The masthead already sets the name in type next to the mark, and Material
    draws that mark about 30 px wide. images/mycolors.png is a 2781 x 2093
    composition whose lettering occupies roughly the bottom third and the right
    quarter of the canvas, so at that width every letter of "mycolors" lands on
    under 4 px of height and comes out as grey mush beside a name that already
    says the same word. The tree does survive: it is 14 saturated colours in a
    radial fan, it is the part of the drawing that is about the palette, and it
    is still one recognisable object at 16 px.

    So the site does not use images/mycolors.png directly. It uses this cut of
    it, and this script is how the cut is made, rather than a cropped PNG
    appearing in the repository with no record of where it came from.

WHAT COUNTS AS THE TREE
    Ink is defined exactly as in make_dark_logo.py: in HSV, saturation < 0.12
    and value < 0.50. Everything else that is not fully transparent is colour.
    Under that rule the lettering, the bacilli and the tree's own central fork
    are all ink, and the 14 branches are all colour, so ink alone does not
    separate the tree from the writing. Distance does:

        every ink pixel of the central fork lies within 447.1 px of (1008.5, 806)
        the nearest ink pixel that is not the fork lies 799.5 px away

    That is a gap of 350 px with a single pixel in it, so the cut-off is not
    finely balanced. INK_KEEP_RADIUS sits at 600, in the middle of the gap. Ink
    inside the disc is the fork and is kept; ink outside it is the lettering and
    is made fully transparent.

WHY THE FORK IS REPAINTED GREY
    Material has one logo slot, not a light one and a dark one, and this site's
    two schemes give the masthead opposite grounds: white in light, black in
    dark. The fork is black ink, so it would disappear into the dark masthead,
    and white ink would disappear into the light one. Every other pixel of the
    tree is saturated colour and reads on both.

    The fork is therefore repainted a single neutral grey, chosen to balance the
    two contrast ratios rather than to favour either ground. The grounds were
    read off the built site rather than assumed: with `primary: white` the light
    masthead is #ffffff, and with `primary: black` the dark one is #14151a, not
    the #000000 the setting's name suggests. Balanced against those two,

        #7a7a7a   4.29:1 on #ffffff   4.25:1 on #14151a   4.89:1 on #000000

    which is as level as an 8 bit grey gets; #757575 reaches 4.61:1 on white at
    the cost of 3.96:1 on the dark masthead, and #808080 trades the other way.
    All of them clear the 3:1 that WCAG asks of a graphic. Pure black is measured
    too, and not because any masthead is black: it is the darkest ground a
    browser tab strip can put behind the favicon, which this script never sees.

    The repaint is flat rather than shaded. The fork's strokes are antialiased
    through the alpha channel, which is copied unchanged, so the edges stay
    smooth; the value differences inside the stroke are not resolvable at 30 px
    and are not worth carrying.

SIZES
    emblem.png is 384 px wide. Material draws it at 1.6rem tall, so 384 covers a
    4x display with room to spare, and the file is small enough that widening it
    later costs nothing.

    favicon.ico carries three square entries, 16, 32 and 48 px, each rendered
    here from the full resolution cut rather than left to the browser to derive
    from one another. A tab asks for 16 on a 1x display and 32 on a 2x one, and
    a bookmark bar or a pinned tab asks for 48.

    Squaring matters for the icon and not for the masthead: the cut is 1.22:1,
    and a browser handed a non-square icon for a square slot decides for itself
    what to do with it. The padding here decides it once, the same way
    everywhere, and costs nothing, since the width is what binds either way.

WHY THE ICON'S ALPHA IS BOOSTED AND THE MASTHEAD'S IS NOT
    Downscaling a line drawing multiplies each stroke's alpha by the fraction of
    the destination pixel it covers. The cut is 2229 px across and a branch is a
    few pixels wide, so at 16 px a branch covers a small part of one pixel and
    arrives at a small part of its opacity: the mark fades to a pale wash on a
    light tab strip while the ground shows through it. Raising alpha to the power
    ICON_ALPHA_GAMMA after the resample gives the strokes their weight back
    without widening them. 0.6 was chosen against 0.75, which barely moves, and
    0.45, which starts closing the gaps between neighbouring branches so the fan
    reads as a blob. The script prints the mean alpha before and after so the
    effect is a number and not a claim.

    The masthead mark needs none of this. It is drawn about 39 px wide, where a
    branch still covers whole pixels, and it comes out saturated on both
    grounds.

USAGE
    python3 .github/scripts/make_docs_emblem.py

    Runs from anywhere; paths are resolved relative to the repository root. The
    script rebuilds both files and then verifies its own output, printing the
    pixel counts, the measured fork radius and the contrast ratios. Requires
    numpy and Pillow.
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image, PngImagePlugin

REPO = Path(__file__).resolve().parents[2]
SRC = REPO / "images" / "mycolors.png"
EMBLEM = REPO / "docs" / "assets" / "emblem.png"
FAVICON = REPO / "docs" / "assets" / "favicon.ico"

# Ink rule, identical to make_dark_logo.py. See that script for the check
# against all 14 lineage colours: none of them is caught by it.
INK_MAX_SATURATION = 0.12
INK_MAX_VALUE = 0.50

# The central fork, in source pixel coordinates. Measured, not eyeballed: see
# the module docstring for the 447.1 px / 799.5 px separation this sits between.
FORK_CENTRE = (1008.5, 806.0)
INK_KEEP_RADIUS = 600.0

# The grey the fork is repainted, and the grounds it has to hold on. The two
# mastheads were measured in a browser on the built site; pure black stands for
# the darkest tab strip a browser might put behind the favicon.
FORK_GREY = (0x7a, 0x7a, 0x7a)
GROUNDS = [
    ("light masthead", "#ffffff"),
    ("dark masthead", "#14151a"),
    ("tab strip, darkest", "#000000"),
]

EMBLEM_WIDTH = 384
FAVICON_SIZES = (48, 32, 16)
ICON_ALPHA_GAMMA = 0.6


# ---------------------------------------------------------------- colour maths

def rgb_to_sv(rgb_u8):
    """Saturation and value of 8 bit RGB of shape (h, w, 3), as floats in [0, 1]."""
    rgb = rgb_u8.astype(np.float64) / 255.0
    mx = rgb.max(axis=-1)
    mn = rgb.min(axis=-1)
    s = np.where(mx > 0, (mx - mn) / np.where(mx > 0, mx, 1.0), 0.0)
    return s, mx


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


def contrast_ratio(fg, bg):
    """WCAG 2.1 contrast ratio between two opaque colours given as RGB triples."""
    lighter = max(relative_luminance(fg), relative_luminance(bg))
    darker = min(relative_luminance(fg), relative_luminance(bg))
    return (lighter + 0.05) / (darker + 0.05)


# ------------------------------------------------------------------- transform

def cut_tree(pixels):
    """Return the emblem as RGBA, cropped, plus the measurements verify() reports."""
    rgb = pixels[..., :3]
    alpha = pixels[..., 3]
    visible = alpha > 0

    s, v = rgb_to_sv(rgb)
    ink = (s < INK_MAX_SATURATION) & (v < INK_MAX_VALUE) & visible
    colour = visible & ~ink

    rows, cols = np.indices(alpha.shape)
    distance = np.hypot(cols - FORK_CENTRE[0], rows - FORK_CENTRE[1])
    fork = ink & (distance <= INK_KEEP_RADIUS)
    lettering = ink & ~fork

    out = pixels.copy()
    out[..., :3][fork] = FORK_GREY
    # Dropping the lettering means dropping its alpha as well as its colour;
    # leaving black at alpha 0 would still darken any filter that resamples it.
    out[lettering] = 0

    kept = colour | fork
    ys, xs = np.nonzero(kept)
    box = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
    cropped = out[box[1]:box[3], box[0]:box[2]]

    measured = {
        "fork_max_radius": float(distance[ink & (distance <= INK_KEEP_RADIUS)].max()),
        "nearest_lettering": float(distance[lettering].min()),
        "colour": int(colour.sum()),
        "fork": int(fork.sum()),
        "lettering": int(lettering.sum()),
        "box": box,
    }
    return cropped, measured


def save_png(image, path, note):
    meta = PngImagePlugin.PngInfo()
    meta.add_text("Software", "mycolorsTB .github/scripts/make_docs_emblem.py")
    meta.add_text("Comment", note)
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=True, pnginfo=meta)


def icon_at(tree, size):
    """One square icon entry: fit the cut to `size`, pad, then boost the alpha."""
    height = max(1, round(size * tree.height / tree.width))
    small = np.asarray(tree.resize((size, height), Image.LANCZOS)).copy()

    before = float(small[..., 3].mean())
    alpha = (small[..., 3].astype(np.float64) / 255.0) ** ICON_ALPHA_GAMMA
    small[..., 3] = np.clip(np.rint(alpha * 255.0), 0, 255).astype(np.uint8)
    after = float(small[..., 3].mean())

    square = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    square.paste(Image.fromarray(small), (0, (size - height) // 2))
    return square, before, after


def build():
    source = Image.open(SRC).convert("RGBA")
    cropped, measured = cut_tree(np.asarray(source))

    tree = Image.fromarray(cropped)
    height = max(1, round(EMBLEM_WIDTH * tree.height / tree.width))
    emblem = tree.resize((EMBLEM_WIDTH, height), Image.LANCZOS)
    save_png(emblem, EMBLEM, "Radial tree cut from images/mycolors.png.")

    icons = []
    measured["alpha"] = {}
    for size in FAVICON_SIZES:
        icon, before, after = icon_at(tree, size)
        icons.append(icon)
        measured["alpha"][size] = (before, after)

    # Pillow writes one ICO from several images by matching each to a requested
    # size, so every entry is rendered from the full resolution cut instead of
    # being derived from the entry above it.
    FAVICON.parent.mkdir(parents=True, exist_ok=True)
    icons[0].save(FAVICON, format="ICO",
                  sizes=[(s, s) for s in FAVICON_SIZES],
                  append_images=icons[1:])

    return tree, measured


# ---------------------------------------------------------------- verification

def verify(tree, measured):
    ok = True
    print("source  %s  %dx%d" % (SRC.name, *Image.open(SRC).size))
    print("cut     %dx%d from box %s" % (tree.width, tree.height, measured["box"]))
    print()
    print("coloured pixels kept       %9d" % measured["colour"])
    print("fork ink kept, repainted   %9d" % measured["fork"])
    print("lettering ink dropped      %9d" % measured["lettering"])
    print()

    # 1. the disc separates the fork from the lettering with room to spare
    print("1. fork ink reaches       %7.1f px from %s" % (measured["fork_max_radius"], FORK_CENTRE))
    print("   nearest lettering ink  %7.1f px" % measured["nearest_lettering"])
    print("   radius in use          %7.1f px" % INK_KEEP_RADIUS)
    separated = measured["fork_max_radius"] < INK_KEEP_RADIUS < measured["nearest_lettering"]
    print("   the radius sits inside the gap                %s" % ("YES" if separated else "NO"))
    ok &= separated

    # 2. no ink survives except the repainted fork. The fork grey is itself
    # neutral and below the value cut, so it has to be excluded by hand: the
    # question this asks is whether any *original* ink is still in the cut.
    pixels = np.asarray(tree)
    s, v = rgb_to_sv(pixels[..., :3])
    grey = np.all(pixels[..., :3] == np.array(FORK_GREY, np.uint8), axis=-1)
    ink_left = (s < INK_MAX_SATURATION) & (v < INK_MAX_VALUE) & (pixels[..., 3] > 0) & ~grey
    stray = int(ink_left.sum())
    print()
    print("2. original ink left in the cut                  %d" % stray)
    ok &= stray == 0

    # 3. the repaint covered the fork and nothing else
    repainted = int((grey & (pixels[..., 3] > 0)).sum())
    print("3. pixels carrying the fork grey                 %d   fork ink %d   %s"
          % (repainted, measured["fork"],
             "MATCH" if repainted == measured["fork"] else "MISMATCH"))
    ok &= repainted == measured["fork"]

    # 4. contrast of that grey against every ground the mark is drawn on
    print()
    print("4. fork grey #%02x%02x%02x" % FORK_GREY)
    for name, ground in GROUNDS:
        bg = tuple(int(ground.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4))
        ratio = contrast_ratio(FORK_GREY, bg)
        print("      vs %-20s %-9s  %5.2f:1  %s"
              % (name, ground, ratio, "PASS" if ratio >= 3.0 else "FAIL"))
        ok &= ratio >= 3.0

    # 5. the alpha boost did something, and the icon carries every size asked for
    print()
    for size, (before, after) in sorted(measured["alpha"].items()):
        print("5. icon %2dpx  mean alpha %6.2f -> %6.2f  (gamma %.2f)"
              % (size, before, after, ICON_ALPHA_GAMMA))
        ok &= after > before

    with Image.open(FAVICON) as out:
        written = sorted(out.ico.sizes())
    wanted = sorted((s, s) for s in FAVICON_SIZES)
    print("   favicon.ico entries %s   %s"
          % (written, "MATCH" if written == wanted else "MISSING %s" % wanted))
    ok &= written == wanted

    # 6. what shipped
    print()
    with Image.open(EMBLEM) as out:
        print("6. %-16s %dx%d  %d bytes" % (EMBLEM.name, out.width, out.height, EMBLEM.stat().st_size))
    print("6. %-16s %d bytes" % (FAVICON.name, FAVICON.stat().st_size))

    print()
    print("VERIFY: %s" % ("PASS" if ok else "FAIL"))
    return ok


def main():
    if not SRC.is_file():
        sys.exit("missing source image: %s" % SRC)
    tree, measured = build()
    if not verify(tree, measured):
        sys.exit("verification failed")


if __name__ == "__main__":
    main()
