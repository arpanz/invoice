"""Second round of icon options. Run: python3 make_icons_v2.py"""
import math
from PIL import Image
from make_icons import Art, build, INK, PAPER, CREAM, RULE, GREEN, BLUE, WHITE, font

SOFT_BLUE = (190, 203, 224)
LEAF = (94, 168, 113)


def teeth(a, x0, x1, y, n, depth=46):
    """Cuts a zig-zag torn edge along the bottom of a slip."""
    w = (x1 - x0) / n
    a.erase(lambda v: [a.poly([(x0 + i * w, y + 6), (x0 + (i + 0.5) * w, y - depth), (x0 + (i + 1) * w, y + 6)], v)
                       for i in range(n)])


def rotate(a, deg):
    a.img = a.img.rotate(deg, resample=Image.BICUBIC)
    from PIL import ImageDraw
    a.d = ImageDraw.Draw(a.img)


# ---- 5: receipt with the tick cut out of it ----
def receipt_tick(a, mono=False):
    a.rrect(295, 165, 705, 800, 40, fill=WHITE if mono else PAPER)
    teeth(a, 295, 705, 800, 7)
    a.erase(lambda v: a.line([(392, 452), (470, 530), (612, 378)], v, 66))
    a.erase(lambda v: a.rrect(385, 640, 615, 676, 18, fill=v))


# ---- 6: lines of a bill, the last one turning into a tick ----
def lines_tick(a, mono=False):
    c = WHITE if mono else PAPER
    g = WHITE if mono else LEAF
    a.rrect(285, 300, 715, 366, 33, fill=c)
    a.rrect(285, 452, 630, 518, 33, fill=c)
    a.rrect(285, 604, 430, 670, 33, fill=c)
    a.line([(520, 632), (592, 704), (722, 548)], g, 66)


# ---- 7: a tilted sheet with a rosette seal ----
def sealed_sheet(a, mono=False):
    paper = WHITE if mono else PAPER
    a.rrect(300, 175, 690, 760, 36, fill=paper)
    def bar(x0, y0, x1, y1, col):
        if mono:
            a.erase(lambda v: a.rrect(x0, y0, x1, y1, (y1 - y0) / 2, fill=v))
        else:
            a.rrect(x0, y0, x1, y1, (y1 - y0) / 2, fill=col)
    bar(360, 270, 520, 304, INK)
    for y in (380, 440, 500):
        bar(360, y, 630, y + 20, RULE)
    rotate(a, 7)
    cx, cy, R = 648, 688, 118
    def rosette(r, fill):
        for i in range(14):
            t = i * 2 * math.pi / 14
            a.circle(cx + math.cos(t) * r, cy + math.sin(t) * r, r * 0.27, fill)
        a.circle(cx, cy, r, fill)
    a.erase(lambda v: rosette(R + 24, v))
    rosette(R, WHITE if mono else GREEN)
    tick = [(cx - 54, cy + 2), (cx - 16, cy + 40), (cx + 56, cy - 40)]
    if mono:
        a.erase(lambda v: a.line(tick, v, 30))
    else:
        a.line(tick, PAPER, 30)


# ---- 8: the letter I as a receipt ----
def slip_i(a, mono=False):
    c = WHITE if mono else INK
    a.rrect(310, 190, 690, 300, 22, fill=c)
    a.rrect(405, 250, 595, 740, 0, fill=c)
    a.rrect(310, 690, 690, 812, 22, fill=c)
    teeth(a, 310, 690, 812, 8, depth=40)
    for y in (400, 470, 540):
        a.erase(lambda v, y=y: a.rrect(445, y, 555, y + 20, 10, fill=v))


# ---- 9: two slips, one behind the other ----
def slip_stack(a, mono=False):
    back = WHITE if mono else SOFT_BLUE
    a.rrect(355, 185, 735, 690, 36, fill=back)
    a.erase(lambda v: a.rrect(245, 265, 665, 840, 44, fill=v))
    a.rrect(270, 290, 640, 800, 34, fill=WHITE if mono else PAPER)
    teeth(a, 270, 640, 800, 6, depth=42)
    def bar(x0, y0, x1, y1, col):
        if mono:
            a.erase(lambda v: a.rrect(x0, y0, x1, y1, (y1 - y0) / 2, fill=v))
        else:
            a.rrect(x0, y0, x1, y1, (y1 - y0) / 2, fill=col)
    bar(325, 370, 470, 402, INK)
    for x in range(325, 590, 44):  # perforation
        bar(x, 462, x + 24, 474, RULE)
    bar(325, 540, 585, 560, RULE)
    bar(325, 600, 585, 620, RULE)
    bar(465, 676, 585, 708, INK)


# ---- 10: a round "No." stamp ----
def number_stamp(a, mono=False):
    c = WHITE if mono else BLUE
    d = a.d
    d.ellipse(a.box(190, 190, 810, 810), outline=c, width=int(a.s(34)))
    d.ellipse(a.box(250, 250, 750, 750), outline=c, width=int(a.s(9)))
    a.text_center(500, 492, '№', 'Fraunces-SemiBold.ttf', 300, c)
    rotate(a, 9)


OPTIONS = [
    ('5_receipt_tick', receipt_tick, GREEN, 1.08),
    ('6_lines_tick', lines_tick, INK, 1.12),
    ('7_sealed_sheet', sealed_sheet, INK, 1.12),
    ('8_slip_i', slip_i, CREAM, 1.02),
    ('9_slip_stack', slip_stack, BLUE, 1.10),
    ('10_number_stamp', number_stamp, CREAM, 1.0),
]

if __name__ == '__main__':
    build(OPTIONS, 'preview_round2.png')
