#!/usr/bin/env python3
"""Build aspect-ratio-specific IL-2 loading backgrounds from one master."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

from PIL import Image, ImageOps


FORMATS = {
    "4x3": (2880, 2160),
    "16x10": (3456, 2160),
    "16x9": (3840, 2160),
    "21x9": (3840, 1600),
    "32x9": (3840, 1080),
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def build(
    master_path: Path, logo_path: Path, output_root: Path, save_png: bool
) -> None:
    master = Image.open(master_path).convert("RGB")
    logo = Image.open(logo_path).convert("RGB")

    for name, size in FORMATS.items():
        output_dir = output_root / name
        output_dir.mkdir(parents=True, exist_ok=True)

        canvas = ImageOps.fit(
            master,
            size,
            method=Image.Resampling.LANCZOS,
            centering=(0.5, 0.5),
        )

        # Match the original 2001 layout: the complete black-and-gold
        # 1C/Maddox Games cartouche sits near the lower-left corner.
        logo_height = round(size[1] * 0.20)
        logo_width = round(logo.width * logo_height / logo.height)
        scaled_logo = logo.resize(
            (logo_width, logo_height), Image.Resampling.LANCZOS
        )
        x = round(size[0] * 0.025)
        y = size[1] - logo_height - round(size[1] * 0.04)
        canvas.paste(scaled_logo, (x, y))

        tga_path = output_dir / "Background.tga"
        canvas.save(tga_path, format="TGA", compression=None)
        hashes = [f"TGA={sha256(tga_path)}"]
        if save_png:
            png_path = output_dir / "Background.png"
            canvas.save(png_path, format="PNG", optimize=True)
            hashes.insert(0, f"PNG={sha256(png_path)}")
        print(f"{name}: {size[0]}x{size[1]} {' '.join(hashes)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("master", type=Path)
    parser.add_argument("logo", type=Path)
    parser.add_argument("output_root", type=Path)
    parser.add_argument(
        "--png", action="store_true", help="also retain editable PNG copies"
    )
    args = parser.parse_args()
    build(args.master, args.logo, args.output_root, args.png)


if __name__ == "__main__":
    main()
