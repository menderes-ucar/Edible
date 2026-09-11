$ErrorActionPreference = 'Stop'
Write-Host '=== EDIBLE IMAGE SYSTEM ===' -ForegroundColor Cyan
if (-not (Test-Path 'pubspec.yaml')) { throw 'Project root / pubspec.yaml not found.' }
python tooling\verify_release_image_system.py
if ($LASTEXITCODE -eq 0) {
  Write-Host 'All bundled image slots are present.' -ForegroundColor Green
  exit 0
}
Write-Host ''
Write-Host 'Bundled images are incomplete. Starting exact licensed harvest...' -ForegroundColor Yellow
python tooling\image_harvester.py --project-root . --workers 8
if ($LASTEXITCODE -ne 0) { throw 'Image harvester failed.' }
python tooling\verify_release_image_system.py
if ($LASTEXITCODE -ne 0) { throw 'IMAGE SYSTEM FAILED: unresolved/missing assets remain. See tooling/catalog_inventory.csv and tooling/image_manifest_missing.txt' }
Write-Host 'IMAGE SYSTEM READY: all bundled assets verified.' -ForegroundColor Green
