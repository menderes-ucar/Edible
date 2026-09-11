#!/usr/bin/env python3
"""Validate an exported country_city_release_coverage CSV before release."""
import argparse,csv,sys
from pathlib import Path

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("coverage_csv",type=Path)
    args=ap.parse_args()
    bad=[]
    with args.coverage_csv.open(encoding="utf-8",newline="") as f:
        for row in csv.DictReader(f):
            if int(row["incomplete_city_count"]) > 0:
                bad.append(row)
    if bad:
        for r in bad:
            print(f'NOT READY {r["country_code"]}: {r["ready_city_count"]}/{r["city_count"]} cities complete')
        sys.exit(1)
    print("All catalog countries have complete city content coverage.")
if __name__=="__main__": main()
