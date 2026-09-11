#!/usr/bin/env python3
"""Fetch named POIs around GeoNames cities from Wikidata Query Service.

This is a bounded per-city enrichment job, not a whole-Wikidata bulk query.
Wikidata documentation explicitly recommends dumps rather than WDQS for
requests that cover a substantial percentage of Wikidata.
"""
import argparse,csv,json,time,urllib.parse,urllib.request
from pathlib import Path

ENDPOINT="https://query.wikidata.org/sparql"
UA="EdibleTravelCatalog/1.0 (catalog enrichment)"
TYPES=["wd:Q570116","wd:Q33506","wd:Q4989906","wd:Q16970","wd:Q839954"]

def query(lat,lon,radius):
    values=" ".join(TYPES)
    return f"""
SELECT DISTINCT ?item ?itemLabel ?coord ?image WHERE {{
  VALUES ?type {{ {values} }}
  ?item wdt:P31/wdt:P279* ?type;
        wdt:P625 ?coord.
  SERVICE wikibase:around {{
    ?item wdt:P625 ?coord.
    bd:serviceParam wikibase:center "Point({lon} {lat})"^^geo:wktLiteral;
                    wikibase:radius "{radius}".
  }}
  OPTIONAL {{ ?item wdt:P18 ?image. }}
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en,tr,de,fr,es,it,ar". }}
}}
LIMIT 30
"""

def fetch(sparql):
    url=ENDPOINT+"?"+urllib.parse.urlencode({"query":sparql,"format":"json"})
    req=urllib.request.Request(url,headers={"User-Agent":UA,"Accept":"application/sparql-results+json"})
    with urllib.request.urlopen(req,timeout=45) as r:
        return json.load(r)["results"]["bindings"]

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("cities_csv",type=Path,
      help="CSV columns: geonames_id,country_code,name,latitude,longitude")
    ap.add_argument("--out",type=Path,default=Path("build/wikidata_city_places.csv"))
    ap.add_argument("--radius-km",type=float,default=15)
    ap.add_argument("--sleep",type=float,default=1.0)
    args=ap.parse_args();args.out.parent.mkdir(parents=True,exist_ok=True)
    fields=["source_provider","source_id","city_geonames_id","category_key","title",
            "image_url","source_url","source_license","source_author"]
    with args.cities_csv.open(encoding="utf-8",newline="") as src, args.out.open("w",encoding="utf-8",newline="") as dst:
        w=csv.DictWriter(dst,fieldnames=fields);w.writeheader()
        for city in csv.DictReader(src):
            try: rows=fetch(query(float(city["latitude"]),float(city["longitude"]),args.radius_km))
            except Exception as e:
                print("SKIP",city.get("name"),e);continue
            seen=set()
            for b in rows:
                uri=b["item"]["value"];qid=uri.rsplit("/",1)[-1]
                if qid in seen:continue
                seen.add(qid)
                w.writerow({
                  "source_provider":"wikidata","source_id":qid,
                  "city_geonames_id":city["geonames_id"],"category_key":"place",
                  "title":b.get("itemLabel",{}).get("value",qid),
                  "image_url":b.get("image",{}).get("value",""),
                  "source_url":uri,
                  "source_license":"","source_author":"",
                })
            time.sleep(args.sleep)

if __name__=="__main__":main()
