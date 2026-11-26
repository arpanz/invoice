"""Draws the app icon options. Run: python3 make_icons.py

Each option gets a folder with:
  icon_1024.png        full-bleed square master (App Store, legacy Android)
  play_512.png         Play Store listing icon
  foreground_1024.png  adaptive-icon foreground (art inside the safe zone)
  monochrome_1024.png  adaptive-icon monochrome layer (themed icons)
  background.txt       adaptive-icon background colour
"""
import os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.join(HERE, '..', '..', 'assets', 'fonts')
SS = 3  # supersampling
U = 1000  # art is drawn in a 1000-unit box

INK = (31, 29, 26)
PAPER = (251, 248, 241)
CREAM = (244, 239, 228)
FOLD = (222, 213, 196)
RULE = (205, 196, 178)
GREEN = (46, 107, 63)
BLUE = (43, 76, 126)
WHITE = (255, 255, 255)


def font(name, size):
    return ImageFont.truetype(os.path.join(FONTS, name), size)


class Art:
    """A transparent layer in 1000-unit coordinates, scaled about the centre."""

    def __init__(self, px, k):
        self.n = px * SS
        self.k = k
        self.img = Image.new('RGBA', (self.n, self.n), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def p(self, v):  # unit -> pixel
        return (500 + (v - 500) * self.k) * self.n / U

    def s(self, v):  # unit length -> pixels
        return v * self.k * self.n / U

    def box(self, x0, y0, x1, y1):
        return [self.p(x0), self.p(y0), self.p(x1), self.p(y1)]

    def rrect(self, x0, y0, x1, y1, r, fill=None, outline=None, width=0):
        self.d.rounded_rectangle(self.box(x0, y0, x1, y1), radius=self.s(r), fill=fill,
                                 outline=outline, width=int(self.s(width)))

    def poly(self, pts, fill):
        self.d.polygon([(self.p(x), self.p(y)) for x, y in pts], fill=fill)

    def circle(self, cx, cy, r, fill):
        self.d.ellipse(self.box(cx - r, cy - r, cx + r, cy + r), fill=fill)

    def line(self, pts, fill, width):
        self.d.line([(self.p(x), self.p(y)) for x, y in pts], fill=fill, width=int(self.s(width)), joint='curve')
        for x, y in pts:  # round caps
            self.circle(x, y, width / 2, fill)

    def erase(self, draw_fn):
        """Cuts a shape out of the layer."""
        mask = Image.new('L', (self.n, self.n), 0)
        saved_img, saved_d = self.img, self.d
        self.img, self.d = mask, ImageDraw.Draw(mask)
        draw_fn(255)
        self.img, self.d = saved_img, saved_d
        clear = Image.new('RGBA', (self.n, self.n), (0, 0, 0, 0))
        self.img.paste(clear, (0, 0), mask)
        self.d = ImageDraw.Draw(self.img)

    def stamp(self, cx, cy, w, h, angle, text, color, font_name='Inter-SemiBold.ttf', stroke=13, cut=False):
        """A rubber stamp: outlined box with spaced capitals, set at an angle."""
        pad = 40
        W, H = int(self.s(w + pad * 2)), int(self.s(h + pad * 2))
        layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        o = self.s(pad)
        d.rounded_rectangle([o, o, W - o, H - o], radius=self.s(h * 0.2), outline=color, width=int(self.s(stroke)))
        f = font(font_name, int(self.s(h * 0.5)))
        spacing = self.s(h * 0.07)
        widths = [d.textlength(c, font=f) for c in text]
        total = sum(widths) + spacing * (len(text) - 1)
        x = (W - total) / 2
        asc, desc = f.getmetrics()
        bbox = f.getbbox(text)
        y = (H - (bbox[3] - bbox[1])) / 2 - bbox[1]
        for c, cw in zip(text, widths):
            d.text((x, y), c, font=f, fill=color)
            x += cw + spacing
        layer = layer.rotate(angle, resample=Image.BICUBIC, expand=True)
        pos = (int(self.p(cx) - layer.width / 2), int(self.p(cy) - layer.height / 2))
        if cut:
            clear = Image.new('RGBA', layer.size, (0, 0, 0, 0))
            self.img.paste(clear, pos, layer.split()[3])
        else:
            self.img.alpha_composite(layer, pos)
        self.d = ImageDraw.Draw(self.img)

    def text_center(self, cx, cy, text, font_name, size, fill):
        f = font(font_name, int(self.s(size)))
        b = f.getbbox(text)
        self.d.text((self.p(cx) - (b[0] + b[2]) / 2, self.p(cy) - (b[1] + b[3]) / 2), text, font=f, fill=fill)

    def done(self, px):
        return self.img.resize((px, px), Image.LANCZOS)


def sheet(a, fill, fold):
    """A sheet of paper with a folded corner."""
    x0, y0, x1, y1, c = 285, 180, 715, 820, 120
    a.rrect(x0, y0, x1, y1, 34, fill=fill)
    a.erase(lambda v: a.poly([(x1 - c, y0 - 5), (x1 + 5, y0 - 5), (x1 + 5, y0 + c)], v))
    if fold:
        a.poly([(x1 - c, y0), (x1, y0 + c), (x1 - c, y0 + c)], fold)


# ---- Option 1: the paid invoice (ink ground, paper sheet, green stamp) ----
def paid_sheet(a, mono=False):
    if mono:
        sheet(a, WHITE, None)
        a.erase(lambda v: a.rrect(345, 300, 520, 332, 16, fill=v))
        for y in (420, 480, 540):
            a.erase(lambda v, y=y: a.rrect(345, y, 655, y + 18, 9, fill=v))
        a.stamp(560, 690, 270, 112, 12, 'PAID', WHITE, stroke=16, cut=True)
        return
    sheet(a, PAPER, FOLD)
    a.rrect(345, 300, 520, 332, 16, fill=INK)
    for y in (420, 480, 540):
        a.rrect(345, y, 655, y + 18, 9, fill=RULE)
    a.stamp(560, 690, 270, 112, 12, 'PAID', GREEN, stroke=14)


# ---- Option 2: the receipt (cream ground, ink receipt, green tick) ----
def receipt(a, mono=False):
    body = WHITE if mono else INK
    x0, y0, x1, y1 = 300, 185, 700, 760
    a.rrect(x0, y0, x1, y1 + 20, 30, fill=body)
    teeth = 8
    tw = (x1 - x0) / teeth
    a.erase(lambda v: [a.poly([(x0 + i * tw, y1 + 30), (x0 + (i + 0.5) * tw, y1 - 22), (x0 + (i + 1) * tw, y1 + 30)], v)
                       for i in range(teeth)])
    cut = (lambda fn: a.erase(fn)) if mono else None
    def bar(xa, ya, xb, yb, col):
        if mono:
            a.erase(lambda v: a.rrect(xa, ya, xb, yb, (yb - ya) / 2, fill=v))
        else:
            a.rrect(xa, ya, xb, yb, (yb - ya) / 2, fill=col)
    bar(360, 280, 540, 312, PAPER)
    for y in (390, 450, 510):
        bar(360, y, 640, y + 18, (120, 113, 100))
    bar(500, 600, 640, 628, PAPER)
    # tick seal
    if mono:
        a.erase(lambda v: a.circle(690, 735, 150, v))
        a.circle(690, 735, 122, WHITE)
        a.erase(lambda v: a.line([(634, 738), (674, 778), (748, 696)], v, 32))
    else:
        a.circle(690, 735, 150, CREAM)
        a.circle(690, 735, 122, GREEN)
        a.line([(634, 738), (674, 778), (748, 696)], PAPER, 32)


# ---- Option 3: the stamp (cream ground, one big ink-blue stamp) ----
def big_stamp(a, mono=False):
    col = WHITE if mono else BLUE
    a.stamp(500, 500, 640, 330, 10, 'INV', col, font_name='Fraunces-SemiBold.ttf', stroke=30)


# ---- Option 4: the monogram (ink ground, serif I, green seal) ----
def monogram(a, mono=False):
    col = WHITE if mono else PAPER
    a.text_center(455, 500, 'I', 'Fraunces-SemiBold.ttf', 640, col)
    if mono:
        a.circle(668, 690, 62, WHITE)
    else:
        a.circle(668, 690, 62, (94, 168, 113))


OPTIONS = [
    ('1_paid_invoice', paid_sheet, INK, 1.12),
    ('2_receipt', receipt, CREAM, 1.10),
    ('3_stamp', big_stamp, CREAM, 1.0),
    ('4_monogram', monogram, INK, 1.0),
]


def render(fn, px, k, mono=False):
    a = Art(px, k)
    fn(a, mono)
    return a.done(px)


def build(options, preview_name):
    previews = []
    for name, fn, bg, k in options:
        out = os.path.join(HERE, name)
        os.makedirs(out, exist_ok=True)
        icon = Image.new('RGBA', (1024, 1024), bg + (255,))
        icon.alpha_composite(render(fn, 1024, k))
        icon.convert('RGB').save(os.path.join(out, 'icon_1024.png'))
        icon.convert('RGB').resize((512, 512), Image.LANCZOS).save(os.path.join(out, 'play_512.png'))
        # Adaptive layers: launchers crop to the middle ~61%, so art shrinks.
        render(fn, 1024, k * 0.60).save(os.path.join(out, 'foreground_1024.png'))
        render(fn, 1024, k * 0.60, mono=True).save(os.path.join(out, 'monochrome_1024.png'))
        with open(os.path.join(out, 'background.txt'), 'w') as f:
            f.write('#%02X%02X%02X\n' % bg)
        previews.append((name, icon, bg, fn, k))

    # Contact sheet: each option as a rounded square, a circle, and themed.
    cell, pad = 300, 36
    sheet_img = Image.new('RGB', (pad + (cell + pad) * 3, pad + (cell + pad) * len(previews)), (236, 232, 224))
    for row, (name, icon, bg, fn, k) in enumerate(previews):
        y = pad + row * (cell + pad)
        small = icon.resize((cell * 2, cell * 2), Image.LANCZOS)
        for col, shape in enumerate(('squircle', 'circle', 'themed')):
            m = Image.new('L', (cell * 2, cell * 2), 0)
            md = ImageDraw.Draw(m)
            if shape == 'circle':
                md.ellipse([0, 0, cell * 2, cell * 2], fill=255)
            else:
                md.rounded_rectangle([0, 0, cell * 2, cell * 2], radius=cell * 0.45, fill=255)
            if shape == 'themed':
                tile = Image.new('RGBA', (cell * 2, cell * 2), (214, 227, 255, 255))
                mono = render(fn, cell * 2, k * 0.60 * 1.5, mono=True)
                tint = Image.new('RGBA', mono.size, (20, 40, 90, 255))
                tile.paste(tint, (0, 0), mono.split()[3])
                src = tile
            elif shape == 'circle':
                src = Image.new('RGBA', (cell * 2, cell * 2), bg + (255,))
                src.alpha_composite(render(fn, cell * 2, k * 0.60 * 1.5))
            else:
                src = small
            tile = Image.new('RGBA', (cell * 2, cell * 2), (0, 0, 0, 0))
            tile.paste(src, (0, 0), m)
            tile = tile.resize((cell, cell), Image.LANCZOS)
            sheet_img.paste(tile, (pad + col * (cell + pad), y), tile)
    sheet_img.save(os.path.join(HERE, preview_name))


if __name__ == '__main__':
    build(OPTIONS, 'preview.png')
