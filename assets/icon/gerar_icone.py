import sys, math, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter
font_path, out = sys.argv[1], sys.argv[2]
SS = 2; N = 1024 * SS

# --- feltro verde: gradiente radial + textura leve
small = Image.new('RGB', (256, 256)); sp = small.load()
for y in range(256):
    for x in range(256):
        d = math.hypot(x - 90, y - 70) / 300
        t = min(d, 1)
        sp[x, y] = (int(22 - 14 * t), int(122 - 70 * t), int(58 - 34 * t))
bg = small.resize((N, N), Image.BICUBIC)
random.seed(7)
noise = Image.effect_noise((N, N), 18).convert('L').filter(ImageFilter.GaussianBlur(1.2))
bg = Image.composite(bg.point(lambda v: min(255, v + 10)), bg, noise.point(lambda v: 255 if v > 140 else 0)).convert('RGBA')

CW, CH, R = 560 * SS // 1, 800 * SS // 1, 44 * SS

def fonte(size, peso):
    f = ImageFont.truetype(font_path, size); f.set_variation_by_name(peso); return f

def paus(d, cx, cy, s, cor=(20, 20, 20)):
    r = s * 0.26
    for dx, dy in ((0, -0.30), (-0.29, 0.05), (0.29, 0.05)):
        d.ellipse((cx + dx * s - r, cy + dy * s - r, cx + dx * s + r, cy + dy * s + r), fill=cor)
    d.polygon([(cx, cy - 0.05 * s), (cx - 0.20 * s, cy + 0.55 * s), (cx + 0.20 * s, cy + 0.55 * s)], fill=cor)
    d.ellipse((cx - r * 0.6, cy - r * 0.6, cx + r * 0.6, cy + r * 0.6), fill=cor)

def carta(letra):
    c = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
    d = ImageDraw.Draw(c)
    d.rounded_rectangle((0, 0, CW - 1, CH - 1), radius=R, fill=(250, 250, 247, 255), outline=(200, 200, 200, 255), width=3 * SS)
    f = fonte(170 * SS, 'SemiBold')
    d.text((92 * SS, 120 * SS), letra, font=f, fill=(20, 20, 20, 255), anchor='mm')
    paus(d, 92 * SS, 265 * SS, 105 * SS)
    # moldura interna da figura (como nas cartas de figura)
    d.rounded_rectangle((175 * SS, 70 * SS, CW - 70 * SS, CH - 70 * SS), radius=16 * SS, outline=(70, 70, 140, 255), width=5 * SS)
    paus(d, (175 * SS + CW - 70 * SS) / 2, CH / 2 - 40 * SS, 230 * SS)
    return c

def colocar(base, img, tx, ty, ang):
    th = math.radians(ang); co, si = math.cos(th), math.sin(th)
    coef = (co, si, -(co * tx + si * ty), -si, co, si * tx - co * ty)
    lay = img.transform((N, N), Image.AFFINE, coef, resample=Image.BICUBIC)
    sombra = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    a = lay.getchannel('A').point(lambda v: int(v * 0.55)).filter(ImageFilter.GaussianBlur(22 * SS))
    sombra.putalpha(a)
    base.alpha_composite(sombra, (-14 * SS, 18 * SS))
    base.alpha_composite(lay)

cartas = Image.new('RGBA', (N, N), (0, 0, 0, 0))
for letra, tx, ty, ang in (('Q', 620, 120, 28), ('K', 420, 360, 30), ('J', 225, 610, 32)):
    colocar(cartas, carta(letra), tx * SS, ty * SS, ang)

def salvar(img, nome, size=1024):
    img.resize((size, size), Image.LANCZOS).save(f'{out}/{nome}', optimize=True)

full = bg.copy(); full.alpha_composite(cartas)
full = full.convert('RGB')
salvar(full, 'cartas_1024.png')            # iOS / legado / tela de abertura
salvar(full, 'playstore_512.png', 512)     # Play Store
salvar(bg.convert('RGB'), 'adaptive_bg.png')
# foreground adaptativo: "leque de mão" (cartas abertas a partir de um pivô
# embaixo), centralizado na área visível (66% central da camada).
# k = escala das cartas; py = altura do pivô; ang = abertura entre cartas
k = float(sys.argv[3]) if len(sys.argv) > 3 else 0.70
py = float(sys.argv[4]) if len(sys.argv) > 4 else 870
ang = float(sys.argv[5]) if len(sys.argv) > 5 else 19
fg = Image.new('RGBA', (N, N), (0, 0, 0, 0))
cw, ch = CW * k, CH * k
for i, letra in enumerate(('J', 'K', 'Q')):
    th = math.radians((i - 1) * ang)
    u, v = -cw / 2, -ch                      # canto sup. esq. relativo ao pivô
    tx = 512 * SS + u * math.cos(th) - v * math.sin(th)
    ty = py * SS + u * math.sin(th) + v * math.cos(th)
    c = carta(letra).resize((int(cw), int(ch)), Image.LANCZOS)
    colocar(fg, c, tx, ty, (i - 1) * ang)
salvar(fg, 'adaptive_fg.png')
# prévia: como fica no launcher com máscara circular (zoom 72/108)
prev = bg.copy(); prev.alpha_composite(fg)
c = int(N * 18 / 108); prev = prev.crop((c, c, N - c, N - c)).resize((512, 512), Image.LANCZOS)
for forma in ('circulo', 'squircle'):
    m = Image.new('L', (512, 512), 0)
    if forma == 'circulo':
        ImageDraw.Draw(m).ellipse((0, 0, 511, 511), fill=255)
    else:
        ImageDraw.Draw(m).rounded_rectangle((0, 0, 511, 511), radius=150, fill=255)
    pv = Image.new('RGBA', (512, 512), (255, 255, 255, 255)); pv.paste(prev, (0, 0), m)
    pv.convert('RGB').save(f'{out}/prev_{forma}.png')
print('ok')
