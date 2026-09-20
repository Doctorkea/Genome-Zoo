"""Extract GenomeZoo export templates from the official Godot 4.7.2 TPZ."""

from __future__ import annotations

import os
import sys
import zipfile

TPZ_PATH = os.path.join(os.environ.get("TEMP", os.environ.get("TMP", ".")), "Godot_v4.7.2-stable_export_templates.tpz")
DEST = os.path.join(os.environ["APPDATA"], "Godot", "export_templates", "4.7.2.stable")
NEEDED = {
    "web_nothreads_release.zip",
    "web_nothreads_debug.zip",
    "windows_release_x86_64.exe",
    "windows_debug_x86_64.exe",
    "macos.zip",
    "version.txt",
}


def main() -> int:
    if not os.path.isfile(TPZ_PATH):
        print(f"MISSING_TPZ {TPZ_PATH}", file=sys.stderr)
        return 1

    size = os.path.getsize(TPZ_PATH)
    print(f"TPZ_SIZE {size}")
    os.makedirs(DEST, exist_ok=True)

    extracted = []
    with zipfile.ZipFile(TPZ_PATH) as zf:
        for info in zf.infolist():
            name = os.path.basename(info.filename.replace("\\", "/"))
            if name not in NEEDED:
                continue
            target = os.path.join(DEST, name)
            print(f"EXTRACT {name} ({info.file_size} bytes) -> {target}")
            with zf.open(info) as src, open(target, "wb") as dst:
                while True:
                    chunk = src.read(1024 * 1024)
                    if not chunk:
                        break
                    dst.write(chunk)
            extracted.append(name)

    missing = sorted(NEEDED - set(extracted))
    if missing:
        print(f"MISSING_TEMPLATES {missing}", file=sys.stderr)
        print("ARCHIVE_NAMES:")
        with zipfile.ZipFile(TPZ_PATH) as zf:
            for info in zf.infolist():
                print(" ", info.filename)
        return 2

    print("TEMPLATES_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
