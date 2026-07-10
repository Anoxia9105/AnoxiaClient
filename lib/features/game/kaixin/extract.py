#!/usr/bin/env python3
"""Extract J2ME composite sprites into Flame sprite sheets.

The sprite .bin format is read to match f.class:
  flags: u8
  tile_count: u16be
  tile rects: x, y, w, h (u8 or s16 depending on flags bits 0..3)
  frame_count: u8
  frames: part_count + parts(tile, transform_bits, dx, dy) + optional bounds
  animation_groups: u8 + groups(length + packed frame indexes)
"""

from __future__ import annotations

import json
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from PIL import Image


SRC = Path(__file__).resolve().parent
OUT = SRC.parent / "NotePadClient" / "assets" / "images" / "flame_sprites"
COLS = 8
TARGETS = [
    "waiter",
    "womanwaiter",
    "aunt",
    "uncle",
    "boy",
    "girl",
    "cleaner",
    "cop",
    "oldman",
    "oldwoman",
    "yongman",
    "yongwoman",
]

LOWER_BODY_DONORS = {
    "aunt": {3: 2, 4: 1, 5: 0, 6: 0},
    "boy": {3: 2, 4: 1, 5: 0, 6: 0},
    "girl": {3: 2, 4: 1, 5: 0, 6: 0},
    "oldman": {3: 2, 4: 1, 5: 0, 6: 0},
    "oldwoman": {3: 2, 4: 1, 5: 0, 6: 0},
    "uncle": {3: 2, 4: 1, 5: 0, 6: 0},
    "yongman": {3: 2, 4: 1, 5: 0, 6: 0},
    "yongwoman": {3: 2, 4: 1, 5: 0, 6: 0},
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
        if effective_h:
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
    global_h, global_v = frame_flip(global_transform)
    effective_h = global_h ^ bool(transform & 0x01)
    effective_v = global_v ^ bool(transform & 0x02)

    result = image
    if transform & 0x04:
        result = result.transpose(Image.Transpose.ROTATE_90)
    if effective_h:
        result = result.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if effective_v:
        result = result.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    return result


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


def display_transforms(groups: list[list[int]], group_packed: list[list[int]]) -> dict[int, int]:
    transforms: dict[int, int] = {}
    for group, packed_group in zip(groups, group_packed):
        for frame_index, packed in zip(group, packed_group):
            transforms.setdefault(frame_index, packed >> 10)
    return transforms


def build_sheet(
    name: str,
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

    rendered_frames = [
        render_frame(
            source,
            tiles,
            frame,
            frame_transforms.get(index, 0),
            (min_x, min_y),
            (cell_w, cell_h),
        )
        for index, frame in enumerate(frames)
    ]
    patch_lower_body(name, rendered_frames, min_y)

    for index, frame in enumerate(frames):
        rendered = rendered_frames[index]
        x = (index % COLS) * cell_w
        y = (index // COLS) * cell_h
        sheet.paste(rendered, (x, y), rendered)

    return sheet, cell_w, cell_h, (min_x, min_y)


def patch_lower_body(
    name: str,
    rendered_frames: list[Image.Image],
    min_y: int,
) -> None:
    donors = LOWER_BODY_DONORS.get(name)
    if not donors:
        return

    for target_index, donor_index in donors.items():
        if target_index >= len(rendered_frames) or donor_index >= len(rendered_frames):
            continue

        rendered_frames[target_index] = rendered_frames[donor_index].copy()


def build_animations(name: str, groups: list[list[int]], frame_count: int) -> dict[str, list[int]]:
    animations: dict[str, list[int]] = {
        "all": list(range(frame_count)),
    }

    for index, group in enumerate(groups):
        animations[f"group{index}"] = group

    if name in {"waiter", "womanwaiter"}:
        animations["idle"] = [0]
        animations["walking"] = [1, 2, 3, 4]
        animations["carryingFood"] = [6, 7, 8, 9]
        animations["preview"] = animations["walking"]
    elif name == "cleaner":
        animations["idle"] = groups[4] if len(groups) > 4 else [0]
        animations["walking"] = groups[5] if len(groups) > 5 else [0]
        animations["preview"] = animations["walking"]
    else:
        first_group = groups[0] if groups else [0]
        animations["idle"] = first_group
        animations["preview"] = first_group

    return animations


def process(name: str) -> dict[str, Any]:
    png_path = SRC / f"{name}.png"
    bin_path = SRC / f"{name}.bin"
    if not png_path.exists() or not bin_path.exists():
        raise FileNotFoundError(f"missing {name}.png or {name}.bin")

    parsed = parse_sprite(bin_path.read_bytes())
    source = Image.open(png_path).convert("RGBA")
    frame_transforms = display_transforms(parsed["groups"], parsed["group_packed"])
    sheet, cell_w, cell_h, origin = build_sheet(
        name,
        source,
        parsed["tiles"],
        parsed["frames"],
        frame_transforms,
    )

    OUT.mkdir(parents=True, exist_ok=True)
    sheet_path = OUT / f"{name}_anim_sheet.png"
    config_path = OUT / f"{name}_anim_config.json"
    sheet.save(sheet_path)

    frame_count = len(parsed["frames"])
    config: dict[str, Any] = {
        "sheet_path": f"flame_sprites/{name}_anim_sheet.png",
        "cell_w": cell_w,
        "cell_h": cell_h,
        "cols": COLS,
        "frame_count": frame_count,
        "origin": list(origin),
        "frame_transforms": {
            str(index): transform for index, transform in sorted(frame_transforms.items())
        },
        "animations": build_animations(name, parsed["groups"], frame_count),
        "groups": parsed["groups"],
        "group_packed": parsed["group_packed"],
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
    return config


def main() -> None:
    targets = sys.argv[1:] or TARGETS
    manifest = {}
    for name in targets:
        config = process(name)
        manifest[name] = {
            "sheet_path": config["sheet_path"],
            "config_path": f"assets/images/flame_sprites/{name}_anim_config.json",
            "cell_w": config["cell_w"],
            "cell_h": config["cell_h"],
            "frame_count": config["frame_count"],
            "animations": config["animations"],
        }
        print(
            f"{name}: {config['frame_count']} frames, "
            f"{len(config['groups'])} groups, cell {config['cell_w']}x{config['cell_h']}"
        )

    (OUT / "character_anim_manifest.json").write_text(
        json.dumps(manifest, indent=2),
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
