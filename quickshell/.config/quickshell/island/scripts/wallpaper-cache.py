import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import tempfile
import time

from PIL import Image, ImageOps


EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".gif"}


def arguments():
    parser = argparse.ArgumentParser(description="Cache Island wallpaper previews.")
    parser.add_argument("directory", type=Path)
    parser.add_argument("--cache-directory", type=Path, required=True)
    parser.add_argument("--width", type=int, default=360)
    parser.add_argument("--height", type=int, default=200)
    parser.add_argument("--watch", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--interval", type=float, default=float(os.environ.get("ISLAND_WALLPAPER_SCAN_INTERVAL", "2")))
    args = parser.parse_args()
    if not args.directory.is_absolute() or not args.cache_directory.is_absolute():
        parser.error("Directory and cache paths must be absolute.")
    if not 1 <= args.width <= 4096 or not 1 <= args.height <= 4096 or args.interval < 0.5:
        parser.error("Preview dimensions must be 1-4096; scan interval must be at least 0.5 seconds.")
    return args


def natural_key(path):
    return [(1, int(part)) if part.isdigit() else (0, part.casefold())
            for part in re.split(r"(\d+)", str(path))]


def wallpapers(directory):
    paths = []
    visited = set()
    for parent, folders, files in os.walk(directory, followlinks=True):
        try:
            stat = os.stat(parent)
        except OSError:
            folders.clear()
            continue
        identity = (stat.st_dev, stat.st_ino)
        if identity in visited:
            folders.clear()
            continue
        visited.add(identity)
        paths.extend(Path(parent) / name for name in files if Path(name).suffix.lower() in EXTENSIONS)
    return sorted(paths, key=natural_key)


def cache_path(path, args):
    stat = path.stat()
    identity = (str(path.resolve()), stat.st_size, stat.st_mtime_ns, stat.st_ctime_ns,
                args.width, args.height, "island-preview-v1")
    digest = hashlib.sha256(json.dumps(identity).encode()).hexdigest()
    return args.cache_directory / (digest + ".png")


def create_preview(path, target, args):
    if target.is_file() or args.dry_run:
        return
    with (args.cache_directory / ".lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if target.is_file():
            return
        with Image.open(path) as image:
            image.draft("RGB", (args.width, args.height))
            oriented = ImageOps.exif_transpose(image)
            preview = ImageOps.fit(oriented.convert("RGB"), (args.width, args.height), Image.Resampling.LANCZOS)
            descriptor, temporary = tempfile.mkstemp(dir=args.cache_directory, suffix=".png")
            try:
                with os.fdopen(descriptor, "wb") as output:
                    preview.save(output, format="PNG")
                os.replace(temporary, target)
            finally:
                Path(temporary).unlink(missing_ok=True)


def scan(args, failures):
    rows = []
    active = set()
    for path in wallpapers(args.directory):
        try:
            target = cache_path(path, args)
            active.add(target)
            if target not in failures:
                try:
                    create_preview(path, target, args)
                except (OSError, ValueError, Image.DecompressionBombError) as error:
                    failures.add(target)
                    print(f"Island preview: {path}: {error}", file=sys.stderr, flush=True)
            rows.append({"path": str(path), "thumbnail": target.as_uri() if target.is_file() else ""})
        except OSError:
            continue
    failures.intersection_update(active)
    return rows


def main():
    args = arguments()
    if not args.dry_run:
        args.cache_directory.mkdir(parents=True, exist_ok=True)
    previous = None
    failures = set()
    while True:
        rows = scan(args, failures)
        if rows != previous:
            print(json.dumps(rows), flush=True)
            previous = rows
        if not args.watch:
            return
        time.sleep(args.interval)


if __name__ == "__main__":
    main()
