import json
import math
import shutil
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

BASE = Path(__file__).resolve().parents[1]
ROOT = BASE.parents[2]
PREVIEWS = BASE / 'apercus-natifs'
REPORT = json.loads((PREVIEWS / 'verification.json').read_text())
FONT = ImageFont.truetype(str(ROOT / 'game/assets/fonts/IBMPlexSans-Variable.ttf'), 18)

for screen in REPORT['screens']:
    source = PREVIEWS / (screen['id'] + '.png')
    if source.exists():
        shutil.copyfile(source, PREVIEWS / (screen['code'] + '.png'))
    native = PREVIEWS / (screen['code'] + '.png')
    if native.exists():
        with Image.open(native) as image:
            image.convert('RGB').save(PREVIEWS / (screen['code'] + '.jpg'), quality=94, subsampling=0)

resource_kit = PREVIEWS / '02-emblemes.png'
if resource_kit.exists():
    with Image.open(resource_kit) as image:
        image.convert('RGB').save(PREVIEWS / '02-emblemes.jpg', quality=94, subsampling=0)

def montage(filename, codes, columns, cell_width, cell_height):
    out = Image.new('RGB', (columns * cell_width, math.ceil(len(codes) / columns) * cell_height), '#25372D')
    draw = ImageDraw.Draw(out)
    for i, code in enumerate(codes):
        im = Image.open(PREVIEWS / (code + '.png')).convert('RGB')
        im.thumbnail((cell_width - 32, cell_height - 72), Image.Resampling.LANCZOS)
        x = 16 + (i % columns) * cell_width
        y = 16 + (i // columns) * cell_height
        out.paste(im, (x, y))
        draw.text((x, y + cell_height - 60), code, fill='#F4E7C6', font=FONT)
    out.save(PREVIEWS / filename, quality=93)

montage('vue-ensemble.jpg', [s['code'] for s in REPORT['screens']], 6, 480, 400)
GROUPS = {
    '01-journee': ['J01', 'J19', 'J20', 'J21', 'J22', 'J23'],
    '02-produit': ['J02', 'J04', 'J05', 'J06', 'J41', 'J44'],
    '03-organisation': ['J07', 'J08', 'J09', 'J10', 'J18', 'J36'],
    '04-equipe': ['J03', 'J11', 'J12', 'J13', 'J37', 'J38'],
    '05-investir': ['J14', 'J15', 'J16', 'J17', 'J32', 'J40'],
    '06-progression': ['J24', 'J25', 'J26', 'J27', 'J28', 'J39'],
    '07-aide': ['J29', 'J30', 'J31', 'J33', 'J34', 'J35'],
}
for name, codes in GROUPS.items():
    montage(name + '.jpg', codes, 2, 800, 630)
print(f"{len(REPORT['screens'])} vues natives et 8 planches de revue.")
