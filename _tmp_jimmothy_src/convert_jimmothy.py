from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

SRC_DIR = Path(__file__).resolve().parent
OUT_DIR = SRC_DIR.parent / "art" / "creatures" / "parts"
SIZE = 400
LIGHT = np.array([-0.6, -0.8], dtype=np.float32)
LIGHT /= np.linalg.norm(LIGHT)

JOBS = [
    ("4kJimmothyBodyReal.jpg", "body_jimmothy.png"),
    ("4kJimmothyHead.jpg", "head_jimmothy.png"),
    ("4KJimmothyFrontLeg.jpg", "front_legs_jimmothy.png"),
    ("4kJimmothyBackLeg.jpg", "back_legs_jimmothy.png"),
    ("4KJimmothyTail.jpg", "tail_jimmothy.png"),
]


def is_paper(rgb: np.ndarray) -> np.ndarray:
    lum = rgb.mean(axis=2)
    mx = rgb.max(axis=2).astype(np.float32)
    mn = rgb.min(axis=2).astype(np.float32)
    sat = np.divide(mx - mn, np.maximum(mx, 1.0))
    pale_pink = (rgb[..., 0] >= 230) & (rgb[..., 1] >= 170) & (rgb[..., 2] >= 170) & (sat < 0.38)
    near_white = (lum >= 242) & (sat < 0.16)
    return near_white | pale_pink


def flood_background(paper: np.ndarray) -> np.ndarray:
    h, w = paper.shape
    bg = np.zeros((h, w), dtype=bool)
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        if paper[0, x]:
            bg[0, x] = True
            q.append((x, 0))
        if paper[h - 1, x]:
            bg[h - 1, x] = True
            q.append((x, h - 1))
    for y in range(h):
        if paper[y, 0]:
            bg[y, 0] = True
            q.append((0, y))
        if paper[y, w - 1]:
            bg[y, w - 1] = True
            q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and (not bg[ny, nx]) and paper[ny, nx]:
                bg[ny, nx] = True
                q.append((nx, ny))
    return bg


def convert(src: Path, dest: Path) -> None:
    rgb = np.array(Image.open(src).convert("RGB").resize((SIZE, SIZE), Image.Resampling.LANCZOS))
    paper = is_paper(rgb)
    bg = flood_background(paper)
    solid = ~bg
    lum = rgb.mean(axis=2)
    outline = solid & (lum < 78)
    fill = solid & ~outline

    out = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    ys, xs = np.where(fill if fill.any() else solid)
    cx = float(xs.mean()) if xs.size else SIZE * 0.5
    cy = float(ys.mean()) if ys.size else SIZE * 0.5
    reach = float(np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2).max()) if xs.size else 1.0
    reach = max(reach, 1.0)
    yy, xx = np.mgrid[0:SIZE, 0:SIZE]
    offset = np.stack([(xx - cx) / reach, (yy - cy) / reach], axis=-1)
    shade = np.clip(0.62 + 0.28 * (offset @ LIGHT), 0.28, 0.92)
    gray = (shade * 255.0).astype(np.uint8)
    out[fill, 0] = gray[fill]
    out[fill, 1] = gray[fill]
    out[fill, 2] = gray[fill]
    out[outline, 0] = 26
    out[outline, 1] = 26
    out[outline, 2] = 26
    out[solid, 3] = 255
    Image.fromarray(out, "RGBA").save(dest)
    opaque = int(solid.sum())
    print(f"{dest.name}: opaque={opaque} outline={int(outline.sum())} fill={int(fill.sum())}")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for src_name, dest_name in JOBS:
        convert(SRC_DIR / src_name, OUT_DIR / dest_name)


if __name__ == "__main__":
    main()
