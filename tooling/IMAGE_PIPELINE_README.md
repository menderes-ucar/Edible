# Exact local image pipeline

Bu paket bilerek hazır görsel dosyaları uydurmaz. Gerçek görseller, senin internet bağlantısı olan geliştirme makinen üzerinde release-time indirilir.

## Tek komut

Flutter proje kökünde:

```powershell
powershell -ExecutionPolicy Bypass -File .\RUN_IMAGE_PIPELINE.ps1
```

veya `RUN_IMAGE_PIPELINE.bat` dosyasına çift tıkla.

## Çıktı

Gerçek dosyalar:

`assets/explore_images/`

Manifest:

`lib/features/explore/data/datasources/generated_image_manifest.dart`

`lib/features/explore/data/datasources/local_image_manifest.dart`

Audit:

`tooling/image_manifest_missing.txt`

## Release kuralı

`tooling/verify_image_manifest.dart` fiziksel dosyayı kontrol eder. Manifestte yol bulunması tek başına yeterli değildir.

Eksik dosya varsa release doğrulaması başarısız olur.
