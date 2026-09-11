#!/usr/bin/env python3
import argparse,csv,sys
from pathlib import Path
def main():
 p=argparse.ArgumentParser();p.add_argument("media_gaps_csv",type=Path);a=p.parse_args()
 with a.media_gaps_csv.open(encoding="utf-8",newline="") as f: rows=list(csv.DictReader(f))
 if rows:
  print(f"NOT READY: {len(rows)} active contents have no verified media.")
  for r in rows[:50]: print(r.get("country_code"),r.get("city_name"),r.get("content_id"))
  sys.exit(1)
 print("All active contents have verified media.")
if __name__=="__main__":main()
