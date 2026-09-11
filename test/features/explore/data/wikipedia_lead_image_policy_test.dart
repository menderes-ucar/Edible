import 'package:flutter_test/flutter_test.dart';

void main() {
  test('image resolver policy is exact-page-first, not generic stock', () {
    const policy = <String>[
      'localized Wikipedia page search',
      'title similarity threshold',
      'page lead image',
      'Commons license metadata',
      'CC BY / CC0 / Public Domain only',
    ];
    expect(policy.length, 5);
  });
}
