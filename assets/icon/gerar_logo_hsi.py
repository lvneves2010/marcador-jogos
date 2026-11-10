import sys, math
from PIL import Image, ImageDraw, ImageFont
font_path, out = sys.argv[1], sys.argv[2]
SS = 4; N = 1024 * SS
RED = (178, 24, 30)
# coordenadas medidas na foto do cartão; caixa do logo ~ (500..1010, 320..830)
X0, Y0, W = 500, 330, 500
def P(x, y): return ((x - X0) / W * N, (y - Y0) / W * N)

def bez(p0, c1, c2, p1, n=80):
    pts = []
    for i in range(n + 1):
        t = i / n; u = 1 - t
        pts.append(tuple(u**3*a + 3*u*u*t*b + 3*u*t*t*c + t**3*d for a, b, c, d in zip(p0, c1, c2, p1)))
    return pts

# peça de cima ("bandeira")
top = []
top += [(540, 632), (538, 548)]
top += bez((538, 548), (585, 430), (680, 362), (765, 352))
top += bez((765, 352), (835, 362), (895, 385), (930, 420))
top += bez((930, 420), (912, 455), (888, 492), (862, 522))
top += bez((862, 522), (760, 585), (640, 622), (540, 632))

# crescente de baixo
cx, cy, r = 772, 530, 212
a0, a1 = math.radians(140), math.radians(-14)
arc = [(cx + r * math.cos(a0 + (a1 - a0) * i / 120), cy + r * math.sin(a0 + (a1 - a0) * i / 120)) for i in range(121)]
cres = arc + bez(arc[-1], (945, 585), (790, 668), arc[0])

img = Image.new('RGBA', (N, N), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.polygon([P(*p) for p in top], fill=RED + (255,))
d.polygon([P(*p) for p in cres], fill=RED + (255,))
f = ImageFont.truetype(font_path, int(30 / W * N)); f.set_variation_by_name('Bold')
d.text(P(902, 524), 'HSI', font=f, fill=RED + (255,), anchor='mm')

img = img.crop(img.getbbox())
w, h = img.size; s = max(w, h)
sq = Image.new('RGBA', (s, s), (0, 0, 0, 0)); sq.paste(img, ((s - w) // 2, (s - h) // 2))
sq = sq.resize((512, 512), Image.LANCZOS)
sq.save(f'{out}/logo_hsi.png')
prev = Image.new('RGBA', (512, 512), 'white'); prev.alpha_composite(sq)
prev.convert('RGB').save(f'{out}/logo_prev.png')
print('ok', sq.size)
