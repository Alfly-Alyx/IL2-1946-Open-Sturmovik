#!/usr/bin/env python3
"""Build verified multi-aspect IL-2 loading-background families.

The artwork is never stretched. Common display families receive a cover crop;
ultrawide formats retain the complete composition over a softened extension.
The Maddox Games badge is composited from one deterministic master derived
from the official registered trademark image.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import OrderedDict
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps


FORMATS = OrderedDict(
    [
        ("4x3", (2880, 2160)),
        ("16x10", (3456, 2160)),
        ("16x9", (3840, 2160)),
        ("21x9", (3840, 1646)),
        ("32x9", (3840, 1080)),
    ]
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def resize_contain(source: Image.Image, size: tuple[int, int]) -> Image.Image:
    scale = min(size[0] / source.width, size[1] / source.height)
    resized = source.resize(
        (round(source.width * scale), round(source.height * scale)),
        Image.Resampling.LANCZOS,
    )
    return resized


def feather_mask(size: tuple[int, int], feather: int) -> Image.Image:
    width, height = size
    feather = max(1, min(feather, width // 2, height // 2))
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rectangle(
        (feather, feather, width - feather - 1, height - feather - 1),
        fill=255,
    )
    return mask.filter(ImageFilter.GaussianBlur(max(1, feather // 2)))


def adapt_without_distortion(
    source: Image.Image, size: tuple[int, int]
) -> Image.Image:
    source_ratio = source.width / source.height
    target_ratio = size[0] / size[1]

    # Only effectively identical ratios can use a cover fit. Any meaningful
    # ratio change retains the complete scene and every corner logo.
    ratio_delta = abs(source_ratio - target_ratio) / source_ratio
    if ratio_delta <= 0.012:
        return ImageOps.fit(
            source,
            size,
            method=Image.Resampling.LANCZOS,
            centering=(0.5, 0.5),
        )

    # Ultrawide screens retain the complete sharp composition. A darker,
    # blurred cover fills the remaining width without stretching the artwork.
    background = ImageOps.fit(
        source,
        size,
        method=Image.Resampling.LANCZOS,
        centering=(0.5, 0.5),
    )
    blur_radius = max(18, round(size[1] * 0.025))
    background = background.filter(ImageFilter.GaussianBlur(blur_radius))
    background = ImageEnhance.Brightness(background).enhance(0.72)

    foreground = resize_contain(source, size)
    x = (size[0] - foreground.width) // 2
    y = (size[1] - foreground.height) // 2
    feather = max(12, round(size[1] * 0.018))
    background.paste(
        foreground,
        (x, y),
        feather_mask(foreground.size, feather),
    )
    return background


def make_maddox_master(source_path: Path, output_path: Path) -> Image.Image:
    """Create one gold-on-black badge from the registered mark geometry."""

    original = Image.open(source_path).convert("L")
    # Crop only the true mark, not arbitrary whitespace in the registry JPEG.
    ink = ImageOps.invert(original)
    bbox = ink.point(lambda value: 255 if value > 18 else 0).getbbox()
    if bbox is None:
        raise RuntimeError("The Maddox Games source contains no detectable mark")
    mark = original.crop(bbox)

    # Preserve antialiasing from the source while removing its white field.
    alpha = ImageOps.invert(mark)
    alpha = alpha.point(lambda value: 0 if value < 10 else value)
    gold = Image.new("RGBA", mark.size, (222, 178, 73, 0))
    gold.putalpha(alpha)

    badge = Image.new("RGBA", (720, 760), (5, 5, 4, 255))
    border = 10
    for offset in range(border):
        color = (222, 178, 73, 255)
        badge.paste(color, (offset, offset, badge.width - offset, offset + 1))
        badge.paste(
            color,
            (
                offset,
                badge.height - offset - 1,
                badge.width - offset,
                badge.height - offset,
            ),
        )
        badge.paste(color, (offset, offset, offset + 1, badge.height - offset))
        badge.paste(
            color,
            (
                badge.width - offset - 1,
                offset,
                badge.width - offset,
                badge.height - offset,
            ),
        )

    fitted = ImageOps.contain(
        gold,
        (badge.width - 88, badge.height - 88),
        method=Image.Resampling.LANCZOS,
    )
    badge.alpha_composite(
        fitted,
        (
            (badge.width - fitted.width) // 2,
            (badge.height - fitted.height) // 2,
        ),
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    badge.save(output_path, format="PNG", optimize=True)
    return badge


def apply_badge(canvas: Image.Image, badge: Image.Image) -> Image.Image:
    result = canvas.convert("RGBA")
    target_height = round(canvas.height * 0.115)
    target_width = round(badge.width * target_height / badge.height)
    scaled = badge.resize((target_width, target_height), Image.Resampling.LANCZOS)
    x = round(canvas.width * 0.028)
    y = canvas.height - target_height - round(canvas.height * 0.035)
    result.alpha_composite(scaled, (x, y))
    return result.convert("RGB")


def build(
    root: Path,
    maddox_source: Path,
    themes: dict[str, Path],
) -> None:
    shared = root / "Shared"
    badge_path = shared / "Maddox-Games-Official-Gold.png"
    badge = make_maddox_master(maddox_source, badge_path)

    manifest: dict[str, object] = {
        "schemaVersion": 1,
        "generatedUtc": datetime.now(timezone.utc).isoformat(),
        "maximumCanvas": "3840x2160",
        "layoutPolicy": {
            "distortion": "never",
            "commonAspects": "centered cover crop",
            "ultrawideAspects": "complete composition over softened extension",
            "selection": "closest aspect family from conf.ini",
        },
        "maddoxGamesSource": {
            "url": (
                "https://s.rbk.ru/v1_companies_s3/media/trademarks/"
                "36552d74-5efd-42c1-a06f-06c6bca6c493.jpg"
            ),
            "record": (
                "https://companies.rbc.ru/trademark/235490/"
                "development-group-maddox-games/"
            ),
            "sourceSha256": sha256(maddox_source),
            "derivedMaster": str(badge_path.relative_to(root)).replace("\\", "/"),
            "derivedMasterSha256": sha256(badge_path),
            "method": "geometry preserved; deterministic gold-on-black treatment",
        },
        "formats": [
            {"name": name, "width": size[0], "height": size[1]}
            for name, size in FORMATS.items()
        ],
        "themes": [],
    }

    for theme_name, source_path in themes.items():
        source = Image.open(source_path).convert("RGB")
        theme_root = root / theme_name
        source_root = theme_root / "Source"
        source_root.mkdir(parents=True, exist_ok=True)
        clean_copy = source_root / "Clean.png"
        source.save(clean_copy, format="PNG", optimize=True)

        outputs = []
        for format_name, size in FORMATS.items():
            output_dir = theme_root / format_name
            output_dir.mkdir(parents=True, exist_ok=True)
            canvas = adapt_without_distortion(source, size)
            canvas = apply_badge(canvas, badge)

            png_path = output_dir / "Background.png"
            tga_path = output_dir / "Background.tga"
            preview_path = output_dir / "Preview.jpg"
            canvas.save(png_path, format="PNG", optimize=True)
            canvas.save(tga_path, format="TGA", compression=None)
            preview = ImageOps.contain(
                canvas,
                (960, 600),
                method=Image.Resampling.LANCZOS,
            )
            preview.save(preview_path, format="JPEG", quality=91, optimize=True)
            outputs.append(
                {
                    "format": format_name,
                    "width": size[0],
                    "height": size[1],
                    "pngSha256": sha256(png_path),
                    "tgaSha256": sha256(tga_path),
                }
            )
            print(f"{theme_name}: {format_name} {size[0]}x{size[1]}")

        manifest["themes"].append(
            {
                "name": theme_name,
                "source": str(source_path),
                "cleanSourceSha256": sha256(clean_copy),
                "outputs": outputs,
            }
        )

    manifest_path = root / "manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Manifest: {manifest_path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    parser.add_argument("maddox_source", type=Path)
    parser.add_argument(
        "themes_json",
        type=Path,
        help="JSON object mapping theme names to clean source paths",
    )
    args = parser.parse_args()
    themes_data = json.loads(args.themes_json.read_text(encoding="utf-8"))
    themes = {name: Path(path) for name, path in themes_data.items()}
    build(args.root, args.maddox_source, themes)


if __name__ == "__main__":
    main()
