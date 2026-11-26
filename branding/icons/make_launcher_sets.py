"""Turns a generated 1024 icon into a launcher-ready set.
Run: python3 make_launcher_sets.py

Per icon, in final_<name>/:
  icon_1024.png        full-bleed master (App Store, legacy Android, splash)
  play_512.png         Play Store listing icon
  foreground_1024.png  adaptive foreground: the art shrunk into the safe zone,
                       with its own background extended to the edges
  monochrome_1024.png  white silhouette for Android themed icons
  background.txt       colour behind the foreground
"""
import os
import numpy as np
from PIL import Image, ImageFilter, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))

# name, source, subject box (fractions: left, top, right, bottom), silhouette rule,
# optional other image to take the silhouette from
ICONS = [
    ('coin_ink', 'gen_d/d1_coin_ink.png', (0.19, 0.19, 0.82, 0.82), 'bright', None),
    ('coin_ink_green', 'gen_d/d3_coin_ink_green_bars.png', (0.19, 0.19, 0.82, 0.82), 'bright', None),
    # Cream on cream has no clean silhouette, so it borrows the ink one's.
    ('coin_cream', 'gen_d/d2_coin_cream.png', (0.19, 0.19, 0.82, 0.82), 'bright', 'gen_d/d1_coin_ink.png'),
    ('stack_ink', 'gen_d/d4_stack_ink.png', (0.23, 0.23, 0.76, 0.76), 'bright', None),
    ('receipt_coin_green', 'gen_a/a1_receipt_coin.png', (0.19, 0.19, 0.82, 0.82), 'not_green', None),
    ('invoice_stack_navy', 'gen_c/c4_bill_stack.png', (0.23, 0.23, 0.76, 0.76), 'bright', None),
]


def extend(img, box, fill):
    """Recentres the subject and shrinks it so its box spans `fill` of the
    canvas, growing the picture's own background out to the edges."""
    n = img.width
    l, t, r, b = box
    scale = fill / max(r - l, b - t)
    size = int(round(n * scale))
    small = img.resize((size, size), Image.LANCZOS)
    cx, cy = (l + r) / 2 * size, (t + b) / 2 * size
    ox, oy = int(round(n / 2 - cx)), int(round(n / 2 - cy))
    big = n * 3
    canvas = np.zeros((big, big, 3), dtype=np.uint8)
    arr = np.asarray(small.convert('RGB'))
    x0, y0 = n + ox, n + oy
    canvas[y0:y0 + size, x0:x0 + size] = arr
    # Replicate the edge rows and columns outward, then soften the streaks.
    canvas[:y0, x0:x0 + size] = arr[0:1]
    canvas[y0 + size:, x0:x0 + size] = arr[-1:]
    canvas[:, :x0] = canvas[:, x0:x0 + 1]
    canvas[:, x0 + size:] = canvas[:, x0 + size - 1:x0 + size]
    full = Image.fromarray(canvas)
    blurred = full.filter(ImageFilter.GaussianBlur(60))
    mask = Image.new('L', (big, big), 255)
    ImageDraw.Draw(mask).rectangle([x0 + 24, y0 + 24, x0 + size - 24, y0 + size - 24], fill=0)
    mask = mask.filter(ImageFilter.GaussianBlur(24))
    full.paste(blurred, (0, 0), mask)
    return full.crop((n, n, 2 * n, 2 * n))


def silhouette(img, rule):
    a = np.asarray(img.convert('RGB')).astype(np.float32) / 255
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    if rule == 'not_green':
        # Paper and coin are warm; the ground and the ruled bars are green.
        m = (r > g * 0.92) & (r > 0.35)
    else:
        # Paper and gold are bright in at least one channel; ink ground and
        # ruled bars are not.
        m = np.maximum(np.maximum(r, g), b) > 0.5
    mask = Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.MedianFilter(9)).filter(ImageFilter.GaussianBlur(1.2))
    out = Image.new('RGBA', img.size, (255, 255, 255, 0))
    out.putalpha(mask)
    return out


def main():
    cell, pad = 300, 36
    sheet = Image.new('RGB', (pad + (cell + pad) * 4, pad + (cell + pad) * len(ICONS)), (236, 232, 224))
    for row, (name, src, box, rule, mono_src) in enumerate(ICONS):
        out = os.path.join(HERE, 'final_' + name)
        os.makedirs(out, exist_ok=True)
        img = Image.open(os.path.join(HERE, src)).convert('RGB')
        icon = extend(img, box, 0.66)       # a touch more air than the raw render
        fg = extend(img, box, 0.46)         # inside the adaptive safe zone
        mono_base = fg if mono_src is None else extend(Image.open(os.path.join(HERE, mono_src)).convert('RGB'), box, 0.46)
        mono = silhouette(mono_base, rule)
        icon.save(os.path.join(out, 'icon_1024.png'))
        icon.resize((512, 512), Image.LANCZOS).save(os.path.join(out, 'play_512.png'))
        fg.save(os.path.join(out, 'foreground_1024.png'))
        mono.save(os.path.join(out, 'monochrome_1024.png'))
        edge = np.asarray(fg)[[0, -1], :, :].reshape(-1, 3).mean(axis=0).astype(int)
        with open(os.path.join(out, 'background.txt'), 'w') as f:
            f.write('#%02X%02X%02X\n' % tuple(edge))

        # Preview: iOS squircle, Android circle and squircle (adaptive crop), themed.
        crop = fg.crop((171, 171, 853, 853))  # the 72/108 a launcher shows
        themed = Image.new('RGBA', crop.size, (214, 227, 255, 255))
        mcrop = mono.crop((171, 171, 853, 853))
        themed.paste(Image.new('RGBA', crop.size, (20, 40, 90, 255)), (0, 0), mcrop.split()[3])
        for col, (src_img, shape) in enumerate([(icon, 'sq'), (crop, 'circle'), (crop, 'sq'), (themed, 'sq')]):
            big = src_img.convert('RGBA').resize((cell * 2, cell * 2), Image.LANCZOS)
            m = Image.new('L', big.size, 0)
            d = ImageDraw.Draw(m)
            if shape == 'circle':
                d.ellipse([0, 0, cell * 2, cell * 2], fill=255)
            else:
                d.rounded_rectangle([0, 0, cell * 2, cell * 2], radius=cell * 0.45, fill=255)
            tile = Image.new('RGBA', big.size, (0, 0, 0, 0))
            tile.paste(big, (0, 0), m)
            tile = tile.resize((cell, cell), Image.LANCZOS)
            sheet.paste(tile, (pad + col * (cell + pad), pad + row * (cell + pad)), tile)
    sheet.save(os.path.join(HERE, 'preview_final.png'))


if __name__ == '__main__':
    main()
