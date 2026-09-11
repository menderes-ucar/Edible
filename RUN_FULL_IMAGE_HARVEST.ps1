$ErrorActionPreference = 'Stop'
Write-Host 'Edible - FULL IMAGE HARVEST' -ForegroundColor Cyan
if (-not (Get-Command python -ErrorAction SilentlyContinue)) { throw 'Python 3 is required.' }
python tooling\image_harvester.py --project-root . --workers 8
if ($LASTEXITCODE -ne 0) { throw 'Image harvester failed.' }
python tooling\verify_local_assets.py
if ($LASTEXITCODE -ne 0) { throw 'Some manifest assets are still missing. See tooling/image_manifest_missing.txt' }
Write-Host 'ALL LOCAL IMAGE ASSETS ARE PRESENT.' -ForegroundColor Green
