#!/usr/bin/env python3
import argparse,csv,json,re,sys,time
from concurrent.futures import ThreadPoolExecutor,as_completed
from pathlib import Path
from urllib.parse import quote
from urllib.request import Request,urlopen

ALLOWED={'cc0','public domain','public domain mark','cc by','cc by-sa','cc by 4.0','cc by-sa 4.0','pdm'}
HEAD={'User-Agent':'EdibleImageHarvester/1.0 (open-license catalog asset builder)'}

def get_json(url):
    req=Request(url,headers=HEAD)
    with urlopen(req,timeout=30) as r:return json.loads(r.read().decode('utf-8'))

def get_bytes(url):
    req=Request(url,headers=HEAD)
    with urlopen(req,timeout=60) as r:return r.read(),r.headers.get_content_type()

def norm(s):
    s=(s or '').strip().lower()
    s=s.replace('ı','i').replace('İ','i').replace('ğ','g').replace('Ğ','g').replace('ü','u').replace('Ü','u').replace('ş','s').replace('Ş','s').replace('ö','o').replace('Ö','o').replace('ç','c').replace('Ç','c')
    return re.sub(r'\s+',' ',re.sub(r'[^a-z0-9]+',' ',s)).strip()
def tokens(s):return set(norm(s).split())
def allowed(lic):
    n=norm(lic)
    if 'non commercial' in n or re.search(r'\bnd\b',n): return False
    return any(n==x or n.startswith(x+' ') for x in ALLOWED)
def score(title,city,country,cand):
    q=tokens(' '.join([title,city,country])); c=tokens(' '.join([cand.get('title',''),cand.get('description',''),cand.get('tags',''),cand.get('categories','')]))
    return len(q & c)*10 + (20 if norm(title)==norm(cand.get('title','')) else 0) + (8 if norm(city) in norm(cand.get('description','')+' '+cand.get('title','')) else 0)
def commons_search(title,city,country):
    q=' '.join([title,city,country])
    url='https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrnamespace=6&gsrsearch='+quote(q)+'&gsrlimit=10&prop=imageinfo&iiprop=url|extmetadata&iiurlwidth=1600&format=json'
    data=get_json(url); out=[]
    for p in data.get('query',{}).get('pages',{}).values():
        ii=(p.get('imageinfo') or [{}])[0]; md=ii.get('extmetadata',{})
        def val(k):return re.sub('<[^>]+>',' ',str(md.get(k,{}).get('value','')))
        lic=val('LicenseShortName') or val('License')
        if not allowed(lic):continue
        out.append({'provider':'Wikimedia Commons','license':lic,'source_page':'https://commons.wikimedia.org/wiki/'+quote(p.get('title','').replace(' ','_')),'media_url':ii.get('thumburl') or ii.get('url'),'title':val('ObjectName') or p.get('title',''),'description':val('ImageDescription'),'tags':val('Categories'),'categories':val('Categories'),'score':score(title,city,country,{'title':val('ObjectName') or p.get('title',''),'description':val('ImageDescription'),'tags':val('Categories')})})
    return sorted(out,key=lambda x:x['score'],reverse=True)
def openverse_search(title,city,country):
    q=quote(' '.join([title,city,country]))
    url='https://api.openverse.org/v1/images/?q='+q+'&page_size=10'
    data=get_json(url); out=[]
    for x in data.get('results',[]):
        lic=x.get('license','');
        if not allowed(lic):continue
        out.append({'provider':'Openverse','license':lic,'source_page':x.get('foreign_landing_url',''),'media_url':x.get('url'),'title':x.get('title',''),'description':x.get('description','') or '','tags':' '.join(x.get('tags') or []),'categories':'','score':score(title,city,country,x)})
    return sorted(out,key=lambda x:x['score'],reverse=True)
def key_for(r):
    # MUST match build_image_manifest.dart and SmartContentImage: FNV-1a 64-bit
    value=f"{norm(r['title'])}|{norm(r['city'])}|{norm(r['country'])}"
    h=0xcbf29ce484222325
    for b in value.encode('utf-8'):
        h ^= b
        h=(h*0x100000001b3)&0xffffffffffffffff
    return f'{h:016x}'
def ext(url,ctype):
    u=url.lower().split('?')[0]
    for e in ('.jpg','.jpeg','.png','.webp'):
        if u.endswith(e):return e
    return {'image/jpeg':'.jpg','image/png':'.png','image/webp':'.webp'}.get(ctype,'.jpg')
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--project-root',default='.');ap.add_argument('--workers',type=int,default=6);ap.add_argument('--limit',type=int,default=0);args=ap.parse_args()
 root=Path(args.project_root).resolve(); inv=root/'tooling/catalog_inventory.csv'; assets=root/'assets/explore_images'; assets.mkdir(parents=True,exist_ok=True)
 rows=list(csv.DictReader(inv.open(encoding='utf-8-sig')))
 if args.limit: rows=rows[:args.limit]
 def one(r):
  try:
   cand=commons_search(r['title'],r['city'],r['country'])
   if not cand: cand=openverse_search(r['title'],r['city'],r['country'])
   if not cand:return {**r,'status':'UNRESOLVED'}
   c=cand[0]
   # require meaningful match; prevents random category fallback
   if c['score']<12:return {**r,'status':'UNRESOLVED'}
   data,ctype=get_bytes(c['media_url'])
   if len(data)<1024:return {**r,'status':'UNRESOLVED'}
   extn=ext(c['media_url'],ctype); fn=key_for(r)+extn; (assets/fn).write_bytes(data)
   return {**r,'status':'FOUND','provider':c['provider'],'license':c['license'],'source_page':c['source_page'],'media_url':c['media_url'],'local_asset':'assets/explore_images/'+fn}
  except Exception as e:return {**r,'status':'ERROR','provider':'','license':'','source_page':'','media_url':'','local_asset':'','error':str(e)[:300]}
 results=[]
 with ThreadPoolExecutor(max_workers=args.workers) as ex:
  fs=[ex.submit(one,r) for r in rows]
  for i,f in enumerate(as_completed(fs),1):
   results.append(f.result());
   if i%25==0:print(f'processed {i}/{len(rows)}',flush=True)
 results.sort(key=lambda x:(x['country'].lower(),x['city'].lower(),x['title'].lower()))
 fields=['title','city','country','source_file','status','provider','license','source_page','media_url','local_asset','error']
 with inv.open('w',newline='',encoding='utf-8-sig') as f:
  w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(results)
 from collections import Counter
 c=Counter(x['status'] for x in results);print('SUMMARY',dict(c));print('ASSETS',sum(1 for p in assets.iterdir() if p.suffix.lower() in {'.jpg','.jpeg','.png','.webp'}));
 (root/'tooling/image_manifest_missing.txt').write_text('\n'.join(f"{r['title']} | {r['city']} | {r['country']}" for r in results if r['status']!='FOUND'),encoding='utf-8')
if __name__=='__main__':main()
