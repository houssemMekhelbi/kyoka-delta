#!/usr/bin/env python3
"""Generate the Kyoka delta wallpaper: void ground, off-axis violet aura, and a
tilted mirror pane cracked from one impact point, a few shards displaced.

Writes wallpaper.svg next to this file and renders wallpaper.png with
rsvg-convert. Deterministic (fixed seed); edit the constants and re-run.
"""

import math
import random
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
W, H = 1920, 1080
VOID, VIOLET, VIOLET_LIT, INDIGO, ICE, FROST = (
    "#08070D", "#4A30A6", "#8B6CF0", "#263B8F", "#8FE3F2", "#ECEAF5")

rnd = random.Random(1789)

# The mirror: a pane leaning 6° off vertical, right of centre.
PANE = [(1000, 150), (1560, 104), (1648, 930), (1088, 976)]
IMPACT = (1300, 452)


def pts(ps):
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in ps)


def ray(angle, length):
    """A crack from the impact outwards, kinked twice."""
    x, y = IMPACT
    out = [(x, y)]
    steps = 3
    for i in range(1, steps + 1):
        a = angle + rnd.uniform(-0.09, 0.09)
        r = length * i / steps
        out.append((IMPACT[0] + r * math.cos(a), IMPACT[1] + r * math.sin(a)))
    return out


angles = sorted(rnd.uniform(0, 2 * math.pi) for _ in range(15))
rays = [ray(a, rnd.uniform(420, 820)) for a in angles]


def ring(radius, jitter):
    ps = []
    for a in angles:
        r = radius * rnd.uniform(1 - jitter, 1 + jitter)
        ps.append((IMPACT[0] + r * math.cos(a), IMPACT[1] + r * math.sin(a)))
    return ps


inner, outer = ring(70, 0.25), ring(210, 0.2)

shards = []
for i in rnd.sample(range(len(angles)), 5):
    j = (i + 1) % len(angles)
    tri = [inner[i], outer[i], outer[j]] if i % 2 else [inner[i], outer[j], inner[j]]
    dx, dy = rnd.uniform(-7, 9), rnd.uniform(-6, 6)
    shards.append(([(x + dx, y + dy) for x, y in tri], rnd.uniform(0.07, 0.16)))

cracks = "".join(
    f'<polyline points="{pts(r)}" stroke-opacity="{rnd.uniform(0.10, 0.24):.2f}"/>' for r in rays)
shard_svg = "".join(
    f'<polygon points="{pts(t)}" fill="url(#shard)" fill-opacity="{o:.2f}" '
    f'stroke="{ICE}" stroke-opacity="0.22" stroke-width="1"/>' for t, o in shards)

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
<defs>
 <radialGradient id="aura" cx="0.66" cy="0.40" r="0.55" gradientTransform="translate(0.66 0.40) scale(1 1.75) translate(-0.66 -0.40)"><stop offset="0" stop-color="{VIOLET_LIT}" stop-opacity="0.30"/><stop offset="0.45" stop-color="{VIOLET}" stop-opacity="0.14"/><stop offset="1" stop-color="{VIOLET}" stop-opacity="0"/></radialGradient>
 <radialGradient id="deep" cx="0.10" cy="1.05" r="0.6" gradientTransform="translate(0.10 1.05) scale(1 1.75) translate(-0.10 -1.05)"><stop offset="0" stop-color="{INDIGO}" stop-opacity="0.35"/><stop offset="1" stop-color="{INDIGO}" stop-opacity="0"/></radialGradient>
 <radialGradient id="flash" cx="{IMPACT[0] / W:.3f}" cy="{IMPACT[1] / H:.3f}" r="0.12" gradientTransform="translate({IMPACT[0] / W:.3f} {IMPACT[1] / H:.3f}) scale(1 1.75) translate({-IMPACT[0] / W:.3f} {-IMPACT[1] / H:.3f})"><stop offset="0" stop-color="{ICE}" stop-opacity="0.10"/><stop offset="1" stop-color="{ICE}" stop-opacity="0"/></radialGradient>
 <linearGradient id="pane" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{FROST}" stop-opacity="0.045"/><stop offset="0.5" stop-color="{FROST}" stop-opacity="0.01"/><stop offset="1" stop-color="{VIOLET_LIT}" stop-opacity="0.05"/></linearGradient>
 <linearGradient id="shard" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{ICE}"/><stop offset="1" stop-color="{VIOLET_LIT}"/></linearGradient>
 <clipPath id="glass"><polygon points="{pts(PANE)}"/></clipPath>
</defs>
<rect width="{W}" height="{H}" fill="{VOID}"/>
<rect width="{W}" height="{H}" fill="url(#deep)"/>
<rect width="{W}" height="{H}" fill="url(#aura)"/>
<polygon points="{pts([(x + 22, y - 14) for x, y in PANE])}" fill="none" stroke="{VIOLET_LIT}" stroke-opacity="0.10" stroke-width="1"/>
<polygon points="{pts(PANE)}" fill="url(#pane)" stroke="{FROST}" stroke-opacity="0.16" stroke-width="1.4"/>
<g clip-path="url(#glass)">
 <rect width="{W}" height="{H}" fill="url(#flash)"/>
 <g fill="none" stroke="{FROST}" stroke-width="1.1" stroke-linejoin="miter">{cracks}</g>
 <polygon points="{pts(inner)}" fill="none" stroke="{FROST}" stroke-opacity="0.14" stroke-width="1"/>
 <polygon points="{pts(outer)}" fill="none" stroke="{FROST}" stroke-opacity="0.09" stroke-width="1"/>
 {shard_svg}
</g>
</svg>
'''

(HERE / "wallpaper.svg").write_text(svg)
subprocess.run(["rsvg-convert", "-w", str(W), "-h", str(H), "-o", str(HERE / "wallpaper.png"),
                str(HERE / "wallpaper.svg")], check=True)
print("wrote", HERE / "wallpaper.svg", "and wallpaper.png")
