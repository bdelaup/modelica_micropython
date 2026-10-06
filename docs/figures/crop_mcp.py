"""Recadre une capture d'icône ou de schéma rendue par le serveur MCP-OpenModelica
(outils iconDiagram / classDiagram : PNG 1024 x 1024) pour la documentation.

Le rendu MCP montre la zone de dessin sur fond blanc, quadrillée, posée sur un
fond bleu clair, et laisse le bas de l'image transparent. Ce script remplace
fond, quadrillage et transparence par du blanc, puis recadre au plus juste
autour du dessin, avec une marge.

    python docs/figures/crop_mcp.py capture.png docs/fr/images/mcu-icone.png
    python docs/figures/crop_mcp.py --row a.png b.png c.png -o docs/fr/images/uart-icones.png

--row assemble plusieurs captures côte à côte (alignées en bas, même hauteur de
dessin conservée). --keep-grid garde le quadrillage. --no-name efface le texte
« %name » d'une icône (bleu pur, sur une bande de lignes à part, que le rendu MCP
affiche tel quel faute d'instance). Prérequis : Pillow.
"""
import argparse

from PIL import Image

BACKGROUND = {(229, 244, 255), (242, 242, 242)}  # fond hors de la zone de dessin : bleu clair (icône), gris (schéma)
GRID = {(229, 229, 229), (192, 192, 192)}  # quadrillage et axes de la zone de dessin
NAME = (0, 0, 255)                    # couleur du texte %name des icônes de la bibliothèque
WHITE = (255, 255, 255)
MARGIN = 12


def name_rows(src, w, h):
    """Lignes de la bande du texte %name : groupes de lignes contiguës contenant du
    bleu pur et RIEN d'autre que du bleuté (anticrénelage compris) sur le fond.
    Les connecteurs, du même bleu, partagent leurs lignes avec le corps de
    l'icône : leurs groupes sont écartés."""
    def kind(y):
        blue = False
        for x in range(w):
            r, g, b, a = src[x, y]
            p = (r, g, b)
            if a == 0 or p in BACKGROUND or p in GRID or min(p) >= 220 or (min(p) >= 180 and max(p) - min(p) <= 3):   # fond, quadrillage (et son lissage), presque blanc
                continue
            if max(p) == 255 and min(p) >= 150:   # frange colorée du lissage sous-pixel d'un petit texte (rose, cyan)
                continue
            if min(p) >= 200 and max(p) - min(p) <= 25:   # gris bleuté très clair : lissage du quadrillage
                continue
            if p == NAME:
                blue = True
            elif not (b >= 150 and b - max(r, g) >= 5):   # bleu mêlé de blanc ou de gris clair
                return "other"
        return "blue" if blue else "empty"
    kinds = [kind(y) for y in range(h)]
    skip = set()
    y = 0
    while y < h:
        if kinds[y] != "blue":
            y += 1
            continue
        start = y
        while y < h and kinds[y] in ("blue", "empty") and not (kinds[y] == "empty" and y > start and kinds[y - 1] == "empty"):
            y += 1
        # élargie de quelques lignes pour emporter l'anticrénelage des bords
        for yy in range(max(0, start - 4), min(h, y + 4)):
            if kinds[yy] != "other":
                skip.add(yy)
    return skip


def clean(path, keep_grid=False, no_name=False):
    """Capture -> image RGB sur fond blanc, recadrée sur le dessin."""
    im = Image.open(path).convert("RGBA")
    out = Image.new("RGB", im.size, WHITE)
    src = im.load()
    dst = out.load()
    w, h = im.size
    skip = set()
    if no_name:
        skip = name_rows(src, w, h)
    x0, y0, x1, y1 = w, h, -1, -1
    for y in range(h):
        if y in skip:
            continue
        for x in range(w):
            r, g, b, a = src[x, y]
            p = (r, g, b)
            if a == 0 or p in BACKGROUND or min(p) >= 235 or (not keep_grid and p in GRID):   # min >= 235 : presque blanc (lissage)
                continue
            dst[x, y] = p
            x0, y0, x1, y1 = min(x0, x), min(y0, y), max(x1, x), max(y1, y)
    if x1 < 0:
        raise SystemExit("%s : aucun dessin trouvé" % path)
    return out.crop((max(0, x0 - MARGIN), max(0, y0 - MARGIN),
                     min(w, x1 + MARGIN + 1), min(h, y1 + MARGIN + 1)))


def row(images, gap=90):
    width = sum(i.width for i in images) + gap * (len(images) - 1)
    height = max(i.height for i in images)
    out = Image.new("RGB", (width, height), WHITE)
    x = 0
    for i in images:
        out.paste(i, (x, height - i.height))
        x += i.width + gap
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("inputs", nargs="+")
    ap.add_argument("-o", "--output")
    ap.add_argument("--row", action="store_true", help="assembler les captures côte à côte")
    ap.add_argument("--keep-grid", action="store_true")
    ap.add_argument("--no-name", action="store_true", help="effacer le texte %%name d'une icône")
    ap.add_argument("--max-width", type=int, help="réduire l'image à cette largeur (pixels)")
    args = ap.parse_args()
    if args.row:
        if not args.output:
            ap.error("--row demande -o")
        result, target = row([clean(p, args.keep_grid, args.no_name) for p in args.inputs]), args.output
    else:
        if args.output:
            src, target = args.inputs[0], args.output
        elif len(args.inputs) == 2:
            src, target = args.inputs
        else:
            ap.error("une capture et une sortie, ou -o")
        result = clean(src, args.keep_grid, args.no_name)
    if args.max_width and result.width > args.max_width:
        result = result.resize((args.max_width, round(result.height * args.max_width / result.width)),
                               Image.LANCZOS)
    result.save(target, optimize=True)
    print("écrit %s (%d x %d)" % (target, result.width, result.height))


if __name__ == "__main__":
    main()
