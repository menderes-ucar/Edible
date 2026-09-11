$ErrorActionPreference = "Stop"
Write-Host "=== EDIBLE EXACT IMAGE PIPELINE ===" -ForegroundColor Cyan
Write-Host "This downloads the real, fixed catalog images into assets/explore_images/."
Write-Host "No runtime image search is used."
Write-Host ""

if (-not (Test-Path "lib")) {
  throw "lib/ bulunamadı. Bu dosyayı Flutter proje kökünde çalıştır."
}

if (-not (Test-Path "tooling/build_image_manifest.dart")) {
  throw "tooling/build_image_manifest.dart bulunamadı."
}

New-Item -ItemType Directory -Force -Path "assets/explore_images" | Out-Null

Write-Host "[1/2] Catalog taranıyor, gerçek görseller aranıyor ve indiriliyor..." -ForegroundColor Yellow
dart run tooling/build_image_manifest.dart
if ($LASTEXITCODE -ne 0) {
  Write-Host "Image builder başarısız oldu. tooling/image_manifest_missing.txt dosyasını kontrol et." -ForegroundColor Red
  exit $LASTEXITCODE
}

Write-Host "[2/2] Fiziksel asset doğrulaması..." -ForegroundColor Yellow
dart run tooling/verify_image_manifest.dart
if ($LASTEXITCODE -ne 0) {
  Write-Host "VERIFY BAŞARISIZ: eksik fiziksel görseller var." -ForegroundColor Red
  exit $LASTEXITCODE
}

Write-Host ""
Write-Host "TAMAMLANDI: assets/explore_images artık gerçek görseller içeriyor." -ForegroundColor Green
Write-Host "Flutter pubspec.yaml içine şu satırın olduğundan emin ol:" -ForegroundColor Cyan
Write-Host "  - assets/explore_images/"
