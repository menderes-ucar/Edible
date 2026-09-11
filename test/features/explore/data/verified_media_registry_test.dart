import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/data/datasources/verified_media_registry.dart';

void main() {
  test('verified media has source, author and license', () {
    expect(verifiedMediaRegistry, isNotEmpty);
    for (final media in verifiedMediaRegistry.values) {
      expect(media.imageUrl.startsWith('https://'), isTrue);
      expect(media.sourcePageUrl.startsWith('https://commons.wikimedia.org/wiki/File:'), isTrue);
      expect(media.author.trim(), isNotEmpty);
      expect(media.license.trim(), isNotEmpty);
      expect(media.imageUrl.contains('MediaSearch'), isFalse);
    }
  });
}
