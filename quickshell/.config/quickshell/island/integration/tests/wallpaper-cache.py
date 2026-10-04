import json
import os
from pathlib import Path
import select
import subprocess
import tempfile
import unittest
from urllib.parse import unquote, urlparse

from PIL import Image


SCRIPT = Path(__file__).resolve().parents[2] / "scripts/cache-wallpapers.sh"


class WallpaperCacheTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="island-wallpaper-cache-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.directory = self.root / "wallpapers"
        self.directory.mkdir()
        self.cache = self.root / "cache"
        self.environment = {**os.environ, "ISLAND_THUMBNAIL_CACHE_DIR": str(self.cache)}

    def image(self, name, color="red"):
        path = self.directory / name
        path.parent.mkdir(parents=True, exist_ok=True)
        Image.new("RGB", (800, 600), color).save(path)
        return path

    def scan(self, *arguments):
        result = subprocess.run([str(SCRIPT), str(self.directory), *arguments], env=self.environment,
                                check=True, text=True, capture_output=True)
        return json.loads(result.stdout)

    def thumbnail(self, row):
        return Path(unquote(urlparse(row["thumbnail"]).path))

    def test_reuse_addition_and_edit(self):
        source = self.image("one #?.png")
        first = self.scan()[0]
        target = self.thumbnail(first)
        with Image.open(target) as image:
            self.assertEqual(image.size, (360, 200))
        original_stat = target.stat()
        self.assertEqual(self.scan(), [first])
        self.assertEqual(target.stat().st_mtime_ns, original_stat.st_mtime_ns)
        self.assertEqual(target.stat().st_ino, original_stat.st_ino)
        self.image("nested/two.png", "blue")
        rows = self.scan()
        self.assertEqual(len(rows), 2)
        self.assertIn(first, rows)
        Image.new("RGB", (800, 600), "green").save(source)
        changed = next(row for row in self.scan() if row["path"] == str(source))
        self.assertNotEqual(changed["thumbnail"], first["thumbnail"])
        self.assertTrue(self.thumbnail(changed).is_file())
        self.assertFalse(any(path.suffix == ".png" and len(path.stem) != 64 for path in self.cache.iterdir()))

    def test_dry_run_and_broken_image(self):
        self.image("one.png")
        self.scan("--dry-run")
        self.assertFalse(self.cache.exists())
        (self.directory / "broken.png").write_bytes(b"not an image")
        rows = self.scan()
        self.assertEqual(len(rows), 2)
        self.assertEqual(next(row for row in rows if row["path"].endswith("broken.png"))["thumbnail"], "")

    def read_update(self, worker):
        readable, _, _ = select.select([worker.stdout], [], [], 5)
        self.assertTrue(readable, "Watcher did not publish the changed wallpaper list")
        return json.loads(worker.stdout.readline())

    def test_watch_addition_removal_and_symlink(self):
        self.image("one.png")
        linked = self.root / "repository"
        linked.symlink_to(self.directory, target_is_directory=True)
        worker = subprocess.Popen([str(SCRIPT), str(linked), "--watch", "--interval", "0.5"],
                                  env=self.environment, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            first = self.read_update(worker)
            self.assertEqual(len(first), 1)
            target = self.thumbnail(first[0])
            saved_stat = target.stat()
            self.assertFalse(select.select([worker.stdout], [], [], 0.7)[0])
            added = self.image("nested/new wallpaper.png", "blue")
            rows = self.read_update(worker)
            self.assertEqual(len(rows), 2)
            self.assertTrue(all(self.thumbnail(row).is_file() for row in rows))
            self.assertEqual(target.stat().st_mtime_ns, saved_stat.st_mtime_ns)
            added.unlink()
            self.assertEqual(len(self.read_update(worker)), 1)
        finally:
            worker.terminate()
            worker.communicate(timeout=5)


if __name__ == "__main__":
    unittest.main()
