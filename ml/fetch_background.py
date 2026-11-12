"""Unduh ~300 foto non-tanaman dari Wikimedia Commons untuk kelas _background."""
import io
import pathlib
import time

import requests
from PIL import Image

API = "https://commons.wikimedia.org/w/api.php"
HEADERS = {
    "User-Agent": "FoliaPlantApp/1.0 (https://github.com/syubidin/folia; ML dataset)"
}
OUT = pathlib.Path("dataset/_background")
TARGET_TOTAL = 300

QUERIES = [
    "wooden table furniture",
    "living room interior",
    "domestic cat indoor",
    "coffee mug cup desk",
    "laptop keyboard workspace",
    "ceramic floor tiles texture",
    "concrete brick wall",
    "human hand holding object",
]


def search_images(query, limit=50):
    params = {
        "action": "query",
        "generator": "search",
        "gsrsearch": f"filetype:bitmap {query}",
        "gsrnamespace": 6,
        "gsrlimit": limit,
        "prop": "imageinfo",
        "iiprop": "url|mime",
        "iiurlwidth": 512,
        "format": "json",
    }
    r = requests.get(API, params=params, headers=HEADERS, timeout=30).json()
    return r.get("query", {}).get("pages", {}).values()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    seen = set()
    saved = 0

    for q in QUERIES:
        if saved >= TARGET_TOTAL:
            break
        print(f"Mencari kategori: {q}...")
        try:
            pages = search_images(q, limit=50)
        except Exception as e:
            print(f"Gagal mencari '{q}': {e}")
            continue

        for page in pages:
            if saved >= TARGET_TOTAL:
                break
            pid = page.get("pageid")
            if not pid or pid in seen:
                continue
            seen.add(pid)

            info = page.get("imageinfo", [{}])[0]
            if info.get("mime") not in ("image/jpeg", "image/png"):
                continue
            url = info.get("thumburl") or info.get("url")
            if not url:
                continue

            try:
                data = requests.get(url, headers=HEADERS, timeout=30).content
                img = Image.open(io.BytesIO(data)).convert("RGB")
                img.thumbnail((512, 512))
                img.save(OUT / f"bg_{pid}.jpg", "JPEG", quality=85)
                saved += 1
                time.sleep(0.1)
            except Exception:
                continue

    print(f"Selesai! Total foto _background tersimpan: {saved}")


if __name__ == "__main__":
    main()