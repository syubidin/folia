"""Unduh foto tanaman dari GBIF (lisensi CC0/CC-BY) + catat atribusi."""
import csv
import io
import pathlib
import time

import requests
from PIL import Image

API = "https://api.gbif.org/v1"
LICENSES = ["CC0_1_0", "CC_BY_4_0"]
PER_SPECIES = 250
OUT = pathlib.Path("dataset")


def taxon_key(name):
    r = requests.get(f"{API}/species/match", params={"name": name}, timeout=30).json()
    return r.get("usageKey")


def occurrences(key):
    offset = 0
    while offset < 2000:
        r = requests.get(
            f"{API}/occurrence/search",
            params={
                "taxonKey": key,
                "mediaType": "StillImage",
                "license": LICENSES,
                "basisOfRecord": "HUMAN_OBSERVATION",
                "limit": 100,
                "offset": offset,
            },
            timeout=60,
        ).json()
        yield from r.get("results", [])
        if r.get("endOfRecords", True):
            return
        offset += 100


def main():
    OUT.mkdir(exist_ok=True)
    with open("species.csv", newline="") as f, open(
        OUT / "ATTRIBUTION.csv", "w", newline=""
    ) as attr_file:
        attr = csv.writer(attr_file)
        attr.writerow(["slug", "occurrence", "creator", "license", "source"])
        for row in csv.DictReader(f):
            slug, name = row["slug"], row["scientific_name"]
            key = taxon_key(name)
            if not key:
                print("tidak ditemukan:", name)
                continue
            folder = OUT / slug
            folder.mkdir(exist_ok=True)
            saved = 0
            for occ in occurrences(key):
                if saved >= PER_SPECIES:
                    break
                media = next(
                    (m for m in occ.get("media", []) if m.get("type") == "StillImage"),
                    None,
                )
                if not media or not media.get("identifier"):
                    continue
                try:
                    data = requests.get(media["identifier"], timeout=30).content
                    img = Image.open(io.BytesIO(data)).convert("RGB")
                    img.thumbnail((512, 512))
                    img.save(folder / f"{occ['key']}.jpg", "JPEG", quality=90)
                except Exception:
                    continue
                attr.writerow(
                    [
                        slug,
                        occ["key"],
                        media.get("creator", ""),
                        media.get("license", ""),
                        media.get("references", ""),
                    ]
                )
                saved += 1
                time.sleep(0.1)
            print(f"{slug}: {saved} foto")


if __name__ == "__main__":
    main()