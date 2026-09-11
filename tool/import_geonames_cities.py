#!/usr/bin/env python3
"""Convert GeoNames cities500.txt into Supabase-ready CSV chunks.

GeoNames cities500 is CC BY 4.0. Expected 19 tab-separated columns.
This script does NOT invent or enrich cities.
"""
from __future__ import annotations
import argparse, csv
from pathlib import Path

COLS = [
    "geoname_id","name","ascii_name","alternate_names","latitude","longitude",
    "feature_class","feature_code","country_code","cc2","admin1_code","admin2_code",
    "admin3_code","admin4_code","population","elevation","dem","timezone","modification_date",
]
ALLOWED = {"PPL","PPLA","PPLA2","PPLA3","PPLA4","PPLC"}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cities500_txt", type=Path)
    ap.add_argument("--out", type=Path, default=Path("build/geonames_city_import.csv"))
    args = ap.parse_args()
    args.out.parent.mkdir(parents=True, exist_ok=True)

    kept = 0
    with args.cities500_txt.open("r", encoding="utf-8", newline="") as src, \
         args.out.open("w", encoding="utf-8", newline="") as dst:
        writer = csv.DictWriter(dst, fieldnames=COLS)
        writer.writeheader()
        for line in src:
            row = line.rstrip("\n").split("\t")
            if len(row) != 19:
                continue
            data = dict(zip(COLS, row))
            if data["feature_class"] != "P" or data["feature_code"] not in ALLOWED:
                continue
            writer.writerow(data)
            kept += 1
    print(f"Wrote {kept} city rows to {args.out}")

if __name__ == "__main__":
    main()
