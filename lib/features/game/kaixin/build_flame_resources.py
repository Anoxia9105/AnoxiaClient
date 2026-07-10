#!/usr/bin/env python3
"""Build Flame-ready assets from the original Kaixin J2ME resources.

Outputs:
  assets/images/flame_resources/sheets/*.png
  assets/images/flame_resources/config/*.json
  assets/images/flame_resources/raw/*.png
  assets/images/flame_resources/maps/*.png|*.tsx|*.json
"""

from __future__ import annotations

import json
import math
import shutil
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from PIL import Image


SRC = Path(__file__).resolve().parent
PROJECT = SRC.parents[3]
OUT = PROJECT / "assets" / "images" / "flame_resources"
SHEETS = OUT / "sheets"
CONFIG = OUT / "config"
RAW = OUT / "raw"
MAPS = OUT / "maps"
CUSTOMERS = OUT / "customers"
COLS = 8
MAP_TILE_W = 32
MAP_TILE_H = 16

SKIP_SPRITES = {
    "aunt",
    "boy",
    "cleaner",
    "cop",
    "girl",
    "oldman",
    "oldwoman",
    "uncle",
    "waiter",
    "womanwaiter",
    "yongman",
    "yongwoman",
}

IGNORE_FRAME_TRANSFORMS = {
    "chufang_04",
}

CUSTOMER_SPRITES = {
    "aunt",
    "boy",
    "girl",
    "oldman",
    "oldwoman",
    "uncle",
    "yongman",
    "yongwoman",
}


@dataclass(frozen=True)
class Tile:
    x: int
    y: int
    w: int
    h: int


@dataclass(frozen=True)
class Part:
    tile: int
    transform: int
    dx: int
    dy: int


@dataclass(frozen=True)
class Frame:
    parts: list[Part]
    bounds: list[int] | None
    hit_bounds: list[int] | None


def sbyte(value: int) -> int:
    return value - 256 if value > 127 else value


def u16be(data: bytes, pos: int) -> int:
    return (data[pos] << 8) | data[pos + 1]


def s16be(data: bytes, pos: int) -> int:
    value = u16be(data, pos)
    return value - 65536 if value >= 32768 else value


def i32be(data: bytes, pos: int) -> int:
    value = (
        (data[pos] << 24)
        | (data[pos + 1] << 16)
        | (data[pos + 2] << 8)
        | data[pos + 3]
    )
    return value - 0x100000000 if value >= 0x80000000 else value


def read_coord(data: bytes, pos: int, wide: bool, signed: bool = False) -> tuple[int, int]:
    if wide:
        return s16be(data, pos), pos + 2
    value = sbyte(data[pos]) if signed else data[pos]
    return value, pos + 1


def parse_sprite(data: bytes) -> dict[str, Any]:
    pos = 0
    flags = data[pos]
    pos += 1
    tile_count = u16be(data, pos)
    pos += 2

    tiles: list[Tile] = []
    for _ in range(tile_count):
        x, pos = read_coord(data, pos, bool(flags & 0x01))
        y, pos = read_coord(data, pos, bool(flags & 0x02))
        w, pos = read_coord(data, pos, bool(flags & 0x04))
        h, pos = read_coord(data, pos, bool(flags & 0x08))
        tiles.append(Tile(x, y, w, h))

    frame_count = data[pos]
    pos += 1
    frames: list[Frame] = []
    for _ in range(frame_count):
        part_count = data[pos]
        pos += 1
        parts: list[Part] = []
        for _ in range(part_count):
            tile = sbyte(data[pos])
            transform = sbyte(data[pos + 1])
            pos += 2
            dx, pos = read_coord(data, pos, bool(flags & 0x10), signed=True)
            dy, pos = read_coord(data, pos, bool(flags & 0x20), signed=True)
            parts.append(Part(tile, transform, dx, dy))

        bounds = None
        if not flags & 0x40:
            bounds = [sbyte(data[pos + i]) for i in range(4)]
            pos += 4

        hit_bounds = None
        if not flags & 0x80:
            hit_bounds = [sbyte(data[pos + i]) for i in range(4)]
            pos += 4

        frames.append(Frame(parts, bounds, hit_bounds))

    group_count = data[pos]
    pos += 1
    groups: list[list[int]] = []
    group_packed: list[list[int]] = []
    for _ in range(group_count):
        length = data[pos]
        pos += 1
        group: list[int] = []
        packed_group: list[int] = []
        for _ in range(length):
            low = data[pos]
            high = data[pos + 1]
            pos += 2
            packed = (high << 8) | low
            group.append(packed & 0x03FF)
            packed_group.append(packed)
        groups.append(group)
        group_packed.append(packed_group)

    if pos != len(data):
        raise ValueError(f"parsed {pos} bytes, file has {len(data)} bytes")

    return {
        "flags": flags,
        "tiles": tiles,
        "frames": frames,
        "groups": groups,
        "group_packed": group_packed,
    }


def frame_flip(global_transform: int) -> tuple[bool, bool]:
    return global_transform in (1, 3), global_transform in (2, 3)


def flip_code(horizontal: bool, vertical: bool) -> int:
    if horizontal:
        return 3 if vertical else 2
    return 1 if vertical else 0


def draw_region_transform(part_transform: int, global_transform: int = 0) -> int:
    global_h, global_v = frame_flip(global_transform)
    effective_h = global_h ^ bool(part_transform & 0x01)
    effective_v = global_v ^ bool(part_transform & 0x02)
    code = flip_code(effective_h, effective_v)

    if not part_transform & 0x04:
        return code

    if code == 0:
        return 5
    if code == 1:
        return 7
    if code == 2:
        return 4
    return 6


def transformed_part_bounds(
    tile: Tile,
    part: Part,
    global_transform: int = 0,
) -> tuple[int, int, int, int]:
    global_h, global_v = frame_flip(global_transform)
    effective_h = global_h ^ bool(part.transform & 0x01)
    effective_v = global_v ^ bool(part.transform & 0x02)

    x = -part.dx if global_h else part.dx
    y = -part.dy if global_v else part.dy
    width = tile.w
    height = tile.h

    if part.transform & 0x04:
        if not effective_h:
            x -= tile.h
        if effective_v:
            y -= tile.w
        width, height = tile.h, tile.w
    else:
        if effective_h:
            x -= tile.w
        if effective_v:
            y -= tile.h

    return x, y, x + width, y + height


def transform_tile(
    image: Image.Image,
    transform: int,
    global_transform: int = 0,
) -> Image.Image:
    final_transform = draw_region_transform(transform, global_transform)
    transforms = {
        0: None,
        1: Image.Transpose.FLIP_TOP_BOTTOM,
        2: Image.Transpose.FLIP_LEFT_RIGHT,
        3: Image.Transpose.ROTATE_180,
        4: Image.Transpose.TRANSPOSE,
        5: Image.Transpose.ROTATE_270,
        6: Image.Transpose.ROTATE_90,
        7: Image.Transpose.TRANSVERSE,
    }
    operation = transforms[final_transform]
    return image if operation is None else image.transpose(operation)


def display_transforms(groups: list[list[int]], group_packed: list[list[int]]) -> dict[int, int]:
    transforms: dict[int, int] = {}
    for group, packed_group in zip(groups, group_packed):
        for frame_index, packed in zip(group, packed_group):
            transforms.setdefault(frame_index, packed >> 10)
    return transforms


def render_frame(
    source: Image.Image,
    tiles: list[Tile],
    frame: Frame,
    global_transform: int,
    origin: tuple[int, int],
    size: tuple[int, int],
) -> Image.Image:
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    origin_x, origin_y = origin

    for part in frame.parts:
        tile = tiles[part.tile]
        crop = source.crop((tile.x, tile.y, tile.x + tile.w, tile.y + tile.h))
        crop = transform_tile(crop, part.transform, global_transform)
        left, top, _, _ = transformed_part_bounds(tile, part, global_transform)
        image.paste(crop, (left - origin_x, top - origin_y), crop)

    return image


def build_sheet(
    source: Image.Image,
    tiles: list[Tile],
    frames: list[Frame],
    frame_transforms: dict[int, int],
) -> tuple[Image.Image, int, int, tuple[int, int]]:
    extents: list[tuple[int, int, int, int]] = []
    for index, frame in enumerate(frames):
        global_transform = frame_transforms.get(index, 0)
        for part in frame.parts:
            extents.append(
                transformed_part_bounds(tiles[part.tile], part, global_transform)
            )

    min_x = min(left for left, _, _, _ in extents)
    min_y = min(top for _, top, _, _ in extents)
    max_x = max(right for _, _, right, _ in extents)
    max_y = max(bottom for _, _, _, bottom in extents)

    cell_w = max_x - min_x
    cell_h = max_y - min_y
    rows = math.ceil(len(frames) / COLS)
    sheet = Image.new("RGBA", (cell_w * COLS, cell_h * rows), (0, 0, 0, 0))

    for index, frame in enumerate(frames):
        rendered = render_frame(
            source,
            tiles,
            frame,
            frame_transforms.get(index, 0),
            (min_x, min_y),
            (cell_w, cell_h),
        )
        x = (index % COLS) * cell_w
        y = (index // COLS) * cell_h
        sheet.paste(rendered, (x, y), rendered)

    return sheet, cell_w, cell_h, (min_x, min_y)


def build_sprite(name: str) -> dict[str, Any]:
    parsed = parse_sprite((SRC / f"{name}.bin").read_bytes())
    source = Image.open(SRC / f"{name}.png").convert("RGBA")
    frame_transforms = (
        {}
        if name in IGNORE_FRAME_TRANSFORMS
        else display_transforms(parsed["groups"], parsed["group_packed"])
    )
    sheet, cell_w, cell_h, origin = build_sheet(
        source,
        parsed["tiles"],
        parsed["frames"],
        frame_transforms,
    )

    sheet_path = SHEETS / f"{name}_sheet.png"
    config_path = CONFIG / f"{name}.json"
    sheet.save(sheet_path)

    config = {
        "sheet_path": f"flame_resources/sheets/{name}_sheet.png",
        "cell_w": cell_w,
        "cell_h": cell_h,
        "cols": COLS,
        "frame_count": len(parsed["frames"]),
        "origin": list(origin),
        "animations": {
            "all": list(range(len(parsed["frames"]))),
            **{f"group{i}": group for i, group in enumerate(parsed["groups"])},
        },
        "groups": parsed["groups"],
        "group_packed": parsed["group_packed"],
        "frame_transforms": {
            str(index): transform for index, transform in sorted(frame_transforms.items())
        },
        "tiles": [tile.__dict__ for tile in parsed["tiles"]],
        "frames": [
            {
                "parts": [part.__dict__ for part in frame.parts],
                "bounds": frame.bounds,
                "hit_bounds": frame.hit_bounds,
            }
            for frame in parsed["frames"]
        ],
    }
    config_path.write_text(json.dumps(config, indent=2), encoding="utf-8")
    return {
        "name": name,
        "sheet_path": config["sheet_path"],
        "config_path": f"assets/images/flame_resources/config/{name}.json",
        "cell_w": cell_w,
        "cell_h": cell_h,
        "frame_count": len(parsed["frames"]),
        "group_count": len(parsed["groups"]),
    }


def build_customer_states(name: str) -> dict[str, Any]:
    parsed = parse_sprite((SRC / f"{name}.bin").read_bytes())
    source = Image.open(SRC / f"{name}.png").convert("RGBA")
    frame_transforms = display_transforms(parsed["groups"], parsed["group_packed"])
    sheet, cell_w, cell_h, origin = build_sheet(
        source,
        parsed["tiles"],
        parsed["frames"],
        frame_transforms,
    )

    sheet_path = CUSTOMERS / f"{name}_customer_states.png"
    config_path = CUSTOMERS / f"{name}.json"
    sheet.save(sheet_path)

    animations = {
        "all": list(range(len(parsed["frames"]))),
        "standing": [0, 1, 2],
        "seatedSide": [3, 4],
        "seatedFront": [5, 6],
    }
    config = {
        "sheet_path": f"flame_resources/customers/{name}_customer_states.png",
        "cell_w": cell_w,
        "cell_h": cell_h,
        "cols": COLS,
        "frame_count": len(parsed["frames"]),
        "origin": list(origin),
        "animations": animations,
        "description": (
            "Original customer frames. Frames 4-5 and 6-7 are intentionally "
            "partial seated/occluded poses from the J2ME data."
        ),
        "groups": parsed["groups"],
        "group_packed": parsed["group_packed"],
        "frame_transforms": {
            str(index): transform for index, transform in sorted(frame_transforms.items())
        },
    }
    config_path.write_text(json.dumps(config, indent=2), encoding="utf-8")
    return {
        "name": name,
        "sheet_path": config["sheet_path"],
        "config_path": f"assets/images/flame_resources/customers/{name}.json",
        "cell_w": cell_w,
        "cell_h": cell_h,
        "frame_count": len(parsed["frames"]),
        "animations": animations,
    }


def parse_map_dat(path: Path) -> dict[str, Any]:
    data = path.read_bytes()
    name_length = u16be(data, 0)
    signature = data[2 : 2 + name_length].decode("ascii", errors="replace")
    pos = 2 + name_length
    ints = [i32be(data, i) for i in range(pos, len(data), 4)]
    return {
        "signature": signature,
        "version": ints[0] if len(ints) > 0 else None,
        "width": ints[1] if len(ints) > 1 else None,
        "height": ints[2] if len(ints) > 2 else None,
        "tile_width": ints[3] if len(ints) > 3 else MAP_TILE_W,
        "tile_height": ints[4] if len(ints) > 4 else MAP_TILE_H,
        "raw_values_offset": pos,
        "raw_value_count": len(ints),
        "raw_values_preview": ints[:32],
    }


def build_tileset(name: str) -> dict[str, Any]:
    source_path = SRC / f"{name}.png"
    image = Image.open(source_path)
    target_png = MAPS / source_path.name
    shutil.copy2(source_path, target_png)

    columns = image.width // MAP_TILE_W
    rows = image.height // MAP_TILE_H
    tile_count = columns * rows

    tileset = ET.Element(
        "tileset",
        {
            "version": "1.10",
            "tiledversion": "1.10.2",
            "name": name,
            "tilewidth": str(MAP_TILE_W),
            "tileheight": str(MAP_TILE_H),
            "tilecount": str(tile_count),
            "columns": str(columns),
        },
    )
    ET.SubElement(
        tileset,
        "image",
        {
            "source": f"{name}.png",
            "width": str(image.width),
            "height": str(image.height),
        },
    )
    ET.ElementTree(tileset).write(
        MAPS / f"{name}.tsx",
        encoding="utf-8",
        xml_declaration=True,
    )

    metadata = {
        "name": name,
        "image_path": f"flame_resources/maps/{name}.png",
        "tsx_path": f"assets/images/flame_resources/maps/{name}.tsx",
        "image_width": image.width,
        "image_height": image.height,
        "tile_width": MAP_TILE_W,
        "tile_height": MAP_TILE_H,
        "columns": columns,
        "rows": rows,
        "tile_count": tile_count,
        "dat": parse_map_dat(SRC / f"{name}.dat"),
    }
    (MAPS / f"{name}.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    return metadata


def copy_raw_png(name: str) -> dict[str, Any]:
    source_path = SRC / f"{name}.png"
    image = Image.open(source_path)
    target_path = RAW / source_path.name
    shutil.copy2(source_path, target_path)
    return {
        "name": name,
        "path": f"flame_resources/raw/{source_path.name}",
        "width": image.width,
        "height": image.height,
    }


def clean_output() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    for directory in (SHEETS, CONFIG, RAW, MAPS, CUSTOMERS):
        directory.mkdir(parents=True, exist_ok=True)


def main() -> None:
    clean_output()

    sprite_names = sorted(
        path.stem
        for path in SRC.glob("*.bin")
        if (SRC / f"{path.stem}.png").exists() and path.stem not in SKIP_SPRITES
    )
    map_names = sorted(path.stem for path in SRC.glob("map_wall_*.dat"))
    raw_names = sorted(
        path.stem
        for path in SRC.glob("*.png")
        if not (SRC / f"{path.stem}.bin").exists()
        and not (SRC / f"{path.stem}.dat").exists()
    )

    manifest = {
        "sprites": [build_sprite(name) for name in sprite_names],
        "customers": [build_customer_states(name) for name in sorted(CUSTOMER_SPRITES)],
        "raw_images": [copy_raw_png(name) for name in raw_names],
        "maps": [build_tileset(name) for name in map_names],
        "skipped_existing_character_sprites": sorted(SKIP_SPRITES),
        "counts": {
            "sprites": len(sprite_names),
            "customers": len(CUSTOMER_SPRITES),
            "raw_images": len(raw_names),
            "maps": len(map_names),
        },
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps(manifest["counts"], indent=2))


if __name__ == "__main__":
    main()
