"""Download Godot 4.7.2 export templates via the GitHub release CDN."""

from __future__ import annotations

import os
import re
import subprocess
import sys
import threading
import time

RELEASE_URL = "https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz"
DEST = os.path.join(os.environ.get("TEMP", os.environ.get("TMP", ".")), "Godot_v4.7.2-stable_export_templates.tpz")
PARTS = 6
EXPECTED_SIZE = 1281349702
EXPECTED_SHA256 = "f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011"


def curl_output(args: list[str]) -> str:
    completed = subprocess.run(["curl.exe", *args], check=True, capture_output=True, text=True)
    return completed.stdout + completed.stderr


def resolve_cdn() -> tuple[str, int]:
    headers = curl_output(["-sI", "-L", "--http1.1", RELEASE_URL])
    locations = re.findall(r"(?im)^location:\s*(.+)$", headers)
    lengths = re.findall(r"(?im)^content-length:\s*(\d+)$", headers)
    if not locations:
        raise RuntimeError("No CDN redirect from GitHub releases.")
    cdn_url = locations[-1].strip()
    total = int(lengths[-1]) if lengths else EXPECTED_SIZE
    return cdn_url, total


def download_part(cdn_url: str, start: int, end: int, part_path: str, idx: int, status: list[object]) -> None:
    if os.path.isfile(part_path) and os.path.getsize(part_path) == (end - start + 1):
        status[idx] = os.path.getsize(part_path)
        return
    cmd = [
        "curl.exe",
        "--http1.1",
        "--retry",
        "20",
        "--retry-delay",
        "2",
        "--retry-all-errors",
        "--fail",
        "-r",
        f"{start}-{end}",
        "--output",
        part_path,
        cdn_url,
    ]
    proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    expected = end - start + 1
    while proc.poll() is None:
        size = os.path.getsize(part_path) if os.path.isfile(part_path) else 0
        status[idx] = size
        time.sleep(1)
    if proc.returncode != 0:
        status[idx] = f"fail:{proc.returncode}"
        raise RuntimeError(f"curl part {idx} failed with {proc.returncode}")
    size = os.path.getsize(part_path)
    status[idx] = size
    if size != expected:
        raise RuntimeError(f"curl part {idx} size {size} != {expected}")


def main() -> int:
    print(f"DEST {DEST}")
    if os.path.isfile(DEST) and os.path.getsize(DEST) == EXPECTED_SIZE:
        print("ALREADY_COMPLETE")
        return 0

    cdn_url, total = resolve_cdn()
    print(f"TOTAL {total}")
    if total != EXPECTED_SIZE:
        print(f"UNEXPECTED_SIZE {total}", file=sys.stderr)

    part_dir = DEST + ".parts"
    os.makedirs(part_dir, exist_ok=True)
    ranges: list[tuple[int, int]] = []
    part_size = total // PARTS
    for idx in range(PARTS):
        start = idx * part_size
        end = total - 1 if idx == PARTS - 1 else start + part_size - 1
        ranges.append((start, end))

    status: list[object] = [0] * PARTS
    threads: list[threading.Thread] = []
    errors: list[BaseException] = []

    def run(idx: int, start: int, end: int) -> None:
        try:
            download_part(cdn_url, start, end, os.path.join(part_dir, f"part{idx}"), idx, status)
        except BaseException as exc:  # noqa: BLE001
            errors.append(exc)

    for idx, (start, end) in enumerate(ranges):
        thread = threading.Thread(target=run, args=(idx, start, end), daemon=True)
        threads.append(thread)
        thread.start()

    while any(thread.is_alive() for thread in threads):
        done = sum(value for value in status if isinstance(value, int))
        print(f"PROGRESS {done}/{total} ({done * 100 / total:.1f}%)", flush=True)
        time.sleep(3)

    for thread in threads:
        thread.join()
    if errors:
        print(f"PART_ERRORS {errors}", file=sys.stderr)
        return 2

    print("ASSEMBLING")
    with open(DEST, "wb") as out:
        for idx in range(PARTS):
            part_path = os.path.join(part_dir, f"part{idx}")
            with open(part_path, "rb") as src:
                while True:
                    chunk = src.read(1024 * 1024)
                    if not chunk:
                        break
                    out.write(chunk)

    actual = os.path.getsize(DEST)
    print(f"DOWNLOADED {actual}")
    if actual != total:
        print("SIZE_MISMATCH", file=sys.stderr)
        return 3

    import hashlib

    digest = hashlib.sha256()
    with open(DEST, "rb") as handle:
        while True:
            data = handle.read(1024 * 1024)
            if not data:
                break
            digest.update(data)
    hexdigest = digest.hexdigest()
    print(f"SHA256 {hexdigest}")
    if hexdigest != EXPECTED_SHA256:
        print("HASH_MISMATCH", file=sys.stderr)
        return 4

    print("DOWNLOAD_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
