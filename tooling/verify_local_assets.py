import re,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
manifest=root/'lib/features/explore/data/datasources/local_image_manifest.dart'
assets=root/'assets/explore_images'
paths=re.findall(r": '([^']+)'", manifest.read_text(encoding='utf-8'))
missing=[p for p in paths if not (root/p).is_file()]
images=[p for p in assets.iterdir() if p.suffix.lower() in {'.jpg','.jpeg','.png','.webp'}] if assets.exists() else []
print(f'manifest entries: {len(paths)}')
print(f'physical images: {len(images)}')
print(f'missing manifest files: {len(missing)}')
if missing:
    print('first missing:')
    for p in missing[:20]: print(' ',p)
    sys.exit(2)
print('LOCAL ASSET CHECK: PASS')
