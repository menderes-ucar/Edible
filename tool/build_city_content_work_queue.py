#!/usr/bin/env python3
"""Prioritize incomplete cities without pretending generated content is factual."""
import argparse,csv
from pathlib import Path

def main():
    ap=argparse.ArgumentParser();ap.add_argument("coverage_csv",type=Path)
    ap.add_argument("--out",type=Path,default=Path("build/city_content_work_queue.csv"))
    args=ap.parse_args();args.out.parent.mkdir(parents=True,exist_ok=True)
    with args.coverage_csv.open(encoding="utf-8",newline="") as f:
        rows=list(csv.DictReader(f))
    rows=[r for r in rows if str(r.get("is_content_ready","")).lower() not in {"true","t","1"}]
    rows.sort(key=lambda r:(-int(r.get("population") or 0),r["country_code"],r["city_name"]))
    fields=["country_code","city_id","city_name","population","place_count","food_count","drink_count","snack_count","culture_count","regional_product_count"]
    with args.out.open("w",encoding="utf-8",newline="") as f:
        w=csv.DictWriter(f,fieldnames=fields);w.writeheader()
        for r in rows:w.writerow({k:r.get(k,"") for k in fields})
    print(f"{len(rows)} incomplete cities queued")
if __name__=="__main__":main()
