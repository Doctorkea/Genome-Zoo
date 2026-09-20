"""Fetch only the Godot 4.7.2 Web export template from the official TPZ."""

from __future__ import annotations

import os
import re
import struct
import subprocess
import sys
import tempfile
import zlib

RELEASE_URL = "https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz"
DEST_DIR = os.path.join(os.environ["APPDATA"], "Godot", "export_templates", "4.7.2.stable")
WANT = ("web_nothreads_release.zip", "web_nothreads_debug.zip")
TAIL = 4 * 1024 * 1024


def curl(args: list[str], dest: str | None = None) -> bytes:
    cmd = ["curl.exe", "--http1.1", "--retry", "8", "--retry-delay", "1", "--retry-all-errors", "--fail", "-L", *args]
    if dest is None:
        completed = subprocess.run(cmd, check=True, capture_output=True)
        return completed.stdout
    subprocess.run(cmd + ["--output", dest], check=True)
    with open(dest, "rb") as handle:
        return handle.read()


def resolve() -> tuple[str, int]:
    headers = curl(["-sD", "-", "-o", os.devnull, "-r", "0-0", RELEASE_URL]).decode("utf-8", "replace")
    locations = re.findall(r"(?im)^location:\s*(.+)$", headers)
    ranges = re.findall(r"(?im)^content-range:\s*bytes\s+\d+-\d+/(\d+)", headers)
    lengths = [int(value) for value in re.findall(r"(?im)^content-length:\s*(\d+)$", headers) if int(value) > 1000]
    total = int(ranges[-1]) if ranges else (lengths[-1] if lengths else 1281349702)
    cdn_url = locations[-1].strip() if locations else RELEASE_URL
    print("RESOLVE_HEADERS_OK")
    return cdn_url, total


def parse_eocd(blob: bytes) -> tuple[int, int, int]:
    idx = blob.rfind(b"PK\x05\x06")
    if idx < 0:
        raise RuntimeError("EOCD not found. Need a larger tail.")
    cd_size, cd_offset = struct.unpack_from("<II", blob, idx + 12)
    if cd_offset == 0xFFFFFFFF or cd_size == 0xFFFFFFFF:
        loc = blob.rfind(b"PK\x06\x07")
        if loc < 0:
            raise RuntimeError("ZIP64 locator missing.")
        zip64_offset = struct.unpack_from("<Q", blob, loc + 8)[0]
        raise RuntimeError(f"ZIP64 EOCD at {zip64_offset}; re-run with larger tail.")
    return cd_offset, cd_size, len(blob)


def parse_central_directory(cd: bytes) -> dict[str, dict]:
    entries: dict[str, dict] = {}
    pos = 0
    while pos + 46 <= len(cd):
        if cd[pos:pos + 4] != b"PK\x01\x02":
            break
        (
            _ver_made,
            _ver_need,
            _flags,
            method,
            _time,
            _date,
            _crc,
            comp_size,
            uncomp_size,
            name_len,
            extra_len,
            comment_len,
            _disk,
            _int_attr,
            _ext_attr,
            local_off,
        ) = struct.unpack_from("<HHHHHHIIIHHHHHII", cd, pos + 4)
        pos += 46
        name = cd[pos:pos + name_len].decode("utf-8", "replace")
        pos += name_len + extra_len + comment_len
        entries[name] = {
            "method": method,
            "comp_size": comp_size,
            "uncomp_size": uncomp_size,
            "local_off": local_off,
        }
    return entries


def extract_entry(cdn_url: str, entry: dict, raw_name: str) -> bytes:
    header = curl(["-r", f"{entry['local_off']}-{entry['local_off'] + 64 * 1024 - 1}", cdn_url])
    if header[:4] != b"PK\x03\x04":
        raise RuntimeError(f"Bad local header for {raw_name}")
    name_len, extra_len = struct.unpack_from("<HH", header, 26)
    data_start = 30 + name_len + extra_len
    need = data_start + entry["comp_size"]
    if len(header) < need:
        extra = curl(
            ["-r", f"{entry['local_off'] + len(header)}-{entry['local_off'] + need - 1}", cdn_url]
        )
        header += extra
    payload = header[data_start:data_start + entry["comp_size"]]
    if entry["method"] == 0:
        return payload
    if entry["method"] == 8:
        return zlib.decompress(payload, -15)
    raise RuntimeError(f"Unsupported compression {entry['method']} for {raw_name}")


def main() -> int:
    cdn_url, total = resolve()
    print(f"TOTAL {total}")
    tail_start = max(0, total - TAIL)
    tail_path = os.path.join(tempfile.gettempdir(), "godot_templates_tail.bin")
    print(f"TAIL {tail_start}-{total - 1}")
    curl(["-r", f"{tail_start}-{total - 1}", cdn_url], dest=tail_path)
    tail = open(tail_path, "rb").read()
    cd_offset, cd_size, _ = parse_eocd(tail)
    print(f"CD offset={cd_offset} size={cd_size}")
    if cd_offset < tail_start:
        cd = curl(["-r", f"{cd_offset}-{cd_offset + cd_size - 1}", cdn_url])
    else:
        start = cd_offset - tail_start
        cd = tail[start:start + cd_size]
    entries = parse_central_directory(cd)
    print("FILES")
    for name in sorted(entries):
        print(f"  {name} {entries[name]['uncomp_size']}")

    os.makedirs(DEST_DIR, exist_ok=True)
    found = 0
    for raw_name, entry in entries.items():
        base = os.path.basename(raw_name.replace("\\", "/"))
        if base not in WANT:
            continue
        print(f"EXTRACT {raw_name} ({entry['uncomp_size']} bytes)")
        data = extract_entry(cdn_url, entry, raw_name)
        target = os.path.join(DEST_DIR, base)
        with open(target, "wb") as handle:
            handle.write(data)
        print(f"WROTE {target} {len(data)}")
        found += 1

    version_path = os.path.join(DEST_DIR, "version.txt")
    with open(version_path, "w", encoding="utf-8") as handle:
        handle.write("4.7.2.stable\n")
    if found == 0:
        print("WEB_TEMPLATE_NOT_FOUND", file=sys.stderr)
        return 2
    print("WEB_TEMPLATES_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
