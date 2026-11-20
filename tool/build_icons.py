"""Compiles assets/icons/*.svg into the app's icon font.

    python3 -m venv ~/.venvs/icons
    ~/.venvs/icons/bin/pip install fonttools skia-pathops
    ~/.venvs/icons/bin/python tool/build_icons.py

Writes:
    assets/icon_font/AppIcons.ttf     the font, registered in pubspec.yaml
    lib/core/theme/app_icons.dart     one `IconData` constant per SVG
    tool/icon_codepoints.json         keeps each icon's codepoint stable

Each SVG is drawn on a 24x24 grid as ink lines (stroke, round caps and
joins). A font holds filled outlines only, so every stroke is expanded to
its outline here. The SVG subset understood:

    <path> <circle> <ellipse> <rect> <line> <polyline> <polygon>
    stroke / fill / stroke-width / fill-rule, on the element or inherited
    <g mask="url(#id)"> with a <mask id> whose black shapes are cut out of
    the group (used for knock-outs in the solid icons)

File name -> constant: `check_circle.svg` becomes `AppIcons.checkCircle`.
"""
import json
import os
import re
import sys
import xml.etree.ElementTree as ET

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.svgLib.path import parse_path
from pathops import FillType, LineCap, LineJoin, Path, PathOp, op

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SVG_DIR = os.path.join(ROOT, 'assets', 'icons')
FONT_PATH = os.path.join(ROOT, 'assets', 'icon_font', 'AppIcons.ttf')
DART_PATH = os.path.join(ROOT, 'lib', 'core', 'theme', 'app_icons.dart')
CODEPOINTS_PATH = os.path.join(ROOT, 'tool', 'icon_codepoints.json')

FAMILY = 'AppIcons'
GRID = 24.0
EM = 1000
FIRST_CODEPOINT = 0xE000

# Icons that point along the reading direction and flip in RTL layouts.
DIRECTIONAL = {
    'arrow_back', 'arrow_forward', 'chevron_back', 'chevron_right', 'send',
    'undo',
}

NS = '{http://www.w3.org/2000/svg}'
INHERITED = ('stroke', 'fill', 'stroke-width', 'stroke-linecap',
             'stroke-linejoin', 'fill-rule')


def num(value):
    return float(value) if value is not None else 0.0


def shape_to_d(el):
    """Path data for any supported shape element, or None."""
    tag = el.tag.replace(NS, '')
    g = el.get
    if tag == 'path':
        return g('d')
    if tag in ('circle', 'ellipse'):
        cx, cy = num(g('cx')), num(g('cy'))
        rx = num(g('r')) if tag == 'circle' else num(g('rx'))
        ry = num(g('r')) if tag == 'circle' else num(g('ry'))
        return (f'M{cx - rx},{cy} A{rx},{ry} 0 1 0 {cx + rx},{cy} '
                f'A{rx},{ry} 0 1 0 {cx - rx},{cy} Z')
    if tag == 'rect':
        x, y, w, h = num(g('x')), num(g('y')), num(g('width')), num(g('height'))
        rx = g('rx') or g('ry')
        ry = g('ry') or g('rx')
        rx, ry = min(num(rx), w / 2), min(num(ry), h / 2)
        if rx == 0 or ry == 0:
            return f'M{x},{y} H{x + w} V{y + h} H{x} Z'
        return (f'M{x + rx},{y} H{x + w - rx} A{rx},{ry} 0 0 1 {x + w},{y + ry} '
                f'V{y + h - ry} A{rx},{ry} 0 0 1 {x + w - rx},{y + h} '
                f'H{x + rx} A{rx},{ry} 0 0 1 {x},{y + h - ry} '
                f'V{y + ry} A{rx},{ry} 0 0 1 {x + rx},{y} Z')
    if tag == 'line':
        return f"M{g('x1')},{g('y1')} L{g('x2')},{g('y2')}"
    if tag in ('polyline', 'polygon'):
        pts = re.findall(r'-?\d*\.?\d+(?:e-?\d+)?', g('points') or '')
        pairs = [f'{pts[i]},{pts[i + 1]}' for i in range(0, len(pts) - 1, 2)]
        if not pairs:
            return None
        return 'M' + ' L'.join(pairs) + (' Z' if tag == 'polygon' else '')
    return None


def union(paths):
    paths = list(paths)
    if not paths:
        return Path()
    out = paths[0]
    for p in paths[1:]:
        out = op(out, p, PathOp.UNION, fix_winding=True,
                 keep_starting_points=False)
    return out


def element_outline(el, style):
    """The inked area of one shape element as a filled path."""
    d = shape_to_d(el)
    if not d:
        return None
    parts = []
    fill = style.get('fill', 'none')
    stroke = style.get('stroke', 'none')
    if fill != 'none':
        p = Path()
        parse_path(d, p.getPen())
        if style.get('fill-rule') == 'evenodd':
            p.fillType = FillType.EVEN_ODD
        p.simplify(fix_winding=False, keep_starting_points=False)
        parts.append(p)
    if stroke != 'none':
        p = Path()
        parse_path(d, p.getPen())
        cap = {'butt': LineCap.BUTT_CAP, 'square': LineCap.SQUARE_CAP}.get(
            style.get('stroke-linecap'), LineCap.ROUND_CAP)
        join = {'miter': LineJoin.MITER_JOIN, 'bevel': LineJoin.BEVEL_JOIN}.get(
            style.get('stroke-linejoin'), LineJoin.ROUND_JOIN)
        p.stroke(float(style.get('stroke-width', 1)), cap, join, 4)
        p.convertConicsToQuads()
        p.simplify(fix_winding=False, keep_starting_points=False)
        parts.append(p)
    return union(parts) if parts else None


def collect(node, style, masks):
    """Union of everything drawn under `node`, with mask cut-outs applied."""
    style = dict(style)
    for key in INHERITED:
        if node.get(key) is not None:
            style[key] = node.get(key)
    tag = node.tag.replace(NS, '')
    if tag in ('mask', 'defs', 'title', 'desc'):
        return None
    if tag in ('svg', 'g'):
        parts = [collect(child, style, masks) for child in node]
        shape = union([p for p in parts if p is not None])
        ref = re.match(r'url\(#(.+)\)', node.get('mask') or '')
        if ref:
            shape = op(shape, masks[ref.group(1)], PathOp.DIFFERENCE,
                       fix_winding=True, keep_starting_points=False)
        return shape
    return element_outline(node, style)


def read_masks(root):
    """mask id -> the area its black shapes cover (what gets cut away)."""
    masks = {}
    for mask in root.iter(NS + 'mask'):
        cuts = []
        for el in mask.iter():
            style = {k: el.get(k) for k in INHERITED if el.get(k) is not None}
            style.setdefault('stroke-linecap', 'round')
            style.setdefault('stroke-linejoin', 'round')
            if 'black' not in (style.get('fill'), style.get('stroke')):
                continue
            for key in ('fill', 'stroke'):
                if style.get(key) not in ('black', None):
                    style[key] = 'none'
            outline = element_outline(el, style)
            if outline is not None:
                cuts.append(outline)
        masks[mask.get('id')] = union(cuts)
    return masks


def build_glyph(svg_path):
    root = ET.parse(svg_path).getroot()
    shape = collect(root, {}, read_masks(root))
    shape.simplify(fix_winding=True, keep_starting_points=False)
    glyph_pen = TTGlyphPen(None)
    scale = EM / GRID
    # SVG y runs down from the top; font y runs up from the baseline.
    pen = TransformPen(
        Cu2QuPen(glyph_pen, max_err=0.5, reverse_direction=False),
        (scale, 0, 0, -scale, 0, EM),
    )
    shape.draw(pen)
    return glyph_pen.glyph()


def camel(name):
    head, *rest = name.split('_')
    return head + ''.join(part.capitalize() for part in rest)


def main():
    names = sorted(f[:-4] for f in os.listdir(SVG_DIR) if f.endswith('.svg'))
    if not names:
        sys.exit(f'no SVGs in {SVG_DIR}')

    codepoints = {}
    if os.path.exists(CODEPOINTS_PATH):
        with open(CODEPOINTS_PATH) as f:
            codepoints = {k: int(v, 16) for k, v in json.load(f).items()}
    next_free = max(codepoints.values(), default=FIRST_CODEPOINT - 1) + 1
    for name in names:
        if name not in codepoints:
            codepoints[name] = next_free
            next_free += 1

    glyphs = {'.notdef': TTGlyphPen(None).glyph()}
    for name in names:
        glyphs[name] = build_glyph(os.path.join(SVG_DIR, name + '.svg'))

    order = ['.notdef'] + names
    fb = FontBuilder(EM, isTTF=True)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap({codepoints[n]: n for n in names})
    fb.setupGlyf(glyphs)
    fb.setupHorizontalMetrics(
        {n: (EM, glyphs[n].xMin if glyphs[n].numberOfContours else 0)
         for n in order})
    # The glyph box is the full em above the baseline, so an `Icon` of size
    # s draws the 24-grid artwork in exactly an s x s square.
    fb.setupHorizontalHeader(ascent=EM, descent=0)
    fb.setupNameTable({'familyName': FAMILY, 'styleName': 'Regular'})
    fb.setupOS2(sTypoAscender=EM, sTypoDescender=0, sTypoLineGap=0,
                usWinAscent=EM, usWinDescent=0)
    fb.setupPost()
    os.makedirs(os.path.dirname(FONT_PATH), exist_ok=True)
    fb.save(FONT_PATH)

    with open(CODEPOINTS_PATH, 'w') as f:
        json.dump({n: f'{codepoints[n]:04x}' for n in sorted(codepoints)}, f,
                  indent=2)
        f.write('\n')

    lines = [
        '// GENERATED by tool/build_icons.py from assets/icons/*.svg.',
        '// Do not edit by hand: change the SVG and run the script again.',
        '',
        "import 'package:flutter/widgets.dart';",
        '',
        '/// The app\'s own ink-line icon set, drawn to sit with the',
        '/// paper-and-stamp look. Use like Material\'s `Icons`:',
        '/// `Icon(AppIcons.receipt)`.',
        'abstract final class AppIcons {',
        f"  static const String _family = '{FAMILY}';",
        '',
    ]
    for name in names:
        flip = ', matchTextDirection: true' if name in DIRECTIONAL else ''
        lines.append(
            f'  static const IconData {camel(name)} = '
            f'IconData(0x{codepoints[name]:04x}, fontFamily: _family{flip});')
    lines += ['}', '']
    with open(DART_PATH, 'w') as f:
        f.write('\n'.join(lines))

    print(f'{len(names)} icons -> {os.path.relpath(FONT_PATH, ROOT)}')


if __name__ == '__main__':
    main()
