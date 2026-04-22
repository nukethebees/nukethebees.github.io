#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import subprocess
import sys


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Recursively convert every PNG in the images directory to WebP."
    )
    parser.add_argument(
        "--images-dir",
        type=Path,
        default=Path("images"),
        help="Directory to scan for PNG files. Defaults to ./images.",
    )
    parser.add_argument(
        "--quality",
        type=int,
        default=80,
        help="WebP quality from 0 to 100. Defaults to 80.",
    )
    parser.add_argument(
        "--cwebp",
        type=str,
        default="cwebp",
        help="Path to the cwebp executable. Defaults to `cwebp`.",
    )
    return parser.parse_args()


def iter_pngs(images_dir: Path) -> list[Path]:
    return sorted(
        path
        for path in images_dir.rglob("*")
        if path.is_file() and path.suffix.lower() == ".webp"
    )


def convert_png_to_webp(source_path: Path, quality: int, cwebp_path: str) -> Path:
    destination_path = source_path.with_suffix(".webp")
    result = subprocess.run(
        [
            cwebp_path,
            "-quiet",
            "-q",
            str(quality),
            str(source_path),
            "-o",
            str(destination_path),
        ],
        capture_output=True,
        text=True,
        check=False,
    )

    if result.returncode != 0:
        error_output = result.stderr.strip() or result.stdout.strip() or "Unknown cwebp error"
        raise RuntimeError(f"Failed to convert {source_path}: {error_output}")

    return destination_path


def main() -> int:
    args = parse_args()
    images_dir = args.images_dir.resolve()

    if not images_dir.exists():
        print(f"Images directory does not exist: {images_dir}", file=sys.stderr)
        return 1

    if not images_dir.is_dir():
        print(f"Images path is not a directory: {images_dir}", file=sys.stderr)
        return 1

    if not 0 <= args.quality <= 100:
        print("--quality must be between 0 and 100.", file=sys.stderr)
        return 1

    if shutil.which(args.cwebp) is None:
        print(
            f"Could not find cwebp executable: {args.cwebp}. Install cwebp or pass --cwebp.",
            file=sys.stderr,
        )
        return 1

    png_files = iter_pngs(images_dir)

    if not png_files:
        print(f"No PNG files found in {images_dir}")
        return 0

    for source_path in png_files:
        try:
            destination_path = convert_png_to_webp(source_path, args.quality, args.cwebp)
        except RuntimeError as exc:
            print(str(exc), file=sys.stderr)
            return 1

        print(f"{source_path} -> {destination_path}")

    print(f"Converted {len(png_files)} PNG file(s). Originals were left unchanged.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
