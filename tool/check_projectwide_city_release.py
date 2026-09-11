#!/usr/bin/env python3
import argparse,csv,sys
from pathlib import Path
p=argparse.ArgumentParser()
p.add_argument("city_release_quality_csv",type=Path)
a=p.parse_args()
with a.city_release_quality_csv.open(encoding="utf-8",newline="") as f:
    rows=list(csv.DictReader(f))
bad=[r for r in rows if str(r.get("release_ready","")).lower() not in ("true","t","1")]
if bad:
    print(f"NOT READY: {len(bad)} cities fail project-wide release quality.")
    for r in bad[:100]:
        print(r.get("country_code"),r.get("city_name"),
              "places=",r.get("place_count"),
              "categories=",r.get("category_count"),
              "media=",r.get("verified_media_count"),
              "placeholders=",r.get("placeholder_count"))
    sys.exit(1)
print(f"READY: all {len(rows)} catalog cities pass the same release standard.")
