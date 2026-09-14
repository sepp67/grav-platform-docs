#!/usr/bin/env python3
"""Vérifie que chaque lien interne de contenu (zone #body-inner, pas la
barre latérale générée par le thème) répond HTTP 200, sur toutes les pages
publiées déduites de grav/user/pages/. Usage :

    check_internal_links.py <base_url> <pages_dir>

Code de sortie 0 si tous les liens répondent 200, 1 sinon (détail affiché).
"""
import os
import re
import sys
import urllib.error
import urllib.request


def routes_from_pages_dir(pages_dir: str) -> list[str]:
    routes = []
    for top in sorted(os.listdir(pages_dir)):
        top_path = os.path.join(pages_dir, top)
        if not os.path.isdir(top_path):
            continue
        top_slug = re.sub(r"^\d+\.", "", top)
        routes.append(f"/{top_slug}")
        for sub in sorted(os.listdir(top_path)):
            sub_path = os.path.join(top_path, sub)
            if not os.path.isdir(sub_path):
                continue
            sub_slug = re.sub(r"^\d+\.", "", sub)
            routes.append(f"/{top_slug}/{sub_slug}")
    return routes


def main() -> int:
    base_url, pages_dir = sys.argv[1], sys.argv[2]
    routes = routes_from_pages_dir(pages_dir)

    cache: dict[str, object] = {}

    def check(url: str):
        if url in cache:
            return cache[url]
        try:
            req = urllib.request.Request(base_url + url, method="HEAD")
            with urllib.request.urlopen(req, timeout=5) as r:
                code = r.status
        except urllib.error.HTTPError as e:
            code = e.code
        except Exception as e:  # noqa: BLE001 - report, don't crash the crawl
            code = f"ERR:{e}"
        cache[url] = code
        return code

    total_links = 0
    broken: list[tuple[str, str, object]] = []
    for route in routes:
        try:
            with urllib.request.urlopen(base_url + route, timeout=5) as r:
                html = r.read().decode("utf-8", "ignore")
        except Exception as e:  # noqa: BLE001
            print(f"[FAIL] page injoignable : {route} -> {e}", file=sys.stderr)
            broken.append((route, "(page elle-même)", str(e)))
            continue
        m = re.search(r'id="body-inner"(.*?)(?:<footer|id="sidebar"|$)', html, re.DOTALL)
        region = m.group(1) if m else html
        for href in re.findall(r'<a[^>]+href="([^"#]+)"', region):
            if href.startswith("http") or href.startswith("mailto:"):
                continue
            total_links += 1
            code = check(href)
            if code != 200:
                broken.append((route, href, code))

    print(f"[test] {total_links} lien(s) interne(s) de contenu examinés sur {len(routes)} page(s)")
    if broken:
        print(f"[FAIL] {len(broken)} lien(s) cassé(s) :", file=sys.stderr)
        for route, href, code in broken:
            print(f"  {route} -> {href} ({code})", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
