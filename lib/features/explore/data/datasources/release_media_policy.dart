class ReleaseMediaPolicy {
  const ReleaseMediaPolicy._();

  static const bool allowSearchPageAsImage = false;
  static const bool requireAttribution = true;
  static const bool requirePerFileLicenseVerification = true;

  static bool isDirectHttpsImageCandidate(String url) =>
      url.startsWith('https://') &&
      !url.contains('Special:MediaSearch') &&
      !url.contains('/wiki/Special:Search');
}
