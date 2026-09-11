class GlobalMediaReleasePolicy {
  const GlobalMediaReleasePolicy._();
  static const bool allowGenericCategoryStockAsLandmarkPhoto = false;
  static const bool requireDirectAssetUrl = true;
  static const bool requirePerAssetLicenseRecord = true;

  static bool isReleaseSafePreferredUrl(String url) {
    final value = url.trim().toLowerCase();
    if (value.isEmpty) return false;
    if (value.contains('images.unsplash.com') || value.contains('source.unsplash.com')) {
      return false;
    }
    return value.contains('commons.wikimedia.org') ||
        value.contains('upload.wikimedia.org') ||
        value.contains('images.pexels.com');
  }
}
