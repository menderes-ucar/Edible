#!/usr/bin/env python3
"""Filter GeoNames alternateNamesV2.txt to app-supported locales and city IDs.

Input columns:
alternateNameId, geonameid, isolanguage, alternate name,
isPreferredName, isShortName, isColloquial, isHistoric, from, to
"""
from __future__ import annotations
import argparse, csv
from pathlib import Path

LOCALES = {"en","tr","de","fr","es","it","ar"}
OUT = [
    "alternate_name_id","geoname_id","isolanguage","alternate_name",
    "is_preferred_name","is_short_name","is_colloquial","is_historic",
    "valid_from","valid_to",
]

def truthy(v: str) -> str:
    return "true" if v == "1" else "false"

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("alternate_names_v2_txt", type=Path)
    ap.add_argument("city_ids_txt", type=Path,
                    help="One GeoNames city ID per line; generated from the cities500 import.")
    ap.add_argument("--out", type=Path,
                    default=Path("build/geonames_alternate_name_import.csv"))
    args=ap.parse_args()

    city_ids={x.strip() for x in args.city_ids_txt.read_text(encoding="utf-8").splitlines() if x.strip()}
    args.out.parent.mkdir(parents=True, exist_ok=True)
    kept=0
    with args.alternate_names_v2_txt.open("r",encoding="utf-8",newline="") as src, \
         args.out.open("w",encoding="utf-8",newline="") as dst:
        w=csv.DictWriter(dst,fieldnames=OUT); w.writeheader()
        for line in src:
            row=line.rstrip("\n").split("\t")
            if len(row) < 4: continue
            row += [""] * (10-len(row))
            alt_id,gid,lang,name,pref,short,colloq,historic,valid_from,valid_to=row[:10]
            if gid not in city_ids or lang.lower() not in LOCALES or not name.strip():
                continue
            w.writerow({
                "alternate_name_id":alt_id,"geoname_id":gid,
                "isolanguage":lang.lower(),"alternate_name":name,
                "is_preferred_name":truthy(pref),"is_short_name":truthy(short),
                "is_colloquial":truthy(colloq),"is_historic":truthy(historic),
                "valid_from":valid_from,"valid_to":valid_to,
            })
            kept+=1
    print(f"Wrote {kept} localized city names to {args.out}")

if __name__=="__main__":
    main()
