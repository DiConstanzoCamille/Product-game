#!/usr/bin/env python3
"""Génère game/assets/fonts/ProductIcons.ttf à partir de tools/icons/manifest.json.

L'asset embarqué dans le jeu est un binaire ; sans ce script et sans le
manifeste, personne ne peut savoir quel tracé dessine quel caractère, ni
ajouter un pictogramme sans repartir de zéro. Les deux sont donc versionnés,
et la sortie est déterministe : régénérer sans rien changer laisse
`git status` propre.

Usage :
    python3 tools/icons/build_product_icons.py            # écrit la police
    python3 tools/icons/build_product_icons.py --check    # vérifie sans écrire
    python3 tools/icons/build_product_icons.py --fetch    # télécharge les SVG manquants

Dépendances : `pip install fonttools picosvg` (picosvg tire skia-pathops, qui
convertit les traits Lucide en contours remplis — une police ne sait dessiner
que des surfaces).
"""

from __future__ import annotations

import argparse
import json
import sys
import urllib.request
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.misc.transform import Transform
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.svgLib.path import parse_path
from picosvg.svg import SVG

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
MANIFEST = HERE / "manifest.json"
OUTPUT = REPO / "game" / "assets" / "fonts" / "ProductIcons.ttf"

SOURCE_DIRS = {"lucide": HERE / "lucide", "extra": HERE / "extra"}
VIEWBOX = 24.0
# Horodatage figé : sans lui, deux régénérations identiques produisent deux
# binaires différents et le contrôle `--check` ne vaut plus rien.
FIXED_TIMESTAMP = 3852921600  # 2022-01-01T00:00:00Z, en secondes depuis 1904.


def load_manifest() -> dict:
    return json.loads(MANIFEST.read_text(encoding="utf-8"))


def source_path(entry: dict) -> Path:
    return SOURCE_DIRS[entry["source"]] / f"{entry['icon']}.svg"


def fetch_missing(manifest: dict) -> None:
    template = manifest["lucideBaseUrl"]
    version = manifest["lucideVersion"]
    for entry in manifest["glyphs"]:
        if entry["source"] != "lucide":
            continue
        target = source_path(entry)
        if target.exists():
            continue
        url = template.format(version=version, name=entry["icon"])
        print(f"↓ {entry['icon']}.svg")
        target.parent.mkdir(parents=True, exist_ok=True)
        with urllib.request.urlopen(url) as response:
            if response.status != 200:
                raise SystemExit(f"{url} → HTTP {response.status}")
            target.write_bytes(response.read())


def outline_of(entry: dict) -> str:
    """Aplatit un SVG Lucide en un unique tracé rempli."""
    svg = SVG.parse(str(source_path(entry))).topicosvg()
    return " ".join(shape.d for shape in svg.shapes())


def draw_glyph(path_data: str, metrics: dict) -> object:
    scale = metrics["iconBox"] / VIEWBOX
    left = (metrics["advance"] - metrics["iconBox"]) / 2.0
    top = metrics["baselineOffset"] + metrics["iconBox"] / 2.0
    # Le SVG descend, la police monte : l'axe Y est retourné.
    transform = Transform(scale, 0, 0, -scale, left, top)
    pen = TTGlyphPen(None)
    parse_path(path_data, TransformPen(Cu2QuPen(pen, 0.6), transform))
    return pen.glyph()


def build(manifest: dict) -> FontBuilder:
    metrics = manifest["metrics"]
    upem = metrics["unitsPerEm"]
    advance = metrics["advance"]

    glyphs: dict[str, object] = {}
    hmtx: dict[str, tuple[int, int]] = {}
    cmap: dict[int, str] = {}
    order = [".notdef"]

    empty = TTGlyphPen(None).glyph()
    glyphs[".notdef"] = empty
    hmtx[".notdef"] = (advance, 0)

    for entry in manifest["glyphs"]:
        codepoint = int(entry["codepoint"][2:], 16)
        if entry["source"] == "blank":
            name = "blank"
            if name not in glyphs:
                order.append(name)
                glyphs[name] = empty
                # Avance nulle : un sélecteur de variante ne doit pas creuser
                # un blanc dans la phrase.
                hmtx[name] = (0, 0)
        else:
            name = entry["icon"].replace("-", "_")
            if name not in glyphs:
                order.append(name)
                glyphs[name] = draw_glyph(outline_of(entry), metrics)
                hmtx[name] = (advance, 0)
        cmap[codepoint] = name

    builder = FontBuilder(upem, isTTF=True)
    builder.font.recalcTimestamp = False
    builder.setupGlyphOrder(order)
    builder.setupCharacterMap(cmap)
    builder.setupGlyf(glyphs)
    builder.setupHorizontalMetrics(hmtx)
    builder.setupHorizontalHeader(ascent=metrics["ascent"], descent=metrics["descent"])
    builder.setupNameTable(
        {
            "familyName": "ProductIcons",
            "styleName": "Regular",
            "uniqueFontIdentifier": "ProductIcons;Product Tycoon",
            "fullName": "ProductIcons",
            "psName": "ProductIcons",
            "version": "Version 2.0",
            "manufacturer": "tools/icons/build_product_icons.py",
            "designer": f"Lucide {manifest['lucideVersion']} (ISC)",
        }
    )
    builder.setupOS2(
        sTypoAscender=metrics["ascent"],
        sTypoDescender=metrics["descent"],
        sTypoLineGap=0,
        usWinAscent=metrics["ascent"],
        usWinDescent=-metrics["descent"],
        achVendID="PTYC",
    )
    builder.setupPost(isFixedPitch=1)
    builder.font["head"].created = FIXED_TIMESTAMP
    builder.font["head"].modified = FIXED_TIMESTAMP
    return builder


def to_bytes(builder: FontBuilder) -> bytes:
    from io import BytesIO

    buffer = BytesIO()
    builder.save(buffer)
    return buffer.getvalue()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="échoue si l'asset versionné diffère")
    parser.add_argument("--fetch", action="store_true", help="télécharge les SVG Lucide manquants")
    args = parser.parse_args()

    manifest = load_manifest()
    if args.fetch:
        fetch_missing(manifest)

    absents = [
        entry["icon"]
        for entry in manifest["glyphs"]
        if entry["source"] != "blank" and not source_path(entry).exists()
    ]
    if absents:
        print("SVG source manquant : %s (relancer avec --fetch)" % ", ".join(sorted(set(absents))))
        return 1

    payload = to_bytes(build(manifest))
    if args.check:
        if not OUTPUT.exists():
            print(f"{OUTPUT} est absent.")
            return 1
        if OUTPUT.read_bytes() != payload:
            print(f"{OUTPUT} ne correspond plus au manifeste — régénérer.")
            return 1
        print(f"OK — {OUTPUT.name} correspond au manifeste ({len(manifest['glyphs'])} caractères).")
        return 0

    OUTPUT.write_bytes(payload)
    print(f"OK — {OUTPUT} écrit ({len(manifest['glyphs'])} caractères, {len(payload)} octets).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
