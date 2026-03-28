from __future__ import annotations

import json
from pathlib import Path
from collections import deque

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = ROOT / "art" / "runtime" / "environment" / "source" / "forest_tiles_sheet_v1.png"
MANIFEST_PATH = ROOT / "art" / "runtime" / "environment" / "environment_tiles_manifest.json"
PREVIEW_PATH = ROOT / "art" / "runtime" / "validation" / "forest_tiles_preview.png"

WHITE_THRESHOLD = 248
PREVIEW_COLUMNS = 4
PREVIEW_CELL = (244, 228)

SPECS = [
    {
        "name": "forest_floor_dusk_a",
        "category": "floor",
        "box": [2, 2, 163, 157],
        "inset": 1,
        "tileable_edge_band": 6,
        "transparent_bg": False,
        "trim": False,
        "usage": "base floor",
    },
    {
        "name": "forest_floor_dusk_b",
        "category": "floor",
        "box": [2, 163, 163, 219],
        "transparent_bg": False,
        "trim": False,
        "usage": "base floor",
    },
    {
        "name": "forest_patch_root_stumps_mix",
        "category": "patch",
        "box": [503, 2, 163, 157],
        "transparent_bg": False,
        "trim": False,
        "usage": "floor patch",
    },
    {
        "name": "forest_floor_twilight_a",
        "category": "floor",
        "box": [2, 609, 163, 157],
        "transparent_bg": False,
        "trim": False,
        "usage": "base floor",
    },
    {
        "name": "forest_patch_grass_dry_large",
        "category": "patch",
        "box": [335, 2, 163, 157],
        "transparent_bg": False,
        "trim": False,
        "usage": "floor patch",
    },
    {
        "name": "forest_patch_roots_large",
        "category": "patch",
        "box": [335, 163, 163, 219],
        "transparent_bg": False,
        "trim": False,
        "usage": "floor patch",
    },
    {
        "name": "forest_patch_leaf_rust_large",
        "category": "patch",
        "box": [707, 163, 198, 219],
        "transparent_bg": False,
        "trim": False,
        "usage": "floor patch",
    },
    {
        "name": "forest_patch_leaf_rust_dense",
        "category": "patch",
        "box": [2, 383, 163, 219],
        "transparent_bg": False,
        "trim": False,
        "usage": "floor patch",
    },
    {
        "name": "forest_patch_stone_crack_large",
        "category": "patch",
        "box": [707, 383, 198, 219],
        "transparent_bg": False,
        "trim": False,
        "usage": "floor patch",
    },
    {
        "name": "forest_decor_rock_moss_small",
        "category": "decor",
        "box": [1246, 167, 75, 71],
        "transparent_bg": True,
        "trim": True,
        "bg_tolerance": 18,
        "usage": "decor",
    },
    {
        "name": "forest_decor_shroom_purple_cluster",
        "category": "decor",
        "box": [1076, 535, 81, 69],
        "transparent_bg": True,
        "trim": True,
        "bg_tolerance": 18,
        "usage": "decor",
    },
    {
        "name": "forest_decor_branch_dead_small",
        "category": "decor",
        "box": [1246, 243, 72, 68],
        "transparent_bg": True,
        "trim": True,
        "bg_tolerance": 18,
        "usage": "decor",
    },
    {
        "name": "forest_decor_shrub_green_small",
        "category": "decor",
        "box": [1250, 322, 62, 57],
        "transparent_bg": True,
        "trim": True,
        "bg_tolerance": 22,
        "usage": "decor",
    },
]


def _key_white_background(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = list(rgba.getdata())
    processed = []
    for red, green, blue, alpha in pixels:
        if red >= WHITE_THRESHOLD and green >= WHITE_THRESHOLD and blue >= WHITE_THRESHOLD:
            processed.append((red, green, blue, 0))
        else:
            processed.append((red, green, blue, alpha))
    rgba.putdata(processed)
    return rgba


def _color_distance(a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> int:
    return abs(a[0] - b[0]) + abs(a[1] - b[1]) + abs(a[2] - b[2])


def _remove_corner_background(image: Image.Image, tolerance: int) -> Image.Image:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    visited: set[tuple[int, int]] = set()
    seeds = [
        (0, 0),
        (width - 1, 0),
        (0, height - 1),
        (width - 1, height - 1),
    ]

    for seed_x, seed_y in seeds:
        seed_color = pixels[seed_x, seed_y]
        if seed_color[3] == 0:
            continue
        queue: deque[tuple[int, int]] = deque([(seed_x, seed_y)])
        while queue:
            x, y = queue.popleft()
            if (x, y) in visited:
                continue
            visited.add((x, y))
            color = pixels[x, y]
            if color[3] == 0 or _color_distance(color, seed_color) > tolerance:
                continue
            pixels[x, y] = (color[0], color[1], color[2], 0)
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in visited:
                    queue.append((nx, ny))

    return rgba


def _make_tileable_edges(image: Image.Image, band: int) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    edge_band = min(band, width // 2, height // 2)
    if edge_band <= 0:
        return rgba

    for offset in range(edge_band):
        opposite_x = width - 1 - offset
        for y in range(height):
            left = pixels[offset, y]
            right = pixels[opposite_x, y]
            averaged = (
                (left[0] + right[0]) // 2,
                (left[1] + right[1]) // 2,
                (left[2] + right[2]) // 2,
                (left[3] + right[3]) // 2,
            )
            pixels[offset, y] = averaged
            pixels[opposite_x, y] = averaged

    for offset in range(edge_band):
        opposite_y = height - 1 - offset
        for x in range(width):
            top = pixels[x, offset]
            bottom = pixels[x, opposite_y]
            averaged = (
                (top[0] + bottom[0]) // 2,
                (top[1] + bottom[1]) // 2,
                (top[2] + bottom[2]) // 2,
                (top[3] + bottom[3]) // 2,
            )
            pixels[x, offset] = averaged
            pixels[x, opposite_y] = averaged

    return rgba


def _extract_asset(source: Image.Image, spec: dict) -> tuple[Image.Image, dict]:
    x, y, width, height = spec["box"]
    region = source.crop((x, y, x + width, y + height)).convert("RGBA")
    inset: int = int(spec.get("inset", 0))
    if inset > 0 and region.width > inset * 2 and region.height > inset * 2:
        region = region.crop((inset, inset, region.width - inset, region.height - inset))
    tileable_edge_band: int = int(spec.get("tileable_edge_band", 0))
    if tileable_edge_band > 0:
        region = _make_tileable_edges(region, tileable_edge_band)
    if spec["transparent_bg"]:
        region = _key_white_background(region)
        region = _remove_corner_background(region, spec.get("bg_tolerance", 18))
    if spec["trim"]:
        bbox = region.getbbox()
        if bbox is not None:
            region = region.crop(bbox)

    output_dir = ROOT / "art" / "runtime" / "environment" / "tiles" / spec["category"]
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{spec['name']}.png"
    region.save(output_path)

    manifest_entry = {
        "name": spec["name"],
        "category": spec["category"],
        "usage": spec["usage"],
        "source": str(SOURCE_PATH.relative_to(ROOT)).replace("\\", "/"),
        "source_rect": spec["box"],
        "inset": inset,
        "path": str(output_path.relative_to(ROOT)).replace("\\", "/"),
        "size": [region.width, region.height],
        "transparent_bg": spec["transparent_bg"],
        "trimmed": spec["trim"],
    }
    return region, manifest_entry


def _clear_generated_outputs() -> None:
    tiles_root = ROOT / "art" / "runtime" / "environment" / "tiles"
    for category in ("floor", "patch", "decor"):
        category_dir = tiles_root / category
        category_dir.mkdir(parents=True, exist_ok=True)
        for pattern in ("*.png", "*.png.import"):
            for file_path in category_dir.glob(pattern):
                file_path.unlink()


def _build_preview(entries: list[dict], images: dict[str, Image.Image]) -> None:
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    rows = (len(entries) + PREVIEW_COLUMNS - 1) // PREVIEW_COLUMNS
    canvas = Image.new(
        "RGBA",
        (PREVIEW_COLUMNS * PREVIEW_CELL[0], rows * PREVIEW_CELL[1]),
        (18, 22, 28, 255),
    )
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.load_default()

    for index, entry in enumerate(entries):
        image = images[entry["name"]]
        row = index // PREVIEW_COLUMNS
        column = index % PREVIEW_COLUMNS
        left = column * PREVIEW_CELL[0]
        top = row * PREVIEW_CELL[1]
        draw.rounded_rectangle(
            (left + 8, top + 8, left + PREVIEW_CELL[0] - 8, top + PREVIEW_CELL[1] - 8),
            radius=12,
            fill=(30, 36, 44, 255),
            outline=(76, 94, 110, 255),
            width=2,
        )
        checker_left = left + 18
        checker_top = top + 18
        checker_right = left + PREVIEW_CELL[0] - 18
        checker_bottom = top + PREVIEW_CELL[1] - 58
        _draw_checkerboard(draw, checker_left, checker_top, checker_right, checker_bottom)
        paste_x = checker_left + (checker_right - checker_left - image.width) // 2
        paste_y = checker_top + (checker_bottom - checker_top - image.height) // 2
        canvas.alpha_composite(image, (paste_x, paste_y))
        label = f"{entry['name']}\n{entry['category']}  {entry['size'][0]}x{entry['size'][1]}"
        draw.multiline_text(
            (left + 18, top + PREVIEW_CELL[1] - 48),
            label,
            font=font,
            fill=(220, 230, 236, 255),
            spacing=2,
        )

    canvas.save(PREVIEW_PATH)


def _draw_checkerboard(draw: ImageDraw.ImageDraw, left: int, top: int, right: int, bottom: int) -> None:
    square = 12
    colors = [(52, 58, 66, 255), (66, 74, 84, 255)]
    for y in range(top, bottom, square):
        for x in range(left, right, square):
            color_index = ((x - left) // square + (y - top) // square) % 2
            draw.rectangle((x, y, min(x + square, right), min(y + square, bottom)), fill=colors[color_index])


def main() -> None:
    if not SOURCE_PATH.exists():
        raise FileNotFoundError(f"Missing source sheet: {SOURCE_PATH}")

    source = Image.open(SOURCE_PATH).convert("RGBA")
    _clear_generated_outputs()
    entries = []
    images: dict[str, Image.Image] = {}
    for spec in SPECS:
        image, entry = _extract_asset(source, spec)
        entries.append(entry)
        images[entry["name"]] = image

    MANIFEST_PATH.write_text(json.dumps({"assets": entries}, indent=2), encoding="utf-8")
    _build_preview(entries, images)
    print(f"EXTRACTED {len(entries)} assets to {MANIFEST_PATH}")
    print(f"PREVIEW {PREVIEW_PATH}")


if __name__ == "__main__":
    main()
