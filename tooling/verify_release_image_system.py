import re, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
MAN=ROOT/'lib/features/explore/data/datasources/local_image_manifest.dart'
ASSETS=ROOT/'assets/explore_images'
PUB=ROOT/'pubspec.yaml'
paths=re.findall(r"^\s*'([0-9a-f]{16})':\s*'([^']+)'", MAN.read_text(encoding='utf-8'), re.M)
physical={p.as_posix() for p in ASSETS.glob('*') if p.suffix.lower() in {'.jpg','.jpeg','.png','.webp'}} if ASSETS.exists() else set()
missing=[(k,path) for k,path in paths if not (ROOT/path).is_file()]
asset_decl='assets/explore_images/' in PUB.read_text(encoding='utf-8')
print('=== EDIBLE RELEASE IMAGE SYSTEM ===')
print('Manifest slots :',len(paths))
print('Physical images:',len(physical))
print('Missing files  :',len(missing))
print('Pubspec asset  :', 'PASS' if asset_decl else 'FAIL')
if missing:
    print('\nFIRST 30 MISSING:')
    for k,p in missing[:30]: print(k,p)
if not asset_decl or missing:
    print('\nRELEASE IMAGE CHECK: FAIL')
    sys.exit(2)
print('\nRELEASE IMAGE CHECK: PASS')
