#!/usr/bin/env python3
from pathlib import Path
import argparse

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("cities500_txt",type=Path)
    ap.add_argument("--out",type=Path,default=Path("build/geonames_city_ids.txt"))
    args=ap.parse_args()
    args.out.parent.mkdir(parents=True,exist_ok=True)
    ids=[]
    for line in args.cities500_txt.read_text(encoding="utf-8").splitlines():
        cols=line.split("\t")
        if len(cols)>=8 and cols[6]=="P" and cols[7] in {"PPL","PPLA","PPLA2","PPLA3","PPLA4","PPLC"}:
            ids.append(cols[0])
    args.out.write_text("\n".join(ids)+"\n",encoding="utf-8")
    print(f"Wrote {len(ids)} city ids")
if __name__=="__main__": main()
